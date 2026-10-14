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
import 'package:gavel_client/src/protocol/lot_as_of.dart' as _inzqluk9;
import 'package:gavel_client/src/protocol/lot_card.dart' as _ik2e60uo;
import 'package:gavel_client/src/protocol/lot_detail.dart' as _izswfryi;
import 'package:gavel_client/src/protocol/my_auctions.dart' as _i5vumg4u;
import 'package:gavel_client/src/protocol/new_lot.dart' as _iw77avg8;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'package:tarodomain_serverpod_client/tarodomain_serverpod_client.dart'
    as _ispsicqs;
import 'protocol.dart' as _il2as5qe;

/// Email sign-up, sign-in and password reset for organizers (X6).
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>('emailIdp', 'login', {
    'email': email,
    'password': password,
  });

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) =>
      caller.callServerEndpoint<String>('emailIdp', 'verifyRegistrationCode', {
        'accountRequestId': accountRequestId,
        'verificationCode': verificationCode,
      });

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {'registrationToken': registrationToken, 'password': password},
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) =>
      caller.callServerEndpoint<String>('emailIdp', 'verifyPasswordResetCode', {
        'passwordResetRequestId': passwordResetRequestId,
        'verificationCode': verificationCode,
      });

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>('emailIdp', 'finishPasswordReset', {
    'finishPasswordResetToken': finishPasswordResetToken,
    'newPassword': newPassword,
  });

  @override
  _ida.Future<bool> hasAccount() =>
      caller.callServerEndpoint<bool>('emailIdp', 'hasAccount', {});
}

