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

/// An event a projection or saga has handled (spec §27.1
/// `processed_events`).
abstract class TaroProcessedEventRow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TaroProcessedEventRow._({
    this.id,
    required this.handlerName,
    required this.handlerInstance,
    required this.eventId,
    required this.processedAt,
  });

  factory TaroProcessedEventRow({
    int? id,
    required String handlerName,
    required String handlerInstance,
    required _is.UuidValue eventId,
    required DateTime processedAt,
  }) = _TaroProcessedEventRowImpl;

  factory TaroProcessedEventRow.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TaroProcessedEventRow(
      id: jsonSerialization['id'] as int?,
      handlerName: jsonSerialization['handlerName'] as String,
      handlerInstance: jsonSerialization['handlerInstance'] as String,
      eventId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['eventId'],
      ),
      processedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['processedAt'],
      ),
    );
  }

  static final t = TaroProcessedEventRowTable();

  static const db = TaroProcessedEventRowRepository._();

  @override
  int? id;

  /// The projection name or saga type.
  String handlerName;

  /// The projection or shard name, or the saga ID.
  String handlerInstance;

  /// The handled event.
  _is.UuidValue eventId;

  /// When the event was recorded, in UTC.
  DateTime processedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaroProcessedEventRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TaroProcessedEventRow copyWith({
    int? id,
    String? handlerName,
    String? handlerInstance,
    _is.UuidValue? eventId,
    DateTime? processedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'tarodomain_serverpod.TaroProcessedEventRow',
      if (id != null) 'id': id,
      'handlerName': handlerName,
      'handlerInstance': handlerInstance,
      'eventId': eventId.toJson(),
      'processedAt': processedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TaroProcessedEventRowInclude include() {
    return TaroProcessedEventRowInclude._();
  }

  static TaroProcessedEventRowIncludeList includeList({
    _is.WhereExpressionBuilder<TaroProcessedEventRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroProcessedEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedEventRowTable>? orderByList,
    TaroProcessedEventRowInclude? include,
  }) {
    return TaroProcessedEventRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroProcessedEventRow.t),
      orderByList: orderByList?.call(TaroProcessedEventRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaroProcessedEventRowImpl extends TaroProcessedEventRow {
  _TaroProcessedEventRowImpl({
    int? id,
    required String handlerName,
    required String handlerInstance,
    required _is.UuidValue eventId,
    required DateTime processedAt,
  }) : super._(
         id: id,
         handlerName: handlerName,
         handlerInstance: handlerInstance,
         eventId: eventId,
         processedAt: processedAt,
       );

  /// Returns a shallow copy of this [TaroProcessedEventRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TaroProcessedEventRow copyWith({
    Object? id = _Undefined,
    String? handlerName,
    String? handlerInstance,
    _is.UuidValue? eventId,
    DateTime? processedAt,
  }) {
    return TaroProcessedEventRow(
      id: id is int? ? id : this.id,
      handlerName: handlerName ?? this.handlerName,
      handlerInstance: handlerInstance ?? this.handlerInstance,
      eventId: eventId ?? this.eventId,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}

class TaroProcessedEventRowUpdateTable
    extends _is.UpdateTable<TaroProcessedEventRowTable> {
  TaroProcessedEventRowUpdateTable(super.table);

  _is.ColumnValue<String, String> handlerName(String value) =>
      _is.ColumnValue(table.handlerName, value);

  _is.ColumnValue<String, String> handlerInstance(String value) =>
      _is.ColumnValue(table.handlerInstance, value);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> eventId(_is.UuidValue value) =>
      _is.ColumnValue(table.eventId, value);

  _is.ColumnValue<DateTime, DateTime> processedAt(DateTime value) =>
      _is.ColumnValue(table.processedAt, value);
}

class TaroProcessedEventRowTable extends _is.Table<int?> {
  TaroProcessedEventRowTable({super.tableRelation})
    : super(tableName: 'tarodomain_processed_events') {
    updateTable = TaroProcessedEventRowUpdateTable(this);
    handlerName = _is.ColumnString('handlerName', this);
    handlerInstance = _is.ColumnString('handlerInstance', this);
    eventId = _is.ColumnUuid('eventId', this);
    processedAt = _is.ColumnDateTime('processedAt', this);
  }

  late final TaroProcessedEventRowUpdateTable updateTable;

  /// The projection name or saga type.
  late final _is.ColumnString handlerName;

  /// The projection or shard name, or the saga ID.
  late final _is.ColumnString handlerInstance;

  /// The handled event.
  late final _is.ColumnUuid eventId;

  /// When the event was recorded, in UTC.
  late final _is.ColumnDateTime processedAt;

  @override
  List<_is.Column> get columns => [
    id,
    handlerName,
    handlerInstance,
    eventId,
    processedAt,
  ];
}

class TaroProcessedEventRowInclude extends _is.IncludeObject {
  TaroProcessedEventRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TaroProcessedEventRow.t;
}

class TaroProcessedEventRowIncludeList extends _is.IncludeList {
  TaroProcessedEventRowIncludeList._({
    _is.WhereExpressionBuilder<TaroProcessedEventRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaroProcessedEventRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaroProcessedEventRow.t;
}

class TaroProcessedEventRowRepository {
  const TaroProcessedEventRowRepository._();

  /// Returns a list of [TaroProcessedEventRow]s matching the given query parameters.
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
  Future<List<TaroProcessedEventRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroProcessedEventRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroProcessedEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedEventRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaroProcessedEventRow>(
      where: where?.call(TaroProcessedEventRow.t),
      orderBy: orderBy?.call(TaroProcessedEventRow.t),
      orderByList: orderByList?.call(TaroProcessedEventRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaroProcessedEventRow] matching the given query parameters.
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
  Future<TaroProcessedEventRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroProcessedEventRowTable>? where,
    int? offset,
    _is.OrderByBuilder<TaroProcessedEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedEventRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaroProcessedEventRow>(
      where: where?.call(TaroProcessedEventRow.t),
      orderBy: orderBy?.call(TaroProcessedEventRow.t),
      orderByList: orderByList?.call(TaroProcessedEventRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaroProcessedEventRow] by its [id] or null if no such row exists.
  Future<TaroProcessedEventRow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaroProcessedEventRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaroProcessedEventRow]s in the list and returns the inserted rows.
  ///
  /// The returned [TaroProcessedEventRow]s will have their `id` fields set.
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
  Future<List<TaroProcessedEventRow>> insert(
    _is.DatabaseSession session,
    List<TaroProcessedEventRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaroProcessedEventRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaroProcessedEventRow] and returns the inserted row.
  ///
  /// The returned [TaroProcessedEventRow] will have its `id` field set.
  Future<TaroProcessedEventRow> insertRow(
    _is.DatabaseSession session,
    TaroProcessedEventRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaroProcessedEventRow>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TaroProcessedEventRow]s in the list and returns the resulting rows.
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
  /// The returned [TaroProcessedEventRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroProcessedEventRow>> upsert(
    _is.DatabaseSession session,
    List<TaroProcessedEventRow> rows, {
    required _is.ColumnSelections<TaroProcessedEventRowTable> conflictColumns,
    _is.ColumnSelections<TaroProcessedEventRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroProcessedEventRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaroProcessedEventRow>(
      rows,
      conflictColumns: conflictColumns(TaroProcessedEventRow.t),
      updateColumns: updateColumns?.call(TaroProcessedEventRow.t),
      updateWhere: updateWhere?.call(TaroProcessedEventRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaroProcessedEventRow] and returns the resulting row.
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
  /// The returned [TaroProcessedEventRow] will have its `id` field set.
  Future<TaroProcessedEventRow?> upsertRow(
    _is.DatabaseSession session,
    TaroProcessedEventRow row, {
    required _is.ColumnSelections<TaroProcessedEventRowTable> conflictColumns,
    _is.ColumnSelections<TaroProcessedEventRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroProcessedEventRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaroProcessedEventRow>(
      row,
      conflictColumns: conflictColumns(TaroProcessedEventRow.t),
      updateColumns: updateColumns?.call(TaroProcessedEventRow.t),
      updateWhere: updateWhere?.call(TaroProcessedEventRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaroProcessedEventRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroProcessedEventRow>> update(
    _is.DatabaseSession session,
    List<TaroProcessedEventRow> rows, {
    _is.ColumnSelections<TaroProcessedEventRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaroProcessedEventRow>(
      rows,
      columns: columns?.call(TaroProcessedEventRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaroProcessedEventRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaroProcessedEventRow> updateRow(
    _is.DatabaseSession session,
    TaroProcessedEventRow row, {
    _is.ColumnSelections<TaroProcessedEventRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaroProcessedEventRow>(
      row,
      columns: columns?.call(TaroProcessedEventRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaroProcessedEventRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaroProcessedEventRow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaroProcessedEventRowUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaroProcessedEventRow>(
      id,
      columnValues: columnValues(TaroProcessedEventRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaroProcessedEventRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroProcessedEventRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaroProcessedEventRowUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<TaroProcessedEventRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroProcessedEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedEventRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaroProcessedEventRow>(
      columnValues: columnValues(TaroProcessedEventRow.t.updateTable),
      where: where(TaroProcessedEventRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroProcessedEventRow.t),
      orderByList: orderByList?.call(TaroProcessedEventRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaroProcessedEventRow]s in the list and returns the deleted rows.
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
  Future<List<TaroProcessedEventRow>> delete(
    _is.DatabaseSession session,
    List<TaroProcessedEventRow> rows, {
    _is.OrderByBuilder<TaroProcessedEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedEventRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaroProcessedEventRow>(
      rows,
      orderBy: orderBy?.call(TaroProcessedEventRow.t),
      orderByList: orderByList?.call(TaroProcessedEventRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaroProcessedEventRow].
  Future<TaroProcessedEventRow> deleteRow(
    _is.DatabaseSession session,
    TaroProcessedEventRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaroProcessedEventRow>(
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
  Future<List<TaroProcessedEventRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroProcessedEventRowTable> where,
    _is.OrderByBuilder<TaroProcessedEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroProcessedEventRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaroProcessedEventRow>(
      where: where(TaroProcessedEventRow.t),
      orderBy: orderBy?.call(TaroProcessedEventRow.t),
      orderByList: orderByList?.call(TaroProcessedEventRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroProcessedEventRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaroProcessedEventRow>(
      where: where?.call(TaroProcessedEventRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaroProcessedEventRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroProcessedEventRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaroProcessedEventRow>(
      where: where(TaroProcessedEventRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
