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

/// One bid in a lot's ledger. Written from UC-06 on.
abstract class LedgerEntry
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  LedgerEntry._({
    this.id,
    required this.lotId,
    required this.sequence,
    required this.participantId,
    required this.bidderName,
    required this.amount,
    required this.placedAt,
    required this.retracted,
    this.retractedAt,
  });

  factory LedgerEntry({
    int? id,
    required _is.UuidValue lotId,
    required int sequence,
    required _is.UuidValue participantId,
    required String bidderName,
    required int amount,
    required DateTime placedAt,
    required bool retracted,
    DateTime? retractedAt,
  }) = _LedgerEntryImpl;

  factory LedgerEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return LedgerEntry(
      id: jsonSerialization['id'] as int?,
      lotId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['lotId']),
      sequence: jsonSerialization['sequence'] as int,
      participantId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['participantId'],
      ),
      bidderName: jsonSerialization['bidderName'] as String,
      amount: jsonSerialization['amount'] as int,
      placedAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['placedAt'],
      ),
      retracted: _is.BoolJsonExtension.fromJson(jsonSerialization['retracted']),
      retractedAt: jsonSerialization['retractedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['retractedAt'],
            ),
    );
  }

  static final t = LedgerEntryTable();

  static const db = LedgerEntryRepository._();

  @override
  int? id;

  /// The lot bid on.
  _is.UuidValue lotId;

  /// The bid's place in the lot's ledger, from 1.
  int sequence;

  /// Who bid.
  _is.UuidValue participantId;

  /// The bidder's display name.
  String bidderName;

  /// The bid, in rupiah.
  int amount;

  /// When the bid was placed, in UTC.
  DateTime placedAt;

  /// Whether the bidder took the bid back.
  bool retracted;

  /// When the bid was taken back, in UTC.
  DateTime? retractedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [LedgerEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LedgerEntry copyWith({
    int? id,
    _is.UuidValue? lotId,
    int? sequence,
    _is.UuidValue? participantId,
    String? bidderName,
    int? amount,
    DateTime? placedAt,
    bool? retracted,
    DateTime? retractedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LedgerEntry',
      if (id != null) 'id': id,
      'lotId': lotId.toJson(),
      'sequence': sequence,
      'participantId': participantId.toJson(),
      'bidderName': bidderName,
      'amount': amount,
      'placedAt': placedAt.toJson(),
      'retracted': retracted,
      if (retractedAt != null) 'retractedAt': retractedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LedgerEntry',
      if (id != null) 'id': id,
      'lotId': lotId.toJson(),
      'sequence': sequence,
      'participantId': participantId.toJson(),
      'bidderName': bidderName,
      'amount': amount,
      'placedAt': placedAt.toJson(),
      'retracted': retracted,
      if (retractedAt != null) 'retractedAt': retractedAt?.toJson(),
    };
  }

  static LedgerEntryInclude include() {
    return LedgerEntryInclude._();
  }

  static LedgerEntryIncludeList includeList({
    _is.WhereExpressionBuilder<LedgerEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LedgerEntryTable>? orderBy,
    _is.OrderByListBuilder<LedgerEntryTable>? orderByList,
    LedgerEntryInclude? include,
  }) {
    return LedgerEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LedgerEntry.t),
      orderByList: orderByList?.call(LedgerEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LedgerEntryImpl extends LedgerEntry {
  _LedgerEntryImpl({
    int? id,
    required _is.UuidValue lotId,
    required int sequence,
    required _is.UuidValue participantId,
    required String bidderName,
    required int amount,
    required DateTime placedAt,
    required bool retracted,
    DateTime? retractedAt,
  }) : super._(
         id: id,
         lotId: lotId,
         sequence: sequence,
         participantId: participantId,
         bidderName: bidderName,
         amount: amount,
         placedAt: placedAt,
         retracted: retracted,
         retractedAt: retractedAt,
       );

  /// Returns a shallow copy of this [LedgerEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LedgerEntry copyWith({
    Object? id = _Undefined,
    _is.UuidValue? lotId,
    int? sequence,
    _is.UuidValue? participantId,
    String? bidderName,
    int? amount,
    DateTime? placedAt,
    bool? retracted,
    Object? retractedAt = _Undefined,
  }) {
    return LedgerEntry(
      id: id is int? ? id : this.id,
      lotId: lotId ?? this.lotId,
      sequence: sequence ?? this.sequence,
      participantId: participantId ?? this.participantId,
      bidderName: bidderName ?? this.bidderName,
      amount: amount ?? this.amount,
      placedAt: placedAt ?? this.placedAt,
      retracted: retracted ?? this.retracted,
      retractedAt: retractedAt is DateTime? ? retractedAt : this.retractedAt,
    );
  }
}

