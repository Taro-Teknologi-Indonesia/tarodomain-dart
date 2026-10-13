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

/// What `AuctionEndpoint.join` returns to a new bidder.
abstract class JoinResult
    implements _is.SerializableModel, _is.ProtocolSerialization {
  JoinResult._({
    required this.participantId,
    required this.participantKey,
    required this.displayName,
    required this.auction,
  });

  factory JoinResult({
    required _is.UuidValue participantId,
    required String participantKey,
    required String displayName,
    required _iwrduo5z.AuctionView auction,
  }) = _JoinResultImpl;

  factory JoinResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return JoinResult(
      participantId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['participantId'],
      ),
      participantKey: jsonSerialization['participantKey'] as String,
      displayName: jsonSerialization['displayName'] as String,
      auction: _imkuj2yl.Protocol().deserialize<_iwrduo5z.AuctionView>(
        jsonSerialization['auction'],
      ),
    );
  }

  /// The new participant. Public: it appears on lot cards and the ledger.
  _is.UuidValue participantId;

  /// The participant's secret. The server keeps only its hash, so this is
  /// the one time it is sent.
  String participantKey;

  /// The name shown to the other bidders, trimmed.
  String displayName;

  /// The auction joined.
  _iwrduo5z.AuctionView auction;

  /// Returns a shallow copy of this [JoinResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  JoinResult copyWith({
    _is.UuidValue? participantId,
    String? participantKey,
    String? displayName,
    _iwrduo5z.AuctionView? auction,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'JoinResult',
      'participantId': participantId.toJson(),
      'participantKey': participantKey,
      'displayName': displayName,
      'auction': auction.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'JoinResult',
      'participantId': participantId.toJson(),
      'participantKey': participantKey,
      'displayName': displayName,
      'auction': auction.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _JoinResultImpl extends JoinResult {
  _JoinResultImpl({
    required _is.UuidValue participantId,
    required String participantKey,
    required String displayName,
    required _iwrduo5z.AuctionView auction,
  }) : super._(
         participantId: participantId,
         participantKey: participantKey,
         displayName: displayName,
         auction: auction,
       );

  /// Returns a shallow copy of this [JoinResult]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  JoinResult copyWith({
    _is.UuidValue? participantId,
    String? participantKey,
    String? displayName,
    _iwrduo5z.AuctionView? auction,
  }) {
    return JoinResult(
      participantId: participantId ?? this.participantId,
      participantKey: participantKey ?? this.participantKey,
      displayName: displayName ?? this.displayName,
      auction: auction ?? this.auction.copyWith(),
    );
  }
}
