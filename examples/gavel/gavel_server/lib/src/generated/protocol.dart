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
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    as _i13if8es;
import 'auction_view.dart' as _iwrduo5z;
import 'board_snapshot.dart' as _i5fz6h4w;
import 'created_auction.dart' as _ij286fs9;
import 'future_calls_generated_models/auction_close_calls_close_model.dart'
    as _ijzrfwlf;
import 'join_result.dart' as _irdkvnmr;
import 'ledger_entry.dart' as _ivha9tke;
import 'live_update.dart' as _irca74ja;
import 'live_update_kind.dart' as _i6d34ixx;
import 'lot_card.dart' as _i7jzpqum;
import 'lot_detail.dart' as _ivoeyyyp;
import 'new_lot.dart' as _i7vyupo4;
import 'participant_row.dart' as _ioa4m2zs;
export 'auction_view.dart';
export 'board_snapshot.dart';
export 'created_auction.dart';
export 'join_result.dart';
export 'ledger_entry.dart';
export 'live_update.dart';
export 'live_update_kind.dart';
export 'lot_card.dart';
export 'lot_detail.dart';
export 'new_lot.dart';
export 'participant_row.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'gavel_auctions',
      dartName: 'AuctionView',
      schema: 'public',
      module: 'gavel',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'auctionId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'code',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'closeAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'lotCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'gavel_auctions_code_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'code',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'gavel_auctions_auction_id_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'auctionId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'gavel_auctions_status_close_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'closeAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'gavel_ledger_entries',
      dartName: 'LedgerEntry',
      schema: 'public',
      module: 'gavel',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'lotId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'sequence',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'participantId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'bidderName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'amount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'placedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'retracted',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'retractedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'gavel_ledger_lot_seq_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'lotId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'sequence',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'gavel_lot_cards',
      dartName: 'LotCard',
      schema: 'public',
      module: 'gavel',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'lotId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'auctionId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'code',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'position',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'description',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'imageUrl',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'tileEmoji',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'tileColor',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'openBid',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'increments',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<int>',
        ),
        _isp.ColumnDefinition(
          name: 'buyNowPrice',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'currentPrice',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'leaderId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'leaderName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'bidCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'version',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'winnerName',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'finalPrice',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'closeCause',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'closedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'gavel_lot_cards_lot_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'lotId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'gavel_lot_cards_code_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'code',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'position',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'gavel_participants',
      dartName: 'ParticipantRow',
      schema: 'public',
      module: 'gavel',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue?',
          columnDefault: 'random_v7',
        ),
        _isp.ColumnDefinition(
          name: 'auctionId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'displayName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'keyHash',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'version',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'gavel_participants_auction_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'auctionId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i13if8es.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

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
      } on _is.DeserializationClassNameNotFoundException catch (_) {
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
    if (t == _ijzrfwlf.AuctionCloseCallsCloseModel) {
      return _ijzrfwlf.AuctionCloseCallsCloseModel.fromJson(data) as T;
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
    if (t == _ivoeyyyp.LotDetail) {
      return _ivoeyyyp.LotDetail.fromJson(data) as T;
    }
    if (t == _i7vyupo4.NewLot) {
      return _i7vyupo4.NewLot.fromJson(data) as T;
    }
    if (t == _ioa4m2zs.ParticipantRow) {
      return _ioa4m2zs.ParticipantRow.fromJson(data) as T;
    }
    if (t == _is.getType<_iwrduo5z.AuctionView?>()) {
      return (data != null ? _iwrduo5z.AuctionView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i5fz6h4w.BoardSnapshot?>()) {
      return (data != null ? _i5fz6h4w.BoardSnapshot.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ij286fs9.CreatedAuction?>()) {
      return (data != null ? _ij286fs9.CreatedAuction.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ijzrfwlf.AuctionCloseCallsCloseModel?>()) {
      return (data != null
              ? _ijzrfwlf.AuctionCloseCallsCloseModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_irdkvnmr.JoinResult?>()) {
      return (data != null ? _irdkvnmr.JoinResult.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ivha9tke.LedgerEntry?>()) {
      return (data != null ? _ivha9tke.LedgerEntry.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_irca74ja.LiveUpdate?>()) {
      return (data != null ? _irca74ja.LiveUpdate.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i6d34ixx.LiveUpdateKind?>()) {
      return (data != null ? _i6d34ixx.LiveUpdateKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i7jzpqum.LotCard?>()) {
      return (data != null ? _i7jzpqum.LotCard.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ivoeyyyp.LotDetail?>()) {
      return (data != null ? _ivoeyyyp.LotDetail.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i7vyupo4.NewLot?>()) {
      return (data != null ? _i7vyupo4.NewLot.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ioa4m2zs.ParticipantRow?>()) {
      return (data != null ? _ioa4m2zs.ParticipantRow.fromJson(data) : null)
          as T;
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
    if (t == List<_ivha9tke.LedgerEntry>) {
      return (data as List)
              .map((e) => deserialize<_ivha9tke.LedgerEntry>(e))
              .toList()
          as T;
    }
    if (t == Map<String, String>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<String>(v)),
          )
          as T;
    }
    try {
      return _i13if8es.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _iwrduo5z.AuctionView => 'AuctionView',
      _i5fz6h4w.BoardSnapshot => 'BoardSnapshot',
      _ij286fs9.CreatedAuction => 'CreatedAuction',
      _ijzrfwlf.AuctionCloseCallsCloseModel => 'AuctionCloseCallsCloseModel',
      _irdkvnmr.JoinResult => 'JoinResult',
      _ivha9tke.LedgerEntry => 'LedgerEntry',
      _irca74ja.LiveUpdate => 'LiveUpdate',
      _i6d34ixx.LiveUpdateKind => 'LiveUpdateKind',
      _i7jzpqum.LotCard => 'LotCard',
      _ivoeyyyp.LotDetail => 'LotDetail',
      _i7vyupo4.NewLot => 'NewLot',
      _ioa4m2zs.ParticipantRow => 'ParticipantRow',
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
      case _ijzrfwlf.AuctionCloseCallsCloseModel():
        return 'AuctionCloseCallsCloseModel';
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
      case _ivoeyyyp.LotDetail():
        return 'LotDetail';
      case _i7vyupo4.NewLot():
        return 'NewLot';
      case _ioa4m2zs.ParticipantRow():
        return 'ParticipantRow';
    }
    className = _i13if8es.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'tarodomain_serverpod.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
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
    if (dataClassName == 'AuctionCloseCallsCloseModel') {
      return deserialize<_ijzrfwlf.AuctionCloseCallsCloseModel>(data['data']);
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
    if (dataClassName == 'LotDetail') {
      return deserialize<_ivoeyyyp.LotDetail>(data['data']);
    }
    if (dataClassName == 'NewLot') {
      return deserialize<_i7vyupo4.NewLot>(data['data']);
    }
    if (dataClassName == 'ParticipantRow') {
      return deserialize<_ioa4m2zs.ParticipantRow>(data['data']);
    }
    if (dataClassName.startsWith('tarodomain_serverpod.')) {
      data['className'] = dataClassName.substring(21);
      return _i13if8es.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _i13if8es.Protocol().registerHostProtocol('gavel', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _i13if8es.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _iwrduo5z.AuctionView:
        return _iwrduo5z.AuctionView.t;
      case _ivha9tke.LedgerEntry:
        return _ivha9tke.LedgerEntry.t;
      case _i7jzpqum.LotCard:
        return _i7jzpqum.LotCard.t;
      case _ioa4m2zs.ParticipantRow:
        return _ioa4m2zs.ParticipantRow.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

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
      return _i13if8es.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
