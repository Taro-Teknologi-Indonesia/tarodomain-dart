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
import 'ledger_entry.dart' as _ivha9tke;
import 'live_update_kind.dart' as _i6d34ixx;
import 'lot_card.dart' as _i7jzpqum;

/// One message on an auction's live channel, `auction:<CODE>`.
abstract class LiveUpdate
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LiveUpdate._({
    required this.kind,
    this.auction,
    this.lot,
    this.ledgerEntry,
    required this.serverNow,
  });

  factory LiveUpdate({
    required _i6d34ixx.LiveUpdateKind kind,
    _iwrduo5z.AuctionView? auction,
    _i7jzpqum.LotCard? lot,
    _ivha9tke.LedgerEntry? ledgerEntry,
    required DateTime serverNow,
  }) = _LiveUpdateImpl;

  factory LiveUpdate.fromJson(Map<String, dynamic> jsonSerialization) {
    return LiveUpdate(
      kind: _i6d34ixx.LiveUpdateKind.fromJson(
        (jsonSerialization['kind'] as String),
      ),
      auction: jsonSerialization['auction'] == null
          ? null
          : _ivmqq51r.Protocol().deserialize<_iwrduo5z.AuctionView>(
              jsonSerialization['auction'],
            ),
      lot: jsonSerialization['lot'] == null
          ? null
          : _ivmqq51r.Protocol().deserialize<_i7jzpqum.LotCard>(
              jsonSerialization['lot'],
            ),
      ledgerEntry: jsonSerialization['ledgerEntry'] == null
          ? null
          : _ivmqq51r.Protocol().deserialize<_ivha9tke.LedgerEntry>(
              jsonSerialization['ledgerEntry'],
            ),
      serverNow: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverNow'],
      ),
    );
  }

  /// What changed.
  _i6d34ixx.LiveUpdateKind kind;

  /// The auction as it is now, when [kind] is `auctionChanged`.
  _iwrduo5z.AuctionView? auction;

  /// The lot as it is now, when [kind] is `lotChanged`.
  _i7jzpqum.LotCard? lot;

  /// The ledger line the change added, when a bid was placed.
  _ivha9tke.LedgerEntry? ledgerEntry;

  /// The server's clock when it posted, for the client's clock offset.
  DateTime serverNow;

  /// Returns a shallow copy of this [LiveUpdate]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LiveUpdate copyWith({
    _i6d34ixx.LiveUpdateKind? kind,
    _iwrduo5z.AuctionView? auction,
    _i7jzpqum.LotCard? lot,
    _ivha9tke.LedgerEntry? ledgerEntry,
    DateTime? serverNow,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LiveUpdate',
      'kind': kind.toJson(),
      if (auction != null) 'auction': auction?.toJson(),
      if (lot != null) 'lot': lot?.toJson(),
      if (ledgerEntry != null) 'ledgerEntry': ledgerEntry?.toJson(),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LiveUpdate',
      'kind': kind.toJson(),
      if (auction != null) 'auction': auction?.toJsonForProtocol(),
      if (lot != null) 'lot': lot?.toJsonForProtocol(),
      if (ledgerEntry != null) 'ledgerEntry': ledgerEntry?.toJsonForProtocol(),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LiveUpdateImpl extends LiveUpdate {
  _LiveUpdateImpl({
    required _i6d34ixx.LiveUpdateKind kind,
    _iwrduo5z.AuctionView? auction,
    _i7jzpqum.LotCard? lot,
    _ivha9tke.LedgerEntry? ledgerEntry,
    required DateTime serverNow,
  }) : super._(
         kind: kind,
         auction: auction,
         lot: lot,
         ledgerEntry: ledgerEntry,
         serverNow: serverNow,
       );

  /// Returns a shallow copy of this [LiveUpdate]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LiveUpdate copyWith({
    _i6d34ixx.LiveUpdateKind? kind,
    Object? auction = _Undefined,
    Object? lot = _Undefined,
    Object? ledgerEntry = _Undefined,
    DateTime? serverNow,
  }) {
    return LiveUpdate(
      kind: kind ?? this.kind,
      auction: auction is _iwrduo5z.AuctionView?
          ? auction
          : this.auction?.copyWith(),
      lot: lot is _i7jzpqum.LotCard? ? lot : this.lot?.copyWith(),
      ledgerEntry: ledgerEntry is _ivha9tke.LedgerEntry?
          ? ledgerEntry
          : this.ledgerEntry?.copyWith(),
      serverNow: serverNow ?? this.serverNow,
    );
  }
}
