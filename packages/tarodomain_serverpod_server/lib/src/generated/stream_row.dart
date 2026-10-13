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

/// Metadata of one event stream (spec §27.1 `streams`).
abstract class TaroStreamRow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TaroStreamRow._({
    this.id,
    required this.streamId,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaroStreamRow({
    int? id,
    required String streamId,
    required int version,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TaroStreamRowImpl;

  factory TaroStreamRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaroStreamRow(
      id: jsonSerialization['id'] as int?,
      streamId: jsonSerialization['streamId'] as String,
      version: jsonSerialization['version'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = TaroStreamRowTable();

  static const db = TaroStreamRowRepository._();

  @override
  int? id;

  /// The stream ID, such as `BankAccount-01909e3c-…`.
  String streamId;

  /// The version of the stream's last event.
  int version;

  /// When the first event was appended, in UTC.
  DateTime createdAt;

  /// When the last event was appended, in UTC.
  DateTime updatedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaroStreamRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TaroStreamRow copyWith({
    int? id,
    String? streamId,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'tarodomain_serverpod.TaroStreamRow',
      if (id != null) 'id': id,
      'streamId': streamId,
      'version': version,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TaroStreamRowInclude include() {
    return TaroStreamRowInclude._();
  }

  static TaroStreamRowIncludeList includeList({
    _is.WhereExpressionBuilder<TaroStreamRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroStreamRowTable>? orderBy,
    _is.OrderByListBuilder<TaroStreamRowTable>? orderByList,
    TaroStreamRowInclude? include,
  }) {
    return TaroStreamRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroStreamRow.t),
      orderByList: orderByList?.call(TaroStreamRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaroStreamRowImpl extends TaroStreamRow {
  _TaroStreamRowImpl({
    int? id,
    required String streamId,
    required int version,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         streamId: streamId,
         version: version,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [TaroStreamRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TaroStreamRow copyWith({
    Object? id = _Undefined,
    String? streamId,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaroStreamRow(
      id: id is int? ? id : this.id,
      streamId: streamId ?? this.streamId,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TaroStreamRowUpdateTable extends _is.UpdateTable<TaroStreamRowTable> {
  TaroStreamRowUpdateTable(super.table);

  _is.ColumnValue<String, String> streamId(String value) =>
      _is.ColumnValue(table.streamId, value);

  _is.ColumnValue<int, int> version(int value) =>
      _is.ColumnValue(table.version, value);

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(table.createdAt, value);

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(table.updatedAt, value);
}

class TaroStreamRowTable extends _is.Table<int?> {
  TaroStreamRowTable({super.tableRelation})
    : super(tableName: 'tarodomain_streams') {
    updateTable = TaroStreamRowUpdateTable(this);
    streamId = _is.ColumnString('streamId', this);
    version = _is.ColumnInt('version', this);
    createdAt = _is.ColumnDateTime('createdAt', this);
    updatedAt = _is.ColumnDateTime('updatedAt', this);
  }

  late final TaroStreamRowUpdateTable updateTable;

  /// The stream ID, such as `BankAccount-01909e3c-…`.
  late final _is.ColumnString streamId;

  /// The version of the stream's last event.
  late final _is.ColumnInt version;

  /// When the first event was appended, in UTC.
  late final _is.ColumnDateTime createdAt;

  /// When the last event was appended, in UTC.
  late final _is.ColumnDateTime updatedAt;

  @override
  List<_is.Column> get columns => [id, streamId, version, createdAt, updatedAt];
}

class TaroStreamRowInclude extends _is.IncludeObject {
  TaroStreamRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TaroStreamRow.t;
}

class TaroStreamRowIncludeList extends _is.IncludeList {
  TaroStreamRowIncludeList._({
    _is.WhereExpressionBuilder<TaroStreamRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaroStreamRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaroStreamRow.t;
}

class TaroStreamRowRepository {
  const TaroStreamRowRepository._();

  /// Returns a list of [TaroStreamRow]s matching the given query parameters.
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
  Future<List<TaroStreamRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroStreamRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroStreamRowTable>? orderBy,
    _is.OrderByListBuilder<TaroStreamRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaroStreamRow>(
      where: where?.call(TaroStreamRow.t),
      orderBy: orderBy?.call(TaroStreamRow.t),
      orderByList: orderByList?.call(TaroStreamRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaroStreamRow] matching the given query parameters.
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
  Future<TaroStreamRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroStreamRowTable>? where,
    int? offset,
    _is.OrderByBuilder<TaroStreamRowTable>? orderBy,
    _is.OrderByListBuilder<TaroStreamRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaroStreamRow>(
      where: where?.call(TaroStreamRow.t),
      orderBy: orderBy?.call(TaroStreamRow.t),
      orderByList: orderByList?.call(TaroStreamRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaroStreamRow] by its [id] or null if no such row exists.
  Future<TaroStreamRow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaroStreamRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaroStreamRow]s in the list and returns the inserted rows.
  ///
  /// The returned [TaroStreamRow]s will have their `id` fields set.
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
  Future<List<TaroStreamRow>> insert(
    _is.DatabaseSession session,
    List<TaroStreamRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaroStreamRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaroStreamRow] and returns the inserted row.
  ///
  /// The returned [TaroStreamRow] will have its `id` field set.
  Future<TaroStreamRow> insertRow(
    _is.DatabaseSession session,
    TaroStreamRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaroStreamRow>(row, transaction: transaction);
  }

  /// Upserts all [TaroStreamRow]s in the list and returns the resulting rows.
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
  /// The returned [TaroStreamRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroStreamRow>> upsert(
    _is.DatabaseSession session,
    List<TaroStreamRow> rows, {
    required _is.ColumnSelections<TaroStreamRowTable> conflictColumns,
    _is.ColumnSelections<TaroStreamRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroStreamRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaroStreamRow>(
      rows,
      conflictColumns: conflictColumns(TaroStreamRow.t),
      updateColumns: updateColumns?.call(TaroStreamRow.t),
      updateWhere: updateWhere?.call(TaroStreamRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaroStreamRow] and returns the resulting row.
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
  /// The returned [TaroStreamRow] will have its `id` field set.
  Future<TaroStreamRow?> upsertRow(
    _is.DatabaseSession session,
    TaroStreamRow row, {
    required _is.ColumnSelections<TaroStreamRowTable> conflictColumns,
    _is.ColumnSelections<TaroStreamRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroStreamRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaroStreamRow>(
      row,
      conflictColumns: conflictColumns(TaroStreamRow.t),
      updateColumns: updateColumns?.call(TaroStreamRow.t),
      updateWhere: updateWhere?.call(TaroStreamRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaroStreamRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroStreamRow>> update(
    _is.DatabaseSession session,
    List<TaroStreamRow> rows, {
    _is.ColumnSelections<TaroStreamRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaroStreamRow>(
      rows,
      columns: columns?.call(TaroStreamRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaroStreamRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaroStreamRow> updateRow(
    _is.DatabaseSession session,
    TaroStreamRow row, {
    _is.ColumnSelections<TaroStreamRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaroStreamRow>(
      row,
      columns: columns?.call(TaroStreamRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaroStreamRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaroStreamRow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaroStreamRowUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaroStreamRow>(
      id,
      columnValues: columnValues(TaroStreamRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaroStreamRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroStreamRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaroStreamRowUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TaroStreamRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroStreamRowTable>? orderBy,
    _is.OrderByListBuilder<TaroStreamRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaroStreamRow>(
      columnValues: columnValues(TaroStreamRow.t.updateTable),
      where: where(TaroStreamRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroStreamRow.t),
      orderByList: orderByList?.call(TaroStreamRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaroStreamRow]s in the list and returns the deleted rows.
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
  Future<List<TaroStreamRow>> delete(
    _is.DatabaseSession session,
    List<TaroStreamRow> rows, {
    _is.OrderByBuilder<TaroStreamRowTable>? orderBy,
    _is.OrderByListBuilder<TaroStreamRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaroStreamRow>(
      rows,
      orderBy: orderBy?.call(TaroStreamRow.t),
      orderByList: orderByList?.call(TaroStreamRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaroStreamRow].
  Future<TaroStreamRow> deleteRow(
    _is.DatabaseSession session,
    TaroStreamRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaroStreamRow>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroStreamRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroStreamRowTable> where,
    _is.OrderByBuilder<TaroStreamRowTable>? orderBy,
    _is.OrderByListBuilder<TaroStreamRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaroStreamRow>(
      where: where(TaroStreamRow.t),
      orderBy: orderBy?.call(TaroStreamRow.t),
      orderByList: orderByList?.call(TaroStreamRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroStreamRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaroStreamRow>(
      where: where?.call(TaroStreamRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaroStreamRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroStreamRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaroStreamRow>(
      where: where(TaroStreamRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
