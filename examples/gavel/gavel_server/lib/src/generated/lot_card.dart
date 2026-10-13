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
import 'package:gavel_server/src/generated/protocol.dart' as _imkuj2yl;
import 'package:serverpod/serverpod.dart' as _is;

/// One lot as the board shows it: the read model of `LotTableProjection`.
abstract class LotCard
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  LotCard._({
    this.id,
    required this.lotId,
    required this.auctionId,
    required this.code,
    required this.position,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.tileEmoji,
    required this.tileColor,
    required this.openBid,
    required this.increments,
    required this.currentPrice,
    this.leaderId,
    this.leaderName,
    required this.bidCount,
    required this.status,
    required this.version,
    this.winnerName,
    this.finalPrice,
    this.closeCause,
    this.closedAt,
  });

  factory LotCard({
    int? id,
    required _is.UuidValue lotId,
    required _is.UuidValue auctionId,
    required String code,
    required int position,
    required String name,
    required String description,
    String? imageUrl,
    required String tileEmoji,
    required String tileColor,
    required int openBid,
    required List<int> increments,
    required int currentPrice,
    _is.UuidValue? leaderId,
    String? leaderName,
    required int bidCount,
    required String status,
    required int version,
    String? winnerName,
    int? finalPrice,
    String? closeCause,
    DateTime? closedAt,
  }) = _LotCardImpl;

  factory LotCard.fromJson(Map<String, dynamic> jsonSerialization) {
    return LotCard(
      id: jsonSerialization['id'] as int?,
      lotId: _is.UuidValueJsonExtension.fromJson(jsonSerialization['lotId']),
      auctionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['auctionId'],
      ),
      code: jsonSerialization['code'] as String,
      position: jsonSerialization['position'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      imageUrl: jsonSerialization['imageUrl'] as String?,
      tileEmoji: jsonSerialization['tileEmoji'] as String,
      tileColor: jsonSerialization['tileColor'] as String,
      openBid: jsonSerialization['openBid'] as int,
      increments: _imkuj2yl.Protocol().deserialize<List<int>>(
        jsonSerialization['increments'],
      ),
      currentPrice: jsonSerialization['currentPrice'] as int,
      leaderId: jsonSerialization['leaderId'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['leaderId']),
      leaderName: jsonSerialization['leaderName'] as String?,
      bidCount: jsonSerialization['bidCount'] as int,
      status: jsonSerialization['status'] as String,
      version: jsonSerialization['version'] as int,
      winnerName: jsonSerialization['winnerName'] as String?,
      finalPrice: jsonSerialization['finalPrice'] as int?,
      closeCause: jsonSerialization['closeCause'] as String?,
      closedAt: jsonSerialization['closedAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(jsonSerialization['closedAt']),
    );
  }

  static final t = LotCardTable();

  static const db = LotCardRepository._();

  @override
  int? id;

  /// The lot.
  _is.UuidValue lotId;

  /// The auction the lot belongs to.
  _is.UuidValue auctionId;

  /// The auction's join code.
  String code;

  /// The lot's place in the auction, from 0.
  int position;

  /// The lot's name.
  String name;

  /// The seller's description, newlines kept.
  String description;

  /// A photo of the lot, or null to show the tile.
  String? imageUrl;

  /// The tile's emoji, shown when there is no photo or it fails to load.
  String tileEmoji;

  /// The tile's background, as `#RRGGBB`.
  String tileColor;

  /// The first bid's minimum, in rupiah.
  int openBid;

  /// The allowed raises (kelipatan), in rupiah, ascending.
  List<int> increments;

  /// The leading bid, or the open bid while there is none.
  int currentPrice;

  /// The leading bidder, if any.
  _is.UuidValue? leaderId;

  /// The leading bidder's display name, if any.
  String? leaderName;

  /// How many bids stand.
  int bidCount;

  /// OPEN, SOLD or PASSED.
  String status;

  /// The lot aggregate's version: the next bid's `expectedVersion`.
  int version;

  /// Who won, once SOLD.
  String? winnerName;

  /// The winning price, once SOLD.
  int? finalPrice;

  /// Why the lot closed: DEADLINE or SELL_NOW.
  String? closeCause;

  /// When the lot closed, in UTC.
  DateTime? closedAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [LotCard]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LotCard copyWith({
    int? id,
    _is.UuidValue? lotId,
    _is.UuidValue? auctionId,
    String? code,
    int? position,
    String? name,
    String? description,
    String? imageUrl,
    String? tileEmoji,
    String? tileColor,
    int? openBid,
    List<int>? increments,
    int? currentPrice,
    _is.UuidValue? leaderId,
    String? leaderName,
    int? bidCount,
    String? status,
    int? version,
    String? winnerName,
    int? finalPrice,
    String? closeCause,
    DateTime? closedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LotCard',
      if (id != null) 'id': id,
      'lotId': lotId.toJson(),
      'auctionId': auctionId.toJson(),
      'code': code,
      'position': position,
      'name': name,
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'tileEmoji': tileEmoji,
      'tileColor': tileColor,
      'openBid': openBid,
      'increments': increments.toJson(),
      'currentPrice': currentPrice,
      if (leaderId != null) 'leaderId': leaderId?.toJson(),
      if (leaderName != null) 'leaderName': leaderName,
      'bidCount': bidCount,
      'status': status,
      'version': version,
      if (winnerName != null) 'winnerName': winnerName,
      if (finalPrice != null) 'finalPrice': finalPrice,
      if (closeCause != null) 'closeCause': closeCause,
      if (closedAt != null) 'closedAt': closedAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LotCard',
      if (id != null) 'id': id,
      'lotId': lotId.toJson(),
      'auctionId': auctionId.toJson(),
      'code': code,
      'position': position,
      'name': name,
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'tileEmoji': tileEmoji,
      'tileColor': tileColor,
      'openBid': openBid,
      'increments': increments.toJson(),
      'currentPrice': currentPrice,
      if (leaderId != null) 'leaderId': leaderId?.toJson(),
      if (leaderName != null) 'leaderName': leaderName,
      'bidCount': bidCount,
      'status': status,
      'version': version,
      if (winnerName != null) 'winnerName': winnerName,
      if (finalPrice != null) 'finalPrice': finalPrice,
      if (closeCause != null) 'closeCause': closeCause,
      if (closedAt != null) 'closedAt': closedAt?.toJson(),
    };
  }

  static LotCardInclude include() {
    return LotCardInclude._();
  }

  static LotCardIncludeList includeList({
    _is.WhereExpressionBuilder<LotCardTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LotCardTable>? orderBy,
    _is.OrderByListBuilder<LotCardTable>? orderByList,
    LotCardInclude? include,
  }) {
    return LotCardIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LotCard.t),
      orderByList: orderByList?.call(LotCard.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LotCardImpl extends LotCard {
  _LotCardImpl({
    int? id,
    required _is.UuidValue lotId,
    required _is.UuidValue auctionId,
    required String code,
    required int position,
    required String name,
    required String description,
    String? imageUrl,
    required String tileEmoji,
    required String tileColor,
    required int openBid,
    required List<int> increments,
    required int currentPrice,
    _is.UuidValue? leaderId,
    String? leaderName,
    required int bidCount,
    required String status,
    required int version,
    String? winnerName,
    int? finalPrice,
    String? closeCause,
    DateTime? closedAt,
  }) : super._(
         id: id,
         lotId: lotId,
         auctionId: auctionId,
         code: code,
         position: position,
         name: name,
         description: description,
         imageUrl: imageUrl,
         tileEmoji: tileEmoji,
         tileColor: tileColor,
         openBid: openBid,
         increments: increments,
         currentPrice: currentPrice,
         leaderId: leaderId,
         leaderName: leaderName,
         bidCount: bidCount,
         status: status,
         version: version,
         winnerName: winnerName,
         finalPrice: finalPrice,
         closeCause: closeCause,
         closedAt: closedAt,
       );

  /// Returns a shallow copy of this [LotCard]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LotCard copyWith({
    Object? id = _Undefined,
    _is.UuidValue? lotId,
    _is.UuidValue? auctionId,
    String? code,
    int? position,
    String? name,
    String? description,
    Object? imageUrl = _Undefined,
    String? tileEmoji,
    String? tileColor,
    int? openBid,
    List<int>? increments,
    int? currentPrice,
    Object? leaderId = _Undefined,
    Object? leaderName = _Undefined,
    int? bidCount,
    String? status,
    int? version,
    Object? winnerName = _Undefined,
    Object? finalPrice = _Undefined,
    Object? closeCause = _Undefined,
    Object? closedAt = _Undefined,
  }) {
    return LotCard(
      id: id is int? ? id : this.id,
      lotId: lotId ?? this.lotId,
      auctionId: auctionId ?? this.auctionId,
      code: code ?? this.code,
      position: position ?? this.position,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl is String? ? imageUrl : this.imageUrl,
      tileEmoji: tileEmoji ?? this.tileEmoji,
      tileColor: tileColor ?? this.tileColor,
      openBid: openBid ?? this.openBid,
      increments: increments ?? this.increments.map((e0) => e0).toList(),
      currentPrice: currentPrice ?? this.currentPrice,
      leaderId: leaderId is _is.UuidValue? ? leaderId : this.leaderId,
      leaderName: leaderName is String? ? leaderName : this.leaderName,
      bidCount: bidCount ?? this.bidCount,
      status: status ?? this.status,
      version: version ?? this.version,
      winnerName: winnerName is String? ? winnerName : this.winnerName,
      finalPrice: finalPrice is int? ? finalPrice : this.finalPrice,
      closeCause: closeCause is String? ? closeCause : this.closeCause,
      closedAt: closedAt is DateTime? ? closedAt : this.closedAt,
    );
  }
}