class LedgerEntryUpdateTable extends _is.UpdateTable<LedgerEntryTable> {
  LedgerEntryUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> lotId(_is.UuidValue value) =>
      _is.ColumnValue(table.lotId, value);

  _is.ColumnValue<int, int> sequence(int value) =>
      _is.ColumnValue(table.sequence, value);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> participantId(
    _is.UuidValue value,
  ) => _is.ColumnValue(table.participantId, value);

  _is.ColumnValue<String, String> bidderName(String value) =>
      _is.ColumnValue(table.bidderName, value);

  _is.ColumnValue<int, int> amount(int value) =>
      _is.ColumnValue(table.amount, value);

  _is.ColumnValue<DateTime, DateTime> placedAt(DateTime value) =>
      _is.ColumnValue(table.placedAt, value);

  _is.ColumnValue<bool, bool> retracted(bool value) =>
      _is.ColumnValue(table.retracted, value);

  _is.ColumnValue<DateTime, DateTime> retractedAt(DateTime? value) =>
      _is.ColumnValue(table.retractedAt, value);
}

class LedgerEntryTable extends _is.Table<int?> {
  LedgerEntryTable({super.tableRelation})
    : super(tableName: 'gavel_ledger_entries') {
    updateTable = LedgerEntryUpdateTable(this);
    lotId = _is.ColumnUuid('lotId', this);
    sequence = _is.ColumnInt('sequence', this);
    participantId = _is.ColumnUuid('participantId', this);
    bidderName = _is.ColumnString('bidderName', this);
    amount = _is.ColumnInt('amount', this);
    placedAt = _is.ColumnDateTime('placedAt', this);
    retracted = _is.ColumnBool('retracted', this);
    retractedAt = _is.ColumnDateTime('retractedAt', this);
  }

  late final LedgerEntryUpdateTable updateTable;

  /// The lot bid on.
  late final _is.ColumnUuid lotId;

  /// The bid's place in the lot's ledger, from 1.
  late final _is.ColumnInt sequence;

  /// Who bid.
  late final _is.ColumnUuid participantId;

  /// The bidder's display name.
  late final _is.ColumnString bidderName;

  /// The bid, in rupiah.
  late final _is.ColumnInt amount;

  /// When the bid was placed, in UTC.
  late final _is.ColumnDateTime placedAt;

  /// Whether the bidder took the bid back.
  late final _is.ColumnBool retracted;

  /// When the bid was taken back, in UTC.
  late final _is.ColumnDateTime retractedAt;

  @override
  List<_is.Column> get columns => [
    id,
    lotId,
    sequence,
    participantId,
    bidderName,
    amount,
    placedAt,
    retracted,
    retractedAt,
  ];
}

class LedgerEntryInclude extends _is.IncludeObject {
  LedgerEntryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => LedgerEntry.t;
}

