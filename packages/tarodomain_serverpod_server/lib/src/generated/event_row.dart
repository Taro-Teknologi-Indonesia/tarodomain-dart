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

/// One stored event (spec §27.1 `events` and `stream_events`).
abstract class TaroEventRow
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  TaroEventRow._({
    this.id,
    required this.eventId,
    required this.streamId,
    required this.category,
    required this.version,
    required this.eventType,
    required this.correlationId,
    required this.payload,
    this.position,
  });

  factory TaroEventRow({
    int? id,
    required _is.UuidValue eventId,
    required String streamId,
    required String category,
    required int version,
    required String eventType,
    required _is.UuidValue correlationId,
    required String payload,
    int? position,
  }) = _TaroEventRowImpl;

  factory TaroEventRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaroEventRow(
      id: jsonSerialization['id'] as int?,
      eventId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['eventId'],
      ),
      streamId: jsonSerialization['streamId'] as String,
      category: jsonSerialization['category'] as String,
      version: jsonSerialization['version'] as int,
      eventType: jsonSerialization['eventType'] as String,
      correlationId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['correlationId'],
      ),
      payload: jsonSerialization['payload'] as String,
      position: jsonSerialization['position'] as int?,
    );
  }

  static final t = TaroEventRowTable();

  static const db = TaroEventRowRepository._();

  @override
  int? id;

  /// The event ID (UUIDv7).
  _is.UuidValue eventId;

  /// The stream the event was appended to.
  String streamId;

  /// The stream's category: the part of [streamId] before the first `-`.
  String category;

  /// The event's version within its stream, counting from 1.
  int version;

  /// The event type name.
  String eventType;

  /// The trace the event belongs to.
  _is.UuidValue correlationId;

  /// The serialized event (type, schema version, envelope and data) as
  /// JSON.
  String payload;

  /// The event's global position, which orders cursor reads. Null until
  /// `EventSequencer` assigns it, after the event has committed. The
  /// auto-increment `id` is insert order, used only to break ties.
  int? position;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [TaroEventRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  TaroEventRow copyWith({
    int? id,
    _is.UuidValue? eventId,
    String? streamId,
    String? category,
    int? version,
    String? eventType,
    _is.UuidValue? correlationId,
    String? payload,
    int? position,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'tarodomain_serverpod.TaroEventRow',
      if (id != null) 'id': id,
      'eventId': eventId.toJson(),
      'streamId': streamId,
      'category': category,
      'version': version,
      'eventType': eventType,
      'correlationId': correlationId.toJson(),
      'payload': payload,
      if (position != null) 'position': position,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static TaroEventRowInclude include() {
    return TaroEventRowInclude._();
  }

  static TaroEventRowIncludeList includeList({
    _is.WhereExpressionBuilder<TaroEventRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroEventRowTable>? orderByList,
    TaroEventRowInclude? include,
  }) {
    return TaroEventRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroEventRow.t),
      orderByList: orderByList?.call(TaroEventRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TaroEventRowImpl extends TaroEventRow {
  _TaroEventRowImpl({
    int? id,
    required _is.UuidValue eventId,
    required String streamId,
    required String category,
    required int version,
    required String eventType,
    required _is.UuidValue correlationId,
    required String payload,
    int? position,
  }) : super._(
         id: id,
         eventId: eventId,
         streamId: streamId,
         category: category,
         version: version,
         eventType: eventType,
         correlationId: correlationId,
         payload: payload,
         position: position,
       );

  /// Returns a shallow copy of this [TaroEventRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  TaroEventRow copyWith({
    Object? id = _Undefined,
    _is.UuidValue? eventId,
    String? streamId,
    String? category,
    int? version,
    String? eventType,
    _is.UuidValue? correlationId,
    String? payload,
    Object? position = _Undefined,
  }) {
    return TaroEventRow(
      id: id is int? ? id : this.id,
      eventId: eventId ?? this.eventId,
      streamId: streamId ?? this.streamId,
      category: category ?? this.category,
      version: version ?? this.version,
      eventType: eventType ?? this.eventType,
      correlationId: correlationId ?? this.correlationId,
      payload: payload ?? this.payload,
      position: position is int? ? position : this.position,
    );
  }
}

class TaroEventRowUpdateTable extends _is.UpdateTable<TaroEventRowTable> {
  TaroEventRowUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> eventId(_is.UuidValue value) =>
      _is.ColumnValue(table.eventId, value);

  _is.ColumnValue<String, String> streamId(String value) =>
      _is.ColumnValue(table.streamId, value);

  _is.ColumnValue<String, String> category(String value) =>
      _is.ColumnValue(table.category, value);

  _is.ColumnValue<int, int> version(int value) =>
      _is.ColumnValue(table.version, value);

  _is.ColumnValue<String, String> eventType(String value) =>
      _is.ColumnValue(table.eventType, value);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> correlationId(
    _is.UuidValue value,
  ) => _is.ColumnValue(table.correlationId, value);

  _is.ColumnValue<String, String> payload(String value) =>
      _is.ColumnValue(table.payload, value);

  _is.ColumnValue<int, int> position(int? value) =>
      _is.ColumnValue(table.position, value);
}

class TaroEventRowTable extends _is.Table<int?> {
  TaroEventRowTable({super.tableRelation})
    : super(tableName: 'tarodomain_events') {
    updateTable = TaroEventRowUpdateTable(this);
    eventId = _is.ColumnUuid('eventId', this);
    streamId = _is.ColumnString('streamId', this);
    category = _is.ColumnString('category', this);
    version = _is.ColumnInt('version', this);
    eventType = _is.ColumnString('eventType', this);
    correlationId = _is.ColumnUuid('correlationId', this);
    payload = _is.ColumnString('payload', this);
    position = _is.ColumnInt('position', this);
  }

  late final TaroEventRowUpdateTable updateTable;

  /// The event ID (UUIDv7).
  late final _is.ColumnUuid eventId;

  /// The stream the event was appended to.
  late final _is.ColumnString streamId;

  /// The stream's category: the part of [streamId] before the first `-`.
  late final _is.ColumnString category;

  /// The event's version within its stream, counting from 1.
  late final _is.ColumnInt version;

  /// The event type name.
  late final _is.ColumnString eventType;

  /// The trace the event belongs to.
  late final _is.ColumnUuid correlationId;

  /// The serialized event (type, schema version, envelope and data) as
  /// JSON.
  late final _is.ColumnString payload;

  /// The event's global position, which orders cursor reads. Null until
  /// `EventSequencer` assigns it, after the event has committed. The
  /// auto-increment `id` is insert order, used only to break ties.
  late final _is.ColumnInt position;

  @override
  List<_is.Column> get columns => [
    id,
    eventId,
    streamId,
    category,
    version,
    eventType,
    correlationId,
    payload,
    position,
  ];
}

class TaroEventRowInclude extends _is.IncludeObject {
  TaroEventRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => TaroEventRow.t;
}

class TaroEventRowIncludeList extends _is.IncludeList {
  TaroEventRowIncludeList._({
    _is.WhereExpressionBuilder<TaroEventRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TaroEventRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => TaroEventRow.t;
}

class TaroEventRowRepository {
  const TaroEventRowRepository._();

  /// Returns a list of [TaroEventRow]s matching the given query parameters.
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
  Future<List<TaroEventRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroEventRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroEventRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TaroEventRow>(
      where: where?.call(TaroEventRow.t),
      orderBy: orderBy?.call(TaroEventRow.t),
      orderByList: orderByList?.call(TaroEventRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TaroEventRow] matching the given query parameters.
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
  Future<TaroEventRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroEventRowTable>? where,
    int? offset,
    _is.OrderByBuilder<TaroEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroEventRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TaroEventRow>(
      where: where?.call(TaroEventRow.t),
      orderBy: orderBy?.call(TaroEventRow.t),
      orderByList: orderByList?.call(TaroEventRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TaroEventRow] by its [id] or null if no such row exists.
  Future<TaroEventRow?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TaroEventRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TaroEventRow]s in the list and returns the inserted rows.
  ///
  /// The returned [TaroEventRow]s will have their `id` fields set.
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
  Future<List<TaroEventRow>> insert(
    _is.DatabaseSession session,
    List<TaroEventRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<TaroEventRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [TaroEventRow] and returns the inserted row.
  ///
  /// The returned [TaroEventRow] will have its `id` field set.
  Future<TaroEventRow> insertRow(
    _is.DatabaseSession session,
    TaroEventRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<TaroEventRow>(row, transaction: transaction);
  }

  /// Upserts all [TaroEventRow]s in the list and returns the resulting rows.
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
  /// The returned [TaroEventRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroEventRow>> upsert(
    _is.DatabaseSession session,
    List<TaroEventRow> rows, {
    required _is.ColumnSelections<TaroEventRowTable> conflictColumns,
    _is.ColumnSelections<TaroEventRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroEventRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<TaroEventRow>(
      rows,
      conflictColumns: conflictColumns(TaroEventRow.t),
      updateColumns: updateColumns?.call(TaroEventRow.t),
      updateWhere: updateWhere?.call(TaroEventRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [TaroEventRow] and returns the resulting row.
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
  /// The returned [TaroEventRow] will have its `id` field set.
  Future<TaroEventRow?> upsertRow(
    _is.DatabaseSession session,
    TaroEventRow row, {
    required _is.ColumnSelections<TaroEventRowTable> conflictColumns,
    _is.ColumnSelections<TaroEventRowTable>? updateColumns,
    _is.WhereExpressionBuilder<TaroEventRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<TaroEventRow>(
      row,
      conflictColumns: conflictColumns(TaroEventRow.t),
      updateColumns: updateColumns?.call(TaroEventRow.t),
      updateWhere: updateWhere?.call(TaroEventRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [TaroEventRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroEventRow>> update(
    _is.DatabaseSession session,
    List<TaroEventRow> rows, {
    _is.ColumnSelections<TaroEventRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<TaroEventRow>(
      rows,
      columns: columns?.call(TaroEventRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [TaroEventRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TaroEventRow> updateRow(
    _is.DatabaseSession session,
    TaroEventRow row, {
    _is.ColumnSelections<TaroEventRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<TaroEventRow>(
      row,
      columns: columns?.call(TaroEventRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TaroEventRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TaroEventRow?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<TaroEventRowUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<TaroEventRow>(
      id,
      columnValues: columnValues(TaroEventRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TaroEventRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroEventRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<TaroEventRowUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<TaroEventRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<TaroEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroEventRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<TaroEventRow>(
      columnValues: columnValues(TaroEventRow.t.updateTable),
      where: where(TaroEventRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TaroEventRow.t),
      orderByList: orderByList?.call(TaroEventRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [TaroEventRow]s in the list and returns the deleted rows.
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
  Future<List<TaroEventRow>> delete(
    _is.DatabaseSession session,
    List<TaroEventRow> rows, {
    _is.OrderByBuilder<TaroEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroEventRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<TaroEventRow>(
      rows,
      orderBy: orderBy?.call(TaroEventRow.t),
      orderByList: orderByList?.call(TaroEventRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [TaroEventRow].
  Future<TaroEventRow> deleteRow(
    _is.DatabaseSession session,
    TaroEventRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TaroEventRow>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<TaroEventRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroEventRowTable> where,
    _is.OrderByBuilder<TaroEventRowTable>? orderBy,
    _is.OrderByListBuilder<TaroEventRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<TaroEventRow>(
      where: where(TaroEventRow.t),
      orderBy: orderBy?.call(TaroEventRow.t),
      orderByList: orderByList?.call(TaroEventRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<TaroEventRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<TaroEventRow>(
      where: where?.call(TaroEventRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TaroEventRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<TaroEventRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TaroEventRow>(
      where: where(TaroEventRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
