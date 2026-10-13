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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// One auction: the read model of `AuctionTableProjection`.
abstract class AuctionView
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
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
    required _isc.UuidValue auctionId,
    required String code,
    required String title,
    required DateTime closeAt,
    required String status,
    required int lotCount,
  }) = _AuctionViewImpl;

  factory AuctionView.fromJson(Map<String, dynamic> jsonSerialization) {
    return AuctionView(
      id: jsonSerialization['id'] as int?,
      auctionId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['auctionId'],
      ),
      code: jsonSerialization['code'] as String,
      title: jsonSerialization['title'] as String,
      closeAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['closeAt'],
      ),
      status: jsonSerialization['status'] as String,
      lotCount: jsonSerialization['lotCount'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The auction.
  _isc.UuidValue auctionId;

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

  /// Returns a shallow copy of this [AuctionView]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AuctionView copyWith({
    int? id,
    _isc.UuidValue? auctionId,
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

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AuctionViewImpl extends AuctionView {
  _AuctionViewImpl({
    int? id,
    required _isc.UuidValue auctionId,
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
  @_isc.useResult
  @override
  AuctionView copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? auctionId,
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
