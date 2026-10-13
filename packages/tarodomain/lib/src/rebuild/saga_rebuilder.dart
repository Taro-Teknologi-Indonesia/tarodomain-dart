import 'package:uuid/uuid.dart';

import '../adapters/event_store_adapter.dart';
import '../adapters/idempotency_stores.dart';
import '../adapters/saga_store_adapter.dart';
import '../domain/command.dart';
import '../event_sourcing/event_store.dart';
import '../saga/process_manager.dart';
import '../saga/saga_event_handler.dart';

/// A saga command dispatch that discards every command, for replaying a
/// saga whose commands already ran (spec §20.2). Pass `call` as the
/// [SagaCommandDispatch].
final class NullCommandDispatcher {
  final _discarded = <Command>[];

  /// The commands discarded so far, in order.
  List<Command> get discarded => List.unmodifiable(_discarded);

  /// Discards [command].
  Future<void> call(Command command) async => _discarded.add(command);
}

/// Rebuilds saga state from the event store (spec §20.2), for example after
/// a bug corrupted it.
///
/// Rebuilding one saga deletes its state and idempotency records, loads
/// every event with its correlation ID, and replays them through a
/// [SagaEventHandler] whose commands are discarded, since they already ran.
///
/// Synthetic `SagaTimeout` events are never stored, so they aren't
/// replayed: a saga that a timeout moved on is rebuilt as it was before the
/// timeout, and the timeout scheduler handles it again.
final class SagaRebuilder {
  /// Creates the rebuilder.
  SagaRebuilder({
    required this.eventStore,
    required this.sagaStore,
    required this.processedEvents,
  });

  /// Holds the events to replay.
  final EventStore eventStore;

  /// Holds the saga state that is rebuilt.
  final SagaStoreAdapter sagaStore;

  /// Holds the sagas' idempotency records.
  final ProcessedEventStore processedEvents;

  /// Rebuilds the saga [sagaId] of the type [create] makes. [create] must
  /// return a new, unstarted saga each time.
  ///
  /// Never throws for a failing event; the result reports it, and the saga
  /// is left as far as the replay got.
  Future<SagaRebuildResult> rebuildInstance(
    ProcessManager<Object?> Function() create,
    UuidValue sagaId,
  ) async {
    final discard = NullCommandDispatcher();
    final handler = SagaEventHandler(
      create: create,
      sagaStore: sagaStore,
      processedEvents: processedEvents,
      dispatch: discard.call,
    );
    final sagaType = handler.sagaType;
    var replayed = 0;
    try {
      await sagaStore.delete(sagaType, sagaId);
      await processedEvents.deleteByHandler(
        sagaType,
        handlerInstance: sagaId.uuid,
      );
      for (final event in await eventStore.loadByCorrelationId(sagaId)) {
        await handler.handle(event);
        replayed++;
      }
      return SagaRebuildResult._(
        sagaType: sagaType,
        sagaId: sagaId,
        eventsReplayed: replayed,
        commandsDiscarded: discard.discarded.length,
        record: await sagaStore.load(sagaType, sagaId),
      );
    } catch (error, stackTrace) {
      return SagaRebuildResult._(
        sagaType: sagaType,
        sagaId: sagaId,
        eventsReplayed: replayed,
        commandsDiscarded: discard.discarded.length,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Rebuilds every saga of the type [create] makes: one per correlation ID
  /// that has an event the saga starts on, found by scanning every event in
  /// pages of [batchSize]. Events that can't be deserialized are passed
  /// over by the scan.
  ///
  /// With [continueOnError] false, stops at the first saga that fails.
  Future<SagaRebuildAllResult> rebuildType(
    ProcessManager<Object?> Function() create, {
    bool continueOnError = true,
    int batchSize = 500,
  }) async {
    final prototype = create();
    final sagaIds = <UuidValue>{};
    UuidValue? cursor;
    while (true) {
      final page = await eventStore.adapter.loadStreamAfterEvent(
        StreamIds.all,
        afterEventId: cursor,
        maxCount: batchSize,
      );
      for (final serialized in page) {
        try {
          final event = eventStore.registry.deserialize(serialized);
          if (prototype.canStart(event)) sagaIds.add(event.correlationId);
        } catch (_) {
          // Not a saga start this scan can read; rebuilding the saga it
          // belongs to, if any, reports the error.
        }
      }
      if (page.length < batchSize) break;
      cursor = page.last.eventId;
    }

    final results = <SagaRebuildResult>[];
    for (final sagaId in sagaIds) {
      final result = await rebuildInstance(create, sagaId);
      results.add(result);
      if (!result.succeeded && !continueOnError) break;
    }
    return SagaRebuildAllResult._(prototype.sagaType, results);
  }

  /// Rebuilds every saga of each type, as [rebuildType] does.
  Future<List<SagaRebuildAllResult>> rebuildAll(
    List<ProcessManager<Object?> Function()> creators, {
    bool continueOnError = true,
    int batchSize = 500,
  }) async => [
    for (final create in creators)
      await rebuildType(
        create,
        continueOnError: continueOnError,
        batchSize: batchSize,
      ),
  ];
}

/// The outcome of rebuilding one saga.
final class SagaRebuildResult {
  SagaRebuildResult._({
    required this.sagaType,
    required this.sagaId,
    required this.eventsReplayed,
    required this.commandsDiscarded,
    this.record,
    this.error,
    this.stackTrace,
  });

  /// The saga type.
  final String sagaType;

  /// The saga ID.
  final UuidValue sagaId;

  /// Events handed to the saga, including ones it had no handler for.
  final int eventsReplayed;

  /// Commands the saga returned, which were discarded.
  final int commandsDiscarded;

  /// The rebuilt saga, or null if no event started it or the rebuild
  /// failed.
  final SagaRecord? record;

  /// What stopped the rebuild, or null.
  final Object? error;

  /// Where [error] was thrown.
  final StackTrace? stackTrace;

  /// Whether every event was replayed.
  bool get succeeded => error == null;

  @override
  String toString() =>
      'SagaRebuildResult($sagaType/$sagaId, events: $eventsReplayed, '
      '${record?.status.code ?? 'no saga'}'
      '${error == null ? '' : ', error: $error'})';
}

/// The outcome of rebuilding every saga of one type.
final class SagaRebuildAllResult {
  SagaRebuildAllResult._(this.sagaType, List<SagaRebuildResult> results)
    : results = List.unmodifiable(results);

  /// The saga type.
  final String sagaType;

  /// One result per saga rebuilt, in the order their first event was
  /// stored.
  final List<SagaRebuildResult> results;

  /// Whether every saga was rebuilt.
  bool get allSucceeded => results.every((r) => r.succeeded);
}
