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

/// An aggregate snapshot (spec §27.1 `snapshots`).
abstract class TaroSnapshotRow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TaroSnapshotRow._({
    this.id,
    required this.sourceUuid,
    required this.sourceType,
    required this.sourceVersion,
    required this.data,
    required this.metadata,
    required this.createdAt,
  });

  factory TaroSnapshotRow({
    int? id,
    required _is.UuidValue sourceUuid,
    required String sourceType,
    required int sourceVersion,
    required String data,
    required String metadata,
    required DateTime createdAt,
  }) = _TaroSnapshotRowImpl;

  factory TaroSnapshotRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaroSnapshotRow(
      id: jsonSerialization['id'] as int?,
      sourceUuid: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['sourceUuid'],
      ),
      sourceType: jsonSerialization['sourceType'] as String,
      sourceVersion: jsonSerialization['sourceVersion'] as int,
      data: jsonSerialization['data'] as String,
      metadata: jsonSerialization['metadata'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = TaroSnapshotRowTable();

  static const db = TaroSnapshotRowRepository._();

  @override
  int? id;

  /// The aggregate's ID.
  _is.UuidValue sourceUuid;

  /// The aggregate type.
  String sourceType;

  /// The aggregate version the snapshot represents.
  int sourceVersion;

  /// The aggregate's state as JSON.
  String data;

  /// Free-form metadata as JSON.
  String metadata;

  /// When the snapshot was stored, in UTC.
  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaroSnapshotRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TaroSnapshotRow copyWith({
    int? id,
    _is.UuidValue? sourceUuid,
    String? sourceType,
    int? sourceVersion,
    String? data,
    String? metadata,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'tarodomain_serverpod.TaroSnapshotRow',
      if (id != null) 'id': id,
      'sourceUuid': sourceUuid.toJson(),
      'sourceType': sourceType,
      'sourceVersion': sourceVersion,
      'data': data,
      'metadata': metadata,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TaroSnapshotRowInclude include() {
    return TaroSnapshotRowInclude._();
  }

  static TaroSnapshotRowIncludeList includeList({
    _is.WhereExpressionBuilder<TaroSnapshotRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroSnapshotRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSnapshotRowTable>? orderByList,
    TaroSnapshotRowInclude? include,
  }) {
    return TaroSnapshotRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroSnapshotRow.t),
      orderByList: orderByList?.call(TaroSnapshotRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaroSnapshotRowImpl extends TaroSnapshotRow {
  _TaroSnapshotRowImpl({
    int? id,
    required _is.UuidValue sourceUuid,
    required String sourceType,
    required int sourceVersion,
    required String data,
    required String metadata,
    required DateTime createdAt,
  }) : super._(
         id: id,
         sourceUuid: sourceUuid,
         sourceType: sourceType,
         sourceVersion: sourceVersion,
         data: data,
         metadata: metadata,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TaroSnapshotRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TaroSnapshotRow copyWith({
    Object? id = _Undefined,
    _is.UuidValue? sourceUuid,
    String? sourceType,
    int? sourceVersion,
    String? data,
    String? metadata,
    DateTime? createdAt,
  }) {
    return TaroSnapshotRow(
      id: id is int? ? id : this.id,
      sourceUuid: sourceUuid ?? this.sourceUuid,
      sourceType: sourceType ?? this.sourceType,
      sourceVersion: sourceVersion ?? this.sourceVersion,
      data: data ?? this.data,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TaroSnapshotRowUpdateTable extends _is.UpdateTable<TaroSnapshotRowTable> {
  TaroSnapshotRowUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> sourceUuid(
    _is.UuidValue value,
  ) => _is.ColumnValue(table.sourceUuid, value);

  _is.ColumnValue<String, String> sourceType(String value) =>
      _is.ColumnValue(table.sourceType, value);

  _is.ColumnValue<int, int> sourceVersion(int value) =>
      _is.ColumnValue(table.sourceVersion, value);

  _is.ColumnValue<String, String> data(String value) =>
      _is.ColumnValue(table.data, value);

  _is.ColumnValue<String, String> metadata(String value) =>
      _is.ColumnValue(table.metadata, value);

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(table.createdAt, value);
}

class TaroSnapshotRowTable extends _is.Table<int?> {
  TaroSnapshotRowTable({super.tableRelation})
    : super(tableName: 'tarodomain_snapshots') {
    updateTable = TaroSnapshotRowUpdateTable(this);
    sourceUuid = _is.ColumnUuid('sourceUuid', this);
    sourceType = _is.ColumnString('sourceType', this);
    sourceVersion = _is.ColumnInt('sourceVersion', this);
    data = _is.ColumnString('data', this);
    metadata = _is.ColumnString('metadata', this);
    createdAt = _is.ColumnDateTime('createdAt', this);
  }

  late final TaroSnapshotRowUpdateTable updateTable;

  /// The aggregate's ID.
  late final _is.ColumnUuid sourceUuid;

  /// The aggregate type.
  late final _is.ColumnString sourceType;

  /// The aggregate version the snapshot represents.
  late final _is.ColumnInt sourceVersion;

  /// The aggregate's state as JSON.
  late final _is.ColumnString data;

  /// Free-form metadata as JSON.
  late final _is.ColumnString metadata;

  /// When the snapshot was stored, in UTC.
  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    sourceUuid,
    sourceType,
    sourceVersion,
    data,
    metadata,
    createdAt,
  ];
}

class TaroSnapshotRowInclude extends _is.IncludeObject {
  TaroSnapshotRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TaroSnapshotRow.t;
}

class TaroSnapshotRowIncludeList extends _is.IncludeList {
  TaroSnapshotRowIncludeList._({
    _is.WhereExpressionBuilder<TaroSnapshotRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaroSnapshotRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaroSnapshotRow.t;
}

class TaroSnapshotRowRepository {
  const TaroSnapshotRowRepository._();

  /// Returns a list of [TaroSnapshotRow]s matching the given query parameters.
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
  Future<List<TaroSnapshotRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroSnapshotRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroSnapshotRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSnapshotRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaroSnapshotRow>(
      where: where?.call(TaroSnapshotRow.t),
      orderBy: orderBy?.call(TaroSnapshotRow.t),
      orderByList: orderByList?.call(TaroSnapshotRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaroSnapshotRow] matching the given query parameters.
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
  Future<TaroSnapshotRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroSnapshotRowTable>? where,
    int? offset,
    _is.OrderByBuilder<TaroSnapshotRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSnapshotRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaroSnapshotRow>(
      where: where?.call(TaroSnapshotRow.t),
      orderBy: orderBy?.call(TaroSnapshotRow.t),
      orderByList: orderByList?.call(TaroSnapshotRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaroSnapshotRow] by its [id] or null if no such row exists.
  Future<TaroSnapshotRow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaroSnapshotRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaroSnapshotRow]s in the list and returns the inserted rows.
  ///
  /// The returned [TaroSnapshotRow]s will have their `id` fields set.
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
  Future<List<TaroSnapshotRow>> insert(
    _is.DatabaseSession session,
    List<TaroSnapshotRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaroSnapshotRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaroSnapshotRow] and returns the inserted row.
  ///
  /// The returned [TaroSnapshotRow] will have its `id` field set.
  Future<TaroSnapshotRow> insertRow(
    _is.DatabaseSession session,
    TaroSnapshotRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaroSnapshotRow>(row, transaction: transaction);
  }

  /// Upserts all [TaroSnapshotRow]s in the list and returns the resulting rows.
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
  /// The returned [TaroSnapshotRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroSnapshotRow>> upsert(
    _is.DatabaseSession session,
    List<TaroSnapshotRow> rows, {
    required _is.ColumnSelections<TaroSnapshotRowTable> conflictColumns,
    _is.ColumnSelections<TaroSnapshotRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroSnapshotRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaroSnapshotRow>(
      rows,
      conflictColumns: conflictColumns(TaroSnapshotRow.t),
      updateColumns: updateColumns?.call(TaroSnapshotRow.t),
      updateWhere: updateWhere?.call(TaroSnapshotRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaroSnapshotRow] and returns the resulting row.
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
  /// The returned [TaroSnapshotRow] will have its `id` field set.
  Future<TaroSnapshotRow?> upsertRow(
    _is.DatabaseSession session,
    TaroSnapshotRow row, {
    required _is.ColumnSelections<TaroSnapshotRowTable> conflictColumns,
    _is.ColumnSelections<TaroSnapshotRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroSnapshotRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaroSnapshotRow>(
      row,
      conflictColumns: conflictColumns(TaroSnapshotRow.t),
      updateColumns: updateColumns?.call(TaroSnapshotRow.t),
      updateWhere: updateWhere?.call(TaroSnapshotRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaroSnapshotRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroSnapshotRow>> update(
    _is.DatabaseSession session,
    List<TaroSnapshotRow> rows, {
    _is.ColumnSelections<TaroSnapshotRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaroSnapshotRow>(
      rows,
      columns: columns?.call(TaroSnapshotRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaroSnapshotRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaroSnapshotRow> updateRow(
    _is.DatabaseSession session,
    TaroSnapshotRow row, {
    _is.ColumnSelections<TaroSnapshotRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaroSnapshotRow>(
      row,
      columns: columns?.call(TaroSnapshotRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaroSnapshotRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaroSnapshotRow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaroSnapshotRowUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaroSnapshotRow>(
      id,
      columnValues: columnValues(TaroSnapshotRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaroSnapshotRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroSnapshotRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaroSnapshotRowUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<TaroSnapshotRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroSnapshotRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSnapshotRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaroSnapshotRow>(
      columnValues: columnValues(TaroSnapshotRow.t.updateTable),
      where: where(TaroSnapshotRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroSnapshotRow.t),
      orderByList: orderByList?.call(TaroSnapshotRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaroSnapshotRow]s in the list and returns the deleted rows.
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
  Future<List<TaroSnapshotRow>> delete(
    _is.DatabaseSession session,
    List<TaroSnapshotRow> rows, {
    _is.OrderByBuilder<TaroSnapshotRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSnapshotRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaroSnapshotRow>(
      rows,
      orderBy: orderBy?.call(TaroSnapshotRow.t),
      orderByList: orderByList?.call(TaroSnapshotRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaroSnapshotRow].
  Future<TaroSnapshotRow> deleteRow(
    _is.DatabaseSession session,
    TaroSnapshotRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaroSnapshotRow>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroSnapshotRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroSnapshotRowTable> where,
    _is.OrderByBuilder<TaroSnapshotRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSnapshotRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaroSnapshotRow>(
      where: where(TaroSnapshotRow.t),
      orderBy: orderBy?.call(TaroSnapshotRow.t),
      orderByList: orderByList?.call(TaroSnapshotRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroSnapshotRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaroSnapshotRow>(
      where: where?.call(TaroSnapshotRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaroSnapshotRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroSnapshotRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaroSnapshotRow>(
      where: where(TaroSnapshotRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
