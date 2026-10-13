import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';

import '../db/taro_db.dart';
import '../generated/protocol.dart';
import 'event_sequencer.dart';

/// An [EventStoreAdapter] on the module's `tarodomain_events`,
/// `tarodomain_streams` and `tarodomain_subscriptions` tables.
///
/// Cursor reads ([loadAll] and [loadStreamAfterEvent], which catch-up uses)
/// return only events with a global position, in position order. Positions
/// are assigned after commit by [EventSequencer], which these reads run
/// first when no unit of work is active, so a read right after an append
/// sees it. A read that finds another run positioning events doesn't wait
/// to retry; it reads what that run positioned. Inside a unit of work they don't: on SQLite the sequencer's
/// transaction would wait on the open one.
final class ServerpodEventStoreAdapter implements EventStoreAdapter {
  /// Creates the adapter on [session].
  ServerpodEventStoreAdapter(Session session, {DateTime Function()? clock})
    : _db = TaroDb(session, clock: clock),
      _sequencer = EventSequencer(session);

  final TaroDb _db;
  final EventSequencer _sequencer;

  static final _events = TaroEventRow.t;
  static final _streams = TaroStreamRow.t;
  static final _subscriptions = TaroSubscriptionRow.t;

  @override
  Future<AppendResult> appendToStream(
    String streamId,
    List<SerializedEvent> events,
    int expectedVersion,
  ) async {
    if (events.isEmpty) {
      final actual = await getStreamVersion(streamId);
      if (actual != expectedVersion) {
        throw _conflict(streamId, expectedVersion, actual);
      }
      return AppendResult(streamId: streamId, version: actual);
    }

    return _db.atomically(() async {
      final now = _db.now();
      final version = expectedVersion + events.length;
      final written = expectedVersion == 0
          ? await _db.insert<TaroStreamRow>([
              TaroStreamRow(
                streamId: streamId,
                version: version,
                createdAt: now,
                updatedAt: now,
              ),
            ], ignoreConflicts: true)
          : await _db.updateWhere<TaroStreamRow>(
              columnValues: [
                ColumnValue(_streams.version, version),
                ColumnValue(_streams.updatedAt, now),
              ],
              where:
                  _streams.streamId.equals(streamId) &
                  _streams.version.equals(expectedVersion),
            );
      if (written.isEmpty) {
        throw _conflict(
          streamId,
          expectedVersion,
          await getStreamVersion(streamId),
        );
      }

      final category = StreamIds.categoryOf(streamId);
      await _db.insert<TaroEventRow>([
        for (final (i, event) in events.indexed)
          TaroEventRow(
            eventId: event.eventId,
            streamId: streamId,
            category: category,
            version: expectedVersion + i + 1,
            eventType: event.eventType,
            correlationId: event.correlationId,
            payload: jsonEncode(event.toJson()),
          ),
      ], noReturn: true);
      return AppendResult(streamId: streamId, version: version);
    });
  }

  @override
  Future<List<SerializedEvent>> loadStream(
    String streamId, {
    int fromVersion = 0,
    int? maxCount,
  }) async => _decode(
    await _db.find<TaroEventRow>(
      where:
          _events.streamId.equals(streamId) & (_events.version > fromVersion),
      orderBy: _events.version,
      limit: maxCount,
    ),
  );

  @override
  Future<List<SerializedEvent>> loadStreamAfterEvent(
    String streamId, {
    UuidValue? afterEventId,
    int? maxCount,
  }) async {
    if (!_db.inUnitOfWork) await _sequencer.tryRun();

    Expression<Object?> where = _events.position.notEquals(null);
    if (streamId == StreamIds.all) {
      // Every stream.
    } else if (streamId.contains('-')) {
      where &= _events.streamId.equals(streamId);
    } else {
      where &= _events.category.equals(streamId);
    }
    if (afterEventId != null) {
      switch (await _cursorPosition(afterEventId)) {
        case _Position(:final position):
          where &= _events.position > position;
        case _NotYetPositioned():
          // Nothing positioned can come after an event that has no
          // position yet without risking a skip.
          return const [];
        case _Unknown():
          // The cursor's event was deleted and no subscription remembers
          // its position: fall back to event ID order.
          where &= _events.eventId > afterEventId;
      }
    }

    return _decode(
      await _db.find<TaroEventRow>(
        where: where,
        orderBy: _events.position,
        limit: maxCount,
      ),
    );
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
  ) async => _decode(
    await _db.find<TaroEventRow>(
      where: _events.correlationId.equals(correlationId),
      orderBy: _events.id,
    ),
  );

  @override
  Future<bool> streamExists(String streamId) async =>
      await _stream(streamId) != null;

  @override
  Future<int> getStreamVersion(String streamId) async =>
      (await _stream(streamId))?.version ?? 0;

  @override
  Future<StreamMetadata?> getStreamMetadata(String streamId) async {
    final row = await _stream(streamId);
    if (row == null) return null;
    return StreamMetadata(
      streamId: row.streamId,
      version: row.version,
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
    );
  }

