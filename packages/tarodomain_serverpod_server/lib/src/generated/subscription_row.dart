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

/// A persistent catch-up cursor (spec §27.1 `subscriptions`).
abstract class TaroSubscriptionRow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TaroSubscriptionRow._({
    this.id,
    required this.name,
    this.streamId,
    this.lastSeen,
    this.lastPosition,
    required this.createdAt,
    this.failedEventId,
    int? failedAttempts,
  }) : failedAttempts = failedAttempts ?? 0;

  factory TaroSubscriptionRow({
    int? id,
    required String name,
    String? streamId,
    _is.UuidValue? lastSeen,
    int? lastPosition,
    required DateTime createdAt,
    _is.UuidValue? failedEventId,
    int? failedAttempts,
  }) = _TaroSubscriptionRowImpl;

  factory TaroSubscriptionRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaroSubscriptionRow(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      streamId: jsonSerialization['streamId'] as String?,
      lastSeen: jsonSerialization['lastSeen'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['lastSeen']),
      lastPosition: jsonSerialization['lastPosition'] as int?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      failedEventId: jsonSerialization['failedEventId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(
              jsonSerialization['failedEventId'],
            ),
      failedAttempts: jsonSerialization['failedAttempts'] as int?,
    );
  }

  static final t = TaroSubscriptionRowTable();

  static const db = TaroSubscriptionRowRepository._();

  @override
  int? id;

  /// The subscription name.
  String name;

  /// The stream followed, or null for every stream.
  String? streamId;

  /// The ID of the last processed event, or null before the first ack.
  _is.UuidValue? lastSeen;

  /// The position of [lastSeen], so the cursor survives the deletion of
  /// that event. It only moves forward.
  int? lastPosition;

  /// When the subscription was created, in UTC.
  DateTime createdAt;

  /// The event the handler last failed on with a retryable error, or null
  /// if it hasn't failed since the last ack.
  _is.UuidValue? failedEventId;

  /// How many times in a row the handler has failed on [failedEventId].
  int failedAttempts;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaroSubscriptionRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TaroSubscriptionRow copyWith({
    int? id,
    String? name,
    String? streamId,
    _is.UuidValue? lastSeen,
    int? lastPosition,
    DateTime? createdAt,
    _is.UuidValue? failedEventId,
    int? failedAttempts,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'tarodomain_serverpod.TaroSubscriptionRow',
      if (id != null) 'id': id,
      'name': name,
      if (streamId != null) 'streamId': streamId,
      if (lastSeen != null) 'lastSeen': lastSeen?.toJson(),
      if (lastPosition != null) 'lastPosition': lastPosition,
      'createdAt': createdAt.toJson(),
      if (failedEventId != null) 'failedEventId': failedEventId?.toJson(),
      'failedAttempts': failedAttempts,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TaroSubscriptionRowInclude include() {
    return TaroSubscriptionRowInclude._();
  }

  static TaroSubscriptionRowIncludeList includeList({
    _is.WhereExpressionBuilder<TaroSubscriptionRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroSubscriptionRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSubscriptionRowTable>? orderByList,
    TaroSubscriptionRowInclude? include,
  }) {
    return TaroSubscriptionRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroSubscriptionRow.t),
      orderByList: orderByList?.call(TaroSubscriptionRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaroSubscriptionRowImpl extends TaroSubscriptionRow {
  _TaroSubscriptionRowImpl({
    int? id,
    required String name,
    String? streamId,
    _is.UuidValue? lastSeen,
    int? lastPosition,
    required DateTime createdAt,
    _is.UuidValue? failedEventId,
    int? failedAttempts,
  }) : super._(
         id: id,
         name: name,
         streamId: streamId,
         lastSeen: lastSeen,
         lastPosition: lastPosition,
         createdAt: createdAt,
         failedEventId: failedEventId,
         failedAttempts: failedAttempts,
       );

  /// Returns a shallow copy of this [TaroSubscriptionRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TaroSubscriptionRow copyWith({
    Object? id = _Undefined,
    String? name,
    Object? streamId = _Undefined,
    Object? lastSeen = _Undefined,
    Object? lastPosition = _Undefined,
    DateTime? createdAt,
    Object? failedEventId = _Undefined,
    int? failedAttempts,
  }) {
    return TaroSubscriptionRow(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      streamId: streamId is String? ? streamId : this.streamId,
      lastSeen: lastSeen is _is.UuidValue? ? lastSeen : this.lastSeen,
      lastPosition: lastPosition is int? ? lastPosition : this.lastPosition,
      createdAt: createdAt ?? this.createdAt,
      failedEventId: failedEventId is _is.UuidValue?
          ? failedEventId
          : this.failedEventId,
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }
}

class TaroSubscriptionRowUpdateTable
    extends _is.UpdateTable<TaroSubscriptionRowTable> {
  TaroSubscriptionRowUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) =>
      _is.ColumnValue(table.name, value);

  _is.ColumnValue<String, String> streamId(String? value) =>
      _is.ColumnValue(table.streamId, value);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> lastSeen(
    _is.UuidValue? value,
  ) => _is.ColumnValue(table.lastSeen, value);

  _is.ColumnValue<int, int> lastPosition(int? value) =>
      _is.ColumnValue(table.lastPosition, value);

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(table.createdAt, value);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> failedEventId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(table.failedEventId, value);

  _is.ColumnValue<int, int> failedAttempts(int value) =>
      _is.ColumnValue(table.failedAttempts, value);
}

class TaroSubscriptionRowTable extends _is.Table<int?> {
  TaroSubscriptionRowTable({super.tableRelation})
    : super(tableName: 'tarodomain_subscriptions') {
    updateTable = TaroSubscriptionRowUpdateTable(this);
    name = _is.ColumnString('name', this);
    streamId = _is.ColumnString('streamId', this);
    lastSeen = _is.ColumnUuid('lastSeen', this);
    lastPosition = _is.ColumnInt('lastPosition', this);
    createdAt = _is.ColumnDateTime('createdAt', this);
    failedEventId = _is.ColumnUuid('failedEventId', this);
    failedAttempts = _is.ColumnInt('failedAttempts', this, hasDefault: true);
  }

  late final TaroSubscriptionRowUpdateTable updateTable;

  /// The subscription name.
  late final _is.ColumnString name;

  /// The stream followed, or null for every stream.
  late final _is.ColumnString streamId;

  /// The ID of the last processed event, or null before the first ack.
  late final _is.ColumnUuid lastSeen;

  /// The position of [lastSeen], so the cursor survives the deletion of
  /// that event. It only moves forward.
  late final _is.ColumnInt lastPosition;

  /// When the subscription was created, in UTC.
  late final _is.ColumnDateTime createdAt;

  /// The event the handler last failed on with a retryable error, or null
  /// if it hasn't failed since the last ack.
  late final _is.ColumnUuid failedEventId;

  /// How many times in a row the handler has failed on [failedEventId].
  late final _is.ColumnInt failedAttempts;

  @override
  List<_is.Column> get columns => [
    id,
    name,
    streamId,
    lastSeen,
    lastPosition,
    createdAt,
    failedEventId,
    failedAttempts,
  ];
}

class TaroSubscriptionRowInclude extends _is.IncludeObject {
  TaroSubscriptionRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TaroSubscriptionRow.t;
}

class TaroSubscriptionRowIncludeList extends _is.IncludeList {
  TaroSubscriptionRowIncludeList._({
    _is.WhereExpressionBuilder<TaroSubscriptionRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaroSubscriptionRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaroSubscriptionRow.t;
}

class TaroSubscriptionRowRepository {
  const TaroSubscriptionRowRepository._();

  /// Returns a list of [TaroSubscriptionRow]s matching the given query parameters.
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
  Future<List<TaroSubscriptionRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroSubscriptionRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroSubscriptionRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSubscriptionRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaroSubscriptionRow>(
      where: where?.call(TaroSubscriptionRow.t),
      orderBy: orderBy?.call(TaroSubscriptionRow.t),
      orderByList: orderByList?.call(TaroSubscriptionRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaroSubscriptionRow] matching the given query parameters.
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
  Future<TaroSubscriptionRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroSubscriptionRowTable>? where,
    int? offset,
    _is.OrderByBuilder<TaroSubscriptionRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSubscriptionRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaroSubscriptionRow>(
      where: where?.call(TaroSubscriptionRow.t),
      orderBy: orderBy?.call(TaroSubscriptionRow.t),
      orderByList: orderByList?.call(TaroSubscriptionRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaroSubscriptionRow] by its [id] or null if no such row exists.
  Future<TaroSubscriptionRow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaroSubscriptionRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaroSubscriptionRow]s in the list and returns the inserted rows.
  ///
  /// The returned [TaroSubscriptionRow]s will have their `id` fields set.
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
  Future<List<TaroSubscriptionRow>> insert(
    _is.DatabaseSession session,
    List<TaroSubscriptionRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaroSubscriptionRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaroSubscriptionRow] and returns the inserted row.
  ///
  /// The returned [TaroSubscriptionRow] will have its `id` field set.
  Future<TaroSubscriptionRow> insertRow(
    _is.DatabaseSession session,
    TaroSubscriptionRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaroSubscriptionRow>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [TaroSubscriptionRow]s in the list and returns the resulting rows.
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
  /// The returned [TaroSubscriptionRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroSubscriptionRow>> upsert(
    _is.DatabaseSession session,
    List<TaroSubscriptionRow> rows, {
    required _is.ColumnSelections<TaroSubscriptionRowTable> conflictColumns,
    _is.ColumnSelections<TaroSubscriptionRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroSubscriptionRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaroSubscriptionRow>(
      rows,
      conflictColumns: conflictColumns(TaroSubscriptionRow.t),
      updateColumns: updateColumns?.call(TaroSubscriptionRow.t),
      updateWhere: updateWhere?.call(TaroSubscriptionRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaroSubscriptionRow] and returns the resulting row.
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
  /// The returned [TaroSubscriptionRow] will have its `id` field set.
  Future<TaroSubscriptionRow?> upsertRow(
    _is.DatabaseSession session,
    TaroSubscriptionRow row, {
    required _is.ColumnSelections<TaroSubscriptionRowTable> conflictColumns,
    _is.ColumnSelections<TaroSubscriptionRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroSubscriptionRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaroSubscriptionRow>(
      row,
      conflictColumns: conflictColumns(TaroSubscriptionRow.t),
      updateColumns: updateColumns?.call(TaroSubscriptionRow.t),
      updateWhere: updateWhere?.call(TaroSubscriptionRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaroSubscriptionRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroSubscriptionRow>> update(
    _is.DatabaseSession session,
    List<TaroSubscriptionRow> rows, {
    _is.ColumnSelections<TaroSubscriptionRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaroSubscriptionRow>(
      rows,
      columns: columns?.call(TaroSubscriptionRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaroSubscriptionRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaroSubscriptionRow> updateRow(
    _is.DatabaseSession session,
    TaroSubscriptionRow row, {
    _is.ColumnSelections<TaroSubscriptionRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaroSubscriptionRow>(
      row,
      columns: columns?.call(TaroSubscriptionRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaroSubscriptionRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaroSubscriptionRow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaroSubscriptionRowUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaroSubscriptionRow>(
      id,
      columnValues: columnValues(TaroSubscriptionRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaroSubscriptionRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroSubscriptionRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaroSubscriptionRowUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<TaroSubscriptionRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroSubscriptionRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSubscriptionRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaroSubscriptionRow>(
      columnValues: columnValues(TaroSubscriptionRow.t.updateTable),
      where: where(TaroSubscriptionRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroSubscriptionRow.t),
      orderByList: orderByList?.call(TaroSubscriptionRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaroSubscriptionRow]s in the list and returns the deleted rows.
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
  Future<List<TaroSubscriptionRow>> delete(
    _is.DatabaseSession session,
    List<TaroSubscriptionRow> rows, {
    _is.OrderByBuilder<TaroSubscriptionRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSubscriptionRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaroSubscriptionRow>(
      rows,
      orderBy: orderBy?.call(TaroSubscriptionRow.t),
      orderByList: orderByList?.call(TaroSubscriptionRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaroSubscriptionRow].
  Future<TaroSubscriptionRow> deleteRow(
    _is.DatabaseSession session,
    TaroSubscriptionRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaroSubscriptionRow>(
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
  Future<List<TaroSubscriptionRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroSubscriptionRowTable> where,
    _is.OrderByBuilder<TaroSubscriptionRowTable>? orderBy,
    _is.OrderByListBuilder<TaroSubscriptionRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaroSubscriptionRow>(
      where: where(TaroSubscriptionRow.t),
      orderBy: orderBy?.call(TaroSubscriptionRow.t),
      orderByList: orderByList?.call(TaroSubscriptionRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroSubscriptionRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaroSubscriptionRow>(
      where: where?.call(TaroSubscriptionRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaroSubscriptionRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroSubscriptionRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaroSubscriptionRow>(
      where: where(TaroSubscriptionRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
