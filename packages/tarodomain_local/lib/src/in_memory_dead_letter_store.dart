import 'package:tarodomain/tarodomain.dart';

import 'local_database.dart';

/// A [DeadLetterStore] over a [LocalDatabase].
final class InMemoryDeadLetterStore implements DeadLetterStore {
  /// Creates the store.
  InMemoryDeadLetterStore(this.database);

  /// The database the entries live in.
  final LocalDatabase database;

  List<DeadLetterEntry> get _entries => database.tables.deadLetters;

  @override
  Future<void> write(DeadLetterInput entry) async {
    final tables = database.tables;
    tables.deadLetters.add(
      DeadLetterEntry(
        id: tables.nextDeadLetterId++,
        handlerName: entry.handlerName,
        event: entry.event,
        errorMessage: entry.errorMessage,
        errorCode: entry.errorCode,
        attempts: entry.attempts,
        createdAt: database.now(),
      ),
    );
  }

  @override
  Future<List<DeadLetterEntry>> list(String handlerName, {int? limit}) async =>
      sortedByTime(
        _entries.where((e) => e.handlerName == handlerName),
        (e) => e.createdAt,
        newestFirst: true,
        limit: limit,
      );

  @override
  Future<DeadLetterEntry?> get(UuidValue eventId, String handlerName) async =>
      sortedByTime(
        _entries.where(
          (e) => e.eventId == eventId && e.handlerName == handlerName,
        ),
        (e) => e.createdAt,
        newestFirst: true,
      ).firstOrNull;

  @override
  Future<DeadLetterEntry?> getById(int id) async =>
      _entries.where((e) => e.id == id).firstOrNull;

  @override
  Future<void> delete(int id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<int> count({String? handlerName}) async => _entries
      .where((e) => handlerName == null || e.handlerName == handlerName)
      .length;

  @override
  Future<int> deleteOld(DateTime olderThan) async {
    final before = _entries.length;
    _entries.removeWhere((e) => e.createdAt.isBefore(olderThan));
    return before - _entries.length;
  }
}
