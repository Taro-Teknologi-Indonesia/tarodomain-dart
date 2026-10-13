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
import 'live_update_kind.dart' as _i6d34ixx;

/// One message on an auction's live channel, `auction:<CODE>`.
///
/// Lot and ledger payloads are added with their read models (UC-02, UC-05).
abstract class LiveUpdate
    implements _is.SerializableModel, _is.ProtocolSerialization {
  LiveUpdate._({required this.kind, this.auction, required this.serverNow});

  factory LiveUpdate({
    required _i6d34ixx.LiveUpdateKind kind,
    _iwrduo5z.AuctionView? auction,
    required DateTime serverNow,
  }) = _LiveUpdateImpl;

  factory LiveUpdate.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveUpdate(
      kind: _i6d34ixx.LiveUpdateKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      auction: jsonSerialization['auction'] == null
          ? null
          : _imkuj2yl.Protocol().deserialize<_iwrduo5z.AuctionView>(
              jsonSerialization['auction'],
            ),
      serverNow: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverNow'],
      ),
    );
  }

  /// What changed.
  _i6d34ixx.LiveUpdateKind kind;

  /// The auction as it is now, when [kind] is `auctionChanged`.
  _iwrduo5z.AuctionView? auction;

  /// The server's clock when it posted, for the client's clock offset.
  DateTime serverNow;

  /// Returns a shallow copy of this [LiveUpdate]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  LiveUpdate copyWith({
    _i6d34ixx.LiveUpdateKind? kind,
    _iwrduo5z.AuctionView? auction,
    DateTime? serverNow,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveUpdate',
      'kind': kind.toJson(),
      if (auction != null) 'auction': auction?.toJson(),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LiveUpdate',
      'kind': kind.toJson(),
      if (auction != null) 'auction': auction?.toJsonForProtocol(),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveUpdateImpl extends LiveUpdate {
  _LiveUpdateImpl({
    required _i6d34ixx.LiveUpdateKind kind,
    _iwrduo5z.AuctionView? auction,
    required DateTime serverNow,
  }) : super._(kind: kind, auction: auction, serverNow: serverNow);

  /// Returns a shallow copy of this [LiveUpdate]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  LiveUpdate copyWith({
    _i6d34ixx.LiveUpdateKind? kind,
    Object? auction = _Undefined,
    DateTime? serverNow,
  }) {
    return LiveUpdate(
      kind: kind ?? this.kind,
      auction: auction is _iwrduo5z.AuctionView?
          ? auction
          : this.auction?.copyWith(),
      serverNow: serverNow ?? this.serverNow,
    );
  }
}
