import 'dart:convert';
import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../domain/auction.dart';
import '../domain/auction_commands.dart';
import '../domain/errors.dart';
import '../domain/keys.dart';
import '../generated/future_calls.dart';
import '../generated/protocol.dart';

/// Creating and reading auctions.
class AuctionEndpoint extends Endpoint {
  TaroDomainServerpod get _taro => TaroDomainServerpod.instance;

  static final _random = Random.secure();

  /// Join code characters: no 0/O, 1/I/L.
  static const _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const _codeLength = 6;
  static const _codeAttempts = 3;

  /// Creates an auction called [title] that closes at [closeAt], truncated
  /// to the second, and schedules its close.
  ///
  /// The returned organizer key is sent only this once.
  Future<CreatedAuction> create(
    Session session,
    String title,
    DateTime closeAt,
  ) async {
    final auctionId = AuctionId.generate();
    final organizerKey = _secret();
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

  /// The auction with join [code] and its lots, with the server's clock.
  ///
  /// Throws `AUCTION_NOT_FOUND` if no auction has the code.
  Future<BoardSnapshot> board(Session session, String code) =>
      rethrowAsTaroDomainException(() async {
        final normalized = code.trim().toUpperCase();
        final auction = await AuctionView.db.findFirstRow(
          session,
          where: (t) => t.code.equals(normalized),
        );
        if (auction == null) throw AuctionNotFoundError(normalized);
        final lots = await LotCard.db.find(
          session,
          where: (t) => t.code.equals(normalized),
          orderBy: (t) => t.position,
        );
        return BoardSnapshot(
          auction: auction,
          lots: lots,
          serverNow: DateTime.now().toUtc(),
        );
      });

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
        await _taro.dispatch(session, command(code));
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

  static DateTime _toSecond(DateTime t) =>
      DateTime.utc(t.year, t.month, t.day, t.hour, t.minute, t.second);

  static String _joinCode() => String.fromCharCodes([
    for (var i = 0; i < _codeLength; i++)
      _codeAlphabet.codeUnitAt(_random.nextInt(_codeAlphabet.length)),
  ]);

  /// 32 random bytes, base64url without padding.
  static String _secret() => base64Url
      .encode([for (var i = 0; i < 32; i++) _random.nextInt(256)])
      .replaceAll('=', '');
}
