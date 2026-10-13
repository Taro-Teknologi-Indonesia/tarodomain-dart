import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../demo/demo_auctions.dart';
import '../domain/auction.dart';
import '../domain/errors.dart';
import '../domain/keys.dart';
import '../domain/participant.dart';
import '../domain/participant_commands.dart';
import '../generated/protocol.dart';
import '../infra/auction_creation.dart';
import '../infra/participant_guard.dart';

/// Creating, reading and joining auctions.
class AuctionEndpoint extends Endpoint {
  TaroDomainServerpod get _taro => TaroDomainServerpod.instance;

  /// Creates an auction called [title] that closes at [closeAt], truncated
  /// to the second, and schedules its close.
  ///
  /// The returned organizer key is sent only this once.
  Future<CreatedAuction> create(
    Session session,
    String title,
    DateTime closeAt,
  ) => createAuction(session, title: title, closeAt: closeAt);

  /// The join code of the open public demo auction (X2), opening one first
  /// if the demo job hasn't yet.
  Future<String> currentDemo(Session session) => currentDemoCode(session);

  /// The auction with join [code] and its lots, with the server's clock.
  ///
  /// Throws `AUCTION_NOT_FOUND` if no auction has the code.
  Future<BoardSnapshot> board(Session session, String code) =>
      rethrowAsTaroDomainException(() async {
        final auction = await findAuction(session, code);
        final lots = await LotCard.db.find(
          session,
          where: (t) => t.code.equals(auction.code),
          orderBy: (t) => t.position,
        );
        return BoardSnapshot(
          auction: auction,
          lots: lots,
          serverNow: DateTime.now().toUtc(),
        );
      });

  /// Joins the auction with join [code] as [displayName].
  ///
  /// Works on a closed auction too: the record outlives the event, and the
  /// client renders it read-only. The returned participant key is sent
  /// only this once.
  ///
  /// Throws `AUCTION_NOT_FOUND` for an unknown code and
  /// `COMMAND_VALIDATION` on `displayName` for a bad name.
  Future<JoinResult> join(Session session, String code, String displayName) =>
      rethrowAsTaroDomainException(() async {
        final auction = await findAuction(session, code);
        final participantId = ParticipantId.generate();
        final participantKey = newSecret();
        await _taro.dispatch(
          session,
          JoinAuction(
            participantId,
            auctionId: auction.auctionId.uuid,
            displayName: displayName,
            keyHash: hashKey(participantKey),
          ),
        );
        return JoinResult(
          participantId: participantId.value,
          participantKey: participantKey,
          displayName: displayName.trim(),
          auction: auction,
        );
      });

  /// Whether [participantId] joined the auction with join [code] and
  /// [participantKey] is their key: the client's check of the identity it
  /// kept.
  Future<bool> checkParticipant(
    Session session,
    String code,
    UuidValue participantId,
    String participantKey,
  ) async {
    try {
      final auction = await findAuction(session, code);
      await verifyParticipant(
        session,
        auction.auctionId,
        participantId,
        participantKey,
      );
      return true;
    } on AuctionNotFoundError {
      return false;
    } on NotParticipantError {
      return false;
    }
  }

  /// The winner code of every SOLD lot in the auction with join [code],
  /// by lot ID (UC-09), for the organizer to check a buyer's claim.
  ///
  /// A read: nothing is dispatched and the codes are never stored or
  /// logged.
  ///
  /// Throws `AUCTION_NOT_FOUND` for an unknown code and `NOT_ORGANIZER`
  /// for a wrong [organizerKey].
  Future<Map<String, String>> winnerCodes(
    Session session,
    String code,
    String organizerKey,
  ) => rethrowAsTaroDomainException(() async {
    final view = await findAuction(session, code);
    final auction = await _taro
        .runtime(session)
        .repository<Auction, AuctionId>()
        .load(AuctionId.fromExisting(view.auctionId.uuid));
    if (!auction.isOrganizer(organizerKey)) throw NotOrganizerError();

    final sold = await LotCard.db.find(
      session,
      where: (t) => t.code.equals(view.code) & t.status.equals('SOLD'),
    );
    final winners = {
      for (final row in await ParticipantRow.db.find(
        session,
        where: (t) => t.auctionId.equals(view.auctionId),
      ))
        row.id!: row.keyHash,
    };
    return {
      for (final lot in sold)
        if (winners[lot.leaderId] case final keyHash?)
          lot.lotId.uuid: winnerCode(keyHash, lot.lotId.uuid),
    };
  });
}
