import 'package:meta/meta.dart';
import 'package:serverpod/serverpod.dart';

import '../serverpod_unit_of_work.dart';

/// The only way this package reaches Serverpod's ORM.
///
/// The ORM doesn't pick up an ambient transaction, so a call that forgets
/// to pass one runs outside the unit of work (and on SQLite, with its one
/// connection, waits on it forever). Every method here passes the
/// transaction of the unit of work active on [session], if any. A test
/// fails if code elsewhere in `lib/src/` uses the ORM directly.
@internal
final class TaroDb {
  /// Creates the helper for [session].
  TaroDb(this.session, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.timestamp;

  /// The request's session.
  final Session session;

  final DateTime Function() _clock;

  /// The current time in UTC, from the clock, rounded up to the next whole
  /// millisecond.
  ///
  /// SQLite stores milliseconds and PostgreSQL microseconds. Rounding up
  /// makes both read back the same value, and one that is never earlier
  /// than the moment of the call.
  DateTime now() {
    final now = _clock().toUtc();
    return now.microsecond == 0
        ? now
        : now.add(Duration(microseconds: 1000 - now.microsecond));
  }

  Transaction? get _transaction => ServerpodUnitOfWork.transactionOf(session);

  /// Whether a unit of work is active on [session].
  bool get inUnitOfWork => _transaction != null;

  /// Runs [work] in the active unit of work, or in a new one if there is
  /// none, so its writes are all or nothing.
  Future<T> atomically<T>(Future<T> Function() work) =>
      ServerpodUnitOfWork(session).execute(work);

  /// Runs [work] in a new transaction of its own, even inside a unit of
  /// work, and commits it when [work] completes.
  Future<T> separately<T>(Future<T> Function() work) =>
      ServerpodUnitOfWork.separately(session, work);

  /// The table of row type [t], such as `Expense.t` for `Expense`.
  Table<Object?>? tableFor(Type t) =>
      session.db.serializationManager.getTableForType(t);

  /// See [Database.find].
  Future<List<T>> find<T extends TableRow<Object?>>({
    Expression<Object?>? where,
    int? limit,
    Column<Object?>? orderBy,
    List<Column<Object?>>? orderByList,
  }) => session.db.find<T>(
    where: where,
    limit: limit,
    orderBy: orderBy,
    orderByList: orderByList,
    transaction: _transaction,
  );

  /// See [Database.findFirstRow].
  Future<T?> findFirstRow<T extends TableRow<Object?>>({
    Expression<Object?>? where,
    Column<Object?>? orderBy,
    List<Column<Object?>>? orderByList,
  }) => session.db.findFirstRow<T>(
    where: where,
    orderBy: orderBy,
    orderByList: orderByList,
    transaction: _transaction,
  );

  /// See [Database.findById].
  Future<T?> findById<T extends TableRow<Object?>>(Object id) =>
      session.db.findById<T>(id, transaction: _transaction);

  /// See [Database.count].
  Future<int> count<T extends TableRow<Object?>>({
    Expression<Object?>? where,
  }) => session.db.count<T>(where: where, transaction: _transaction);

  /// See [Database.insert].
  Future<List<T>> insert<T extends TableRow<Object?>>(
    List<T> rows, {
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) => session.db.insert<T>(
    rows,
    ignoreConflicts: ignoreConflicts,
    noReturn: noReturn,
    transaction: _transaction,
  );

  /// See [Database.insertRow].
  Future<T> insertRow<T extends TableRow<Object?>>(T row) =>
      session.db.insertRow<T>(row, transaction: _transaction);

  /// See [Database.updateWhere].
  Future<List<T>> updateWhere<T extends TableRow<Object?>>({
    required List<ColumnValue<Object?, Object?>> columnValues,
    required Expression<Object?> where,
    bool noReturn = false,
  }) => session.db.updateWhere<T>(
    columnValues: columnValues,
    where: where,
    noReturn: noReturn,
    transaction: _transaction,
  );

  /// See [Database.updateRow].
  Future<T> updateRow<T extends TableRow<Object?>>(T row) =>
      session.db.updateRow<T>(row, transaction: _transaction);

  /// See [Database.upsert].
  Future<List<T>> upsert<T extends TableRow<Object?>>(
    List<T> rows, {
    required List<Column<Object?>> conflictColumns,
    List<Column<Object?>>? updateColumns,
    bool noReturn = false,
  }) => session.db.upsert<T>(
    rows,
    conflictColumns: conflictColumns,
    updateColumns: updateColumns,
    noReturn: noReturn,
    transaction: _transaction,
  );

  /// See [Database.deleteWhere]. Returns how many rows were deleted.
  Future<int> deleteWhere<T extends TableRow<Object?>>({
    required Expression<Object?> where,
  }) async => (await session.db.deleteWhere<T>(
    where: where,
    transaction: _transaction,
  )).length;
}
