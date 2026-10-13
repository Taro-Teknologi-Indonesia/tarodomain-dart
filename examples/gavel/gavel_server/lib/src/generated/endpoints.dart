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
import 'package:gavel_server/src/generated/new_lot.dart' as _ipyv8n10;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    as _i13if8es;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/refresh_jwt_tokens_endpoint.dart' as _ih79u0oj;
import '../endpoints/auction_endpoint.dart' as _iyn8i9y2;
import '../endpoints/live_endpoint.dart' as _ixgr9pqx;
import '../endpoints/lot_endpoint.dart' as _i6hhfich;
import '../endpoints/organizer_endpoint.dart' as _iqabi5q3;
export 'future_calls.dart' show ServerpodFutureCallsGetter;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'emailIdp': _iuc1hd5t.EmailIdpEndpoint()
        ..initialize(server, 'emailIdp', null),
      'refreshJwtTokens': _ih79u0oj.RefreshJwtTokensEndpoint()
        ..initialize(server, 'refreshJwtTokens', null),
      'auction': _iyn8i9y2.AuctionEndpoint()
        ..initialize(server, 'auction', null),
      'live': _ixgr9pqx.LiveEndpoint()..initialize(server, 'live', null),
      'lot': _i6hhfich.LotEndpoint()..initialize(server, 'lot', null),
      'organizer': _iqabi5q3.OrganizerEndpoint()
        ..initialize(server, 'organizer', null),
    };
    connectors['emailIdp'] = _is.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
              ),
        ),
        'startRegistration': _is.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startRegistration(session, email: params['email']),
        ),
        'verifyRegistrationCode': _is.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _is.ParameterDescription(
              name: 'accountRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _is.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _is.ParameterDescription(
              name: 'registrationToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _is.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startPasswordReset(session, email: params['email']),
        ),
        'verifyPasswordResetCode': _is.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _is.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _is.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _is.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'newPassword': _is.ParameterDescription(
              name: 'newPassword',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint).hasAccount(
                session,
              ),
        ),
      },
    );
    connectors['refreshJwtTokens'] = _is.EndpointConnector(
      name: 'refreshJwtTokens',
      endpoint: endpoints['refreshJwtTokens']!,
      methodConnectors: {
        'refreshAccessToken': _is.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _is.ParameterDescription(
              name: 'refreshToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['refreshJwtTokens']
                      as _ih79u0oj.RefreshJwtTokensEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['auction'] = _is.EndpointConnector(
      name: 'auction',
      endpoint: endpoints['auction']!,
      methodConnectors: {
        'currentDemo': _is.MethodConnector(
          name: 'currentDemo',
          params: {},
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['auction'] as _iyn8i9y2.AuctionEndpoint).currentDemo(
                session,
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
        'join': _is.MethodConnector(
          name: 'join',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'displayName': _is.ParameterDescription(
              name: 'displayName',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['auction'] as _iyn8i9y2.AuctionEndpoint).join(
                session,
                params['code'],
                params['displayName'],
              ),
        ),
        'checkParticipant': _is.MethodConnector(
          name: 'checkParticipant',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'participantId': _is.ParameterDescription(
              name: 'participantId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'participantKey': _is.ParameterDescription(
              name: 'participantKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['auction'] as _iyn8i9y2.AuctionEndpoint)
                  .checkParticipant(
                    session,
                    params['code'],
                    params['participantId'],
                    params['participantKey'],
                  ),
        ),
        'winnerCodes': _is.MethodConnector(
          name: 'winnerCodes',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'organizerKey': _is.ParameterDescription(
              name: 'organizerKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['auction'] as _iyn8i9y2.AuctionEndpoint).winnerCodes(
                session,
                params['code'],
                params['organizerKey'],
              ),
        ),
      },
    );
    connectors['live'] = _is.EndpointConnector(
      name: 'live',
      endpoint: endpoints['live']!,
      methodConnectors: {
        'ping': _is.MethodConnector(
          name: 'ping',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['live'] as _ixgr9pqx.LiveEndpoint).ping(
                session,
                params['code'],
              ),
        ),
        'watch': _is.MethodStreamConnector(
          name: 'watch',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['live'] as _ixgr9pqx.LiveEndpoint).watch(
                session,
                params['code'],
              ),
        ),
      },
    );
    connectors['lot'] = _is.EndpointConnector(
      name: 'lot',
      endpoint: endpoints['lot']!,
      methodConnectors: {
        'add': _is.MethodConnector(
          name: 'add',
          params: {
            'code': _is.ParameterDescription(
              name: 'code',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'organizerKey': _is.ParameterDescription(
              name: 'organizerKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'lot': _is.ParameterDescription(
              name: 'lot',
              type: _is.getType<_ipyv8n10.NewLot>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['lot'] as _i6hhfich.LotEndpoint).add(
                session,
                params['code'],
                params['organizerKey'],
                params['lot'],
              ),
        ),
        'placeBid': _is.MethodConnector(
          name: 'placeBid',
          params: {
            'lotId': _is.ParameterDescription(
              name: 'lotId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'participantId': _is.ParameterDescription(
              name: 'participantId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'participantKey': _is.ParameterDescription(
              name: 'participantKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'amount': _is.ParameterDescription(
              name: 'amount',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'expectedVersion': _is.ParameterDescription(
              name: 'expectedVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'commandId': _is.ParameterDescription(
              name: 'commandId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['lot'] as _i6hhfich.LotEndpoint).placeBid(
                session,
                params['lotId'],
                params['participantId'],
                params['participantKey'],
                params['amount'],
                params['expectedVersion'],
                params['commandId'],
              ),
        ),
        'buyNow': _is.MethodConnector(
          name: 'buyNow',
          params: {
            'lotId': _is.ParameterDescription(
              name: 'lotId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'participantId': _is.ParameterDescription(
              name: 'participantId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'participantKey': _is.ParameterDescription(
              name: 'participantKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedVersion': _is.ParameterDescription(
              name: 'expectedVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'commandId': _is.ParameterDescription(
              name: 'commandId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['lot'] as _i6hhfich.LotEndpoint).buyNow(
                session,
                params['lotId'],
                params['participantId'],
                params['participantKey'],
                params['expectedVersion'],
                params['commandId'],
              ),
        ),
        'retractBid': _is.MethodConnector(
          name: 'retractBid',
          params: {
            'lotId': _is.ParameterDescription(
              name: 'lotId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'participantId': _is.ParameterDescription(
              name: 'participantId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'participantKey': _is.ParameterDescription(
              name: 'participantKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'expectedVersion': _is.ParameterDescription(
              name: 'expectedVersion',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'commandId': _is.ParameterDescription(
              name: 'commandId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['lot'] as _i6hhfich.LotEndpoint).retractBid(
                session,
                params['lotId'],
                params['participantId'],
                params['participantKey'],
                params['expectedVersion'],
                params['commandId'],
              ),
        ),
        'markUnpaid': _is.MethodConnector(
          name: 'markUnpaid',
          params: {
            'lotId': _is.ParameterDescription(
              name: 'lotId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'organizerKey': _is.ParameterDescription(
              name: 'organizerKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'note': _is.ParameterDescription(
              name: 'note',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['lot'] as _i6hhfich.LotEndpoint).markUnpaid(
                session,
                params['lotId'],
                params['organizerKey'],
                params['note'],
              ),
        ),
        'detail': _is.MethodConnector(
          name: 'detail',
          params: {
            'lotId': _is.ParameterDescription(
              name: 'lotId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['lot'] as _i6hhfich.LotEndpoint).detail(
                session,
                params['lotId'],
              ),
        ),
        'winnerCode': _is.MethodConnector(
          name: 'winnerCode',
          params: {
            'lotId': _is.ParameterDescription(
              name: 'lotId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'participantId': _is.ParameterDescription(
              name: 'participantId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'participantKey': _is.ParameterDescription(
              name: 'participantKey',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['lot'] as _i6hhfich.LotEndpoint).winnerCode(
                session,
                params['lotId'],
                params['participantId'],
                params['participantKey'],
              ),
        ),
        'asOf': _is.MethodConnector(
          name: 'asOf',
          params: {
            'lotId': _is.ParameterDescription(
              name: 'lotId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'at': _is.ParameterDescription(
              name: 'at',
              type: _is.getType<DateTime>(),
              nullable: false,
            ),
          },
          call: (_is.Session session, Map<String, dynamic> params) async =>
              (endpoints['lot'] as _i6hhfich.LotEndpoint).asOf(
                session,
                params['lotId'],
                params['at'],
              ),
        ),
      },
    );
    connectors['organizer'] = _is.EndpointConnector(
      name: 'organizer',
      endpoint: endpoints['organizer']!,
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
              (endpoints['organizer'] as _iqabi5q3.OrganizerEndpoint).create(
                session,
                params['title'],
                params['closeAt'],
              ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeEndpoints(server);
    modules['tarodomain_serverpod'] = _i13if8es.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeEndpoints(server);
  }

  @override
  _is.FutureCallDispatch? get futureCalls {
    return _ixqh6y26.FutureCalls();
  }
}
