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
import 'package:bank_account_serverpod_server/src/generated/future_calls.dart'
    as _i7eo08al;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    as _i13if8es;
import '../endpoints/bank_endpoint.dart' as _im7q42yu;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'bank': _im7q42yu.BankEndpoint()..initialize(server, 'bank', null),
    };
    connectors['bank'] = _is.EndpointConnector(
      name: 'bank',
      endpoint: endpoints['bank']!,
      methodConnectors: {
        'openAccount': _is.MethodConnector(
          name: 'openAccount',
          params: {
            'owner': _is.ParameterDescription(
              name: 'owner',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['bank'] as _im7q42yu.BankEndpoint).openAccount(
                session,
                params['owner'],
              ),
        ),
        'deposit': _is.MethodConnector(
          name: 'deposit',
          params: {
            'accountId': _is.ParameterDescription(
              name: 'accountId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'cents': _is.ParameterDescription(
              name: 'cents',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['bank'] as _im7q42yu.BankEndpoint).deposit(
                session,
                params['accountId'],
                params['cents'],
              ),
        ),
        'withdraw': _is.MethodConnector(
          name: 'withdraw',
          params: {
            'accountId': _is.ParameterDescription(
              name: 'accountId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'cents': _is.ParameterDescription(
              name: 'cents',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['bank'] as _im7q42yu.BankEndpoint).withdraw(
                session,
                params['accountId'],
                params['cents'],
              ),
        ),
        'transfer': _is.MethodConnector(
          name: 'transfer',
          params: {
            'from': _is.ParameterDescription(
              name: 'from',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'to': _is.ParameterDescription(
              name: 'to',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'cents': _is.ParameterDescription(
              name: 'cents',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['bank'] as _im7q42yu.BankEndpoint).transfer(
                session,
                params['from'],
                params['to'],
                params['cents'],
              ),
        ),
        'balance': _is.MethodConnector(
          name: 'balance',
          params: {
            'accountId': _is.ParameterDescription(
              name: 'accountId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['bank'] as _im7q42yu.BankEndpoint).balance(
                session,
                params['accountId'],
              ),
        ),
        'registerHolder': _is.MethodConnector(
          name: 'registerHolder',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['bank'] as _im7q42yu.BankEndpoint).registerHolder(
                session,
                params['name'],
                params['email'],
              ),
        ),
        'changeHolderEmail': _is.MethodConnector(
          name: 'changeHolderEmail',
          params: {
            'holderId': _is.ParameterDescription(
              name: 'holderId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['bank'] as _im7q42yu.BankEndpoint).changeHolderEmail(
                session,
                params['holderId'],
                params['email'],
              ),
        ),
      },
    );
    modules['tarodomain_serverpod'] = _i13if8es.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _is.FutureCallDispatch? get futureCalls {
    return _i7eo08al.FutureCalls();
  }
}