class LotCardUpdateTable extends _is.UpdateTable<LotCardTable> {
  LotCardUpdateTable(super.table);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> lotId(_is.UuidValue value) =>
      _is.ColumnValue(table.lotId, value);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> auctionId(
    _is.UuidValue value,
  ) => _is.ColumnValue(table.auctionId, value);

  _is.ColumnValue<String, String> code(String value) =>
      _is.ColumnValue(table.code, value);

  _is.ColumnValue<int, int> position(int value) =>
      _is.ColumnValue(table.position, value);

  _is.ColumnValue<String, String> name(String value) =>
      _is.ColumnValue(table.name, value);

  _is.ColumnValue<String, String> description(String value) =>
      _is.ColumnValue(table.description, value);

  _is.ColumnValue<String, String> imageUrl(String? value) =>
      _is.ColumnValue(table.imageUrl, value);

  _is.ColumnValue<String, String> tileEmoji(String value) =>
      _is.ColumnValue(table.tileEmoji, value);

  _is.ColumnValue<String, String> tileColor(String value) =>
      _is.ColumnValue(table.tileColor, value);

  _is.ColumnValue<int, int> openBid(int value) =>
      _is.ColumnValue(table.openBid, value);

  _is.ColumnValue<List<int>, List<int>> increments(List<int> value) =>
      _is.ColumnValue(table.increments, value);

