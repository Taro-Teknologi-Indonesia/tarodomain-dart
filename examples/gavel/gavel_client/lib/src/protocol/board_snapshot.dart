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
import 'lot_card.dart' as _i7jzpqum;

/// An auction as the board shows it.
abstract class BoardSnapshot
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BoardSnapshot._({
    required this.auction,
    required this.lots,
    required this.serverNow,
  });

  factory BoardSnapshot({
    required _iwrduo5z.AuctionView auction,
    required List<_i7jzpqum.LotCard> lots,
    required DateTime serverNow,
  }) = _BoardSnapshotImpl;

  factory BoardSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return BoardSnapshot(
      auction: _ivmqq51r.Protocol().deserialize<_iwrduo5z.AuctionView>(
        jsonSerialization['auction'],
      ),
      lots: _ivmqq51r.Protocol().deserialize<List<_i7jzpqum.LotCard>>(
        jsonSerialization['lots'],
      ),
      serverNow: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverNow'],
      ),
    );
  }

  /// The auction.
  _iwrduo5z.AuctionView auction;

  /// The auction's lots, in the order they were added.
  List<_i7jzpqum.LotCard> lots;

  /// The server's clock when it answered, for the client's clock offset.
  DateTime serverNow;

  /// Returns a shallow copy of this [BoardSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BoardSnapshot copyWith({
    _iwrduo5z.AuctionView? auction,
    List<_i7jzpqum.LotCard>? lots,
    DateTime? serverNow,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BoardSnapshot',
      'auction': auction.toJson(),
      'lots': lots.toJson(valueToJson: (v) => v.toJson()),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BoardSnapshot',
      'auction': auction.toJsonForProtocol(),
      'lots': lots.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _BoardSnapshotImpl extends BoardSnapshot {
  _BoardSnapshotImpl({
    required _iwrduo5z.AuctionView auction,
    required List<_i7jzpqum.LotCard> lots,
    required DateTime serverNow,
  }) : super._(auction: auction, lots: lots, serverNow: serverNow);

  /// Returns a shallow copy of this [BoardSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BoardSnapshot copyWith({
    _iwrduo5z.AuctionView? auction,
    List<_i7jzpqum.LotCard>? lots,
    DateTime? serverNow,
  }) {
    return BoardSnapshot(
      auction: auction ?? this.auction.copyWith(),
      lots: lots ?? this.lots.map((e0) => e0.copyWith()).toList(),
      serverNow: serverNow ?? this.serverNow,
    );
  }
}
