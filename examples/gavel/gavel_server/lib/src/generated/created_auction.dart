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
import 'package:serverpod/serverpod.dart' as _is;

/// What `AuctionEndpoint.create` returns to the organizer.
abstract class CreatedAuction
    implements _is.SerializableModel, _is.ProtocolSerialization {
  CreatedAuction._({
    required this.code,
    required this.auctionId,
    required this.organizerKey,
    required this.closeAt,
    required this.serverNow,
  });

  factory CreatedAuction({
    required String code,
    required _is.UuidValue auctionId,
    required String organizerKey,
    required DateTime closeAt,
    required DateTime serverNow,
  }) = _CreatedAuctionImpl;

  factory CreatedAuction.fromJson(Map<String, dynamic> jsonSerialization) {
    return CreatedAuction(
      code: jsonSerialization['code'] as String,
      auctionId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['auctionId'],
      ),
      organizerKey: jsonSerialization['organizerKey'] as String,
      closeAt: _is.DateTimeJsonExtension.fromJson(jsonSerialization['closeAt']),
      serverNow: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['serverNow'],
      ),
    );
  }

  /// The join code in the share link.
  String code;

  /// The new auction.
  _is.UuidValue auctionId;

  /// The organizer's secret. The server keeps only its hash, so this is
  /// the one time it is sent.
  String organizerKey;

  /// When the auction closes, in UTC.
  DateTime closeAt;

  /// The server's clock when it answered, for the client's clock offset.
  DateTime serverNow;

  /// Returns a shallow copy of this [CreatedAuction]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  CreatedAuction copyWith({
    String? code,
    _is.UuidValue? auctionId,
    String? organizerKey,
    DateTime? closeAt,
    DateTime? serverNow,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'CreatedAuction',
      'code': code,
      'auctionId': auctionId.toJson(),
      'organizerKey': organizerKey,
      'closeAt': closeAt.toJson(),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'CreatedAuction',
      'code': code,
      'auctionId': auctionId.toJson(),
      'organizerKey': organizerKey,
      'closeAt': closeAt.toJson(),
      'serverNow': serverNow.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _CreatedAuctionImpl extends CreatedAuction {
  _CreatedAuctionImpl({
    required String code,
    required _is.UuidValue auctionId,
    required String organizerKey,
    required DateTime closeAt,
    required DateTime serverNow,
  }) : super._(
         code: code,
         auctionId: auctionId,
         organizerKey: organizerKey,
         closeAt: closeAt,
         serverNow: serverNow,
       );

  /// Returns a shallow copy of this [CreatedAuction]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  CreatedAuction copyWith({
    String? code,
    _is.UuidValue? auctionId,
    String? organizerKey,
    DateTime? closeAt,
    DateTime? serverNow,
  }) {
    return CreatedAuction(
      code: code ?? this.code,
      auctionId: auctionId ?? this.auctionId,
      organizerKey: organizerKey ?? this.organizerKey,
      closeAt: closeAt ?? this.closeAt,
      serverNow: serverNow ?? this.serverNow,
    );
  }
}