  @override
  Future<void> deleteStream(String streamId) => _db.atomically(() async {
    await _db.deleteWhere<TaroEventRow>(
      where: _events.streamId.equals(streamId),
    );
    await _db.deleteWhere<TaroStreamRow>(
      where: _streams.streamId.equals(streamId),
    );
  });

  @override
  Future<Subscription> subscribe(String name, {String? streamId}) async {
    await _db.insert<TaroSubscriptionRow>([
      TaroSubscriptionRow(name: name, streamId: streamId, createdAt: _db.now()),
    ], ignoreConflicts: true);
    return (await getSubscription(name))!;
  }

  @override
  Future<Subscription?> getSubscription(String name) async {
    final row = await _subscription(name);
    return row == null ? null : _toSubscription(row);
  }

  /// Moves the cursor of subscription [name] to [lastSeenEventId] and clears
  /// its failed attempts, but never moves it back: if the event has a
  /// position, the cursor moves only if that position is past the current
  /// one. Two catch-up runs on one subscription therefore can't undo each
  /// other's progress.
  @override
  Future<void> ackSubscription(String name, UuidValue lastSeenEventId) async {
    final position = (await _event(lastSeenEventId))?.position;
    final named = _subscriptions.name.equals(name);
    final updated = await _db.updateWhere<TaroSubscriptionRow>(
      columnValues: [
        ColumnValue(_subscriptions.lastSeen, lastSeenEventId),
        if (position != null)
          ColumnValue(_subscriptions.lastPosition, position),
        ColumnValue(_subscriptions.failedEventId, null),
        ColumnValue(_subscriptions.failedAttempts, 0),
      ],
      where: position == null
          ? named
          : named &
                (_subscriptions.lastPosition.equals(null) |
                    (_subscriptions.lastPosition < position)),
    );
    if (updated.isEmpty && await _subscription(name) == null) {
      throw StateError('Subscription $name does not exist');
    }
  }

  @override
  Future<int> recordFailedAttempt(String name, UuidValue eventId) =>
      _db.atomically(() async {
        final row =
            await _subscription(name) ??
            (throw StateError('Subscription $name does not exist'));
        final attempts = row.failedEventId == eventId
            ? row.failedAttempts + 1
            : 1;
        await _db.updateWhere<TaroSubscriptionRow>(
          columnValues: [
            ColumnValue(_subscriptions.failedEventId, eventId),
            ColumnValue(_subscriptions.failedAttempts, attempts),
          ],
          where: _subscriptions.name.equals(name),
        );
        return attempts;
      });

  @override
  Future<void> deleteSubscription(String name) async {
    await _db.deleteWhere<TaroSubscriptionRow>(
      where: _subscriptions.name.equals(name),
    );
  }

  @override
  Future<List<Subscription>> listSubscriptions() async => [
    for (final row in await _db.find<TaroSubscriptionRow>(
      orderBy: _subscriptions.name,
    ))
      _toSubscription(row),
  ];

  Future<_CursorPosition> _cursorPosition(UuidValue eventId) async {
    final event = await _event(eventId);
    if (event != null) {
      final position = event.position;
      return position == null ? const _NotYetPositioned() : _Position(position);
    }
    final subscription = await _db.findFirstRow<TaroSubscriptionRow>(
      where:
          _subscriptions.lastSeen.equals(eventId) &
          _subscriptions.lastPosition.notEquals(null),
    );
    final position = subscription?.lastPosition;
    return position == null ? const _Unknown() : _Position(position);
  }

  Future<TaroEventRow?> _event(UuidValue eventId) =>
      _db.findFirstRow<TaroEventRow>(where: _events.eventId.equals(eventId));

  Future<TaroStreamRow?> _stream(String streamId) => _db
      .findFirstRow<TaroStreamRow>(where: _streams.streamId.equals(streamId));

  Future<TaroSubscriptionRow?> _subscription(String name) =>
      _db.findFirstRow<TaroSubscriptionRow>(
        where: _subscriptions.name.equals(name),
      );

  static Subscription _toSubscription(TaroSubscriptionRow row) => Subscription(
    name: row.name,
    streamId: row.streamId,
    lastSeen: row.lastSeen,
    createdAt: row.createdAt.toUtc(),
    failedEventId: row.failedEventId,
    failedAttempts: row.failedAttempts,
  );

  static List<SerializedEvent> _decode(List<TaroEventRow> rows) => [
    for (final row in rows)
      SerializedEvent.fromJson(jsonDecode(row.payload) as Map<String, Object?>),
  ];

  static OptimisticConcurrencyError _conflict(
    String streamId,
    int expectedVersion,
    int actualVersion,
  ) => OptimisticConcurrencyError(
    'Stream $streamId is at version $actualVersion, '
    'expected $expectedVersion',
    context: {
      'streamId': streamId,
      'expectedVersion': expectedVersion,
      'actualVersion': actualVersion,
    },
  );
}

/// Where a cursor event sits in the global order.
sealed class _CursorPosition {
  const _CursorPosition();
}

final class _Position extends _CursorPosition {
  const _Position(this.position);

  final int position;
}

final class _NotYetPositioned extends _CursorPosition {
  const _NotYetPositioned();
}

final class _Unknown extends _CursorPosition {
  const _Unknown();
}
