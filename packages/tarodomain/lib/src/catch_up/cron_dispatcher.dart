import 'package:uuid/uuid.dart';

import '../adapters/dead_letter_store.dart';
import '../adapters/event_store_adapter.dart';
import '../adapters/unit_of_work.dart';
import '../bus/event_handler.dart';
import '../domain/serialized_event.dart';
import '../errors/error_codes.dart';
import '../errors/framework_error.dart';
import '../event_sourcing/event_store.dart';
import 'subscription_manager.dart';

/// Pull-based catch-up (spec §18.3): reads the events after each
/// subscription's cursor and hands them to the subscription's handler.
///
/// Each handler is subscribed under its own name. For each event, in order:
///
/// - on success, the cursor moves past the event;
/// - on a retryable error ([shouldRetry]), the pass stops and the cursor
///   stays, so the event is tried again on the next run;
/// - on any other error, including an event that can't be deserialized, the
///   event is written to the [deadLetters] store if there is one, and the
///   cursor moves past it.
///
/// With a [unitOfWork], each event's handler and cursor move commit
/// together, so a crash can't record one without the other. Without one, a
/// crash after the handler delivers the event again; handlers are
/// idempotent (spec §10.2), so that is safe.
final class CronDispatcher {
  /// Creates the dispatcher. [batchSize] is how many events one [catchUp]
  /// handles at most.
  ///
  /// Throws [InvalidConfigurationError] if [batchSize] is less than 1.
  CronDispatcher({
    required this.eventStore,
    required this.subscriptions,
    this.batchSize = 100,
    this.unitOfWork,
    this.deadLetters,
  }) {
    _checkBatchSize(batchSize);
  }

  /// Reads the events and deserializes them.
  final EventStore eventStore;

  /// Stores the cursors.
  final SubscriptionManager subscriptions;

  /// The default number of events per [catchUp].
  final int batchSize;

  /// Commits each event's handler and cursor move together, if given.
  final UnitOfWork? unitOfWork;

  /// Receives the events skipped after a non-retryable error, if given.
  final DeadLetterStore? deadLetters;

  final _handlers = <String, EventHandler>{};

  /// The registered handlers, in registration order.
  List<EventHandler> get handlers => List.unmodifiable(_handlers.values);

  /// The handler subscribed as [name], or null.
  EventHandler? handlerFor(String name) => _handlers[name];

  /// Subscribes [handler] under its name to [streamId] (null for every
  /// event). Registering the same handler again does nothing.
  ///
  /// Throws [InvalidConfigurationError] if a different handler has the same
  /// name, or the name is registered for another stream.
  void register(EventHandler handler, {String? streamId}) {
    final existing = _handlers[handler.name];
    if (existing != null && !identical(existing, handler)) {
      throw InvalidConfigurationError(
        'CronDispatcher already has a handler named "${handler.name}"',
        context: {'handler': handler.name},
      );
    }
    subscriptions.register(handler.name, streamId: streamId);
    _handlers[handler.name] = handler;
  }

  /// Runs one [catchUp] for every registered handler, after creating any
  /// missing subscriptions. A failure in one doesn't stop the others.
  Future<List<CatchUpResult>> runAll({int? batchSize}) async {
    await subscriptions.ensureAllSubscriptions();
    return [
      for (final name in List.of(_handlers.keys))
        await catchUp(name, batchSize: batchSize),
    ];
  }

