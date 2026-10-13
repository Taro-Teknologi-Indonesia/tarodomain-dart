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

/// One account's balance: the read model of `BalanceTableProjection`.
abstract class AccountBalance
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  AccountBalance._({
    this.id,
    required this.accountId,
    required this.owner,
    required this.balanceCents,
    required this.rejectedWithdrawals,
  });

  factory AccountBalance({
    int? id,
    required _is.UuidValue accountId,
    required String owner,
    required int balanceCents,
    required int rejectedWithdrawals,
  }) = _AccountBalanceImpl;

  factory AccountBalance.fromJson(Map<String, dynamic> jsonSerialization) {
    return AccountBalance(
      id: jsonSerialization['id'] as int?,
      accountId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['accountId'],
      ),
      owner: jsonSerialization['owner'] as String,
      balanceCents: jsonSerialization['balanceCents'] as int,
      rejectedWithdrawals: jsonSerialization['rejectedWithdrawals'] as int,
    );
  }

  static final t = AccountBalanceTable();

  static const db = AccountBalanceRepository._();

  @override
  int? id;

  /// The account.
  _is.UuidValue accountId;

  /// The account holder.
  String owner;

  /// The balance, in cents.
  int balanceCents;

  /// How many withdrawals were rejected.
  int rejectedWithdrawals;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [AccountBalance]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AccountBalance copyWith({
    int? id,
    _is.UuidValue? accountId,
    String? owner,
    int? balanceCents,
    int? rejectedWithdrawals,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AccountBalance',
      if (id != null) 'id': id,
      'accountId': accountId.toJson(),
      'owner': owner,
      'balanceCents': balanceCents,
      'rejectedWithdrawals': rejectedWithdrawals,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AccountBalance',
      if (id != null) 'id': id,
      'accountId': accountId.toJson(),
      'owner': owner,
      'balanceCents': balanceCents,
      'rejectedWithdrawals': rejectedWithdrawals,
    };
  }

  static AccountBalanceInclude include() {
    return AccountBalanceInclude._();
  }

  static AccountBalanceIncludeList includeList({
    _is.WhereExpressionBuilder<AccountBalanceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountBalanceTable>? orderBy,
    _is.OrderByListBuilder<AccountBalanceTable>? orderByList,
    AccountBalanceInclude? include,
  }) {
    return AccountBalanceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AccountBalance.t),
      orderByList: orderByList?.call(AccountBalance.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AccountBalanceImpl extends AccountBalance {
  _AccountBalanceImpl({
    int? id,
    required _is.UuidValue accountId,
    required String owner,
    required int balanceCents,
    required int rejectedWithdrawals,
  }) : super._(
         id: id,
         accountId: accountId,
         owner: owner,
         balanceCents: balanceCents,
         rejectedWithdrawals: rejectedWithdrawals,
       );

  /// Returns a shallow copy of this [AccountBalance]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AccountBalance copyWith({
    Object? id = _Undefined,
    _is.UuidValue? accountId,
    String? owner,
    int? balanceCents,
    int? rejectedWithdrawals,
  }) {
    return AccountBalance(
      id: id is int? ? id : this.id,
      accountId: accountId ?? this.accountId,
      owner: owner ?? this.owner,
      balanceCents: balanceCents ?? this.balanceCents,
      rejectedWithdrawals: rejectedWithdrawals ?? this.rejectedWithdrawals,
    );
  }
}

class AccountBalanceUpdateTable extends _is.UpdateTable<AccountBalanceTable> {
  AccountBalanceUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> accountId(
    _is.UuidValue value,
  ) => _is.ColumnValue(table.accountId, value);

  _is.ColumnValue<String, String> owner(String value) =>
      _is.ColumnValue(table.owner, value);

  _is.ColumnValue<int, int> balanceCents(int value) =>
      _is.ColumnValue(table.balanceCents, value);

  _is.ColumnValue<int, int> rejectedWithdrawals(int value) =>
      _is.ColumnValue(table.rejectedWithdrawals, value);
}

class AccountBalanceTable extends _is.Table<int?> {
  AccountBalanceTable({super.tableRelation})
    : super(tableName: 'bank_account_balances') {
    updateTable = AccountBalanceUpdateTable(this);
    accountId = _is.ColumnUuid('accountId', this);
    owner = _is.ColumnString('owner', this);
    balanceCents = _is.ColumnInt('balanceCents', this);
    rejectedWithdrawals = _is.ColumnInt('rejectedWithdrawals', this);
  }

  late final AccountBalanceUpdateTable updateTable;

  /// The account.
  late final _is.ColumnUuid accountId;

  /// The account holder.
  late final _is.ColumnString owner;

  /// The balance, in cents.
  late final _is.ColumnInt balanceCents;

  /// How many withdrawals were rejected.
  late final _is.ColumnInt rejectedWithdrawals;

  @override
  List<_is.Column> get columns => [
    id,
    accountId,
    owner,
    balanceCents,
    rejectedWithdrawals,
  ];
}

class AccountBalanceInclude extends _is.IncludeObject {
  AccountBalanceInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => AccountBalance.t;
}

