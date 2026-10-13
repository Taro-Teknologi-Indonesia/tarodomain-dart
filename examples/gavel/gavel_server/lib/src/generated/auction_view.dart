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

/// One auction: the read model of `AuctionTableProjection`.
abstract class AuctionView
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  AuctionView._({
    this.id,
    required this.auctionId,
    required this.code,
    required this.title,
    required this.closeAt,
    required this.status,
    required this.lotCount,
  });

  factory AuctionView({
    int? id,
    required _is.UuidValue auctionId,
    required String code,
    required String title,
    required DateTime closeAt,
    required String status,
    required int lotCount,
  }) = _AuctionViewImpl;

  factory AuctionView.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuctionView(
      id: jsonSerialization['id'] as int?,
      auctionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['auctionId'],
      ),
      code: jsonSerialization['code'] as String,
      title: jsonSerialization['title'] as String,
      closeAt: _is.DateTimeJsonExtension.fromJson(jsonSerialization['closeAt']),
      status: jsonSerialization['status'] as String,
      lotCount: jsonSerialization['lotCount'] as int,
    );
  }

  static final t = AuctionViewTable();

  static const db = AuctionViewRepository._();

  @override
  int? id;

  /// The auction.
  _is.UuidValue auctionId;

  /// The join code in the share link.
  String code;

  /// The auction's title.
  String title;

  /// When the auction closes, in UTC.
  DateTime closeAt;

  /// OPEN, CLOSING or CLOSED.
  String status;

  /// How many lots the auction has.
  int lotCount;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [AuctionView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AuctionView copyWith({
    int? id,
    _is.UuidValue? auctionId,
    String? code,
    String? title,
    DateTime? closeAt,
    String? status,
    int? lotCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AuctionView',
      if (id != null) 'id': id,
      'auctionId': auctionId.toJson(),
      'code': code,
      'title': title,
      'closeAt': closeAt.toJson(),
      'status': status,
      'lotCount': lotCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AuctionView',
      if (id != null) 'id': id,
      'auctionId': auctionId.toJson(),
      'code': code,
      'title': title,
      'closeAt': closeAt.toJson(),
      'status': status,
      'lotCount': lotCount,
    };
  }

  static AuctionViewInclude include() {
    return AuctionViewInclude._();
  }

  static AuctionViewIncludeList includeList({
    _is.WhereExpressionBuilder<AuctionViewTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuctionViewTable>? orderBy,
    _is.OrderByListBuilder<AuctionViewTable>? orderByList,
    AuctionViewInclude? include,
  }) {
    return AuctionViewIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuctionView.t),
      orderByList: orderByList?.call(AuctionView.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuctionViewImpl extends AuctionView {
  _AuctionViewImpl({
    int? id,
    required _is.UuidValue auctionId,
    required String code,
    required String title,
    required DateTime closeAt,
    required String status,
    required int lotCount,
  }) : super._(
         id: id,
         auctionId: auctionId,
         code: code,
         title: title,
         closeAt: closeAt,
         status: status,
         lotCount: lotCount,
       );

  /// Returns a shallow copy of this [AuctionView]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AuctionView copyWith({
    Object? id = _Undefined,
    _is.UuidValue? auctionId,
    String? code,
    String? title,
    DateTime? closeAt,
    String? status,
    int? lotCount,
  }) {
    return AuctionView(
      id: id is int? ? id : this.id,
      auctionId: auctionId ?? this.auctionId,
      code: code ?? this.code,
      title: title ?? this.title,
      closeAt: closeAt ?? this.closeAt,
      status: status ?? this.status,
      lotCount: lotCount ?? this.lotCount,
    );
  }
}

class AuctionViewUpdateTable extends _is.UpdateTable<AuctionViewTable> {
  AuctionViewUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> auctionId(
    _is.UuidValue value,
  ) => _is.ColumnValue(table.auctionId, value);

  _is.ColumnValue<String, String> code(String value) =>
      _is.ColumnValue(table.code, value);

  _is.ColumnValue<String, String> title(String value) =>
      _is.ColumnValue(table.title, value);

  _is.ColumnValue<DateTime, DateTime> closeAt(DateTime value) =>
      _is.ColumnValue(table.closeAt, value);

  _is.ColumnValue<String, String> status(String value) =>
      _is.ColumnValue(table.status, value);

  _is.ColumnValue<int, int> lotCount(int value) =>
      _is.ColumnValue(table.lotCount, value);
}

class AuctionViewTable extends _is.Table<int?> {
  AuctionViewTable({super.tableRelation}) : super(tableName: 'gavel_auctions') {
    updateTable = AuctionViewUpdateTable(this);
    auctionId = _is.ColumnUuid('auctionId', this);
    code = _is.ColumnString('code', this);
    title = _is.ColumnString('title', this);
    closeAt = _is.ColumnDateTime('closeAt', this);
    status = _is.ColumnString('status', this);
    lotCount = _is.ColumnInt('lotCount', this);
  }

  late final AuctionViewUpdateTable updateTable;

  /// The auction.
  late final _is.ColumnUuid auctionId;

  /// The join code in the share link.
  late final _is.ColumnString code;

  /// The auction's title.
  late final _is.ColumnString title;

  /// When the auction closes, in UTC.
  late final _is.ColumnDateTime closeAt;

  /// OPEN, CLOSING or CLOSED.
  late final _is.ColumnString status;

