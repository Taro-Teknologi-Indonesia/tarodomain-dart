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
import 'package:gavel_client/src/protocol/board_snapshot.dart' as _icq9digg;
import 'package:gavel_client/src/protocol/created_auction.dart' as _ivm7o2d2;
import 'package:gavel_client/src/protocol/join_result.dart' as _igr184mp;
import 'package:gavel_client/src/protocol/live_update.dart' as _i9po14mf;
import 'package:gavel_client/src/protocol/lot_card.dart' as _ik2e60uo;
import 'package:gavel_client/src/protocol/new_lot.dart' as _iw77avg8;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:tarodomain_serverpod_client/tarodomain_serverpod_client.dart'
    as _ispsicqs;
import 'protocol.dart' as _il2as5qe;

/// Creating, reading and joining auctions.
/// {@category Endpoint}
class EndpointAuction extends _isc.EndpointRef {
  EndpointAuction(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auction';

  /// Creates an auction called [title] that closes at [closeAt], truncated
  /// to the second, and schedules its close.
  ///
  /// The returned organizer key is sent only this once.
  _ida.Future<_ivm7o2d2.CreatedAuction> create(
    String title,
    DateTime closeAt,
  ) => caller.callServerEndpoint<_ivm7o2d2.CreatedAuction>(
    'auction',
    'create',
    {'title': title, 'closeAt': closeAt},
  );

  /// The auction with join [code] and its lots, with the server's clock.
  ///
  /// Throws `AUCTION_NOT_FOUND` if no auction has the code.
  _ida.Future<_icq9digg.BoardSnapshot> board(String code) =>
      caller.callServerEndpoint<_icq9digg.BoardSnapshot>('auction', 'board', {
        'code': code,
      });

  /// Joins the auction with join [code] as [displayName].
  ///
  /// Works on a closed auction too: the record outlives the event, and the
  /// client renders it read-only. The returned participant key is sent
  /// only this once.
  ///
  /// Throws `AUCTION_NOT_FOUND` for an unknown code and
  /// `COMMAND_VALIDATION` on `displayName` for a bad name.
  _ida.Future<_igr184mp.JoinResult> join(String code, String displayName) =>
      caller.callServerEndpoint<_igr184mp.JoinResult>('auction', 'join', {
        'code': code,
        'displayName': displayName,
      });

  /// Whether [participantId] joined the auction with join [code] and
  /// [participantKey] is their key: the client's check of the identity it
  /// kept.
  _ida.Future<bool> checkParticipant(
    String code,
    _isc.UuidValue participantId,
    String participantKey,
  ) => caller.callServerEndpoint<bool>('auction', 'checkParticipant', {
    'code': code,
    'participantId': participantId,
    'participantKey': participantKey,
  });
}

/// Live updates of one auction, pushed to every subscribed browser.
/// {@category Endpoint}
class EndpointLive extends _isc.EndpointRef {
  EndpointLive(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'live';

  /// Streams every [LiveUpdate] of the auction with join [code] until the
  /// client disconnects.
  _ida.Stream<_i9po14mf.LiveUpdate> watch(String code) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i9po14mf.LiveUpdate>,
        _i9po14mf.LiveUpdate
      >('live', 'watch', {'code': code}, {});

  /// Posts a `ping` to the auction with join [code], to check that every
  /// watcher gets it. Development mode only.
  _ida.Future<void> ping(String code) =>
      caller.callServerEndpoint<void>('live', 'ping', {'code': code});
}

/// Adding lots and bidding on them.
/// {@category Endpoint}
class EndpointLot extends _isc.EndpointRef {
  EndpointLot(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'lot';

  /// Adds [lot] to the auction with join [code] and returns its card.
  ///
  /// Throws `AUCTION_NOT_FOUND` for an unknown code, `NOT_ORGANIZER` for a
  /// wrong [organizerKey], `LOT_CLOSED` once the auction has closed, and
  /// `COMMAND_VALIDATION` with the offending `field` for a bad lot.
  _ida.Future<_ik2e60uo.LotCard> add(
    String code,
    String organizerKey,
    _iw77avg8.NewLot lot,
  ) => caller.callServerEndpoint<_ik2e60uo.LotCard>('lot', 'add', {
    'code': code,
    'organizerKey': organizerKey,
    'lot': lot,
  });

  /// Bids [amount] on the lot [lotId] as [participantId], who saw the lot
  /// at [expectedVersion], and returns the lot's fresh card.
  ///
  /// [commandId] comes from the client, so a resend after a lost answer
  /// places no second bid. The bid's time is the server's.
  ///
  /// Throws `NOT_PARTICIPANT` unless [participantKey] is the key of a
  /// participant of the lot's auction, `LOT_CLOSED` at or after the close,
  /// `OUTBID` with the leader if the lot changed since [expectedVersion],
  /// `INVALID_INCREMENT` for a raise off the ladder, and
  /// `AGGREGATE_NOT_FOUND` for an unknown lot. Nothing is stored on any of
  /// them.
  _ida.Future<_ik2e60uo.LotCard> placeBid(
    _isc.UuidValue lotId,
    _isc.UuidValue participantId,
    String participantKey,
    int amount,
    int expectedVersion,
    _isc.UuidValue commandId,
  ) => caller.callServerEndpoint<_ik2e60uo.LotCard>('lot', 'placeBid', {
    'lotId': lotId,
    'participantId': participantId,
    'participantKey': participantKey,
    'amount': amount,
    'expectedVersion': expectedVersion,
    'commandId': commandId,
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
    auction = EndpointAuction(this);
    live = EndpointLive(this);
    lot = EndpointLot(this);
    modules = Modules(this);
  }

  late final EndpointAuction auction;

  late final EndpointLive live;

  late final EndpointLot lot;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'auction': auction,
    'live': live,
    'lot': lot,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'tarodomain_serverpod': modules.tarodomain_serverpod,
  };
}
