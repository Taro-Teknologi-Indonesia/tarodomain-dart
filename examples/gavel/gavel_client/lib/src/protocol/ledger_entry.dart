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

/// One bid in a lot's ledger.
abstract class LedgerEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  LedgerEntry._({
    this.id,
    required this.lotId,
    required this.sequence,
    required this.participantId,
    required this.bidderName,
    required this.amount,
    required this.placedAt,
    required this.retracted,
    this.retractedAt,
    bool? buyNow,
  }) : buyNow = buyNow ?? false;

  factory LedgerEntry({
    int? id,
    required _isc.UuidValue lotId,
    required int sequence,
    required _isc.UuidValue participantId,
    required String bidderName,
    required int amount,
    required DateTime placedAt,
    required bool retracted,
    DateTime? retractedAt,
    bool? buyNow,
  }) = _LedgerEntryImpl;

  factory LedgerEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return LedgerEntry(
      id: jsonSerialization['id'] as int?,
      lotId: _isc.UuidValueJsonExtension.fromJson(jsonSerialization['lotId']),
      sequence: jsonSerialization['sequence'] as int,
      participantId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['participantId'],
      ),
      bidderName: jsonSerialization['bidderName'] as String,
      amount: jsonSerialization['amount'] as int,
      placedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['placedAt'],
      ),
      retracted: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['retracted'],
      ),
      retractedAt: jsonSerialization['retractedAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['retractedAt'],
            ),
      buyNow: jsonSerialization['buyNow'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['buyNow']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The lot bid on.
  _isc.UuidValue lotId;

  /// The bid's place in the lot's ledger, from 1.
  int sequence;

  /// Who bid.
  _isc.UuidValue participantId;

  /// The bidder's display name.
  String bidderName;

  /// The bid, in rupiah.
  int amount;

  /// When the bid was placed, in UTC.
  DateTime placedAt;

  /// Whether the bidder took the bid back.
  bool retracted;

  /// When the bid was taken back, in UTC.
  DateTime? retractedAt;

  /// Whether the bid paid the Buy Now price, closing the lot (UC-13).
  bool buyNow;

  /// Returns a shallow copy of this [LedgerEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  LedgerEntry copyWith({
    int? id,
    _isc.UuidValue? lotId,
    int? sequence,
    _isc.UuidValue? participantId,
    String? bidderName,
    int? amount,
    DateTime? placedAt,
    bool? retracted,
    DateTime? retractedAt,
    bool? buyNow,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LedgerEntry',
      if (id != null) 'id': id,
      'lotId': lotId.toJson(),
      'sequence': sequence,
      'participantId': participantId.toJson(),
      'bidderName': bidderName,
      'amount': amount,
      'placedAt': placedAt.toJson(),
      'retracted': retracted,
      if (retractedAt != null) 'retractedAt': retractedAt?.toJson(),
      'buyNow': buyNow,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LedgerEntry',
      if (id != null) 'id': id,
      'lotId': lotId.toJson(),
      'sequence': sequence,
      'participantId': participantId.toJson(),
      'bidderName': bidderName,
      'amount': amount,
      'placedAt': placedAt.toJson(),
      'retracted': retracted,
      if (retractedAt != null) 'retractedAt': retractedAt?.toJson(),
      'buyNow': buyNow,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LedgerEntryImpl extends LedgerEntry {
  _LedgerEntryImpl({
    int? id,
    required _isc.UuidValue lotId,
    required int sequence,
    required _isc.UuidValue participantId,
    required String bidderName,
    required int amount,
    required DateTime placedAt,
    required bool retracted,
    DateTime? retractedAt,
    bool? buyNow,
  }) : super._(
         id: id,
         lotId: lotId,
         sequence: sequence,
         participantId: participantId,
         bidderName: bidderName,
         amount: amount,
         placedAt: placedAt,
         retracted: retracted,
         retractedAt: retractedAt,
         buyNow: buyNow,
       );

  /// Returns a shallow copy of this [LedgerEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  LedgerEntry copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? lotId,
    int? sequence,
    _isc.UuidValue? participantId,
    String? bidderName,
    int? amount,
    DateTime? placedAt,
    bool? retracted,
    Object? retractedAt = _Undefined,
    bool? buyNow,
  }) {
    return LedgerEntry(
      id: id is int? ? id : this.id,
      lotId: lotId ?? this.lotId,
      sequence: sequence ?? this.sequence,
      participantId: participantId ?? this.participantId,
      bidderName: bidderName ?? this.bidderName,
      amount: amount ?? this.amount,
      placedAt: placedAt ?? this.placedAt,
      retracted: retracted ?? this.retracted,
      retractedAt: retractedAt is DateTime? ? retractedAt : this.retractedAt,
      buyNow: buyNow ?? this.buyNow,
    );
  }
}