  _is.ColumnValue<int, int> currentPrice(int value) =>
      _is.ColumnValue(table.currentPrice, value);

  _is.ColumnValue<_is.UuidValue, _is.UuidValue> leaderId(
    _is.UuidValue? value,
  ) => _is.ColumnValue(table.leaderId, value);

  _is.ColumnValue<String, String> leaderName(String? value) =>
      _is.ColumnValue(table.leaderName, value);

  _is.ColumnValue<int, int> bidCount(int value) =>
      _is.ColumnValue(table.bidCount, value);

  _is.ColumnValue<String, String> status(String value) =>
      _is.ColumnValue(table.status, value);

  _is.ColumnValue<int, int> version(int value) =>
      _is.ColumnValue(table.version, value);

  _is.ColumnValue<String, String> winnerName(String? value) =>
      _is.ColumnValue(table.winnerName, value);

  _is.ColumnValue<int, int> finalPrice(int? value) =>
      _is.ColumnValue(table.finalPrice, value);

  _is.ColumnValue<String, String> closeCause(String? value) =>
      _is.ColumnValue(table.closeCause, value);

  _is.ColumnValue<DateTime, DateTime> closedAt(DateTime? value) =>
      _is.ColumnValue(table.closedAt, value);
}

class LotCardTable extends _is.Table<int?> {
  LotCardTable({super.tableRelation}) : super(tableName: 'gavel_lot_cards') {
    updateTable = LotCardUpdateTable(this);
    lotId = _is.ColumnUuid('lotId', this);
    auctionId = _is.ColumnUuid('auctionId', this);
    code = _is.ColumnString('code', this);
    position = _is.ColumnInt('position', this);
    name = _is.ColumnString('name', this);
    description = _is.ColumnString('description', this);
    imageUrl = _is.ColumnString('imageUrl', this);
    tileEmoji = _is.ColumnString('tileEmoji', this);
    tileColor = _is.ColumnString('tileColor', this);
    openBid = _is.ColumnInt('openBid', this);
    increments = _is.ColumnSerializable<List<int>>('increments', this);
    currentPrice = _is.ColumnInt('currentPrice', this);
    leaderId = _is.ColumnUuid('leaderId', this);
    leaderName = _is.ColumnString('leaderName', this);
    bidCount = _is.ColumnInt('bidCount', this);
    status = _is.ColumnString('status', this);
    version = _is.ColumnInt('version', this);
    winnerName = _is.ColumnString('winnerName', this);
    finalPrice = _is.ColumnInt('finalPrice', this);
    closeCause = _is.ColumnString('closeCause', this);
    closedAt = _is.ColumnDateTime('closedAt', this);
  }

