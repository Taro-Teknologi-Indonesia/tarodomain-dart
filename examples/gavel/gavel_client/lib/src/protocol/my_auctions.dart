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
import 'my_auction.dart' as _itazwe3y;

/// The signed-in organizer's auctions, with the server's clock.
abstract class MyAuctions
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  MyAuctions._({required this.auctions, required this.serverNow});

  factory MyAuctions({
    required List<_itazwe3y.MyAuction> auctions,
    required DateTime serverNow,
  }) = _MyAuctionsImpl;

  factory MyAuctions.fromJson(Map<String, dynamic> jsonSerialization) {
    return MyAuctions(
      auctions: _ivmqq51r.Protocol().deserialize<List<_itazwe3y.MyAuction>>(
        jsonSerialization['auctions'],
      ),
      serverNow: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverNow'],
      ),
    );
  }

  /// Running ones first, then closed ones (see `OrganizerEndpoint.myAuctions`).
  List<_itazwe3y.MyAuction> auctions;

  /// The server's clock when it answered, for the countdowns.
  DateTime serverNow;

  /// Returns a shallow copy of this [MyAuctions]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  MyAuctions copyWith({
    List<_itazwe3y.MyAuction>? auctions,
    DateTime? serverNow,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MyAuctions',
      'auctions': auctions.toJson(valueToJson: (v) => v.toJson()),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'MyAuctions',
      'auctions': auctions.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _MyAuctionsImpl extends MyAuctions {
  _MyAuctionsImpl({
    required List<_itazwe3y.MyAuction> auctions,
    required DateTime serverNow,
  }) : super._(auctions: auctions, serverNow: serverNow);

  /// Returns a shallow copy of this [MyAuctions]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  MyAuctions copyWith({
    List<_itazwe3y.MyAuction>? auctions,
    DateTime? serverNow,
  }) {
    return MyAuctions(
      auctions: auctions ?? this.auctions.map((e0) => e0.copyWith()).toList(),
      serverNow: serverNow ?? this.serverNow,
    );
  }
}
