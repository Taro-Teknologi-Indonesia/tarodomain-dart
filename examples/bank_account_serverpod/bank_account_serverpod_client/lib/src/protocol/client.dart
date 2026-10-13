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
import 'dart:async' as _ida;
import 'package:bank_account_serverpod_client/src/protocol/account_balance.dart'
    as _iw6kixp1;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:tarodomain_serverpod_client/tarodomain_serverpod_client.dart'
    as _ispsicqs;
import 'protocol.dart' as _il2as5qe;

/// The bank's API. Each method dispatches one command on a runtime for the
/// request's session; a `FrameworkError` reaches the client as a
/// `TaroDomainException`.
/// {@category Endpoint}
class EndpointBank extends _isc.EndpointRef {
  EndpointBank(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'bank';

  /// Opens an account for [owner] and returns its ID.
  _ida.Future<_isc.UuidValue> openAccount(String owner) =>
      caller.callServerEndpoint<_isc.UuidValue>('bank', 'openAccount', {
        'owner': owner,
      });

  /// Pays [cents] into [accountId].
  _ida.Future<void> deposit(_isc.UuidValue accountId, int cents) =>
      caller.callServerEndpoint<void>('bank', 'deposit', {
        'accountId': accountId,
        'cents': cents,
      });

  /// Pays [cents] out of [accountId].
  _ida.Future<void> withdraw(_isc.UuidValue accountId, int cents) =>
      caller.callServerEndpoint<void>('bank', 'withdraw', {
        'accountId': accountId,
        'cents': cents,
      });

  /// Starts moving [cents] from [from] to [to] and returns the transfer ID.
  _ida.Future<_isc.UuidValue> transfer(
    _isc.UuidValue from,
    _isc.UuidValue to,
    int cents,
  ) => caller.callServerEndpoint<_isc.UuidValue>('bank', 'transfer', {
    'from': from,
    'to': to,
    'cents': cents,
  });

  /// The balance of [accountId] from the read model, or null.
  _ida.Future<_iw6kixp1.AccountBalance?> balance(_isc.UuidValue accountId) =>
      caller.callServerEndpoint<_iw6kixp1.AccountBalance?>('bank', 'balance', {
        'accountId': accountId,
      });

  /// Registers an account holder and returns their ID.
  _ida.Future<_isc.UuidValue> registerHolder(String name, String email) =>
      caller.callServerEndpoint<_isc.UuidValue>('bank', 'registerHolder', {
        'name': name,
        'email': email,
      });

  /// Changes a holder's email address.
  _ida.Future<void> changeHolderEmail(_isc.UuidValue holderId, String email) =>
      caller.callServerEndpoint<void>('bank', 'changeHolderEmail', {
        'holderId': holderId,
        'email': email,
      });
}

class Modules {
  Modules(Client client) {
    tarodomain_serverpod = _ispsicqs.Caller(client);
  }

  late final _ispsicqs.Caller tarodomain_serverpod;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(_isc.MethodCallContext, Object, StackTrace)? onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    bank = EndpointBank(this);
    modules = Modules(this);
  }

  late final EndpointBank bank;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {'bank': bank};

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'tarodomain_serverpod': modules.tarodomain_serverpod,
  };
}
