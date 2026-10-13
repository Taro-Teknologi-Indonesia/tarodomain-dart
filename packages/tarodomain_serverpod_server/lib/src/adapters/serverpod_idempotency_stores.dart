import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';

import '../db/taro_db.dart';
import '../generated/protocol.dart';

/// A [ProcessedEventStore] on the module's `tarodomain_processed_events`
/// table.
final class ServerpodProcessedEventStore implements ProcessedEventStore {
  /// Creates the store on [session].
  ServerpodProcessedEventStore(Session session, {DateTime Function()? clock})
    : _db = TaroDb(session, clock: clock);

  final TaroDb _db;

  static final _t = TaroProcessedEventRow.t;

  @override
  Future<bool> exists(
    String handlerName,
    String handlerInstance,
    UuidValue eventId,
  ) async =>
      await _db.count<TaroProcessedEventRow>(
        where: _of(handlerName, handlerInstance) & _t.eventId.equals(eventId),
      ) >
      0;

  @override
  Future<void> markProcessed(
    String handlerName,
    String handlerInstance,
    UuidValue eventId,
  ) async {
    await _db.insert<TaroProcessedEventRow>(
      [
        TaroProcessedEventRow(
          handlerName: handlerName,
          handlerInstance: handlerInstance,
          eventId: eventId,
          processedAt: _db.now(),
        ),
      ],
      ignoreConflicts: true,
      noReturn: true,
    );
  }

  @override
  Future<int> count(String handlerName, {String? handlerInstance}) => _db
      .count<TaroProcessedEventRow>(where: _of(handlerName, handlerInstance));

  @override
  Future<int> deleteByHandler(String handlerName, {String? handlerInstance}) =>
      _db.deleteWhere<TaroProcessedEventRow>(
        where: _of(handlerName, handlerInstance),
      );

  @override
  Future<int> deleteOld(DateTime olderThan) =>
      _db.deleteWhere<TaroProcessedEventRow>(
        where: _t.processedAt < olderThan.toUtc(),
      );

  static Expression<Object?> _of(String handlerName, String? handlerInstance) {
    final handler = _t.handlerName.equals(handlerName);
    return handlerInstance == null
        ? handler
        : handler & _t.handlerInstance.equals(handlerInstance);
  }
}

/// A [CommandIdempotencyStore] on the module's
/// `tarodomain_processed_commands` table.
final class ServerpodCommandIdempotencyStore
    implements CommandIdempotencyStore {
  /// Creates the store on [session].
  ServerpodCommandIdempotencyStore(
    Session session, {
    DateTime Function()? clock,
  }) : _db = TaroDb(session, clock: clock);

  final TaroDb _db;

  static final _t = TaroProcessedCommandRow.t;

  @override
  Future<bool> exists(UuidValue commandId) async =>
      await _find(commandId) != null;

  @override
  Future<void> markProcessed(
    UuidValue commandId,
    String commandType,
    String handlerName,
  ) async {
    await _db.insert<TaroProcessedCommandRow>(
      [
        TaroProcessedCommandRow(
          commandId: commandId,
          commandType: commandType,
          handlerName: handlerName,
          processedAt: _db.now(),
        ),
      ],
      ignoreConflicts: true,
      noReturn: true,
    );
  }

  @override
  Future<DateTime?> getProcessedAt(UuidValue commandId) async =>
      (await _find(commandId))?.processedAt.toUtc();

  @override
  Future<int> count({String? handlerName}) =>
      _db.count<TaroProcessedCommandRow>(
        where: handlerName == null ? null : _t.handlerName.equals(handlerName),
      );

  @override
  Future<List<ProcessedCommand>> list(String handlerName, {int? limit}) async =>
      [
        for (final row in await _db.find<TaroProcessedCommandRow>(
          where: _t.handlerName.equals(handlerName),
          orderByList: [_t.processedAt.desc(), _t.id.desc()],
          limit: limit,
        ))
          ProcessedCommand(
            commandId: row.commandId,
            commandType: row.commandType,
            handlerName: row.handlerName,
            processedAt: row.processedAt.toUtc(),
          ),
      ];

  @override
  Future<int> deleteOld(DateTime olderThan) =>
      _db.deleteWhere<TaroProcessedCommandRow>(
        where: _t.processedAt < olderThan.toUtc(),
      );

  Future<TaroProcessedCommandRow?> _find(UuidValue commandId) =>
      _db.findFirstRow<TaroProcessedCommandRow>(
        where: _t.commandId.equals(commandId),
      );
}
