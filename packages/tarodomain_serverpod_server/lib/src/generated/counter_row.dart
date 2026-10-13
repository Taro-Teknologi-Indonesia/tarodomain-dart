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

/// A named counter. `EventSequencer` takes event positions from the
/// `event-position` counter, so a position is never handed out twice, even
/// after the event that had it is deleted.
abstract class TaroCounterRow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TaroCounterRow._({this.id, required this.name, required this.value});

  factory TaroCounterRow({int? id, required String name, required int value}) =
      _TaroCounterRowImpl;

  factory TaroCounterRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaroCounterRow(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      value: jsonSerialization['value'] as int,
    );
  }

  static final t = TaroCounterRowTable();

  static const db = TaroCounterRowRepository._();

  @override
  int? id;

  /// The counter name.
  String name;

  /// The last value handed out.
  int value;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaroCounterRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TaroCounterRow copyWith({int? id, String? name, int? value});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'tarodomain_serverpod.TaroCounterRow',
      if (id != null) 'id': id,
      'name': name,
      'value': value,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TaroCounterRowInclude include() {
    return TaroCounterRowInclude._();
  }

  static TaroCounterRowIncludeList includeList({
    _is.WhereExpressionBuilder<TaroCounterRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroCounterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroCounterRowTable>? orderByList,
    TaroCounterRowInclude? include,
  }) {
    return TaroCounterRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroCounterRow.t),
      orderByList: orderByList?.call(TaroCounterRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaroCounterRowImpl extends TaroCounterRow {
  _TaroCounterRowImpl({int? id, required String name, required int value})
    : super._(id: id, name: name, value: value);

  /// Returns a shallow copy of this [TaroCounterRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TaroCounterRow copyWith({Object? id = _Undefined, String? name, int? value}) {
    return TaroCounterRow(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}

class TaroCounterRowUpdateTable extends _is.UpdateTable<TaroCounterRowTable> {
  TaroCounterRowUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) =>
      _is.ColumnValue(table.name, value);

  _is.ColumnValue<int, int> value(int value) =>
      _is.ColumnValue(table.value, value);
}

class TaroCounterRowTable extends _is.Table<int?> {
  TaroCounterRowTable({super.tableRelation})
    : super(tableName: 'tarodomain_counters') {
    updateTable = TaroCounterRowUpdateTable(this);
    name = _is.ColumnString('name', this);
    value = _is.ColumnInt('value', this);
  }

  late final TaroCounterRowUpdateTable updateTable;

  /// The counter name.
  late final _is.ColumnString name;

  /// The last value handed out.
  late final _is.ColumnInt value;

  @override
  List<_is.Column> get columns => [id, name, value];
}

class TaroCounterRowInclude extends _is.IncludeObject {
  TaroCounterRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TaroCounterRow.t;
}

class TaroCounterRowIncludeList extends _is.IncludeList {
  TaroCounterRowIncludeList._({
    _is.WhereExpressionBuilder<TaroCounterRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaroCounterRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaroCounterRow.t;
}

class TaroCounterRowRepository {
  const TaroCounterRowRepository._();

  /// Returns a list of [TaroCounterRow]s matching the given query parameters.
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
  Future<List<TaroCounterRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroCounterRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroCounterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroCounterRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaroCounterRow>(
      where: where?.call(TaroCounterRow.t),
      orderBy: orderBy?.call(TaroCounterRow.t),
      orderByList: orderByList?.call(TaroCounterRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaroCounterRow] matching the given query parameters.
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
  Future<TaroCounterRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroCounterRowTable>? where,
    int? offset,
    _is.OrderByBuilder<TaroCounterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroCounterRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaroCounterRow>(
      where: where?.call(TaroCounterRow.t),
      orderBy: orderBy?.call(TaroCounterRow.t),
      orderByList: orderByList?.call(TaroCounterRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaroCounterRow] by its [id] or null if no such row exists.
  Future<TaroCounterRow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaroCounterRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaroCounterRow]s in the list and returns the inserted rows.
  ///
  /// The returned [TaroCounterRow]s will have their `id` fields set.
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
  Future<List<TaroCounterRow>> insert(
    _is.DatabaseSession session,
    List<TaroCounterRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaroCounterRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaroCounterRow] and returns the inserted row.
  ///
  /// The returned [TaroCounterRow] will have its `id` field set.
  Future<TaroCounterRow> insertRow(
    _is.DatabaseSession session,
    TaroCounterRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaroCounterRow>(row, transaction: transaction);
  }

  /// Upserts all [TaroCounterRow]s in the list and returns the resulting rows.
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
  /// The returned [TaroCounterRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroCounterRow>> upsert(
    _is.DatabaseSession session,
    List<TaroCounterRow> rows, {
    required _is.ColumnSelections<TaroCounterRowTable> conflictColumns,
    _is.ColumnSelections<TaroCounterRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroCounterRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaroCounterRow>(
      rows,
      conflictColumns: conflictColumns(TaroCounterRow.t),
      updateColumns: updateColumns?.call(TaroCounterRow.t),
      updateWhere: updateWhere?.call(TaroCounterRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaroCounterRow] and returns the resulting row.
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
  /// The returned [TaroCounterRow] will have its `id` field set.
  Future<TaroCounterRow?> upsertRow(
    _is.DatabaseSession session,
    TaroCounterRow row, {
    required _is.ColumnSelections<TaroCounterRowTable> conflictColumns,
    _is.ColumnSelections<TaroCounterRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroCounterRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaroCounterRow>(
      row,
      conflictColumns: conflictColumns(TaroCounterRow.t),
      updateColumns: updateColumns?.call(TaroCounterRow.t),
      updateWhere: updateWhere?.call(TaroCounterRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaroCounterRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroCounterRow>> update(
    _is.DatabaseSession session,
    List<TaroCounterRow> rows, {
    _is.ColumnSelections<TaroCounterRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaroCounterRow>(
      rows,
      columns: columns?.call(TaroCounterRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaroCounterRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaroCounterRow> updateRow(
    _is.DatabaseSession session,
    TaroCounterRow row, {
    _is.ColumnSelections<TaroCounterRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaroCounterRow>(
      row,
      columns: columns?.call(TaroCounterRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaroCounterRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaroCounterRow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaroCounterRowUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaroCounterRow>(
      id,
      columnValues: columnValues(TaroCounterRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaroCounterRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroCounterRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaroCounterRowUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TaroCounterRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroCounterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroCounterRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaroCounterRow>(
      columnValues: columnValues(TaroCounterRow.t.updateTable),
      where: where(TaroCounterRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroCounterRow.t),
      orderByList: orderByList?.call(TaroCounterRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaroCounterRow]s in the list and returns the deleted rows.
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
  Future<List<TaroCounterRow>> delete(
    _is.DatabaseSession session,
    List<TaroCounterRow> rows, {
    _is.OrderByBuilder<TaroCounterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroCounterRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaroCounterRow>(
      rows,
      orderBy: orderBy?.call(TaroCounterRow.t),
      orderByList: orderByList?.call(TaroCounterRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaroCounterRow].
  Future<TaroCounterRow> deleteRow(
    _is.DatabaseSession session,
    TaroCounterRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaroCounterRow>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroCounterRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroCounterRowTable> where,
    _is.OrderByBuilder<TaroCounterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroCounterRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaroCounterRow>(
      where: where(TaroCounterRow.t),
      orderBy: orderBy?.call(TaroCounterRow.t),
      orderByList: orderByList?.call(TaroCounterRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroCounterRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaroCounterRow>(
      where: where?.call(TaroCounterRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaroCounterRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroCounterRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaroCounterRow>(
      where: where(TaroCounterRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