  /// Hands up to [batchSize] events after the cursor of subscription [name]
  /// to its handler. Never throws for a failing event or load; the result
  /// reports it.
  ///
  /// With [stopOnError], a non-retryable error also stops the pass instead
  /// of skipping the event.
  ///
  /// Throws [InvalidConfigurationError] if no handler is registered as
  /// [name].
  Future<CatchUpResult> catchUp(
    String name, {
    int? batchSize,
    bool stopOnError = false,
  }) async {
    final handler =
        _handlers[name] ??
        (throw InvalidConfigurationError(
          'CronDispatcher has no handler named "$name"',
          context: {'subscription': name},
        ));
    final size = batchSize ?? this.batchSize;
    _checkBatchSize(size);
    final result = _CatchUpBuilder(name);

    final List<SerializedEvent> loaded;
    try {
      final subscription = await subscriptions.ensure(name);
      loaded = await eventStore.adapter.loadStreamAfterEvent(
        subscription.streamId ?? StreamIds.all,
        afterEventId: subscription.lastSeen,
        maxCount: size + 1,
      );
    } catch (error, stackTrace) {
      return result.stop(_loadFailed(name, error, stackTrace), stackTrace);
    }

    for (final serialized in loaded.take(size)) {
      try {
        await _run(() async {
          await handler.handle(eventStore.registry.deserialize(serialized));
          await _ack(name, serialized.eventId);
        });
        result.processed++;
      } catch (error, stackTrace) {
        if (stopOnError || shouldRetry(error)) {
          return result.stop(error, stackTrace, serialized.eventId);
        }
        try {
          await deadLetters?.write(
            DeadLetterInput(
              handlerName: name,
              event: serialized,
              errorMessage: '$error',
              errorCode: error is FrameworkError ? error.code : null,
              attempts: 1,
            ),
          );
          await _ack(name, serialized.eventId);
        } catch (writeError, writeStackTrace) {
          return result.stop(writeError, writeStackTrace, serialized.eventId);
        }
        result.skipped.add(SkippedEvent._(serialized, error, stackTrace));
      }
    }
    return result.finish(hasMore: loaded.length > size);
  }

  Future<void> _run(Future<void> Function() work) =>
      unitOfWork?.execute(work) ?? work();

  Future<void> _ack(String name, UuidValue eventId) =>
      eventStore.adapter.ackSubscription(name, eventId);

  static Object _loadFailed(String name, Object error, StackTrace stackTrace) =>
      error is FrameworkError
      ? error
      : EventLoadFailedError(
          'Catch-up for "$name" could not load events: $error',
          context: {'subscription': name},
          cause: error,
          stackTrace: stackTrace,
        );

  static void _checkBatchSize(int batchSize) {
    if (batchSize < 1) {
      throw InvalidConfigurationError(
        'Batch size must be at least 1, not $batchSize',
        context: {'batchSize': batchSize},
      );
    }
  }
}

/// An event [CronDispatcher] skipped after a non-retryable error.
final class SkippedEvent {
  SkippedEvent._(this.event, this.error, this.stackTrace);

  /// The event, as stored.
  final SerializedEvent event;

  /// What the handler, or deserialization, threw.
  final Object error;

  /// Where [error] was thrown.
  final StackTrace stackTrace;
}

/// The outcome of one [CronDispatcher.catchUp].
final class CatchUpResult {
  CatchUpResult._({
    required this.subscription,
    required this.processed,
    required List<SkippedEvent> skipped,
    required this.hasMore,
    this.error,
    this.stackTrace,
    this.failedEventId,
  }) : skipped = List.unmodifiable(skipped);

  /// The subscription name.
  final String subscription;

  /// How many events the handler completed.
  final int processed;

  /// The events skipped after a non-retryable error. The cursor moved past
  /// them.
  final List<SkippedEvent> skipped;

  /// Whether more events may follow the cursor: the batch was full, or the
  /// pass stopped early.
  final bool hasMore;

  /// The error that stopped the pass, or null if it wasn't stopped.
  final Object? error;

  /// Where [error] was thrown.
  final StackTrace? stackTrace;

  /// The event the pass stopped at, or null if it stopped while loading or
  /// wasn't stopped. The cursor is still before it.
  final UuidValue? failedEventId;

  /// Whether the pass stopped at an error.
  bool get stopped => error != null;

  /// How many events the cursor moved past.
  int get advanced => processed + skipped.length;

  @override
  String toString() =>
      'CatchUpResult($subscription, processed: $processed, '
      'skipped: ${skipped.length}, hasMore: $hasMore'
      '${stopped ? ', stopped: $error' : ''})';
}

final class _CatchUpBuilder {
  _CatchUpBuilder(this.subscription);

  final String subscription;
  int processed = 0;
  final skipped = <SkippedEvent>[];

  CatchUpResult stop(
    Object error,
    StackTrace stackTrace, [
    UuidValue? failedEventId,
  ]) => CatchUpResult._(
    subscription: subscription,
    processed: processed,
    skipped: skipped,
    hasMore: true,
    error: error,
    stackTrace: stackTrace,
    failedEventId: failedEventId,
  );

  CatchUpResult finish({required bool hasMore}) => CatchUpResult._(
    subscription: subscription,
    processed: processed,
    skipped: skipped,
    hasMore: hasMore,
  );
}
