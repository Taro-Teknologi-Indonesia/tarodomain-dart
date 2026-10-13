import '../domain/domain_event.dart';
import '../errors/error_codes.dart';
import '../errors/framework_error.dart';
import 'event_handler.dart';

/// Delivers events to its handlers in the caller's zone, one at a time
/// (spec §10.4). Used for strong consistency, where the handlers run inside
/// the command's unit of work, and by queue consumers.
///
/// Each event goes to every handler, in subscription order, before the next
/// event is delivered.
class InMemoryEventBus implements SubscribableEventBus {
  /// Creates a bus with no handlers.
  InMemoryEventBus({this.name = 'in-memory'});

  @override
  final String name;

  final _handlers = <EventHandler>[];

  @override
  List<EventHandler> get handlers => List.unmodifiable(_handlers);

  @override
  void subscribe(EventHandler handler) {
    for (final existing in _handlers) {
      if (identical(existing, handler)) return;
      if (existing.name == handler.name) {
        throw InvalidConfigurationError(
          'Event bus "$name" already has a handler named "${handler.name}"',
          context: {'bus': name, 'handler': handler.name},
        );
      }
    }
    _handlers.add(handler);
  }

  @override
  void unsubscribe(EventHandler handler) =>
      _handlers.removeWhere((existing) => identical(existing, handler));

  /// Delivers [events] and stops at the first handler that throws.
  ///
  /// A [FrameworkError] is rethrown as it is, so that a concurrency conflict
  /// in a handler stays retryable and a domain error stays a domain error.
  /// Any other error is wrapped in [EventHandlerFailedError].
  @override
  Future<void> publishAll(List<DomainEvent> events) async {
    for (final event in events) {
      for (final handler in List.of(_handlers)) {
        try {
          await handler.handle(event);
        } on FrameworkError {
          rethrow;
        } catch (error, stackTrace) {
          throw _handlerFailed(handler, event, error, stackTrace);
        }
      }
    }
  }

  @override
  Future<void> publish(DomainEvent event) => publishAll([event]);

  /// Delivers [events] to every handler even when some throw, and reports
  /// each delivery. Never throws.
  Future<List<EventHandlerResult>> publishAllWithResults(
    List<DomainEvent> events,
  ) async {
    final results = <EventHandlerResult>[];
    for (final event in events) {
      for (final handler in List.of(_handlers)) {
        try {
          await handler.handle(event);
          results.add(EventHandlerResult._(event, handler.name));
        } catch (error, stackTrace) {
          results.add(
            EventHandlerResult._(event, handler.name, error, stackTrace),
          );
        }
      }
    }
    return results;
  }

  EventHandlerFailedError _handlerFailed(
    EventHandler handler,
    DomainEvent event,
    Object error,
    StackTrace stackTrace,
  ) => EventHandlerFailedError(
    'Handler "${handler.name}" failed on ${event.eventName} ${event.id}: '
    '$error',
    context: {
      'bus': name,
      'handler': handler.name,
      'eventType': event.eventName,
      'eventId': event.id.uuid,
    },
    cause: error,
    stackTrace: stackTrace,
  );
}

/// The outcome of delivering one event to one handler, from
/// [InMemoryEventBus.publishAllWithResults].
final class EventHandlerResult {
  EventHandlerResult._(
    this.event,
    this.handlerName, [
    this.error,
    this.stackTrace,
  ]);

  /// The delivered event.
  final DomainEvent event;

  /// The handler it was delivered to.
  final String handlerName;

  /// What the handler threw, or null if it succeeded.
  final Object? error;

  /// Where [error] was thrown.
  final StackTrace? stackTrace;

  /// Whether the handler completed without throwing.
  bool get succeeded => error == null;
}
