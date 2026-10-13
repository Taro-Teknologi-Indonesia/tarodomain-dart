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
import 'package:gavel_server/src/generated/future_calls.dart' as _ixqh6y26;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    as _i13if8es;
import '../endpoints/auction_endpoint.dart' as _iyn8i9y2;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'auction': _iyn8i9y2.AuctionEndpoint()
        ..initialize(server, 'auction', null),
    };
    connectors['auction'] = _is.EndpointConnector(
      name: 'auction',
      endpoint: endpoints['auction']!,
      methodConnectors: {
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'title': _is.ParameterDescription(
              name: 'title',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'closeAt': _is.ParameterDescription(
              name: 'closeAt',
              type: _is.getType<DateTime>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['auction'] as _iyn8i9y2.AuctionEndpoint).create(
                session,
                params['title'],
                params['closeAt'],
              ),
        ),
        'board': _is.MethodConnector(
          name: 'board',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['auction'] as _iyn8i9y2.AuctionEndpoint).board(
                session,
                params['code'],
              ),
        ),
      },
    );
    modules['tarodomain_serverpod'] = _i13if8es.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _is.FutureCallDispatch? get futureCalls {
    return _ixqh6y26.FutureCalls();
  }
}
