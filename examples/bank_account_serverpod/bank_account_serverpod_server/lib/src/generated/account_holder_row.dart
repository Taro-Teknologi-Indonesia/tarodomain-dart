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

/// The current state of an `AccountHolder`, stored by
/// `AccountHolderRepository` instead of its events.
abstract class AccountHolderRow
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  AccountHolderRow._({
    this.id,
    required this.name,
    required this.email,
    required this.version,
  });

  factory AccountHolderRow({
    _is.UuidValue? id,
    required String name,
    required String email,
    required int version,
  }) = _AccountHolderRowImpl;

  factory AccountHolderRow.fromJson(Map<String, dynamic> jsonSerialization) {
    return AccountHolderRow(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      name: jsonSerialization['name'] as String,
      email: jsonSerialization['email'] as String,
      version: jsonSerialization['version'] as int,
    );
  }

  static final t = AccountHolderRowTable();

  static const db = AccountHolderRowRepository._();

  @override
  _is.UuidValue? id;

  /// The holder's name.
  String name;

  /// The holder's email address.
  String email;

  /// The aggregate version, for optimistic concurrency.
  int version;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [AccountHolderRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  AccountHolderRow copyWith({
    _is.UuidValue? id,
    String? name,
    String? email,
    int? version,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AccountHolderRow',
      if (id != null) 'id': id?.toJson(),
      'name': name,
      'email': email,
      'version': version,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static AccountHolderRowInclude include() {
    return AccountHolderRowInclude._();
  }

  static AccountHolderRowIncludeList includeList({
    _is.WhereExpressionBuilder<AccountHolderRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountHolderRowTable>? orderBy,
    _is.OrderByListBuilder<AccountHolderRowTable>? orderByList,
    AccountHolderRowInclude? include,
  }) {
    return AccountHolderRowIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AccountHolderRow.t),
      orderByList: orderByList?.call(AccountHolderRow.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AccountHolderRowImpl extends AccountHolderRow {
  _AccountHolderRowImpl({
    _is.UuidValue? id,
    required String name,
    required String email,
    required int version,
  }) : super._(id: id, name: name, email: email, version: version);

  /// Returns a shallow copy of this [AccountHolderRow]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  AccountHolderRow copyWith({
    Object? id = _Undefined,
    String? name,
    String? email,
    int? version,
  }) {
    return AccountHolderRow(
      id: id is _is.UuidValue? ? id : this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      version: version ?? this.version,
    );
  }
}

class AccountHolderRowUpdateTable
    extends _is.UpdateTable<AccountHolderRowTable> {
  AccountHolderRowUpdateTable(super.table);

  _is.ColumnValue<String, String> name(String value) =>
      _is.ColumnValue(table.name, value);

  _is.ColumnValue<String, String> email(String value) =>
      _is.ColumnValue(table.email, value);

  _is.ColumnValue<int, int> version(int value) =>
      _is.ColumnValue(table.version, value);
}

class AccountHolderRowTable extends _is.Table<_is.UuidValue?> {
  AccountHolderRowTable({super.tableRelation})
    : super(tableName: 'bank_account_holders') {
    updateTable = AccountHolderRowUpdateTable(this);
    name = _is.ColumnString('name', this);
    email = _is.ColumnString('email', this);
    version = _is.ColumnInt('version', this);
  }

  late final AccountHolderRowUpdateTable updateTable;

  /// The holder's name.
  late final _is.ColumnString name;

  /// The holder's email address.
  late final _is.ColumnString email;

  /// The aggregate version, for optimistic concurrency.
  late final _is.ColumnInt version;

  @override
  List<_is.Column> get columns => [id, name, email, version];
}

class AccountHolderRowInclude extends _is.IncludeObject {
  AccountHolderRowInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => AccountHolderRow.t;
}

class AccountHolderRowIncludeList extends _is.IncludeList {
  AccountHolderRowIncludeList._({
    _is.WhereExpressionBuilder<AccountHolderRowTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AccountHolderRow.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => AccountHolderRow.t;
}

class AccountHolderRowRepository {
  const AccountHolderRowRepository._();

  /// Returns a list of [AccountHolderRow]s matching the given query parameters.
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
  Future<List<AccountHolderRow>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountHolderRowTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountHolderRowTable>? orderBy,
    _is.OrderByListBuilder<AccountHolderRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AccountHolderRow>(
      where: where?.call(AccountHolderRow.t),
      orderBy: orderBy?.call(AccountHolderRow.t),
      orderByList: orderByList?.call(AccountHolderRow.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AccountHolderRow] matching the given query parameters.
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
  Future<AccountHolderRow?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountHolderRowTable>? where,
    int? offset,
    _is.OrderByBuilder<AccountHolderRowTable>? orderBy,
    _is.OrderByListBuilder<AccountHolderRowTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AccountHolderRow>(
      where: where?.call(AccountHolderRow.t),
      orderBy: orderBy?.call(AccountHolderRow.t),
      orderByList: orderByList?.call(AccountHolderRow.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AccountHolderRow] by its [id] or null if no such row exists.
  Future<AccountHolderRow?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AccountHolderRow>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AccountHolderRow]s in the list and returns the inserted rows.
  ///
  /// The returned [AccountHolderRow]s will have their `id` fields set.
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
  Future<List<AccountHolderRow>> insert(
    _is.DatabaseSession session,
    List<AccountHolderRow> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<AccountHolderRow>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [AccountHolderRow] and returns the inserted row.
  ///
  /// The returned [AccountHolderRow] will have its `id` field set.
  Future<AccountHolderRow> insertRow(
    _is.DatabaseSession session,
    AccountHolderRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<AccountHolderRow>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [AccountHolderRow]s in the list and returns the resulting rows.
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
  /// The returned [AccountHolderRow]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountHolderRow>> upsert(
    _is.DatabaseSession session,
    List<AccountHolderRow> rows, {
    required _is.ColumnSelections<AccountHolderRowTable> conflictColumns,
    _is.ColumnSelections<AccountHolderRowTable>? updateColumns,
    _is.WhereExpressionBuilder<AccountHolderRowTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<AccountHolderRow>(
      rows,
      conflictColumns: conflictColumns(AccountHolderRow.t),
      updateColumns: updateColumns?.call(AccountHolderRow.t),
      updateWhere: updateWhere?.call(AccountHolderRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [AccountHolderRow] and returns the resulting row.
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
  /// The returned [AccountHolderRow] will have its `id` field set.
  Future<AccountHolderRow?> upsertRow(
    _is.DatabaseSession session,
    AccountHolderRow row, {
    required _is.ColumnSelections<AccountHolderRowTable> conflictColumns,
    _is.ColumnSelections<AccountHolderRowTable>? updateColumns,
    _is.WhereExpressionBuilder<AccountHolderRowTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<AccountHolderRow>(
      row,
      conflictColumns: conflictColumns(AccountHolderRow.t),
      updateColumns: updateColumns?.call(AccountHolderRow.t),
      updateWhere: updateWhere?.call(AccountHolderRow.t),
      transaction: transaction,
    );
  }

  /// Updates all [AccountHolderRow]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountHolderRow>> update(
    _is.DatabaseSession session,
    List<AccountHolderRow> rows, {
    _is.ColumnSelections<AccountHolderRowTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<AccountHolderRow>(
      rows,
      columns: columns?.call(AccountHolderRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [AccountHolderRow]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AccountHolderRow> updateRow(
    _is.DatabaseSession session,
    AccountHolderRow row, {
    _is.ColumnSelections<AccountHolderRowTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<AccountHolderRow>(
      row,
      columns: columns?.call(AccountHolderRow.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AccountHolderRow] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AccountHolderRow?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<AccountHolderRowUpdateTable>
    columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<AccountHolderRow>(
      id,
      columnValues: columnValues(AccountHolderRow.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AccountHolderRow]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<AccountHolderRow>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<AccountHolderRowUpdateTable>
    columnValues,
    required _is.WhereExpressionBuilder<AccountHolderRowTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<AccountHolderRowTable>? orderBy,
    _is.OrderByListBuilder<AccountHolderRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<AccountHolderRow>(
      columnValues: columnValues(AccountHolderRow.t.updateTable),
      where: where(AccountHolderRow.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AccountHolderRow.t),
      orderByList: orderByList?.call(AccountHolderRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [AccountHolderRow]s in the list and returns the deleted rows.
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
  Future<List<AccountHolderRow>> delete(
    _is.DatabaseSession session,
    List<AccountHolderRow> rows, {
    _is.OrderByBuilder<AccountHolderRowTable>? orderBy,
    _is.OrderByListBuilder<AccountHolderRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<AccountHolderRow>(
      rows,
      orderBy: orderBy?.call(AccountHolderRow.t),
      orderByList: orderByList?.call(AccountHolderRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [AccountHolderRow].
  Future<AccountHolderRow> deleteRow(
    _is.DatabaseSession session,
    AccountHolderRow row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AccountHolderRow>(
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
  Future<List<AccountHolderRow>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AccountHolderRowTable> where,
    _is.OrderByBuilder<AccountHolderRowTable>? orderBy,
    _is.OrderByListBuilder<AccountHolderRowTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<AccountHolderRow>(
      where: where(AccountHolderRow.t),
      orderBy: orderBy?.call(AccountHolderRow.t),
      orderByList: orderByList?.call(AccountHolderRow.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<AccountHolderRowTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<AccountHolderRow>(
      where: where?.call(AccountHolderRow.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AccountHolderRow] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<AccountHolderRowTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AccountHolderRow>(
      where: where(AccountHolderRow.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
