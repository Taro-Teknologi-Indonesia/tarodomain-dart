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

/// The current state of a `Participant`, stored by `ParticipantRepository`
/// instead of its events.
abstract class ParticipantRow
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  ParticipantRow._({
    this.id,
    required this.auctionId,
    required this.displayName,
    required this.keyHash,
    required this.version,
  });

  factory ParticipantRow({
    _is.UuidValue? id,
    required _is.UuidValue auctionId,
    required String displayName,
    required String keyHash,
    required int version,
  }) = _ParticipantRowImpl;

  factory ParticipantRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return ParticipantRow(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      auctionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['auctionId'],
      ),
      displayName: jsonSerialization['displayName'] as String,
      keyHash: jsonSerialization['keyHash'] as String,
      version: jsonSerialization['version'] as int,
    );
  }

  static final t = ParticipantRowTable();

  static const db = ParticipantRowRepository._();

  @override
  _is.UuidValue? id;

  /// The auction joined.
  _is.UuidValue auctionId;

  /// The name shown to the other bidders.
  String displayName;

  /// The SHA-256 of the participant key. The key itself is never stored.
  String keyHash;

  /// The aggregate version, for optimistic concurrency.
  int version;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [ParticipantRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  ParticipantRow copyWith({
    _is.UuidValue? id,
    _is.UuidValue? auctionId,
    String? displayName,
    String? keyHash,
    int? version,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ParticipantRow',
      if (id != null) 'id': id?.toJson(),
      'auctionId': auctionId.toJson(),
      'displayName': displayName,
      'keyHash': keyHash,
      'version': version,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static ParticipantRowInclude include() {
    return ParticipantRowInclude._();
  }

  static ParticipantRowIncludeList includeList({
    _is.WhereExpressionBuilder<ParticipantRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ParticipantRowTable>? orderBy,
    _is.OrderByListBuilder<ParticipantRowTable>? orderByList,
    ParticipantRowInclude? include,
  }) {
    return ParticipantRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ParticipantRow.t),
      orderByList: orderByList?.call(ParticipantRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ParticipantRowImpl extends ParticipantRow {
  _ParticipantRowImpl({
    _is.UuidValue? id,
    required _is.UuidValue auctionId,
    required String displayName,
    required String keyHash,
    required int version,
  }) : super._(
         id: id,
         auctionId: auctionId,
         displayName: displayName,
         keyHash: keyHash,
         version: version,
       );

  /// Returns a shallow copy of this [ParticipantRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  ParticipantRow copyWith({
    Object? id = _Undefined,
    _is.UuidValue? auctionId,
    String? displayName,
    String? keyHash,
    int? version,
  }) {
    return ParticipantRow(
      id: id is _is.UuidValue? ? id : this.id,
      auctionId: auctionId ?? this.auctionId,
      displayName: displayName ?? this.displayName,
      keyHash: keyHash ?? this.keyHash,
      version: version ?? this.version,
    );
  }
}

class ParticipantRowUpdateTable extends _is.UpdateTable<ParticipantRowTable> {
  ParticipantRowUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> auctionId(
    _is.UuidValue value,
  ) => _is.ColumnValue(table.auctionId, value);

  _is.ColumnValue<String, String> displayName(String value) =>
      _is.ColumnValue(table.displayName, value);

  _is.ColumnValue<String, String> keyHash(String value) =>
      _is.ColumnValue(table.keyHash, value);

  _is.ColumnValue<int, int> version(int value) =>
      _is.ColumnValue(table.version, value);
}

class ParticipantRowTable extends _is.Table<_is.UuidValue?> {
  ParticipantRowTable({super.tableRelation})
    : super(tableName: 'gavel_participants') {
    updateTable = ParticipantRowUpdateTable(this);
    auctionId = _is.ColumnUuid('auctionId', this);
    displayName = _is.ColumnString('displayName', this);
    keyHash = _is.ColumnString('keyHash', this);
    version = _is.ColumnInt('version', this);
  }

  late final ParticipantRowUpdateTable updateTable;

  /// The auction joined.
  late final _is.ColumnUuid auctionId;

  /// The name shown to the other bidders.
  late final _is.ColumnString displayName;

  /// The SHA-256 of the participant key. The key itself is never stored.
  late final _is.ColumnString keyHash;

  /// The aggregate version, for optimistic concurrency.
  late final _is.ColumnInt version;

  @override
  List<_is.Column> get columns => [
    id,
    auctionId,
    displayName,
    keyHash,
    version,
  ];
}

class ParticipantRowInclude extends _is.IncludeObject {
  ParticipantRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => ParticipantRow.t;
}

class ParticipantRowIncludeList extends _is.IncludeList {
  ParticipantRowIncludeList._({
    _is.WhereExpressionBuilder<ParticipantRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ParticipantRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => ParticipantRow.t;
}

class ParticipantRowRepository {
  const ParticipantRowRepository._();

  /// Returns a list of [ParticipantRow]s matching the given query parameters.
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
  Future<List<ParticipantRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ParticipantRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ParticipantRowTable>? orderBy,
    _is.OrderByListBuilder<ParticipantRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ParticipantRow>(
      where: where?.call(ParticipantRow.t),
      orderBy: orderBy?.call(ParticipantRow.t),
      orderByList: orderByList?.call(ParticipantRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ParticipantRow] matching the given query parameters.
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
  Future<ParticipantRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ParticipantRowTable>? where,
    int? offset,
    _is.OrderByBuilder<ParticipantRowTable>? orderBy,
    _is.OrderByListBuilder<ParticipantRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ParticipantRow>(
      where: where?.call(ParticipantRow.t),
      orderBy: orderBy?.call(ParticipantRow.t),
      orderByList: orderByList?.call(ParticipantRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ParticipantRow] by its [id] or null if no such row exists.
  Future<ParticipantRow?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ParticipantRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ParticipantRow]s in the list and returns the inserted rows.
  ///
  /// The returned [ParticipantRow]s will have their `id` fields set.
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
  Future<List<ParticipantRow>> insert(
    _is.DatabaseSession session,
    List<ParticipantRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<ParticipantRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [ParticipantRow] and returns the inserted row.
  ///
  /// The returned [ParticipantRow] will have its `id` field set.
  Future<ParticipantRow> insertRow(
    _is.DatabaseSession session,
    ParticipantRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<ParticipantRow>(row, transaction: transaction);
  }

  /// Upserts all [ParticipantRow]s in the list and returns the resulting rows.
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
  /// The returned [ParticipantRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ParticipantRow>> upsert(
    _is.DatabaseSession session,
    List<ParticipantRow> rows, {
    required _is.ColumnSelections<ParticipantRowTable> conflictColumns,
    _is.ColumnSelections<ParticipantRowTable>? updateColumns,
    _is.WhereExpressionBuilder<ParticipantRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<ParticipantRow>(
      rows,
      conflictColumns: conflictColumns(ParticipantRow.t),
      updateColumns: updateColumns?.call(ParticipantRow.t),
      updateWhere: updateWhere?.call(ParticipantRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [ParticipantRow] and returns the resulting row.
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
  /// The returned [ParticipantRow] will have its `id` field set.
  Future<ParticipantRow?> upsertRow(
    _is.DatabaseSession session,
    ParticipantRow row, {
    required _is.ColumnSelections<ParticipantRowTable> conflictColumns,
    _is.ColumnSelections<ParticipantRowTable>? updateColumns,
    _is.WhereExpressionBuilder<ParticipantRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<ParticipantRow>(
      row,
      conflictColumns: conflictColumns(ParticipantRow.t),
      updateColumns: updateColumns?.call(ParticipantRow.t),
      updateWhere: updateWhere?.call(ParticipantRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [ParticipantRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ParticipantRow>> update(
    _is.DatabaseSession session,
    List<ParticipantRow> rows, {
    _is.ColumnSelections<ParticipantRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<ParticipantRow>(
      rows,
      columns: columns?.call(ParticipantRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [ParticipantRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ParticipantRow> updateRow(
    _is.DatabaseSession session,
    ParticipantRow row, {
    _is.ColumnSelections<ParticipantRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<ParticipantRow>(
      row,
      columns: columns?.call(ParticipantRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ParticipantRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ParticipantRow?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<ParticipantRowUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<ParticipantRow>(
      id,
      columnValues: columnValues(ParticipantRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ParticipantRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ParticipantRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ParticipantRowUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ParticipantRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ParticipantRowTable>? orderBy,
    _is.OrderByListBuilder<ParticipantRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<ParticipantRow>(
      columnValues: columnValues(ParticipantRow.t.updateTable),
      where: where(ParticipantRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ParticipantRow.t),
      orderByList: orderByList?.call(ParticipantRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [ParticipantRow]s in the list and returns the deleted rows.
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
  Future<List<ParticipantRow>> delete(
    _is.DatabaseSession session,
    List<ParticipantRow> rows, {
    _is.OrderByBuilder<ParticipantRowTable>? orderBy,
    _is.OrderByListBuilder<ParticipantRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<ParticipantRow>(
      rows,
      orderBy: orderBy?.call(ParticipantRow.t),
      orderByList: orderByList?.call(ParticipantRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [ParticipantRow].
  Future<ParticipantRow> deleteRow(
    _is.DatabaseSession session,
    ParticipantRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ParticipantRow>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<ParticipantRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ParticipantRowTable> where,
    _is.OrderByBuilder<ParticipantRowTable>? orderBy,
    _is.OrderByListBuilder<ParticipantRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<ParticipantRow>(
      where: where(ParticipantRow.t),
      orderBy: orderBy?.call(ParticipantRow.t),
      orderByList: orderByList?.call(ParticipantRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ParticipantRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<ParticipantRow>(
      where: where?.call(ParticipantRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ParticipantRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ParticipantRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ParticipantRow>(
      where: where(ParticipantRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
