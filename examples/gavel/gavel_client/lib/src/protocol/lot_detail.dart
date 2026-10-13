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
import 'ledger_entry.dart' as _ivha9tke;
import 'lot_card.dart' as _i7jzpqum;

/// One lot with its whole ledger, for the lot page.
abstract class LotDetail
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LotDetail._({
    required this.lot,
    required this.ledger,
    required this.closeAt,
    required this.serverNow,
  });

  factory LotDetail({
    required _i7jzpqum.LotCard lot,
    required List<_ivha9tke.LedgerEntry> ledger,
    required DateTime closeAt,
    required DateTime serverNow,
  }) = _LotDetailImpl;

  factory LotDetail.fromJson(Map<String, dynamic> jsonSerialization) {
    return LotDetail(
      lot: _ivmqq51r.Protocol().deserialize<_i7jzpqum.LotCard>(
        jsonSerialization['lot'],
      ),
      ledger: _ivmqq51r.Protocol().deserialize<List<_ivha9tke.LedgerEntry>>(
        jsonSerialization['ledger'],
      ),
      closeAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['closeAt'],
      ),
      serverNow: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverNow'],
      ),
    );
  }

  /// The lot.
  _i7jzpqum.LotCard lot;

  /// Every bid on the lot, retracted ones too, by sequence.
  List<_ivha9tke.LedgerEntry> ledger;

  /// When the lot's auction closes, in UTC.
  DateTime closeAt;

  /// The server's clock when it answered, for the client's clock offset.
  DateTime serverNow;

  /// Returns a shallow copy of this [LotDetail]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LotDetail copyWith({
    _i7jzpqum.LotCard? lot,
    List<_ivha9tke.LedgerEntry>? ledger,
    DateTime? closeAt,
    DateTime? serverNow,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LotDetail',
      'lot': lot.toJson(),
      'ledger': ledger.toJson(valueToJson: (v) => v.toJson()),
      'closeAt': closeAt.toJson(),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LotDetail',
      'lot': lot.toJsonForProtocol(),
      'ledger': ledger.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'closeAt': closeAt.toJson(),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _LotDetailImpl extends LotDetail {
  _LotDetailImpl({
    required _i7jzpqum.LotCard lot,
    required List<_ivha9tke.LedgerEntry> ledger,
    required DateTime closeAt,
    required DateTime serverNow,
  }) : super._(
         lot: lot,
         ledger: ledger,
         closeAt: closeAt,
         serverNow: serverNow,
       );

  /// Returns a shallow copy of this [LotDetail]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LotDetail copyWith({
    _i7jzpqum.LotCard? lot,
    List<_ivha9tke.LedgerEntry>? ledger,
    DateTime? closeAt,
    DateTime? serverNow,
  }) {
    return LotDetail(
      lot: lot ?? this.lot.copyWith(),
      ledger: ledger ?? this.ledger.map((e0) => e0.copyWith()).toList(),
      closeAt: closeAt ?? this.closeAt,
      serverNow: serverNow ?? this.serverNow,
    );
  }
}