class LedgerEntryIncludeList extends _is.IncludeList {
  LedgerEntryIncludeList._({
    _is.WhereExpressionBuilder<LedgerEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LedgerEntry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => LedgerEntry.t;
}

class LedgerEntryRepository {
  const LedgerEntryRepository._();

  /// Returns a list of [LedgerEntry]s matching the given query parameters.
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
  Future<List<LedgerEntry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LedgerEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LedgerEntryTable>? orderBy,
    _is.OrderByListBuilder<LedgerEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LedgerEntry>(
      where: where?.call(LedgerEntry.t),
      orderBy: orderBy?.call(LedgerEntry.t),
      orderByList: orderByList?.call(LedgerEntry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LedgerEntry] matching the given query parameters.
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
  Future<LedgerEntry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LedgerEntryTable>? where,
    int? offset,
    _is.OrderByBuilder<LedgerEntryTable>? orderBy,
    _is.OrderByListBuilder<LedgerEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LedgerEntry>(
      where: where?.call(LedgerEntry.t),
      orderBy: orderBy?.call(LedgerEntry.t),
      orderByList: orderByList?.call(LedgerEntry.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LedgerEntry] by its [id] or null if no such row exists.
  Future<LedgerEntry?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LedgerEntry>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LedgerEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [LedgerEntry]s will have their `id` fields set.
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
  Future<List<LedgerEntry>> insert(
    _is.DatabaseSession session,
    List<LedgerEntry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<LedgerEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [LedgerEntry] and returns the inserted row.
  ///
  /// The returned [LedgerEntry] will have its `id` field set.
  Future<LedgerEntry> insertRow(
    _is.DatabaseSession session,
    LedgerEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<LedgerEntry>(row, transaction: transaction);
  }

  /// Upserts all [LedgerEntry]s in the list and returns the resulting rows.
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
  /// The returned [LedgerEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LedgerEntry>> upsert(
    _is.DatabaseSession session,
    List<LedgerEntry> rows, {
    required _is.ColumnSelections<LedgerEntryTable> conflictColumns,
    _is.ColumnSelections<LedgerEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<LedgerEntryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<LedgerEntry>(
      rows,
      conflictColumns: conflictColumns(LedgerEntry.t),
      updateColumns: updateColumns?.call(LedgerEntry.t),
      updateWhere: updateWhere?.call(LedgerEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [LedgerEntry] and returns the resulting row.
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
  /// The returned [LedgerEntry] will have its `id` field set.
  Future<LedgerEntry?> upsertRow(
    _is.DatabaseSession session,
    LedgerEntry row, {
    required _is.ColumnSelections<LedgerEntryTable> conflictColumns,
    _is.ColumnSelections<LedgerEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<LedgerEntryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<LedgerEntry>(
      row,
      conflictColumns: conflictColumns(LedgerEntry.t),
      updateColumns: updateColumns?.call(LedgerEntry.t),
      updateWhere: updateWhere?.call(LedgerEntry.t),
      transaction: transaction,
    );
  }

  /// Updates all [LedgerEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LedgerEntry>> update(
    _is.DatabaseSession session,
    List<LedgerEntry> rows, {
    _is.ColumnSelections<LedgerEntryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<LedgerEntry>(
      rows,
      columns: columns?.call(LedgerEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [LedgerEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LedgerEntry> updateRow(
    _is.DatabaseSession session,
    LedgerEntry row, {
    _is.ColumnSelections<LedgerEntryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<LedgerEntry>(
      row,
      columns: columns?.call(LedgerEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LedgerEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LedgerEntry?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<LedgerEntryUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<LedgerEntry>(
      id,
      columnValues: columnValues(LedgerEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LedgerEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LedgerEntry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<LedgerEntryUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<LedgerEntryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LedgerEntryTable>? orderBy,
    _is.OrderByListBuilder<LedgerEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<LedgerEntry>(
      columnValues: columnValues(LedgerEntry.t.updateTable),
      where: where(LedgerEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LedgerEntry.t),
      orderByList: orderByList?.call(LedgerEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [LedgerEntry]s in the list and returns the deleted rows.
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
  Future<List<LedgerEntry>> delete(
    _is.DatabaseSession session,
    List<LedgerEntry> rows, {
    _is.OrderByBuilder<LedgerEntryTable>? orderBy,
    _is.OrderByListBuilder<LedgerEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<LedgerEntry>(
      rows,
      orderBy: orderBy?.call(LedgerEntry.t),
      orderByList: orderByList?.call(LedgerEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [LedgerEntry].
  Future<LedgerEntry> deleteRow(
    _is.DatabaseSession session,
    LedgerEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LedgerEntry>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LedgerEntry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LedgerEntryTable> where,
    _is.OrderByBuilder<LedgerEntryTable>? orderBy,
    _is.OrderByListBuilder<LedgerEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<LedgerEntry>(
      where: where(LedgerEntry.t),
      orderBy: orderBy?.call(LedgerEntry.t),
      orderByList: orderByList?.call(LedgerEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LedgerEntryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<LedgerEntry>(
      where: where?.call(LedgerEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LedgerEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LedgerEntryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LedgerEntry>(
      where: where(LedgerEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