class AccountBalanceIncludeList extends _is.IncludeList {
  AccountBalanceIncludeList._({
    _is.WhereExpressionBuilder<AccountBalanceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AccountBalance.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => AccountBalance.t;
}

class AccountBalanceRepository {
  const AccountBalanceRepository._();

  /// Returns a list of [AccountBalance]s matching the given query parameters.
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
  Future<List<AccountBalance>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountBalanceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountBalanceTable>? orderBy,
    _is.OrderByListBuilder<AccountBalanceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AccountBalance>(
      where: where?.call(AccountBalance.t),
      orderBy: orderBy?.call(AccountBalance.t),
      orderByList: orderByList?.call(AccountBalance.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AccountBalance] matching the given query parameters.
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
  Future<AccountBalance?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountBalanceTable>? where,
    int? offset,
    _is.OrderByBuilder<AccountBalanceTable>? orderBy,
    _is.OrderByListBuilder<AccountBalanceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AccountBalance>(
      where: where?.call(AccountBalance.t),
      orderBy: orderBy?.call(AccountBalance.t),
      orderByList: orderByList?.call(AccountBalance.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AccountBalance] by its [id] or null if no such row exists.
  Future<AccountBalance?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AccountBalance>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AccountBalance]s in the list and returns the inserted rows.
  ///
  /// The returned [AccountBalance]s will have their `id` fields set.
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
  Future<List<AccountBalance>> insert(
    _is.DatabaseSession session,
    List<AccountBalance> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AccountBalance>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AccountBalance] and returns the inserted row.
  ///
  /// The returned [AccountBalance] will have its `id` field set.
  Future<AccountBalance> insertRow(
    _is.DatabaseSession session,
    AccountBalance row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AccountBalance>(row, transaction: transaction);
  }

  /// Upserts all [AccountBalance]s in the list and returns the resulting rows.
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
  /// The returned [AccountBalance]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountBalance>> upsert(
    _is.DatabaseSession session,
    List<AccountBalance> rows, {
    required _is.ColumnSelections<AccountBalanceTable> conflictColumns,
    _is.ColumnSelections<AccountBalanceTable>? updateColumns,
    _is.WhereExpressionBuilder<AccountBalanceTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AccountBalance>(
      rows,
      conflictColumns: conflictColumns(AccountBalance.t),
      updateColumns: updateColumns?.call(AccountBalance.t),
      updateWhere: updateWhere?.call(AccountBalance.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AccountBalance] and returns the resulting row.
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
  /// The returned [AccountBalance] will have its `id` field set.
  Future<AccountBalance?> upsertRow(
    _is.DatabaseSession session,
    AccountBalance row, {
    required _is.ColumnSelections<AccountBalanceTable> conflictColumns,
    _is.ColumnSelections<AccountBalanceTable>? updateColumns,
    _is.WhereExpressionBuilder<AccountBalanceTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AccountBalance>(
      row,
      conflictColumns: conflictColumns(AccountBalance.t),
      updateColumns: updateColumns?.call(AccountBalance.t),
      updateWhere: updateWhere?.call(AccountBalance.t),
      transaction: transaction,
    );
  }

  /// Updates all [AccountBalance]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountBalance>> update(
    _is.DatabaseSession session,
    List<AccountBalance> rows, {
    _is.ColumnSelections<AccountBalanceTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AccountBalance>(
      rows,
      columns: columns?.call(AccountBalance.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AccountBalance]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AccountBalance> updateRow(
    _is.DatabaseSession session,
    AccountBalance row, {
    _is.ColumnSelections<AccountBalanceTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AccountBalance>(
      row,
      columns: columns?.call(AccountBalance.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AccountBalance] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AccountBalance?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<AccountBalanceUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AccountBalance>(
      id,
      columnValues: columnValues(AccountBalance.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AccountBalance]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountBalance>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AccountBalanceUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<AccountBalanceTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountBalanceTable>? orderBy,
    _is.OrderByListBuilder<AccountBalanceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AccountBalance>(
      columnValues: columnValues(AccountBalance.t.updateTable),
      where: where(AccountBalance.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AccountBalance.t),
      orderByList: orderByList?.call(AccountBalance.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AccountBalance]s in the list and returns the deleted rows.
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
  Future<List<AccountBalance>> delete(
    _is.DatabaseSession session,
    List<AccountBalance> rows, {
    _is.OrderByBuilder<AccountBalanceTable>? orderBy,
    _is.OrderByListBuilder<AccountBalanceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AccountBalance>(
      rows,
      orderBy: orderBy?.call(AccountBalance.t),
      orderByList: orderByList?.call(AccountBalance.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AccountBalance].
  Future<AccountBalance> deleteRow(
    _is.DatabaseSession session,
    AccountBalance row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AccountBalance>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountBalance>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AccountBalanceTable> where,
    _is.OrderByBuilder<AccountBalanceTable>? orderBy,
    _is.OrderByListBuilder<AccountBalanceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AccountBalance>(
      where: where(AccountBalance.t),
      orderBy: orderBy?.call(AccountBalance.t),
      orderByList: orderByList?.call(AccountBalance.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountBalanceTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AccountBalance>(
      where: where?.call(AccountBalance.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AccountBalance] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AccountBalanceTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AccountBalance>(
      where: where(AccountBalance.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
