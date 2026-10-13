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

/// An event a handler gave up on (spec §27.1 `dead_letters`).
abstract class TaroDeadLetterRow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TaroDeadLetterRow._({
    this.id,
    required this.handlerName,
    required this.eventId,
    required this.event,
    required this.errorMessage,
    this.errorCode,
    required this.attempts,
    required this.createdAt,
  });

  factory TaroDeadLetterRow({
    int? id,
    required String handlerName,
    required _is.UuidValue eventId,
    required String event,
    required String errorMessage,
    String? errorCode,
    required int attempts,
    required DateTime createdAt,
  }) = _TaroDeadLetterRowImpl;

  factory TaroDeadLetterRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaroDeadLetterRow(
      id: jsonSerialization['id'] as int?,
      handlerName: jsonSerialization['handlerName'] as String,
      eventId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['eventId'],
      ),
      event: jsonSerialization['event'] as String,
      errorMessage: jsonSerialization['errorMessage'] as String,
      errorCode: jsonSerialization['errorCode'] as String?,
      attempts: jsonSerialization['attempts'] as int,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = TaroDeadLetterRowTable();

  static const db = TaroDeadLetterRowRepository._();

  @override
  int? id;

  /// The handler that failed.
  String handlerName;

  /// The failed event's ID.
  _is.UuidValue eventId;

  /// The serialized event as JSON.
  String event;

  /// The last error's message.
  String errorMessage;

  /// The last error's code, if it was a framework error.
  String? errorCode;

  /// How many times the handler was tried.
  int attempts;

  /// When the entry was written, in UTC.
  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaroDeadLetterRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TaroDeadLetterRow copyWith({
    int? id,
    String? handlerName,
    _is.UuidValue? eventId,
    String? event,
    String? errorMessage,
    String? errorCode,
    int? attempts,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'tarodomain_serverpod.TaroDeadLetterRow',
      if (id != null) 'id': id,
      'handlerName': handlerName,
      'eventId': eventId.toJson(),
      'event': event,
      'errorMessage': errorMessage,
      if (errorCode != null) 'errorCode': errorCode,
      'attempts': attempts,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TaroDeadLetterRowInclude include() {
    return TaroDeadLetterRowInclude._();
  }

  static TaroDeadLetterRowIncludeList includeList({
    _is.WhereExpressionBuilder<TaroDeadLetterRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroDeadLetterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroDeadLetterRowTable>? orderByList,
    TaroDeadLetterRowInclude? include,
  }) {
    return TaroDeadLetterRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroDeadLetterRow.t),
      orderByList: orderByList?.call(TaroDeadLetterRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaroDeadLetterRowImpl extends TaroDeadLetterRow {
  _TaroDeadLetterRowImpl({
    int? id,
    required String handlerName,
    required _is.UuidValue eventId,
    required String event,
    required String errorMessage,
    String? errorCode,
    required int attempts,
    required DateTime createdAt,
  }) : super._(
         id: id,
         handlerName: handlerName,
         eventId: eventId,
         event: event,
         errorMessage: errorMessage,
         errorCode: errorCode,
         attempts: attempts,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TaroDeadLetterRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TaroDeadLetterRow copyWith({
    Object? id = _Undefined,
    String? handlerName,
    _is.UuidValue? eventId,
    String? event,
    String? errorMessage,
    Object? errorCode = _Undefined,
    int? attempts,
    DateTime? createdAt,
  }) {
    return TaroDeadLetterRow(
      id: id is int? ? id : this.id,
      handlerName: handlerName ?? this.handlerName,
      eventId: eventId ?? this.eventId,
      event: event ?? this.event,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode is String? ? errorCode : this.errorCode,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TaroDeadLetterRowUpdateTable
    extends _is.UpdateTable<TaroDeadLetterRowTable> {
  TaroDeadLetterRowUpdateTable(super.table);

  _is.ColumnValue<String, String> handlerName(String value) =>
      _is.ColumnValue(table.handlerName, value);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> eventId(_is.UuidValue value) =>
      _is.ColumnValue(table.eventId, value);

  _is.ColumnValue<String, String> event(String value) =>
      _is.ColumnValue(table.event, value);

  _is.ColumnValue<String, String> errorMessage(String value) =>
      _is.ColumnValue(table.errorMessage, value);

  _is.ColumnValue<String, String> errorCode(String? value) =>
      _is.ColumnValue(table.errorCode, value);

  _is.ColumnValue<int, int> attempts(int value) =>
      _is.ColumnValue(table.attempts, value);

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(table.createdAt, value);
}

class TaroDeadLetterRowTable extends _is.Table<int?> {
  TaroDeadLetterRowTable({super.tableRelation})
    : super(tableName: 'tarodomain_dead_letters') {
    updateTable = TaroDeadLetterRowUpdateTable(this);
    handlerName = _is.ColumnString('handlerName', this);
    eventId = _is.ColumnUuid('eventId', this);
    event = _is.ColumnString('event', this);
    errorMessage = _is.ColumnString('errorMessage', this);
    errorCode = _is.ColumnString('errorCode', this);
    attempts = _is.ColumnInt('attempts', this);
    createdAt = _is.ColumnDateTime('createdAt', this);
  }

  late final TaroDeadLetterRowUpdateTable updateTable;

  /// The handler that failed.
  late final _is.ColumnString handlerName;

  /// The failed event's ID.
  late final _is.ColumnUuid eventId;

  /// The serialized event as JSON.
  late final _is.ColumnString event;

  /// The last error's message.
  late final _is.ColumnString errorMessage;

  /// The last error's code, if it was a framework error.
  late final _is.ColumnString errorCode;

  /// How many times the handler was tried.
  late final _is.ColumnInt attempts;

  /// When the entry was written, in UTC.
  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    handlerName,
    eventId,
    event,
    errorMessage,
    errorCode,
    attempts,
    createdAt,
  ];
}

class TaroDeadLetterRowInclude extends _is.IncludeObject {
  TaroDeadLetterRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TaroDeadLetterRow.t;
}

class TaroDeadLetterRowIncludeList extends _is.IncludeList {
  TaroDeadLetterRowIncludeList._({
    _is.WhereExpressionBuilder<TaroDeadLetterRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaroDeadLetterRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaroDeadLetterRow.t;
}

class TaroDeadLetterRowRepository {
  const TaroDeadLetterRowRepository._();

  /// Returns a list of [TaroDeadLetterRow]s matching the given query parameters.
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
  Future<List<TaroDeadLetterRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroDeadLetterRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroDeadLetterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroDeadLetterRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaroDeadLetterRow>(
      where: where?.call(TaroDeadLetterRow.t),
      orderBy: orderBy?.call(TaroDeadLetterRow.t),
      orderByList: orderByList?.call(TaroDeadLetterRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaroDeadLetterRow] matching the given query parameters.
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
  Future<TaroDeadLetterRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroDeadLetterRowTable>? where,
    int? offset,
    _is.OrderByBuilder<TaroDeadLetterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroDeadLetterRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaroDeadLetterRow>(
      where: where?.call(TaroDeadLetterRow.t),
      orderBy: orderBy?.call(TaroDeadLetterRow.t),
      orderByList: orderByList?.call(TaroDeadLetterRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaroDeadLetterRow] by its [id] or null if no such row exists.
  Future<TaroDeadLetterRow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaroDeadLetterRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaroDeadLetterRow]s in the list and returns the inserted rows.
  ///
  /// The returned [TaroDeadLetterRow]s will have their `id` fields set.
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
  Future<List<TaroDeadLetterRow>> insert(
    _is.DatabaseSession session,
    List<TaroDeadLetterRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaroDeadLetterRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaroDeadLetterRow] and returns the inserted row.
  ///
  /// The returned [TaroDeadLetterRow] will have its `id` field set.
  Future<TaroDeadLetterRow> insertRow(
    _is.DatabaseSession session,
    TaroDeadLetterRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaroDeadLetterRow>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TaroDeadLetterRow]s in the list and returns the resulting rows.
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
  /// The returned [TaroDeadLetterRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroDeadLetterRow>> upsert(
    _is.DatabaseSession session,
    List<TaroDeadLetterRow> rows, {
    required _is.ColumnSelections<TaroDeadLetterRowTable> conflictColumns,
    _is.ColumnSelections<TaroDeadLetterRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroDeadLetterRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaroDeadLetterRow>(
      rows,
      conflictColumns: conflictColumns(TaroDeadLetterRow.t),
      updateColumns: updateColumns?.call(TaroDeadLetterRow.t),
      updateWhere: updateWhere?.call(TaroDeadLetterRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaroDeadLetterRow] and returns the resulting row.
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
  /// The returned [TaroDeadLetterRow] will have its `id` field set.
  Future<TaroDeadLetterRow?> upsertRow(
    _is.DatabaseSession session,
    TaroDeadLetterRow row, {
    required _is.ColumnSelections<TaroDeadLetterRowTable> conflictColumns,
    _is.ColumnSelections<TaroDeadLetterRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroDeadLetterRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaroDeadLetterRow>(
      row,
      conflictColumns: conflictColumns(TaroDeadLetterRow.t),
      updateColumns: updateColumns?.call(TaroDeadLetterRow.t),
      updateWhere: updateWhere?.call(TaroDeadLetterRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaroDeadLetterRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroDeadLetterRow>> update(
    _is.DatabaseSession session,
    List<TaroDeadLetterRow> rows, {
    _is.ColumnSelections<TaroDeadLetterRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaroDeadLetterRow>(
      rows,
      columns: columns?.call(TaroDeadLetterRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaroDeadLetterRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaroDeadLetterRow> updateRow(
    _is.DatabaseSession session,
    TaroDeadLetterRow row, {
    _is.ColumnSelections<TaroDeadLetterRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaroDeadLetterRow>(
      row,
      columns: columns?.call(TaroDeadLetterRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaroDeadLetterRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaroDeadLetterRow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaroDeadLetterRowUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaroDeadLetterRow>(
      id,
      columnValues: columnValues(TaroDeadLetterRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaroDeadLetterRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroDeadLetterRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaroDeadLetterRowUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<TaroDeadLetterRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroDeadLetterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroDeadLetterRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaroDeadLetterRow>(
      columnValues: columnValues(TaroDeadLetterRow.t.updateTable),
      where: where(TaroDeadLetterRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroDeadLetterRow.t),
      orderByList: orderByList?.call(TaroDeadLetterRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaroDeadLetterRow]s in the list and returns the deleted rows.
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
  Future<List<TaroDeadLetterRow>> delete(
    _is.DatabaseSession session,
    List<TaroDeadLetterRow> rows, {
    _is.OrderByBuilder<TaroDeadLetterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroDeadLetterRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaroDeadLetterRow>(
      rows,
      orderBy: orderBy?.call(TaroDeadLetterRow.t),
      orderByList: orderByList?.call(TaroDeadLetterRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaroDeadLetterRow].
  Future<TaroDeadLetterRow> deleteRow(
    _is.DatabaseSession session,
    TaroDeadLetterRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaroDeadLetterRow>(
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
  Future<List<TaroDeadLetterRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroDeadLetterRowTable> where,
    _is.OrderByBuilder<TaroDeadLetterRowTable>? orderBy,
    _is.OrderByListBuilder<TaroDeadLetterRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaroDeadLetterRow>(
      where: where(TaroDeadLetterRow.t),
      orderBy: orderBy?.call(TaroDeadLetterRow.t),
      orderByList: orderByList?.call(TaroDeadLetterRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroDeadLetterRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaroDeadLetterRow>(
      where: where?.call(TaroDeadLetterRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaroDeadLetterRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroDeadLetterRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaroDeadLetterRow>(
      where: where(TaroDeadLetterRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
