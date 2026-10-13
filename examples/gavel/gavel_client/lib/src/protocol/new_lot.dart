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

/// A lot as the organizer fills it in, sent to `LotEndpoint.add`.
abstract class NewLot
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  NewLot._({
    required this.name,
    required this.openBid,
    required this.increments,
    required this.description,
    this.imageUrl,
    required this.tileEmoji,
    required this.tileColor,
  });

  factory NewLot({
    required String name,
    required int openBid,
    required List<int> increments,
    required String description,
    String? imageUrl,
    required String tileEmoji,
    required String tileColor,
  }) = _NewLotImpl;

  factory NewLot.fromJson(Map<String, dynamic> jsonSerialization) {
    return NewLot(
      name: jsonSerialization['name'] as String,
      openBid: jsonSerialization['openBid'] as int,
      increments: _ivmqq51r.Protocol().deserialize<List<int>>(
        jsonSerialization['increments'],
      ),
      description: jsonSerialization['description'] as String,
      imageUrl: jsonSerialization['imageUrl'] as String?,
      tileEmoji: jsonSerialization['tileEmoji'] as String,
      tileColor: jsonSerialization['tileColor'] as String,
    );
  }

  /// The lot's name, 1 to 80 characters.
  String name;

  /// The first bid's minimum, in rupiah.
  int openBid;

  /// The allowed raises (kelipatan), in rupiah, in any order.
  List<int> increments;

  /// The seller's description, at most 2000 characters.
  String description;

  /// A photo of the lot, or null to show the tile.
  String? imageUrl;

  /// The tile's emoji.
  String tileEmoji;

  /// The tile's background, as `#RRGGBB`.
  String tileColor;

  /// Returns a shallow copy of this [NewLot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  NewLot copyWith({
    String? name,
    int? openBid,
    List<int>? increments,
    String? description,
    String? imageUrl,
    String? tileEmoji,
    String? tileColor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NewLot',
      'name': name,
      'openBid': openBid,
      'increments': increments.toJson(),
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'tileEmoji': tileEmoji,
      'tileColor': tileColor,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'NewLot',
      'name': name,
      'openBid': openBid,
      'increments': increments.toJson(),
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'tileEmoji': tileEmoji,
      'tileColor': tileColor,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _NewLotImpl extends NewLot {
  _NewLotImpl({
    required String name,
    required int openBid,
    required List<int> increments,
    required String description,
    String? imageUrl,
    required String tileEmoji,
    required String tileColor,
  }) : super._(
         name: name,
         openBid: openBid,
         increments: increments,
         description: description,
         imageUrl: imageUrl,
         tileEmoji: tileEmoji,
         tileColor: tileColor,
       );

  /// Returns a shallow copy of this [NewLot]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  NewLot copyWith({
    String? name,
    int? openBid,
    List<int>? increments,
    String? description,
    Object? imageUrl = _Undefined,
    String? tileEmoji,
    String? tileColor,
  }) {
    return NewLot(
      name: name ?? this.name,
      openBid: openBid ?? this.openBid,
      increments: increments ?? this.increments.map((e0) => e0).toList(),
      description: description ?? this.description,
      imageUrl: imageUrl is String? ? imageUrl : this.imageUrl,
      tileEmoji: tileEmoji ?? this.tileEmoji,
      tileColor: tileColor ?? this.tileColor,
    );
  }
}
