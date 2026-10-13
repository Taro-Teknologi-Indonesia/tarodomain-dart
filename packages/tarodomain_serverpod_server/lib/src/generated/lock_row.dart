/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;

/// A lease that lets one server at a time run a scheduled job, such as
/// catch-up.
abstract class TaroLockRow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TaroLockRow._({
    this.id,
    required this.name,
    required this.owner,
    required this.lockedUntil,
  });

  factory TaroLockRow({
    int? id,
    required String name,
    required String owner,
    required DateTime lockedUntil,
  }) = _TaroLockRowImpl;

  factory TaroLockRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaroLockRow(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      owner: jsonSerialization['owner'] as String,
      lockedUntil: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['lockedUntil'],
      ),
    );
  }

  static final t = TaroLockRowTable();

  static const db = TaroLockRowRepository._();

  @override
  int? id;

  /// The job name.
  String name;

  /// Who holds the lease.
  String owner;

  /// When the lease expires, in UTC.
  DateTime lockedUntil;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaroLockRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TaroLockRow copyWith({
    int? id,
    String? name,
    String? owner,
    DateTime? lockedUntil,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'tarodomain_serverpod.TaroLockRow',
      if (id != null) 'id': id,
      'name': name,
      'owner': owner,
      'lockedUntil': lockedUntil.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TaroLockRowInclude include() {
    return TaroLockRowInclude._();
  }

  static TaroLockRowIncludeList includeList({
    _is.WhereExpressionBuilder<TaroLockRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroLockRowTable>? orderBy,
    _is.OrderByListBuilder<TaroLockRowTable>? orderByList,
    TaroLockRowInclude? include,
  }) {
    return TaroLockRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroLockRow.t),
      orderByList: orderByList?.call(TaroLockRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaroLockRowImpl extends TaroLockRow {
  _TaroLockRowImpl({
    int? id,
    required String name,
    required String owner,
    required DateTime lockedUntil,
  }) : super._(id: id, name: name, owner: owner, lockedUntil: lockedUntil);

  /// Returns a shallow copy of this [TaroLockRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TaroLockRow copyWith({
    Object? id = _Undefined,
    String? name,
    String? owner,
    DateTime? lockedUntil,
  }) {
    return TaroLockRow(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      owner: owner ?? this.owner,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }
}

class TaroLockRowUpdateTable extends _is.UpdateTable<TaroLockRowTable> {
  TaroLockRowUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) =>
      _is.ColumnValue(table.name, value);

  _is.ColumnValue<String, String> owner(String value) =>
      _is.ColumnValue(table.owner, value);

  _is.ColumnValue<DateTime, DateTime> lockedUntil(DateTime value) =>
      _is.ColumnValue(table.lockedUntil, value);
}

class TaroLockRowTable extends _is.Table<int?> {
  TaroLockRowTable({super.tableRelation})
    : super(tableName: 'tarodomain_locks') {
    updateTable = TaroLockRowUpdateTable(this);
    name = _is.ColumnString('name', this);
    owner = _is.ColumnString('owner', this);
    lockedUntil = _is.ColumnDateTime('lockedUntil', this);
  }

  late final TaroLockRowUpdateTable updateTable;

  /// The job name.
  late final _is.ColumnString name;

  /// Who holds the lease.
  late final _is.ColumnString owner;

  /// When the lease expires, in UTC.
  late final _is.ColumnDateTime lockedUntil;

  @override
  List<_is.Column> get columns => [id, name, owner, lockedUntil];
}

class TaroLockRowInclude extends _is.IncludeObject {
  TaroLockRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TaroLockRow.t;
}

class TaroLockRowIncludeList extends _is.IncludeList {
  TaroLockRowIncludeList._({
    _is.WhereExpressionBuilder<TaroLockRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaroLockRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaroLockRow.t;
}

class TaroLockRowRepository {
  const TaroLockRowRepository._();

  /// Returns a list of [TaroLockRow]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<TaroLockRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroLockRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroLockRowTable>? orderBy,
    _is.OrderByListBuilder<TaroLockRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaroLockRow>(
      where: where?.call(TaroLockRow.t),
      orderBy: orderBy?.call(TaroLockRow.t),
      orderByList: orderByList?.call(TaroLockRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaroLockRow] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<TaroLockRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroLockRowTable>? where,
    int? offset,
    _is.OrderByBuilder<TaroLockRowTable>? orderBy,
    _is.OrderByListBuilder<TaroLockRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaroLockRow>(
      where: where?.call(TaroLockRow.t),
      orderBy: orderBy?.call(TaroLockRow.t),
      orderByList: orderByList?.call(TaroLockRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaroLockRow] by its [id] or null if no such row exists.
  Future<TaroLockRow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaroLockRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaroLockRow]s in the list and returns the inserted rows.
  ///
  /// The returned [TaroLockRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroLockRow>> insert(
    _is.DatabaseSession session,
    List<TaroLockRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaroLockRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaroLockRow] and returns the inserted row.
  ///
  /// The returned [TaroLockRow] will have its `id` field set.
  Future<TaroLockRow> insertRow(
    _is.DatabaseSession session,
    TaroLockRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaroLockRow>(row, transaction: transaction);
  }

  /// Upserts all [TaroLockRow]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [TaroLockRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroLockRow>> upsert(
    _is.DatabaseSession session,
    List<TaroLockRow> rows, {
    required _is.ColumnSelections<TaroLockRowTable> conflictColumns,
    _is.ColumnSelections<TaroLockRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroLockRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaroLockRow>(
      rows,
      conflictColumns: conflictColumns(TaroLockRow.t),
      updateColumns: updateColumns?.call(TaroLockRow.t),
      updateWhere: updateWhere?.call(TaroLockRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaroLockRow] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [TaroLockRow] will have its `id` field set.
  Future<TaroLockRow?> upsertRow(
    _is.DatabaseSession session,
    TaroLockRow row, {
    required _is.ColumnSelections<TaroLockRowTable> conflictColumns,
    _is.ColumnSelections<TaroLockRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroLockRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaroLockRow>(
      row,
      conflictColumns: conflictColumns(TaroLockRow.t),
      updateColumns: updateColumns?.call(TaroLockRow.t),
      updateWhere: updateWhere?.call(TaroLockRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaroLockRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroLockRow>> update(
    _is.DatabaseSession session,
    List<TaroLockRow> rows, {
    _is.ColumnSelections<TaroLockRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaroLockRow>(
      rows,
      columns: columns?.call(TaroLockRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaroLockRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaroLockRow> updateRow(
    _is.DatabaseSession session,
    TaroLockRow row, {
    _is.ColumnSelections<TaroLockRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaroLockRow>(
      row,
      columns: columns?.call(TaroLockRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaroLockRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaroLockRow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaroLockRowUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaroLockRow>(
      id,
      columnValues: columnValues(TaroLockRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaroLockRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroLockRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaroLockRowUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TaroLockRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroLockRowTable>? orderBy,
    _is.OrderByListBuilder<TaroLockRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaroLockRow>(
      columnValues: columnValues(TaroLockRow.t.updateTable),
      where: where(TaroLockRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroLockRow.t),
      orderByList: orderByList?.call(TaroLockRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaroLockRow]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroLockRow>> delete(
    _is.DatabaseSession session,
    List<TaroLockRow> rows, {
    _is.OrderByBuilder<TaroLockRowTable>? orderBy,
    _is.OrderByListBuilder<TaroLockRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaroLockRow>(
      rows,
      orderBy: orderBy?.call(TaroLockRow.t),
      orderByList: orderByList?.call(TaroLockRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaroLockRow].
  Future<TaroLockRow> deleteRow(
    _is.DatabaseSession session,
    TaroLockRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaroLockRow>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroLockRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroLockRowTable> where,
    _is.OrderByBuilder<TaroLockRowTable>? orderBy,
    _is.OrderByListBuilder<TaroLockRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaroLockRow>(
      where: where(TaroLockRow.t),
      orderBy: orderBy?.call(TaroLockRow.t),
      orderByList: orderByList?.call(TaroLockRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroLockRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaroLockRow>(
      where: where?.call(TaroLockRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaroLockRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroLockRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaroLockRow>(
      where: where(TaroLockRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
