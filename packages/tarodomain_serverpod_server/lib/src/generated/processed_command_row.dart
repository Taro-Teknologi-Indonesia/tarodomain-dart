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

/// A processed command, for command idempotency (spec §27.1
/// `processed_commands`).
abstract class TaroProcessedCommandRow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TaroProcessedCommandRow._({
    this.id,
    required this.commandId,
    required this.commandType,
    required this.handlerName,
    required this.processedAt,
  });

  factory TaroProcessedCommandRow({
    int? id,
    required _is.UuidValue commandId,
    required String commandType,
    required String handlerName,
    required DateTime processedAt,
  }) = _TaroProcessedCommandRowImpl;

  factory TaroProcessedCommandRow.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TaroProcessedCommandRow(
      id: jsonSerialization['id'] as int?,
      commandId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['commandId'],
      ),
      commandType: jsonSerialization['commandType'] as String,
      handlerName: jsonSerialization['handlerName'] as String,
      processedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['processedAt'],
      ),
    );
  }

  static final t = TaroProcessedCommandRowTable();

  static const db = TaroProcessedCommandRowRepository._();

  @override
  int? id;

  /// The command's ID.
  _is.UuidValue commandId;

  /// The command type name.
  String commandType;

  /// The handler that processed it.
  String handlerName;

  /// When it was recorded, in UTC.
  DateTime processedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaroProcessedCommandRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TaroProcessedCommandRow copyWith({
    int? id,
    _is.UuidValue? commandId,
    String? commandType,
    String? handlerName,
    DateTime? processedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'tarodomain_serverpod.TaroProcessedCommandRow',
      if (id != null) 'id': id,
      'commandId': commandId.toJson(),
      'commandType': commandType,
      'handlerName': handlerName,
      'processedAt': processedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TaroProcessedCommandRowInclude include() {
    return TaroProcessedCommandRowInclude._();
  }

  static TaroProcessedCommandRowIncludeList includeList({
    _is.WhereExpressionBuilder<TaroProcessedCommandRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroProcessedCommandRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedCommandRowTable>? orderByList,
    TaroProcessedCommandRowInclude? include,
  }) {
    return TaroProcessedCommandRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroProcessedCommandRow.t),
      orderByList: orderByList?.call(TaroProcessedCommandRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaroProcessedCommandRowImpl extends TaroProcessedCommandRow {
  _TaroProcessedCommandRowImpl({
    int? id,
    required _is.UuidValue commandId,
    required String commandType,
    required String handlerName,
    required DateTime processedAt,
  }) : super._(
         id: id,
         commandId: commandId,
         commandType: commandType,
         handlerName: handlerName,
         processedAt: processedAt,
       );

  /// Returns a shallow copy of this [TaroProcessedCommandRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TaroProcessedCommandRow copyWith({
    Object? id = _Undefined,
    _is.UuidValue? commandId,
    String? commandType,
    String? handlerName,
    DateTime? processedAt,
  }) {
    return TaroProcessedCommandRow(
      id: id is int? ? id : this.id,
      commandId: commandId ?? this.commandId,
      commandType: commandType ?? this.commandType,
      handlerName: handlerName ?? this.handlerName,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}

class TaroProcessedCommandRowUpdateTable
    extends _is.UpdateTable<TaroProcessedCommandRowTable> {
  TaroProcessedCommandRowUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> commandId(
    _is.UuidValue value,
  ) => _is.ColumnValue(table.commandId, value);

  _is.ColumnValue<String, String> commandType(String value) =>
      _is.ColumnValue(table.commandType, value);

  _is.ColumnValue<String, String> handlerName(String value) =>
      _is.ColumnValue(table.handlerName, value);

  _is.ColumnValue<DateTime, DateTime> processedAt(DateTime value) =>
      _is.ColumnValue(table.processedAt, value);
}

class TaroProcessedCommandRowTable extends _is.Table<int?> {
  TaroProcessedCommandRowTable({super.tableRelation})
    : super(tableName: 'tarodomain_processed_commands') {
    updateTable = TaroProcessedCommandRowUpdateTable(this);
    commandId = _is.ColumnUuid('commandId', this);
    commandType = _is.ColumnString('commandType', this);
    handlerName = _is.ColumnString('handlerName', this);
    processedAt = _is.ColumnDateTime('processedAt', this);
  }

  late final TaroProcessedCommandRowUpdateTable updateTable;

  /// The command's ID.
  late final _is.ColumnUuid commandId;

  /// The command type name.
  late final _is.ColumnString commandType;

  /// The handler that processed it.
  late final _is.ColumnString handlerName;

  /// When it was recorded, in UTC.
  late final _is.ColumnDateTime processedAt;

  @override
  List<_is.Column> get columns => [
    id,
    commandId,
    commandType,
    handlerName,
    processedAt,
  ];
}

class TaroProcessedCommandRowInclude extends _is.IncludeObject {
  TaroProcessedCommandRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TaroProcessedCommandRow.t;
}

class TaroProcessedCommandRowIncludeList extends _is.IncludeList {
  TaroProcessedCommandRowIncludeList._({
    _is.WhereExpressionBuilder<TaroProcessedCommandRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaroProcessedCommandRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaroProcessedCommandRow.t;
}

class TaroProcessedCommandRowRepository {
  const TaroProcessedCommandRowRepository._();

  /// Returns a list of [TaroProcessedCommandRow]s matching the given query parameters.
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
  Future<List<TaroProcessedCommandRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroProcessedCommandRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroProcessedCommandRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedCommandRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaroProcessedCommandRow>(
      where: where?.call(TaroProcessedCommandRow.t),
      orderBy: orderBy?.call(TaroProcessedCommandRow.t),
      orderByList: orderByList?.call(TaroProcessedCommandRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaroProcessedCommandRow] matching the given query parameters.
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
  Future<TaroProcessedCommandRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroProcessedCommandRowTable>? where,
    int? offset,
    _is.OrderByBuilder<TaroProcessedCommandRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedCommandRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaroProcessedCommandRow>(
      where: where?.call(TaroProcessedCommandRow.t),
      orderBy: orderBy?.call(TaroProcessedCommandRow.t),
      orderByList: orderByList?.call(TaroProcessedCommandRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaroProcessedCommandRow] by its [id] or null if no such row exists.
  Future<TaroProcessedCommandRow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaroProcessedCommandRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaroProcessedCommandRow]s in the list and returns the inserted rows.
  ///
  /// The returned [TaroProcessedCommandRow]s will have their `id` fields set.
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
  Future<List<TaroProcessedCommandRow>> insert(
    _is.DatabaseSession session,
    List<TaroProcessedCommandRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaroProcessedCommandRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaroProcessedCommandRow] and returns the inserted row.
  ///
  /// The returned [TaroProcessedCommandRow] will have its `id` field set.
  Future<TaroProcessedCommandRow> insertRow(
    _is.DatabaseSession session,
    TaroProcessedCommandRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaroProcessedCommandRow>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TaroProcessedCommandRow]s in the list and returns the resulting rows.
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
  /// The returned [TaroProcessedCommandRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroProcessedCommandRow>> upsert(
    _is.DatabaseSession session,
    List<TaroProcessedCommandRow> rows, {
    required _is.ColumnSelections<TaroProcessedCommandRowTable> conflictColumns,
    _is.ColumnSelections<TaroProcessedCommandRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroProcessedCommandRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaroProcessedCommandRow>(
      rows,
      conflictColumns: conflictColumns(TaroProcessedCommandRow.t),
      updateColumns: updateColumns?.call(TaroProcessedCommandRow.t),
      updateWhere: updateWhere?.call(TaroProcessedCommandRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaroProcessedCommandRow] and returns the resulting row.
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
  /// The returned [TaroProcessedCommandRow] will have its `id` field set.
  Future<TaroProcessedCommandRow?> upsertRow(
    _is.DatabaseSession session,
    TaroProcessedCommandRow row, {
    required _is.ColumnSelections<TaroProcessedCommandRowTable> conflictColumns,
    _is.ColumnSelections<TaroProcessedCommandRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroProcessedCommandRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaroProcessedCommandRow>(
      row,
      conflictColumns: conflictColumns(TaroProcessedCommandRow.t),
      updateColumns: updateColumns?.call(TaroProcessedCommandRow.t),
      updateWhere: updateWhere?.call(TaroProcessedCommandRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaroProcessedCommandRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroProcessedCommandRow>> update(
    _is.DatabaseSession session,
    List<TaroProcessedCommandRow> rows, {
    _is.ColumnSelections<TaroProcessedCommandRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaroProcessedCommandRow>(
      rows,
      columns: columns?.call(TaroProcessedCommandRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaroProcessedCommandRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaroProcessedCommandRow> updateRow(
    _is.DatabaseSession session,
    TaroProcessedCommandRow row, {
    _is.ColumnSelections<TaroProcessedCommandRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaroProcessedCommandRow>(
      row,
      columns: columns?.call(TaroProcessedCommandRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaroProcessedCommandRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaroProcessedCommandRow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaroProcessedCommandRowUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaroProcessedCommandRow>(
      id,
      columnValues: columnValues(TaroProcessedCommandRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaroProcessedCommandRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroProcessedCommandRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaroProcessedCommandRowUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<TaroProcessedCommandRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroProcessedCommandRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedCommandRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaroProcessedCommandRow>(
      columnValues: columnValues(TaroProcessedCommandRow.t.updateTable),
      where: where(TaroProcessedCommandRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroProcessedCommandRow.t),
      orderByList: orderByList?.call(TaroProcessedCommandRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaroProcessedCommandRow]s in the list and returns the deleted rows.
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
  Future<List<TaroProcessedCommandRow>> delete(
    _is.DatabaseSession session,
    List<TaroProcessedCommandRow> rows, {
    _is.OrderByBuilder<TaroProcessedCommandRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedCommandRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaroProcessedCommandRow>(
      rows,
      orderBy: orderBy?.call(TaroProcessedCommandRow.t),
      orderByList: orderByList?.call(TaroProcessedCommandRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaroProcessedCommandRow].
  Future<TaroProcessedCommandRow> deleteRow(
    _is.DatabaseSession session,
    TaroProcessedCommandRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaroProcessedCommandRow>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroProcessedCommandRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroProcessedCommandRowTable> where,
    _is.OrderByBuilder<TaroProcessedCommandRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedCommandRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaroProcessedCommandRow>(
      where: where(TaroProcessedCommandRow.t),
      orderBy: orderBy?.call(TaroProcessedCommandRow.t),
      orderByList: orderByList?.call(TaroProcessedCommandRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroProcessedCommandRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaroProcessedCommandRow>(
      where: where?.call(TaroProcessedCommandRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaroProcessedCommandRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroProcessedCommandRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaroProcessedCommandRow>(
      where: where(TaroProcessedCommandRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
