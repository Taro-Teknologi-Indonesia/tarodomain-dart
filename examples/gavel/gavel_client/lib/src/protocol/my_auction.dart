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
import 'auction_view.dart' as _iwrduo5z;

/// One of the signed-in organizer's auctions, as My auctions lists it.
abstract class MyAuction
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MyAuction._({
    required this.auction,
    required this.soldCount,
    required this.soldTotal,
    required this.unpaidCount,
  });

  factory MyAuction({
    required _iwrduo5z.AuctionView auction,
    required int soldCount,
    required int soldTotal,
    required int unpaidCount,
  }) = _MyAuctionImpl;

  factory MyAuction.fromJson(Map<String, dynamic> jsonSerialization) {
    return MyAuction(
      auction: _ivmqq51r.Protocol().deserialize<_iwrduo5z.AuctionView>(
        jsonSerialization['auction'],
      ),
      soldCount: jsonSerialization['soldCount'] as int,
      soldTotal: jsonSerialization['soldTotal'] as int,
      unpaidCount: jsonSerialization['unpaidCount'] as int,
    );
  }

  /// The auction.
  _iwrduo5z.AuctionView auction;

  /// How many of its lots are SOLD.
  int soldCount;

  /// The sum of the SOLD lots' final prices, in rupiah.
  int soldTotal;

  /// How many SOLD lots were marked unpaid (UC-14).
  int unpaidCount;

  /// Returns a shallow copy of this [MyAuction]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MyAuction copyWith({
    _iwrduo5z.AuctionView? auction,
    int? soldCount,
    int? soldTotal,
    int? unpaidCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MyAuction',
      'auction': auction.toJson(),
      'soldCount': soldCount,
      'soldTotal': soldTotal,
      'unpaidCount': unpaidCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MyAuction',
      'auction': auction.toJsonForProtocol(),
      'soldCount': soldCount,
      'soldTotal': soldTotal,
      'unpaidCount': unpaidCount,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _MyAuctionImpl extends MyAuction {
  _MyAuctionImpl({
    required _iwrduo5z.AuctionView auction,
    required int soldCount,
    required int soldTotal,
    required int unpaidCount,
  }) : super._(
         auction: auction,
         soldCount: soldCount,
         soldTotal: soldTotal,
         unpaidCount: unpaidCount,
       );

  /// Returns a shallow copy of this [MyAuction]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MyAuction copyWith({
    _iwrduo5z.AuctionView? auction,
    int? soldCount,
    int? soldTotal,
    int? unpaidCount,
  }) {
    return MyAuction(
      auction: auction ?? this.auction.copyWith(),
      soldCount: soldCount ?? this.soldCount,
      soldTotal: soldTotal ?? this.soldTotal,
      unpaidCount: unpaidCount ?? this.unpaidCount,
    );
  }
}
