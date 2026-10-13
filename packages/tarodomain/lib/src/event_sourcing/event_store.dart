import 'package:uuid/uuid.dart';

import '../adapters/event_store_adapter.dart';
import '../domain/domain_event.dart';
import '../domain/serialized_event.dart';
import '../errors/error_codes.dart';
import '../errors/framework_error.dart';
import 'event_registry.dart';

/// The serialization boundary in front of an [EventStoreAdapter] (spec §3.3,
/// §7.1): typed events go in, typed events come out, upcast to their current
/// version.
class EventStore {
  /// Creates the store.
  EventStore(this.adapter, this.registry);

  /// The storage this store writes to.
  final EventStoreAdapter adapter;

  /// The registry that builds events on read.
  final EventRegistry registry;

  /// Serializes [events] and appends them to [streamId].
  ///
  /// Throws [UnknownEventTypeError] or [EventVersionMismatchError] before
  /// writing anything if an event's type or version isn't the registered one,
  /// so nothing is stored that can't be read back. Throws
  /// [OptimisticConcurrencyError] on a version conflict, and
  /// [EventAppendFailedError] if the adapter fails in another way.
  Future<AppendResult> appendToStream(
    String streamId,
    List<DomainEvent> events,
    int expectedVersion,
  ) async {
    final serialized = [for (final event in events) _serialize(event)];
    return _wrap(
      () => adapter.appendToStream(streamId, serialized, expectedVersion),
      (message, error, stackTrace) => EventAppendFailedError(
        message,
        context: {'streamId': streamId, 'expectedVersion': expectedVersion},
        cause: error,
        stackTrace: stackTrace,
      ),
    );
  }

  /// The events of [streamId] after [fromVersion], see
  /// [EventStoreAdapter.loadStream].
  Future<List<DomainEvent>> loadStream(
    String streamId, {
    int fromVersion = 0,
    int? maxCount,
  }) => _load(
    () => adapter.loadStream(
      streamId,
      fromVersion: fromVersion,
      maxCount: maxCount,
    ),
    {'streamId': streamId, 'fromVersion': fromVersion},
  );

  /// The events of [streamId] after [afterEventId], see
  /// [EventStoreAdapter.loadStreamAfterEvent].
  Future<List<DomainEvent>> loadStreamAfterEvent(
    String streamId, {
    UuidValue? afterEventId,
    int? maxCount,
  }) => _load(
    () => adapter.loadStreamAfterEvent(
      streamId,
      afterEventId: afterEventId,
      maxCount: maxCount,
    ),
    {'streamId': streamId, 'afterEventId': afterEventId?.uuid},
  );

  /// Every event after [afterEventId], see [EventStoreAdapter.loadAll].
  Future<List<DomainEvent>> loadAll({UuidValue? afterEventId, int? maxCount}) =>
      _load(
        () => adapter.loadAll(afterEventId: afterEventId, maxCount: maxCount),
        {'afterEventId': afterEventId?.uuid},
      );

  /// Every event with [correlationId], ordered by event ID.
  Future<List<DomainEvent>> loadByCorrelationId(UuidValue correlationId) =>
      _load(() => adapter.loadByCorrelationId(correlationId), {
        'correlationId': correlationId.uuid,
      });

  /// Whether [streamId] has at least one event.
  Future<bool> streamExists(String streamId) => _wrap(
    () => adapter.streamExists(streamId),
    (message, error, stackTrace) => EventLoadFailedError(
      message,
      context: {'streamId': streamId},
      cause: error,
      stackTrace: stackTrace,
    ),
  );

  SerializedEvent _serialize(DomainEvent event) {
    final current = registry.currentVersion(event.eventName);
    if (current == null) {
      throw UnknownEventTypeError(
        'Event type ${event.eventName} is not registered',
        context: {'eventType': event.eventName},
      );
    }
    if (current != event.eventVersion) {
      throw EventVersionMismatchError(
        '${event.eventName} has version ${event.eventVersion}, but '
        '$current is registered',
        context: {
          'eventType': event.eventName,
          'eventVersion': event.eventVersion,
          'registeredVersion': current,
        },
      );
    }
    return event.serialize();
  }

  Future<List<DomainEvent>> _load(
    Future<List<SerializedEvent>> Function() load,
    Map<String, Object?> context,
  ) async {
    final events = await _wrap(
      load,
      (message, error, stackTrace) => EventLoadFailedError(
        message,
        context: context,
        cause: error,
        stackTrace: stackTrace,
      ),
    );
    return [for (final event in events) registry.deserialize(event)];
  }

  /// Runs [body], rethrowing framework errors and wrapping anything else
  /// with [wrap].
  static Future<T> _wrap<T>(
    Future<T> Function() body,
    FrameworkError Function(String, Object, StackTrace) wrap,
  ) async {
    try {
      return await body();
    } on FrameworkError {
      rethrow;
    } catch (error, stackTrace) {
      throw wrap('Event store adapter failed: $error', error, stackTrace);
    }
  }
}