  late final LotCardUpdateTable updateTable;

  /// The lot.
  late final _is.ColumnUuid lotId;

  /// The auction the lot belongs to.
  late final _is.ColumnUuid auctionId;

  /// The auction's join code.
  late final _is.ColumnString code;

  /// The lot's place in the auction, from 0.
  late final _is.ColumnInt position;

  /// The lot's name.
  late final _is.ColumnString name;

  /// The seller's description, newlines kept.
  late final _is.ColumnString description;

  /// A photo of the lot, or null to show the tile.
  late final _is.ColumnString imageUrl;

  /// The tile's emoji, shown when there is no photo or it fails to load.
  late final _is.ColumnString tileEmoji;

  /// The tile's background, as `#RRGGBB`.
  late final _is.ColumnString tileColor;

  /// The first bid's minimum, in rupiah.
  late final _is.ColumnInt openBid;

  /// The allowed raises (kelipatan), in rupiah, ascending.
  late final _is.ColumnSerializable<List<int>> increments;

  /// The leading bid, or the open bid while there is none.
  late final _is.ColumnInt currentPrice;

  /// The leading bidder, if any.
  late final _is.ColumnUuid leaderId;

  /// The leading bidder's display name, if any.
  late final _is.ColumnString leaderName;

  /// How many bids stand.
  late final _is.ColumnInt bidCount;

  /// OPEN, SOLD or PASSED.
  late final _is.ColumnString status;

  /// The lot aggregate's version: the next bid's `expectedVersion`.
  late final _is.ColumnInt version;

  /// Who won, once SOLD.
  late final _is.ColumnString winnerName;

  /// The winning price, once SOLD.
  late final _is.ColumnInt finalPrice;

  /// Why the lot closed: DEADLINE or SELL_NOW.
  late final _is.ColumnString closeCause;

  /// When the lot closed, in UTC.
  late final _is.ColumnDateTime closedAt;

  @override
  List<_is.Column> get columns => [
    id,
    lotId,
    auctionId,
    code,
    position,
    name,
    description,
    imageUrl,
    tileEmoji,
    tileColor,
    openBid,
    increments,
    currentPrice,
    leaderId,
    leaderName,
    bidCount,
    status,
    version,
    winnerName,
    finalPrice,
    closeCause,
    closedAt,
  ];
}

class LotCardInclude extends _is.IncludeObject {
  LotCardInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => LotCard.t;
}

