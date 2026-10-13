import 'dart:convert';
import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Protocol;

import '../domain/auction.dart';
import '../domain/auction_commands.dart';
import '../domain/keys.dart';
import '../generated/future_calls.dart';
import '../generated/protocol.dart';

final _random = Random.secure();

const _codeAttempts = 3;

/// Creates an auction called [title] that closes at [closeAt], truncated
/// to the second, through `CreateAuction`, and schedules its close.
///
/// [now] is the command's timestamp, for the close-time check; tests pin
/// it. Only the demo job sets [isDemo]. [organizerUserId] is the signed-in
/// creator (X6), null for the demo. The returned organizer key is sent
/// only this once.
Future<CreatedAuction> createAuction(
  Session session, {
  required String title,
  required DateTime closeAt,
  bool isDemo = false,
  String? organizerUserId,
  DateTime? now,
}) async {
  final auctionId = AuctionId.generate();
  final organizerKey = newSecret();
  // Whole seconds, so the event, the read model, the future call and the
  // response all hold the same instant.
  final utcCloseAt = _toSecond(closeAt.toUtc());

  final code = await _createWithFreshCode(
    session,
    (code) => CreateAuction(
      auctionId,
      title: title,
      closeAt: utcCloseAt,
      code: code,
      organizerKeyHash: hashKey(organizerKey),
      isDemo: isDemo,
      organizerUserId: organizerUserId,
      timestamp: now,
    ),
  );

  // After the commit: the sweep closes the auction if the server stops
  // between the two, and is the only trigger where future calls are
  // disabled.
  if (session.serverpod.config.futureCall.enabled) {
    await session.serverpod.futureCalls
        .callAtTime(utcCloseAt, identifier: 'close-${auctionId.uuid}')
        .auctionCloseCalls
        .close(auctionId.value);
  }

  return CreatedAuction(
    code: code,
    auctionId: auctionId.value,
    organizerKey: organizerKey,
    closeAt: utcCloseAt,
    serverNow: DateTime.now().toUtc(),
  );
}

/// 32 random bytes, base64url without padding.
String newSecret() => base64Url
    .encode([for (var i = 0; i < 32; i++) _random.nextInt(256)])
    .replaceAll('=', '');

/// Dispatches [command] with a new random join code, again with another
/// one if the code is taken, and returns the code that was used.
///
/// A taken code fails the projection's insert, which rolls the command
/// back; any other failure is rethrown.
Future<String> _createWithFreshCode(
  Session session,
  CreateAuction Function(String code) command,
) async {
  for (var attempt = 1; ; attempt++) {
    final code = _joinCode();
    try {
      await TaroDomainServerpod.instance.dispatch(session, command(code));
      return code;
    } on TaroDomainException catch (e) {
      final taken =
          e.code == 'PROJECTION_HANDLER_FAILED' &&
          await AuctionView.db.count(
                session,
                where: (t) => t.code.equals(code),
              ) >
              0;
      if (!taken || attempt == _codeAttempts) rethrow;
    }
  }
}

DateTime _toSecond(DateTime t) =>
    DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second);

String _joinCode() => String.fromCharCodes([
  for (var i = 0; i < Auction.codeLength; i++)
    Auction.codeAlphabet.codeUnitAt(
      _random.nextInt(Auction.codeAlphabet.length),
    ),
]);