/// Renews the app's access token, so an organizer stays signed in.
/// {@category Endpoint}
class EndpointRefreshJwtTokens extends _iacc.EndpointRefreshJwtTokens {
  EndpointRefreshJwtTokens(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'refreshJwtTokens';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'refreshJwtTokens',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// Reading and joining auctions. Creating one needs a signed-in organizer,
/// so it lives on `OrganizerEndpoint` (X6).
/// {@category Endpoint}
class EndpointAuction extends _isc.EndpointRef {
  EndpointAuction(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auction';

  /// The join code of the open public demo auction (X2), opening one first
  /// if the demo job hasn't yet.
  _ida.Future<String> currentDemo() =>
      caller.callServerEndpoint<String>('auction', 'currentDemo', {});

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

  /// The winner code of every SOLD lot in the auction with join [code],
  /// by lot ID (UC-09), for the organizer to check a buyer's claim.
  ///
  /// A read: nothing is dispatched and the codes are never stored or
  /// logged.
  ///
  /// Throws `AUCTION_NOT_FOUND` for an unknown code and `NOT_ORGANIZER`
  /// for a wrong [organizerKey].
  _ida.Future<Map<String, String>> winnerCodes(
    String code,
    String organizerKey,
  ) => caller.callServerEndpoint<Map<String, String>>(
    'auction',
    'winnerCodes',
    {'code': code, 'organizerKey': organizerKey},
  );
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

  /// Buys the lot [lotId] at its Buy Now price as [participantId], who saw
  /// the lot at [expectedVersion], and returns the lot's fresh card, SOLD
  /// to them (UC-13). The price comes from the lot, never from the client.
  ///
  /// [commandId] comes from the client, so a resend buys once.
  ///
  /// Throws `NOT_PARTICIPANT` unless [participantKey] is the key of a
  /// participant of the lot's auction, `LOT_CLOSED` once the lot is sold
  /// or past its close, `COMMAND_VALIDATION` with reason `NO_BUY_NOW` for a
  /// lot with no BN price, `OUTBID` with the leader if the lot changed
  /// since [expectedVersion], `COMMAND_VALIDATION` with reason
  /// `BUY_NOW_PASSED` once bidding reached the BN price, and
  /// `AGGREGATE_NOT_FOUND` for an unknown lot. Nothing is stored on any of
  /// them.
  _ida.Future<_ik2e60uo.LotCard> buyNow(
    _isc.UuidValue lotId,
    _isc.UuidValue participantId,
    String participantKey,
    int expectedVersion,
    _isc.UuidValue commandId,
  ) => caller.callServerEndpoint<_ik2e60uo.LotCard>('lot', 'buyNow', {
    'lotId': lotId,
    'participantId': participantId,
    'participantKey': participantKey,
    'expectedVersion': expectedVersion,
    'commandId': commandId,
  });

  /// Takes back [participantId]'s bid on the lot [lotId], which must be
  /// the latest valid one, as seen at [expectedVersion], and returns the
  /// lot's fresh card. The bid stays in the ledger, struck through.
  ///
  /// [commandId] comes from the client, so a resend retracts once.
  ///
  /// Throws `NOT_PARTICIPANT` unless [participantKey] is the key of a
  /// participant of the lot's auction: the ledger shows every bidder's ID,
  /// so the ID alone proves nothing. Then `LOT_CLOSED` at or after the
  /// close, `RETRACT_NOT_ALLOWED` with `NO_BIDS` or `NOT_LATEST`, `OUTBID`
  /// if the lot changed since [expectedVersion], and `AGGREGATE_NOT_FOUND`
  /// for an unknown lot. Nothing is stored on any of them.
  _ida.Future<_ik2e60uo.LotCard> retractBid(
    _isc.UuidValue lotId,
    _isc.UuidValue participantId,
    String participantKey,
    int expectedVersion,
    _isc.UuidValue commandId,
  ) => caller.callServerEndpoint<_ik2e60uo.LotCard>('lot', 'retractBid', {
    'lotId': lotId,
    'participantId': participantId,
    'participantKey': participantKey,
    'expectedVersion': expectedVersion,
    'commandId': commandId,
  });

  /// Marks the SOLD lot [lotId]'s winner as not having paid, with an
  /// optional public [note] (UC-14), and returns the lot's fresh card. The
  /// sale stays; the mark is a new event after it. Marking twice is a
  /// no-op.
  ///
  /// Throws `NOT_ORGANIZER` for a wrong [organizerKey],
  /// `COMMAND_VALIDATION` with `NOT_SOLD` unless the lot is SOLD or
  /// `TOO_LONG` for a long note, and `AGGREGATE_NOT_FOUND` for an unknown
  /// lot.
  _ida.Future<_ik2e60uo.LotCard> markUnpaid(
    _isc.UuidValue lotId,
    String organizerKey,
    String? note,
  ) => caller.callServerEndpoint<_ik2e60uo.LotCard>('lot', 'markUnpaid', {
    'lotId': lotId,
    'organizerKey': organizerKey,
    'note': note,
  });

  /// The lot [lotId] with every bid on it, retracted ones included, in
  /// ledger order.
  ///
  /// Throws `AGGREGATE_NOT_FOUND` for an unknown lot.
  _ida.Future<_izswfryi.LotDetail> detail(_isc.UuidValue lotId) =>
      caller.callServerEndpoint<_izswfryi.LotDetail>('lot', 'detail', {
        'lotId': lotId,
      });

  /// [participantId]'s winner code for the lot [lotId] (UC-09), or null
  /// unless the lot is SOLD to them. The seller compares it before handing
  /// the lot over, so a namesake can't claim the win.
  ///
  /// A read: nothing is dispatched and the code is never stored or logged.
  ///
  /// Throws `NOT_PARTICIPANT` unless [participantKey] is the key of a
  /// participant of the lot's auction, and `AGGREGATE_NOT_FOUND` for an
  /// unknown lot.
  _ida.Future<String?> winnerCode(
    _isc.UuidValue lotId,
    _isc.UuidValue participantId,
    String participantKey,
  ) => caller.callServerEndpoint<String?>('lot', 'winnerCode', {
    'lotId': lotId,
    'participantId': participantId,
    'participantKey': participantKey,
  });

  /// The lot [lotId] as it stood at [at] (UC-10): its events up to [at]
  /// replayed through the [Lot] aggregate, not read from the projection.
  ///
  /// A read: nothing is dispatched or stored.
  ///
  /// Throws `AGGREGATE_NOT_FOUND` for an unknown lot, or one not yet
  /// created at [at].
  _ida.Future<_inzqluk9.LotAsOf> asOf(_isc.UuidValue lotId, DateTime at) =>
      caller.callServerEndpoint<_inzqluk9.LotAsOf>('lot', 'asOf', {
        'lotId': lotId,
        'at': at,
      });
}

/// What only a signed-in organizer can do (X6).
///
/// `requireLogin` covers the whole endpoint, so these calls live apart from
/// the public `AuctionEndpoint`. A call without a valid token gets 401
/// before the method runs.
/// {@category Endpoint}
class EndpointOrganizer extends _isc.EndpointRef {
  EndpointOrganizer(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'organizer';

  /// Creates an auction called [title] that closes at [closeAt], truncated
  /// to the second, schedules its close, and records the signed-in user
  /// as its creator.
  ///
  /// The returned organizer key is sent only this once.
  _ida.Future<_ivm7o2d2.CreatedAuction> create(
    String title,
    DateTime closeAt,
  ) => caller.callServerEndpoint<_ivm7o2d2.CreatedAuction>(
    'organizer',
    'create',
    {'title': title, 'closeAt': closeAt},
  );

  /// The signed-in organizer's auctions with their sales so far: running
  /// ones (OPEN or CLOSING) first, soonest close first, then closed ones,
  /// most recent close first.
  _ida.Future<_i5vumg4u.MyAuctions> myAuctions() => caller
      .callServerEndpoint<_i5vumg4u.MyAuctions>('organizer', 'myAuctions', {});
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    tarodomain_serverpod = _ispsicqs.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _ispsicqs.Caller tarodomain_serverpod;

  late final _iacc.Caller serverpod_auth_core;
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
    emailIdp = EndpointEmailIdp(this);
    refreshJwtTokens = EndpointRefreshJwtTokens(this);
    auction = EndpointAuction(this);
    live = EndpointLive(this);
    lot = EndpointLot(this);
    organizer = EndpointOrganizer(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointRefreshJwtTokens refreshJwtTokens;

  late final EndpointAuction auction;

  late final EndpointLive live;

  late final EndpointLot lot;

  late final EndpointOrganizer organizer;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'refreshJwtTokens': refreshJwtTokens,
    'auction': auction,
    'live': live,
    'lot': lot,
    'organizer': organizer,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'tarodomain_serverpod': modules.tarodomain_serverpod,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