class LotCardIncludeList extends _is.IncludeList {
  LotCardIncludeList._({
    _is.WhereExpressionBuilder<LotCardTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(LotCard.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => LotCard.t;
}

class LotCardRepository {
  const LotCardRepository._();

  /// Returns a list of [LotCard]s matching the given query parameters.
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
  Future<List<LotCard>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LotCardTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LotCardTable>? orderBy,
    _is.OrderByListBuilder<LotCardTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<LotCard>(
      where: where?.call(LotCard.t),
      orderBy: orderBy?.call(LotCard.t),
      orderByList: orderByList?.call(LotCard.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [LotCard] matching the given query parameters.
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
  Future<LotCard?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LotCardTable>? where,
    int? offset,
    _is.OrderByBuilder<LotCardTable>? orderBy,
    _is.OrderByListBuilder<LotCardTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<LotCard>(
      where: where?.call(LotCard.t),
      orderBy: orderBy?.call(LotCard.t),
      orderByList: orderByList?.call(LotCard.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [LotCard] by its [id] or null if no such row exists.
  Future<LotCard?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<LotCard>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [LotCard]s in the list and returns the inserted rows.
  ///
  /// The returned [LotCard]s will have their `id` fields set.
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
  Future<List<LotCard>> insert(
    _is.DatabaseSession session,
    List<LotCard> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<LotCard>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [LotCard] and returns the inserted row.
  ///
  /// The returned [LotCard] will have its `id` field set.
  Future<LotCard> insertRow(
    _is.DatabaseSession session,
    LotCard row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<LotCard>(row, transaction: transaction);
  }

  /// Upserts all [LotCard]s in the list and returns the resulting rows.
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
  /// The returned [LotCard]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LotCard>> upsert(
    _is.DatabaseSession session,
    List<LotCard> rows, {
    required _is.ColumnSelections<LotCardTable> conflictColumns,
    _is.ColumnSelections<LotCardTable>? updateColumns,
    _is.WhereExpressionBuilder<LotCardTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<LotCard>(
      rows,
      conflictColumns: conflictColumns(LotCard.t),
      updateColumns: updateColumns?.call(LotCard.t),
      updateWhere: updateWhere?.call(LotCard.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [LotCard] and returns the resulting row.
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
  /// The returned [LotCard] will have its `id` field set.
  Future<LotCard?> upsertRow(
    _is.DatabaseSession session,
    LotCard row, {
    required _is.ColumnSelections<LotCardTable> conflictColumns,
    _is.ColumnSelections<LotCardTable>? updateColumns,
    _is.WhereExpressionBuilder<LotCardTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<LotCard>(
      row,
      conflictColumns: conflictColumns(LotCard.t),
      updateColumns: updateColumns?.call(LotCard.t),
      updateWhere: updateWhere?.call(LotCard.t),
      transaction: transaction,
    );
  }

  /// Updates all [LotCard]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LotCard>> update(
    _is.DatabaseSession session,
    List<LotCard> rows, {
    _is.ColumnSelections<LotCardTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<LotCard>(
      rows,
      columns: columns?.call(LotCard.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [LotCard]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<LotCard> updateRow(
    _is.DatabaseSession session,
    LotCard row, {
    _is.ColumnSelections<LotCardTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<LotCard>(
      row,
      columns: columns?.call(LotCard.t),
      transaction: transaction,
    );
  }

  /// Updates a single [LotCard] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<LotCard?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<LotCardUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<LotCard>(
      id,
      columnValues: columnValues(LotCard.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [LotCard]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LotCard>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<LotCardUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<LotCardTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<LotCardTable>? orderBy,
    _is.OrderByListBuilder<LotCardTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<LotCard>(
      columnValues: columnValues(LotCard.t.updateTable),
      where: where(LotCard.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(LotCard.t),
      orderByList: orderByList?.call(LotCard.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [LotCard]s in the list and returns the deleted rows.
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
  Future<List<LotCard>> delete(
    _is.DatabaseSession session,
    List<LotCard> rows, {
    _is.OrderByBuilder<LotCardTable>? orderBy,
    _is.OrderByListBuilder<LotCardTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<LotCard>(
      rows,
      orderBy: orderBy?.call(LotCard.t),
      orderByList: orderByList?.call(LotCard.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [LotCard].
  Future<LotCard> deleteRow(
    _is.DatabaseSession session,
    LotCard row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<LotCard>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<LotCard>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LotCardTable> where,
    _is.OrderByBuilder<LotCardTable>? orderBy,
    _is.OrderByListBuilder<LotCardTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<LotCard>(
      where: where(LotCard.t),
      orderBy: orderBy?.call(LotCard.t),
      orderByList: orderByList?.call(LotCard.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<LotCardTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<LotCard>(
      where: where?.call(LotCard.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [LotCard] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<LotCardTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<LotCard>(
      where: where(LotCard.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
