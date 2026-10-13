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

/// One account's balance: the read model of `BalanceTableProjection`.
abstract class AccountBalance
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  AccountBalance._({
    this.id,
    required this.accountId,
    required this.owner,
    required this.balanceCents,
    required this.rejectedWithdrawals,
  });

  factory AccountBalance({
    int? id,
    required _isc.UuidValue accountId,
    required String owner,
    required int balanceCents,
    required int rejectedWithdrawals,
  }) = _AccountBalanceImpl;

  factory AccountBalance.fromJson(Map<String, dynamic> jsonSerialization) {
    return AccountBalance(
      id: jsonSerialization['id'] as int?,
      accountId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['accountId'],
      ),
      owner: jsonSerialization['owner'] as String,
      balanceCents: jsonSerialization['balanceCents'] as int,
      rejectedWithdrawals: jsonSerialization['rejectedWithdrawals'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The account.
  _isc.UuidValue accountId;

  /// The account holder.
  String owner;

  /// The balance, in cents.
  int balanceCents;

  /// How many withdrawals were rejected.
  int rejectedWithdrawals;

  /// Returns a shallow copy of this [AccountBalance]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  AccountBalance copyWith({
    int? id,
    _isc.UuidValue? accountId,
    String? owner,
    int? balanceCents,
    int? rejectedWithdrawals,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AccountBalance',
      if (id != null) 'id': id,
      'accountId': accountId.toJson(),
      'owner': owner,
      'balanceCents': balanceCents,
      'rejectedWithdrawals': rejectedWithdrawals,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AccountBalance',
      if (id != null) 'id': id,
      'accountId': accountId.toJson(),
      'owner': owner,
      'balanceCents': balanceCents,
      'rejectedWithdrawals': rejectedWithdrawals,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AccountBalanceImpl extends AccountBalance {
  _AccountBalanceImpl({
    int? id,
    required _isc.UuidValue accountId,
    required String owner,
    required int balanceCents,
    required int rejectedWithdrawals,
  }) : super._(
         id: id,
         accountId: accountId,
         owner: owner,
         balanceCents: balanceCents,
         rejectedWithdrawals: rejectedWithdrawals,
       );

  /// Returns a shallow copy of this [AccountBalance]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  AccountBalance copyWith({
    Object? id = _Undefined,
    _isc.UuidValue? accountId,
    String? owner,
    int? balanceCents,
    int? rejectedWithdrawals,
  }) {
    return AccountBalance(
      id: id is int? ? id : this.id,
      accountId: accountId ?? this.accountId,
      owner: owner ?? this.owner,
      balanceCents: balanceCents ?? this.balanceCents,
      rejectedWithdrawals: rejectedWithdrawals ?? this.rejectedWithdrawals,
    );
  }
}
