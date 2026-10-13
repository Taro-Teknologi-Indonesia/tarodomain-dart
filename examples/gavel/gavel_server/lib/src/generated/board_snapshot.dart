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
import 'auction_view.dart' as _iwrduo5z;

/// An auction as the board shows it. Lots are added in UC-02.
abstract class BoardSnapshot
    implements _is.SerializableModel, _is.ProtocolSerialization {
  BoardSnapshot._({required this.auction, required this.serverNow});

  factory BoardSnapshot({
    required _iwrduo5z.AuctionView auction,
    required DateTime serverNow,
  }) = _BoardSnapshotImpl;

  factory BoardSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return BoardSnapshot(
      auction: _imkuj2yl.Protocol().deserialize<_iwrduo5z.AuctionView>(
        jsonSerialization['auction'],
      ),
      serverNow: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverNow'],
      ),
    );
  }

  /// The auction.
  _iwrduo5z.AuctionView auction;

  /// The server's clock when it answered, for the client's clock offset.
  DateTime serverNow;

  /// Returns a shallow copy of this [BoardSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BoardSnapshot copyWith({_iwrduo5z.AuctionView? auction, DateTime? serverNow});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BoardSnapshot',
      'auction': auction.toJson(),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BoardSnapshot',
      'auction': auction.toJsonForProtocol(),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _BoardSnapshotImpl extends BoardSnapshot {
  _BoardSnapshotImpl({
    required _iwrduo5z.AuctionView auction,
    required DateTime serverNow,
  }) : super._(auction: auction, serverNow: serverNow);

  /// Returns a shallow copy of this [BoardSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  BoardSnapshot copyWith({
    _iwrduo5z.AuctionView? auction,
    DateTime? serverNow,
  }) {
    return BoardSnapshot(
      auction: auction ?? this.auction.copyWith(),
      serverNow: serverNow ?? this.serverNow,
    );
  }
}
