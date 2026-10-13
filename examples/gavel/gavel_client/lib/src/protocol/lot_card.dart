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
import 'package:gavel_client/src/protocol/protocol.dart' as _ivmqq51r;
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// One lot as the board shows it: the read model of `LotTableProjection`.
abstract class LotCard
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
    this.buyNowPrice,
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
    bool? unpaid,
    this.unpaidAt,
    this.unpaidNote,
  }) : unpaid = unpaid ?? false;

  factory LotCard({
    int? id,
    required _isc.UuidValue lotId,
    required _isc.UuidValue auctionId,
    required String code,
    required int position,
    required String name,
    required String description,
    String? imageUrl,
    required String tileEmoji,
    required String tileColor,
    required int openBid,
    required List<int> increments,
    int? buyNowPrice,
    required int currentPrice,
    _isc.UuidValue? leaderId,
    String? leaderName,
    required int bidCount,
    required String status,
    required int version,
    String? winnerName,
    int? finalPrice,
    String? closeCause,
    DateTime? closedAt,
    bool? unpaid,
    DateTime? unpaidAt,
    String? unpaidNote,
  }) = _LotCardImpl;

  factory LotCard.fromJson(Map<String, dynamic> jsonSerialization) {
    return LotCard(
      id: jsonSerialization['id'] as int?,
      lotId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['lotId']),
      auctionId: _isc.UuidValueJsonExtension.fromJson(
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
      increments: _ivmqq51r.Protocol().deserialize<List<int>>(
        jsonSerialization['increments'],
      ),
      buyNowPrice: jsonSerialization['buyNowPrice'] as int?,
      currentPrice: jsonSerialization['currentPrice'] as int,
      leaderId: jsonSerialization['leaderId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['leaderId']),
      leaderName: jsonSerialization['leaderName'] as String?,
      bidCount: jsonSerialization['bidCount'] as int,
      status: jsonSerialization['status'] as String,
      version: jsonSerialization['version'] as int,
      winnerName: jsonSerialization['winnerName'] as String?,
      finalPrice: jsonSerialization['finalPrice'] as int?,
      closeCause: jsonSerialization['closeCause'] as String?,
      closedAt: jsonSerialization['closedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['closedAt']),
      unpaid: jsonSerialization['unpaid'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['unpaid']),
      unpaidAt: jsonSerialization['unpaidAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['unpaidAt']),
      unpaidNote: jsonSerialization['unpaidNote'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The lot.
  _isc.UuidValue lotId;

  /// The auction the lot belongs to.
  _isc.UuidValue auctionId;

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

  /// The Buy Now (BN) price, in rupiah, or null for no BN.
  int? buyNowPrice;

  /// The leading bid, or the open bid while there is none.
  int currentPrice;

  /// The leading bidder, if any.
  _isc.UuidValue? leaderId;

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

  /// Whether the organizer marked the winner as not having paid (UC-14).
  bool unpaid;

  /// When the lot was marked unpaid, in UTC.
  DateTime? unpaidAt;

  /// The organizer's public note on the unpaid mark, if any.
  String? unpaidNote;

  /// Returns a shallow copy of this [LotCard]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LotCard copyWith({
    int? id,
    _isc.UuidValue? lotId,
    _isc.UuidValue? auctionId,
    String? code,
    int? position,
    String? name,
    String? description,
    String? imageUrl,
    String? tileEmoji,
    String? tileColor,
    int? openBid,
    List<int>? increments,
    int? buyNowPrice,
    int? currentPrice,
    _isc.UuidValue? leaderId,
    String? leaderName,
    int? bidCount,
    String? status,
    int? version,
    String? winnerName,
    int? finalPrice,
    String? closeCause,
    DateTime? closedAt,
    bool? unpaid,
    DateTime? unpaidAt,
    String? unpaidNote,
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
      if (buyNowPrice != null) 'buyNowPrice': buyNowPrice,
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
      'unpaid': unpaid,
      if (unpaidAt != null) 'unpaidAt': unpaidAt?.toJson(),
      if (unpaidNote != null) 'unpaidNote': unpaidNote,
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
      if (buyNowPrice != null) 'buyNowPrice': buyNowPrice,
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
      'unpaid': unpaid,
      if (unpaidAt != null) 'unpaidAt': unpaidAt?.toJson(),
      if (unpaidNote != null) 'unpaidNote': unpaidNote,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LotCardImpl extends LotCard {
  _LotCardImpl({
    int? id,
    required _isc.UuidValue lotId,
    required _isc.UuidValue auctionId,
    required String code,
    required int position,
    required String name,
    required String description,
    String? imageUrl,
    required String tileEmoji,
    required String tileColor,
    required int openBid,
    required List<int> increments,
    int? buyNowPrice,
    required int currentPrice,
    _isc.UuidValue? leaderId,
    String? leaderName,
    required int bidCount,
    required String status,
    required int version,
    String? winnerName,
    int? finalPrice,
    String? closeCause,
    DateTime? closedAt,
    bool? unpaid,
    DateTime? unpaidAt,
    String? unpaidNote,
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
         buyNowPrice: buyNowPrice,
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
         unpaid: unpaid,
         unpaidAt: unpaidAt,
         unpaidNote: unpaidNote,
       );

  /// Returns a shallow copy of this [LotCard]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LotCard copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? lotId,
    _isc.UuidValue? auctionId,
    String? code,
    int? position,
    String? name,
    String? description,
    Object? imageUrl = _Undefined,
    String? tileEmoji,
    String? tileColor,
    int? openBid,
    List<int>? increments,
    Object? buyNowPrice = _Undefined,
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
    bool? unpaid,
    Object? unpaidAt = _Undefined,
    Object? unpaidNote = _Undefined,
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
      buyNowPrice: buyNowPrice is int? ? buyNowPrice : this.buyNowPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      leaderId: leaderId is _isc.UuidValue? ? leaderId : this.leaderId,
      leaderName: leaderName is String? ? leaderName : this.leaderName,
      bidCount: bidCount ?? this.bidCount,
      status: status ?? this.status,
      version: version ?? this.version,
      winnerName: winnerName is String? ? winnerName : this.winnerName,
      finalPrice: finalPrice is int? ? finalPrice : this.finalPrice,
      closeCause: closeCause is String? ? closeCause : this.closeCause,
      closedAt: closedAt is DateTime? ? closedAt : this.closedAt,
      unpaid: unpaid ?? this.unpaid,
      unpaidAt: unpaidAt is DateTime? ? unpaidAt : this.unpaidAt,
      unpaidNote: unpaidNote is String? ? unpaidNote : this.unpaidNote,
    );
  }
}
