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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// One lot as it stood at a past moment (UC-10), rebuilt by replaying the
/// lot's events up to then.
abstract class LotAsOf
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LotAsOf._({
    required this.at,
    required this.price,
    this.leaderId,
    this.leaderName,
    required this.status,
    required this.bidCount,
    required this.retractedCount,
    required this.lastSequence,
    required this.version,
  });

  factory LotAsOf({
    required DateTime at,
    required int price,
    _isc.UuidValue? leaderId,
    String? leaderName,
    required String status,
    required int bidCount,
    required int retractedCount,
    required int lastSequence,
    required int version,
  }) = _LotAsOfImpl;

  factory LotAsOf.fromJson(Map<String, dynamic> jsonSerialization) {
    return LotAsOf(
      at: _isc.DateTimeJsonExtension.fromJson(jsonSerialization['at']),
      price: jsonSerialization['price'] as int,
      leaderId: jsonSerialization['leaderId'] == null
          ? null
          : _isc.UuidValueJsonExtension.fromJson(jsonSerialization['leaderId']),
      leaderName: jsonSerialization['leaderName'] as String?,
      status: jsonSerialization['status'] as String,
      bidCount: jsonSerialization['bidCount'] as int,
      retractedCount: jsonSerialization['retractedCount'] as int,
      lastSequence: jsonSerialization['lastSequence'] as int,
      version: jsonSerialization['version'] as int,
    );
  }

  /// The moment asked about, in UTC.
  DateTime at;

  /// The leading bid then, or the open bid while there was none.
  int price;

  /// The leading bidder then, if any.
  _isc.UuidValue? leaderId;

  /// The leading bidder's display name then, if any.
  String? leaderName;

  /// OPEN, SOLD or PASSED, as of then.
  String status;

  /// How many bids had been placed, retracted ones included.
  int bidCount;

  /// How many of them had been taken back.
  int retractedCount;

  /// The latest bid's place in the ledger, or 0 before the first bid.
  int lastSequence;

  /// How many of the lot's events the replay applied.
  int version;

  /// Returns a shallow copy of this [LotAsOf]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LotAsOf copyWith({
    DateTime? at,
    int? price,
    _isc.UuidValue? leaderId,
    String? leaderName,
    String? status,
    int? bidCount,
    int? retractedCount,
    int? lastSequence,
    int? version,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LotAsOf',
      'at': at.toJson(),
      'price': price,
      if (leaderId != null) 'leaderId': leaderId?.toJson(),
      if (leaderName != null) 'leaderName': leaderName,
      'status': status,
      'bidCount': bidCount,
      'retractedCount': retractedCount,
      'lastSequence': lastSequence,
      'version': version,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LotAsOf',
      'at': at.toJson(),
      'price': price,
      if (leaderId != null) 'leaderId': leaderId?.toJson(),
      if (leaderName != null) 'leaderName': leaderName,
      'status': status,
      'bidCount': bidCount,
      'retractedCount': retractedCount,
      'lastSequence': lastSequence,
      'version': version,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LotAsOfImpl extends LotAsOf {
  _LotAsOfImpl({
    required DateTime at,
    required int price,
    _isc.UuidValue? leaderId,
    String? leaderName,
    required String status,
    required int bidCount,
    required int retractedCount,
    required int lastSequence,
    required int version,
  }) : super._(
         at: at,
         price: price,
         leaderId: leaderId,
         leaderName: leaderName,
         status: status,
         bidCount: bidCount,
         retractedCount: retractedCount,
         lastSequence: lastSequence,
         version: version,
       );

  /// Returns a shallow copy of this [LotAsOf]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LotAsOf copyWith({
    DateTime? at,
    int? price,
    Object? leaderId = _Undefined,
    Object? leaderName = _Undefined,
    String? status,
    int? bidCount,
    int? retractedCount,
    int? lastSequence,
    int? version,
  }) {
    return LotAsOf(
      at: at ?? this.at,
      price: price ?? this.price,
      leaderId: leaderId is _isc.UuidValue? ? leaderId : this.leaderId,
      leaderName: leaderName is String? ? leaderName : this.leaderName,
      status: status ?? this.status,
      bidCount: bidCount ?? this.bidCount,
      retractedCount: retractedCount ?? this.retractedCount,
      lastSequence: lastSequence ?? this.lastSequence,
      version: version ?? this.version,
    );
  }
}
