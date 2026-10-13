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

/// The state of one saga instance (spec §27.1 `sagas`).
abstract class TaroSagaRow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TaroSagaRow._({
    this.id,
    required this.sagaType,
    required this.sagaId,
    required this.correlationId,
    required this.state,
    required this.status,
    this.currentStep,
    this.failureReason,
    required this.startedAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory TaroSagaRow({
    int? id,
    required String sagaType,
    required _is.UuidValue sagaId,
    required _is.UuidValue correlationId,
    required String state,
    required String status,
    String? currentStep,
    String? failureReason,
    required DateTime startedAt,
    required DateTime updatedAt,
    DateTime? completedAt,
  }) = _TaroSagaRowImpl;

  factory TaroSagaRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaroSagaRow(
      id: jsonSerialization['id'] as int?,
      sagaType: jsonSerialization['sagaType'] as String,
      sagaId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['sagaId']),
      correlationId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['correlationId'],
      ),
      state: jsonSerialization['state'] as String,
      status: jsonSerialization['status'] as String,
      currentStep: jsonSerialization['currentStep'] as String?,
      failureReason: jsonSerialization['failureReason'] as String?,
      startedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['startedAt'],
      ),
      updatedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
      completedAt: jsonSerialization['completedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['completedAt'],
            ),
    );
  }

  static final t = TaroSagaRowTable();

  static const db = TaroSagaRowRepository._();

  @override
  int? id;

  /// The saga type name.
  String sagaType;

  /// The saga instance ID.
  _is.UuidValue sagaId;

  /// The correlation ID shared by the saga's events and commands.
  _is.UuidValue correlationId;

  /// The saga's state as JSON.
  String state;

  /// The stored status: `RUNNING`, `COMPENSATING`, `COMPLETED` or
  /// `FAILED`.
  String status;

  /// The name of the current step, if the saga tracks one.
  String? currentStep;

  /// Why the saga failed.
  String? failureReason;

  /// When the saga was first saved, in UTC.
  DateTime startedAt;

  /// When the saga was last saved, in UTC.
  DateTime updatedAt;

  /// When the saga reached a terminal status, in UTC.
  DateTime? completedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaroSagaRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TaroSagaRow copyWith({
    int? id,
    String? sagaType,
    _is.UuidValue? sagaId,
    _is.UuidValue? correlationId,
    String? state,
    String? status,
    String? currentStep,
    String? failureReason,
    DateTime? startedAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'tarodomain_serverpod.TaroSagaRow',
      if (id != null) 'id': id,
      'sagaType': sagaType,
      'sagaId': sagaId.toJson(),
      'correlationId': correlationId.toJson(),
      'state': state,
      'status': status,
      if (currentStep != null) 'currentStep': currentStep,
      if (failureReason != null) 'failureReason': failureReason,
      'startedAt': startedAt.toJson(),
      'updatedAt': updatedAt.toJson(),
      if (completedAt != null) 'completedAt': completedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TaroSagaRowInclude include() {
    return TaroSagaRowInclude._();
  }

  static TaroSagaRowIncludeList includeList({
    _is.WhereExpressionBuilder<TaroSagaRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroSagaRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSagaRowTable>? orderByList,
    TaroSagaRowInclude? include,
  }) {
    return TaroSagaRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroSagaRow.t),
      orderByList: orderByList?.call(TaroSagaRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaroSagaRowImpl extends TaroSagaRow {
  _TaroSagaRowImpl({
    int? id,
    required String sagaType,
    required _is.UuidValue sagaId,
    required _is.UuidValue correlationId,
    required String state,
    required String status,
    String? currentStep,
    String? failureReason,
    required DateTime startedAt,
    required DateTime updatedAt,
    DateTime? completedAt,
  }) : super._(
         id: id,
         sagaType: sagaType,
         sagaId: sagaId,
         correlationId: correlationId,
         state: state,
         status: status,
         currentStep: currentStep,
         failureReason: failureReason,
         startedAt: startedAt,
         updatedAt: updatedAt,
         completedAt: completedAt,
       );

  /// Returns a shallow copy of this [TaroSagaRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TaroSagaRow copyWith({
    Object? id = _Undefined,
    String? sagaType,
    _is.UuidValue? sagaId,
    _is.UuidValue? correlationId,
    String? state,
    String? status,
    Object? currentStep = _Undefined,
    Object? failureReason = _Undefined,
    DateTime? startedAt,
    DateTime? updatedAt,
    Object? completedAt = _Undefined,
  }) {
    return TaroSagaRow(
      id: id is int? ? id : this.id,
      sagaType: sagaType ?? this.sagaType,
      sagaId: sagaId ?? this.sagaId,
      correlationId: correlationId ?? this.correlationId,
      state: state ?? this.state,
      status: status ?? this.status,
      currentStep: currentStep is String? ? currentStep : this.currentStep,
      failureReason: failureReason is String?
          ? failureReason
          : this.failureReason,
      startedAt: startedAt ?? this.startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt is DateTime? ? completedAt : this.completedAt,
    );
  }
}

class TaroSagaRowUpdateTable extends _is.UpdateTable<TaroSagaRowTable> {
  TaroSagaRowUpdateTable(super.table);

  _is.ColumnValue<String, String> sagaType(String value) =>
      _is.ColumnValue(table.sagaType, value);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> sagaId(_is.UuidValue value) =>
      _is.ColumnValue(table.sagaId, value);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> correlationId(
    _is.UuidValue value,
  ) => _is.ColumnValue(table.correlationId, value);

  _is.ColumnValue<String, String> state(String value) =>
      _is.ColumnValue(table.state, value);

  _is.ColumnValue<String, String> status(String value) =>
      _is.ColumnValue(table.status, value);

  _is.ColumnValue<String, String> currentStep(String? value) =>
      _is.ColumnValue(table.currentStep, value);

  _is.ColumnValue<String, String> failureReason(String? value) =>
      _is.ColumnValue(table.failureReason, value);

  _is.ColumnValue<DateTime, DateTime> startedAt(DateTime value) =>
      _is.ColumnValue(table.startedAt, value);

  _is.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _is.ColumnValue(table.updatedAt, value);

  _is.ColumnValue<DateTime, DateTime> completedAt(DateTime? value) =>
      _is.ColumnValue(table.completedAt, value);
}

class TaroSagaRowTable extends _is.Table<int?> {
  TaroSagaRowTable({super.tableRelation})
    : super(tableName: 'tarodomain_sagas') {
    updateTable = TaroSagaRowUpdateTable(this);
    sagaType = _is.ColumnString('sagaType', this);
    sagaId = _is.ColumnUuid('sagaId', this);
    correlationId = _is.ColumnUuid('correlationId', this);
    state = _is.ColumnString('state', this);
    status = _is.ColumnString('status', this);
    currentStep = _is.ColumnString('currentStep', this);
    failureReason = _is.ColumnString('failureReason', this);
    startedAt = _is.ColumnDateTime('startedAt', this);
    updatedAt = _is.ColumnDateTime('updatedAt', this);
    completedAt = _is.ColumnDateTime('completedAt', this);
  }

  late final TaroSagaRowUpdateTable updateTable;

  /// The saga type name.
  late final _is.ColumnString sagaType;

  /// The saga instance ID.
  late final _is.ColumnUuid sagaId;

  /// The correlation ID shared by the saga's events and commands.
  late final _is.ColumnUuid correlationId;

  /// The saga's state as JSON.
  late final _is.ColumnString state;

  /// The stored status: `RUNNING`, `COMPENSATING`, `COMPLETED` or
  /// `FAILED`.
  late final _is.ColumnString status;

  /// The name of the current step, if the saga tracks one.
  late final _is.ColumnString currentStep;

  /// Why the saga failed.
  late final _is.ColumnString failureReason;

  /// When the saga was first saved, in UTC.
  late final _is.ColumnDateTime startedAt;

  /// When the saga was last saved, in UTC.
  late final _is.ColumnDateTime updatedAt;

  /// When the saga reached a terminal status, in UTC.
  late final _is.ColumnDateTime completedAt;

  @override
  List<_is.Column> get columns => [
    id,
    sagaType,
    sagaId,
    correlationId,
    state,
    status,
    currentStep,
    failureReason,
    startedAt,
    updatedAt,
    completedAt,
  ];
}

class TaroSagaRowInclude extends _is.IncludeObject {
  TaroSagaRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TaroSagaRow.t;
}

class TaroSagaRowIncludeList extends _is.IncludeList {
  TaroSagaRowIncludeList._({
    _is.WhereExpressionBuilder<TaroSagaRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaroSagaRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaroSagaRow.t;
}

class TaroSagaRowRepository {
  const TaroSagaRowRepository._();

  /// Returns a list of [TaroSagaRow]s matching the given query parameters.
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
  Future<List<TaroSagaRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroSagaRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroSagaRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSagaRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaroSagaRow>(
      where: where?.call(TaroSagaRow.t),
      orderBy: orderBy?.call(TaroSagaRow.t),
      orderByList: orderByList?.call(TaroSagaRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaroSagaRow] matching the given query parameters.
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
  Future<TaroSagaRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroSagaRowTable>? where,
    int? offset,
    _is.OrderByBuilder<TaroSagaRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSagaRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaroSagaRow>(
      where: where?.call(TaroSagaRow.t),
      orderBy: orderBy?.call(TaroSagaRow.t),
      orderByList: orderByList?.call(TaroSagaRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaroSagaRow] by its [id] or null if no such row exists.
  Future<TaroSagaRow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaroSagaRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaroSagaRow]s in the list and returns the inserted rows.
  ///
  /// The returned [TaroSagaRow]s will have their `id` fields set.
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
  Future<List<TaroSagaRow>> insert(
    _is.DatabaseSession session,
    List<TaroSagaRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaroSagaRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaroSagaRow] and returns the inserted row.
  ///
  /// The returned [TaroSagaRow] will have its `id` field set.
  Future<TaroSagaRow> insertRow(
    _is.DatabaseSession session,
    TaroSagaRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaroSagaRow>(row, transaction: transaction);
  }

  /// Upserts all [TaroSagaRow]s in the list and returns the resulting rows.
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
  /// The returned [TaroSagaRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroSagaRow>> upsert(
    _is.DatabaseSession session,
    List<TaroSagaRow> rows, {
    required _is.ColumnSelections<TaroSagaRowTable> conflictColumns,
    _is.ColumnSelections<TaroSagaRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroSagaRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaroSagaRow>(
      rows,
      conflictColumns: conflictColumns(TaroSagaRow.t),
      updateColumns: updateColumns?.call(TaroSagaRow.t),
      updateWhere: updateWhere?.call(TaroSagaRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaroSagaRow] and returns the resulting row.
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
  /// The returned [TaroSagaRow] will have its `id` field set.
  Future<TaroSagaRow?> upsertRow(
    _is.DatabaseSession session,
    TaroSagaRow row, {
    required _is.ColumnSelections<TaroSagaRowTable> conflictColumns,
    _is.ColumnSelections<TaroSagaRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroSagaRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaroSagaRow>(
      row,
      conflictColumns: conflictColumns(TaroSagaRow.t),
      updateColumns: updateColumns?.call(TaroSagaRow.t),
      updateWhere: updateWhere?.call(TaroSagaRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaroSagaRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroSagaRow>> update(
    _is.DatabaseSession session,
    List<TaroSagaRow> rows, {
    _is.ColumnSelections<TaroSagaRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaroSagaRow>(
      rows,
      columns: columns?.call(TaroSagaRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaroSagaRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaroSagaRow> updateRow(
    _is.DatabaseSession session,
    TaroSagaRow row, {
    _is.ColumnSelections<TaroSagaRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaroSagaRow>(
      row,
      columns: columns?.call(TaroSagaRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaroSagaRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaroSagaRow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaroSagaRowUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaroSagaRow>(
      id,
      columnValues: columnValues(TaroSagaRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaroSagaRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroSagaRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaroSagaRowUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TaroSagaRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroSagaRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSagaRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaroSagaRow>(
      columnValues: columnValues(TaroSagaRow.t.updateTable),
      where: where(TaroSagaRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroSagaRow.t),
      orderByList: orderByList?.call(TaroSagaRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaroSagaRow]s in the list and returns the deleted rows.
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
  Future<List<TaroSagaRow>> delete(
    _is.DatabaseSession session,
    List<TaroSagaRow> rows, {
    _is.OrderByBuilder<TaroSagaRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSagaRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaroSagaRow>(
      rows,
      orderBy: orderBy?.call(TaroSagaRow.t),
      orderByList: orderByList?.call(TaroSagaRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaroSagaRow].
  Future<TaroSagaRow> deleteRow(
    _is.DatabaseSession session,
    TaroSagaRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaroSagaRow>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroSagaRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroSagaRowTable> where,
    _is.OrderByBuilder<TaroSagaRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSagaRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaroSagaRow>(
      where: where(TaroSagaRow.t),
      orderBy: orderBy?.call(TaroSagaRow.t),
      orderByList: orderByList?.call(TaroSagaRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroSagaRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaroSagaRow>(
      where: where?.call(TaroSagaRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaroSagaRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroSagaRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaroSagaRow>(
      where: where(TaroSagaRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
