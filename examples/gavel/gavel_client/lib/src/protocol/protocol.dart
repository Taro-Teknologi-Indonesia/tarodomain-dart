/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:tarodomain_serverpod_client/tarodomain_serverpod_client.dart'
    as _ispsicqs;
import 'auction_view.dart' as _iwrduo5z;
import 'board_snapshot.dart' as _i5fz6h4w;
import 'created_auction.dart' as _ij286fs9;
import 'join_result.dart' as _irdkvnmr;
import 'ledger_entry.dart' as _ivha9tke;
import 'live_update.dart' as _irca74ja;
import 'live_update_kind.dart' as _i6d34ixx;
import 'lot_card.dart' as _i7jzpqum;
import 'new_lot.dart' as _i7vyupo4;
export 'auction_view.dart';
export 'board_snapshot.dart';
export 'created_auction.dart';
export 'join_result.dart';
export 'ledger_entry.dart';
export 'live_update.dart';
export 'live_update_kind.dart';
export 'lot_card.dart';
export 'new_lot.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(dynamic data, [Type? t]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _iwrduo5z.AuctionView) {
      return _iwrduo5z.AuctionView.fromJson(data) as T;
    }
    if (t == _i5fz6h4w.BoardSnapshot) {
      return _i5fz6h4w.BoardSnapshot.fromJson(data) as T;
    }
    if (t == _ij286fs9.CreatedAuction) {
      return _ij286fs9.CreatedAuction.fromJson(data) as T;
    }
    if (t == _irdkvnmr.JoinResult) {
      return _irdkvnmr.JoinResult.fromJson(data) as T;
    }
    if (t == _ivha9tke.LedgerEntry) {
      return _ivha9tke.LedgerEntry.fromJson(data) as T;
    }
    if (t == _irca74ja.LiveUpdate) {
      return _irca74ja.LiveUpdate.fromJson(data) as T;
    }
    if (t == _i6d34ixx.LiveUpdateKind) {
      return _i6d34ixx.LiveUpdateKind.fromJson(data) as T;
    }
    if (t == _i7jzpqum.LotCard) {
      return _i7jzpqum.LotCard.fromJson(data) as T;
    }
    if (t == _i7vyupo4.NewLot) {
      return _i7vyupo4.NewLot.fromJson(data) as T;
    }
    if (t == _isc.getType<_iwrduo5z.AuctionView?>()) {
      return (data != null ? _iwrduo5z.AuctionView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i5fz6h4w.BoardSnapshot?>()) {
      return (data != null ? _i5fz6h4w.BoardSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ij286fs9.CreatedAuction?>()) {
      return (data != null ? _ij286fs9.CreatedAuction.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_irdkvnmr.JoinResult?>()) {
      return (data != null ? _irdkvnmr.JoinResult.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ivha9tke.LedgerEntry?>()) {
      return (data != null ? _ivha9tke.LedgerEntry.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_irca74ja.LiveUpdate?>()) {
      return (data != null ? _irca74ja.LiveUpdate.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i6d34ixx.LiveUpdateKind?>()) {
      return (data != null ? _i6d34ixx.LiveUpdateKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i7jzpqum.LotCard?>()) {
      return (data != null ? _i7jzpqum.LotCard.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i7vyupo4.NewLot?>()) {
      return (data != null ? _i7vyupo4.NewLot.fromJson(data) : null) as T;
    }
    if (t == List<_i7jzpqum.LotCard>) {
      return (data as List)
              .map((e) => deserialize<_i7jzpqum.LotCard>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    try {
      return _ispsicqs.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _iwrduo5z.AuctionView => 'AuctionView',
      _i5fz6h4w.BoardSnapshot => 'BoardSnapshot',
      _ij286fs9.CreatedAuction => 'CreatedAuction',
      _irdkvnmr.JoinResult => 'JoinResult',
      _ivha9tke.LedgerEntry => 'LedgerEntry',
      _irca74ja.LiveUpdate => 'LiveUpdate',
      _i6d34ixx.LiveUpdateKind => 'LiveUpdateKind',
      _i7jzpqum.LotCard => 'LotCard',
      _i7vyupo4.NewLot => 'NewLot',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('gavel.', '');
    }

    switch (data) {
      case _iwrduo5z.AuctionView():
        return 'AuctionView';
      case _i5fz6h4w.BoardSnapshot():
        return 'BoardSnapshot';
      case _ij286fs9.CreatedAuction():
        return 'CreatedAuction';
      case _irdkvnmr.JoinResult():
        return 'JoinResult';
      case _ivha9tke.LedgerEntry():
        return 'LedgerEntry';
      case _irca74ja.LiveUpdate():
        return 'LiveUpdate';
      case _i6d34ixx.LiveUpdateKind():
        return 'LiveUpdateKind';
      case _i7jzpqum.LotCard():
        return 'LotCard';
      case _i7vyupo4.NewLot():
        return 'NewLot';
    }
    className = _ispsicqs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'tarodomain_serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AuctionView') {
      return deserialize<_iwrduo5z.AuctionView>(data['data']);
    }
    if (dataClassName == 'BoardSnapshot') {
      return deserialize<_i5fz6h4w.BoardSnapshot>(data['data']);
    }
    if (dataClassName == 'CreatedAuction') {
      return deserialize<_ij286fs9.CreatedAuction>(data['data']);
    }
    if (dataClassName == 'JoinResult') {
      return deserialize<_irdkvnmr.JoinResult>(data['data']);
    }
    if (dataClassName == 'LedgerEntry') {
      return deserialize<_ivha9tke.LedgerEntry>(data['data']);
    }
    if (dataClassName == 'LiveUpdate') {
      return deserialize<_irca74ja.LiveUpdate>(data['data']);
    }
    if (dataClassName == 'LiveUpdateKind') {
      return deserialize<_i6d34ixx.LiveUpdateKind>(data['data']);
    }
    if (dataClassName == 'LotCard') {
      return deserialize<_i7jzpqum.LotCard>(data['data']);
    }
    if (dataClassName == 'NewLot') {
      return deserialize<_i7vyupo4.NewLot>(data['data']);
    }
    if (dataClassName.startsWith('tarodomain_serverpod.')) {
      data['className'] = dataClassName.substring(21);
      return _ispsicqs.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _ispsicqs.Protocol().registerHostProtocol('gavel', this);
  }

  @override
  String getModuleName() => 'gavel';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _ispsicqs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