  /// How many lots the auction has.
  late final _is.ColumnInt lotCount;

  @override
  List<_is.Column> get columns => [
    id,
    auctionId,
    code,
    title,
    closeAt,
    status,
    lotCount,
  ];
}

class AuctionViewInclude extends _is.IncludeObject {
  AuctionViewInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => AuctionView.t;
}

class AuctionViewIncludeList extends _is.IncludeList {
  AuctionViewIncludeList._({
    _is.WhereExpressionBuilder<AuctionViewTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AuctionView.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => AuctionView.t;
}

class AuctionViewRepository {
  const AuctionViewRepository._();

  /// Returns a list of [AuctionView]s matching the given query parameters.
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
  Future<List<AuctionView>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuctionViewTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuctionViewTable>? orderBy,
    _is.OrderByListBuilder<AuctionViewTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AuctionView>(
      where: where?.call(AuctionView.t),
      orderBy: orderBy?.call(AuctionView.t),
      orderByList: orderByList?.call(AuctionView.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AuctionView] matching the given query parameters.
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
  Future<AuctionView?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuctionViewTable>? where,
    int? offset,
    _is.OrderByBuilder<AuctionViewTable>? orderBy,
    _is.OrderByListBuilder<AuctionViewTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AuctionView>(
      where: where?.call(AuctionView.t),
      orderBy: orderBy?.call(AuctionView.t),
      orderByList: orderByList?.call(AuctionView.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AuctionView] by its [id] or null if no such row exists.
  Future<AuctionView?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AuctionView>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AuctionView]s in the list and returns the inserted rows.
  ///
  /// The returned [AuctionView]s will have their `id` fields set.
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
  Future<List<AuctionView>> insert(
    _is.DatabaseSession session,
    List<AuctionView> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AuctionView>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AuctionView] and returns the inserted row.
  ///
  /// The returned [AuctionView] will have its `id` field set.
  Future<AuctionView> insertRow(
    _is.DatabaseSession session,
    AuctionView row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AuctionView>(row, transaction: transaction);
  }

  /// Upserts all [AuctionView]s in the list and returns the resulting rows.
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
  /// The returned [AuctionView]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuctionView>> upsert(
    _is.DatabaseSession session,
    List<AuctionView> rows, {
    required _is.ColumnSelections<AuctionViewTable> conflictColumns,
    _is.ColumnSelections<AuctionViewTable>? updateColumns,
    _is.WhereExpressionBuilder<AuctionViewTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AuctionView>(
      rows,
      conflictColumns: conflictColumns(AuctionView.t),
      updateColumns: updateColumns?.call(AuctionView.t),
      updateWhere: updateWhere?.call(AuctionView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AuctionView] and returns the resulting row.
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
  /// The returned [AuctionView] will have its `id` field set.
  Future<AuctionView?> upsertRow(
    _is.DatabaseSession session,
    AuctionView row, {
    required _is.ColumnSelections<AuctionViewTable> conflictColumns,
    _is.ColumnSelections<AuctionViewTable>? updateColumns,
    _is.WhereExpressionBuilder<AuctionViewTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AuctionView>(
      row,
      conflictColumns: conflictColumns(AuctionView.t),
      updateColumns: updateColumns?.call(AuctionView.t),
      updateWhere: updateWhere?.call(AuctionView.t),
      transaction: transaction,
    );
  }

  /// Updates all [AuctionView]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuctionView>> update(
    _is.DatabaseSession session,
    List<AuctionView> rows, {
    _is.ColumnSelections<AuctionViewTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AuctionView>(
      rows,
      columns: columns?.call(AuctionView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AuctionView]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AuctionView> updateRow(
    _is.DatabaseSession session,
    AuctionView row, {
    _is.ColumnSelections<AuctionViewTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AuctionView>(
      row,
      columns: columns?.call(AuctionView.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AuctionView] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AuctionView?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<AuctionViewUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AuctionView>(
      id,
      columnValues: columnValues(AuctionView.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AuctionView]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuctionView>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AuctionViewUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AuctionViewTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AuctionViewTable>? orderBy,
    _is.OrderByListBuilder<AuctionViewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AuctionView>(
      columnValues: columnValues(AuctionView.t.updateTable),
      where: where(AuctionView.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AuctionView.t),
      orderByList: orderByList?.call(AuctionView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AuctionView]s in the list and returns the deleted rows.
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
  Future<List<AuctionView>> delete(
    _is.DatabaseSession session,
    List<AuctionView> rows, {
    _is.OrderByBuilder<AuctionViewTable>? orderBy,
    _is.OrderByListBuilder<AuctionViewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AuctionView>(
      rows,
      orderBy: orderBy?.call(AuctionView.t),
      orderByList: orderByList?.call(AuctionView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AuctionView].
  Future<AuctionView> deleteRow(
    _is.DatabaseSession session,
    AuctionView row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AuctionView>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AuctionView>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AuctionViewTable> where,
    _is.OrderByBuilder<AuctionViewTable>? orderBy,
    _is.OrderByListBuilder<AuctionViewTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AuctionView>(
      where: where(AuctionView.t),
      orderBy: orderBy?.call(AuctionView.t),
      orderByList: orderByList?.call(AuctionView.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AuctionViewTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AuctionView>(
      where: where?.call(AuctionView.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AuctionView] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AuctionViewTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AuctionView>(
      where: where(AuctionView.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
