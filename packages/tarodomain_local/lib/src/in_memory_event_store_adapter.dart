import 'package:tarodomain/tarodomain.dart';

import 'local_database.dart';

/// An [EventStoreAdapter] over a [LocalDatabase].
final class InMemoryEventStoreAdapter implements EventStoreAdapter {
  /// Creates the adapter.
  InMemoryEventStoreAdapter(this.database);

  /// The database the events live in.
  final LocalDatabase database;

  LocalTables get _tables => database.tables;

  @override
  Future<AppendResult> appendToStream(
    String streamId,
    List<SerializedEvent> events,
    int expectedVersion,
  ) async {
    final tables = _tables;
    final stream = tables.streams[streamId];
    final actualVersion = stream?.version ?? 0;
    if (actualVersion != expectedVersion) {
      throw OptimisticConcurrencyError(
        'Stream $streamId is at version $actualVersion, '
        'expected $expectedVersion',
        context: {
          'streamId': streamId,
          'expectedVersion': expectedVersion,
          'actualVersion': actualVersion,
        },
      );
    }
    if (events.isEmpty) {
      return AppendResult(streamId: streamId, version: actualVersion);
    }

    final ids = <String>{};
    for (final event in events) {
      final id = event.eventId.uuid;
      if (!ids.add(id) || tables.eventsById.containsKey(id)) {
        throw ArgumentError.value(id, 'events', 'Duplicate event ID');
      }
    }

    final now = database.now();
    final rows = tables.streamEvents.putIfAbsent(streamId, () => []);
    var version = actualVersion;
    for (final event in events) {
      final row = StoredEvent(
        tables.nextPosition++,
        streamId,
        ++version,
        event,
      );
      tables.events.add(row);
      tables.eventsById[event.eventId.uuid] = row;
      rows.add(row);
    }
    tables.streams[streamId] = StreamMetadata(
      streamId: streamId,
      version: version,
      createdAt: stream?.createdAt ?? now,
      updatedAt: now,
    );
    return AppendResult(streamId: streamId, version: version);
  }

  @override
  Future<List<SerializedEvent>> loadStream(
    String streamId, {
    int fromVersion = 0,
    int? maxCount,
  }) async => _take(
    (_tables.streamEvents[streamId] ?? const <StoredEvent>[]).where(
      (row) => row.version > fromVersion,
    ),
    maxCount,
  );

  @override
  Future<List<SerializedEvent>> loadStreamAfterEvent(
    String streamId, {
    UuidValue? afterEventId,
    int? maxCount,
  }) async {
    final tables = _tables;
    final Iterable<StoredEvent> rows;
    if (streamId == StreamIds.all) {
      rows = tables.events;
    } else if (streamId.contains('-')) {
      rows = tables.streamEvents[streamId] ?? const [];
    } else {
      rows = tables.events.where(
        (row) => StreamIds.categoryOf(row.streamId) == streamId,
      );
    }
    return _take(rows.where(_after(afterEventId)), maxCount);
  }

  @override
  Future<List<SerializedEvent>> loadAll({
    UuidValue? afterEventId,
    int? maxCount,
  }) => loadStreamAfterEvent(
    StreamIds.all,
    afterEventId: afterEventId,
    maxCount: maxCount,
  );

  @override
  Future<List<SerializedEvent>> loadByCorrelationId(
    UuidValue correlationId,
  ) async => _take(
    _tables.events.where((row) => row.event.correlationId == correlationId),
    null,
  );

  @override
  Future<bool> streamExists(String streamId) async =>
      _tables.streams.containsKey(streamId);

  @override
  Future<int> getStreamVersion(String streamId) async =>
      _tables.streams[streamId]?.version ?? 0;

  @override
  Future<StreamMetadata?> getStreamMetadata(String streamId) async =>
      _tables.streams[streamId];

  @override
  Future<void> deleteStream(String streamId) async {
    final tables = _tables;
    final rows = tables.streamEvents.remove(streamId);
    if (rows == null) return;
    tables.streams.remove(streamId);
    tables.events.removeWhere((row) => row.streamId == streamId);
    for (final row in rows) {
      tables.eventsById.remove(row.event.eventId.uuid);
    }
  }

  @override
  Future<Subscription> subscribe(String name, {String? streamId}) async =>
      _tables.subscriptions.putIfAbsent(
        name,
        () => Subscription(
          name: name,
          streamId: streamId,
          createdAt: database.now(),
        ),
      );

  @override
  Future<Subscription?> getSubscription(String name) async =>
      _tables.subscriptions[name];

  @override
  Future<void> ackSubscription(String name, UuidValue lastSeenEventId) async {
    final subscriptions = _tables.subscriptions;
    final subscription = subscriptions[name];
    if (subscription == null) {
      throw StateError('Subscription $name does not exist');
    }
    subscriptions[name] = Subscription(
      name: name,
      streamId: subscription.streamId,
      lastSeen: lastSeenEventId,
      createdAt: subscription.createdAt,
    );
  }

  @override
  Future<void> deleteSubscription(String name) async {
    _tables.subscriptions.remove(name);
  }

  @override
  Future<List<Subscription>> listSubscriptions() async =>
      _tables.subscriptions.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  /// Matches the events after [eventId]: by append position if the event is
  /// stored, otherwise by event ID.
  bool Function(StoredEvent) _after(UuidValue? eventId) {
    if (eventId == null) return (_) => true;
    final cursor = _tables.eventsById[eventId.uuid];
    if (cursor != null) return (row) => row.position > cursor.position;
    return (row) => row.event.eventId.uuid.compareTo(eventId.uuid) > 0;
  }

  static List<SerializedEvent> _take(
    Iterable<StoredEvent> rows,
    int? maxCount,
  ) {
    final events = rows.map((row) => row.event);
    return (maxCount == null ? events : events.take(maxCount)).toList();
  }
}
