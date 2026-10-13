import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';

import '../db/taro_db.dart';
import '../generated/protocol.dart';

/// A [DeadLetterStore] on the module's `tarodomain_dead_letters` table.
final class ServerpodDeadLetterStore implements DeadLetterStore {
  /// Creates the store on [session].
  ServerpodDeadLetterStore(Session session, {DateTime Function()? clock})
    : _db = TaroDb(session, clock: clock);

  final TaroDb _db;

  static final _t = TaroDeadLetterRow.t;
  static final _newestFirst = [_t.createdAt.desc(), _t.id.desc()];

  @override
  Future<void> write(DeadLetterInput entry) async {
    await _db.insert<TaroDeadLetterRow>([
      TaroDeadLetterRow(
        handlerName: entry.handlerName,
        eventId: entry.eventId,
        event: jsonEncode(entry.event.toJson()),
        errorMessage: entry.errorMessage,
        errorCode: entry.errorCode,
        attempts: entry.attempts,
        createdAt: _db.now(),
      ),
    ], noReturn: true);
  }

  @override
  Future<List<DeadLetterEntry>> list(String handlerName, {int? limit}) async =>
      [
        for (final row in await _db.find<TaroDeadLetterRow>(
          where: _t.handlerName.equals(handlerName),
          orderByList: _newestFirst,
          limit: limit,
        ))
          _entry(row),
      ];

  @override
  Future<DeadLetterEntry?> get(UuidValue eventId, String handlerName) async {
    final row = await _db.findFirstRow<TaroDeadLetterRow>(
      where: _t.eventId.equals(eventId) & _t.handlerName.equals(handlerName),
      orderByList: _newestFirst,
    );
    return row == null ? null : _entry(row);
  }

  @override
  Future<DeadLetterEntry?> getById(int id) async {
    final row = await _db.findById<TaroDeadLetterRow>(id);
    return row == null ? null : _entry(row);
  }

  @override
  Future<void> delete(int id) async {
    await _db.deleteWhere<TaroDeadLetterRow>(where: _t.id.equals(id));
  }

  @override
  Future<int> count({String? handlerName}) => _db.count<TaroDeadLetterRow>(
    where: handlerName == null ? null : _t.handlerName.equals(handlerName),
  );

  @override
  Future<int> deleteOld(DateTime olderThan) => _db
      .deleteWhere<TaroDeadLetterRow>(where: _t.createdAt < olderThan.toUtc());

  static DeadLetterEntry _entry(TaroDeadLetterRow row) => DeadLetterEntry(
    id: row.id!,
    handlerName: row.handlerName,
    event: SerializedEvent.fromJson(
      jsonDecode(row.event) as Map<String, Object?>,
    ),
    errorMessage: row.errorMessage,
    errorCode: row.errorCode,
    attempts: row.attempts,
    createdAt: row.createdAt.toUtc(),
  );
}
