import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../domain/auction.dart';
import '../domain/lot.dart';
import '../domain/lot_commands.dart';
import '../domain/participant.dart';
import '../generated/protocol.dart';
import '../infra/participant_guard.dart';

/// Adding lots and bidding on them.
class LotEndpoint extends Endpoint {
  TaroDomainServerpod get _taro => TaroDomainServerpod.instance;

  /// Adds [lot] to the auction with join [code] and returns its card.
  ///
  /// Throws `AUCTION_NOT_FOUND` for an unknown code, `NOT_ORGANIZER` for a
  /// wrong [organizerKey], `LOT_CLOSED` once the auction has closed, and
  /// `COMMAND_VALIDATION` with the offending `field` for a bad lot.
  Future<LotCard> add(
    Session session,
    String code,
    String organizerKey,
    NewLot lot,
  ) => rethrowAsTaroDomainException(() async {
    final auction = await findAuction(session, code);

    final lotId = LotId.generate();
    await _taro.dispatch(
      session,
      AddLot(
        AuctionId.fromExisting(auction.auctionId.uuid),
        lotId,
        organizerKey: organizerKey,
        name: lot.name,
        openBid: lot.openBid,
        increments: lot.increments,
        buyNowPrice: lot.buyNowPrice,
        description: lot.description,
        imageUrl: lot.imageUrl,
        tileEmoji: lot.tileEmoji,
        tileColor: lot.tileColor,
      ),
    );
    return (await LotCard.db.findFirstRow(
      session,
      where: (t) => t.lotId.equals(lotId.value),
    ))!;
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
  Future<LotCard> placeBid(
    Session session,
    UuidValue lotId,
    UuidValue participantId,
    String participantKey,
    int amount,
    int expectedVersion,
    UuidValue commandId,
  ) => rethrowAsTaroDomainException(() async {
    final card = await _card(session, lotId);
    await verifyParticipant(
      session,
      card.auctionId,
      participantId,
      participantKey,
    );
    await _taro.dispatch(
      session,
      PlaceBid(
        LotId.fromExisting(lotId.uuid),
        ParticipantId.fromExisting(participantId.uuid),
        amount: amount,
        expectedVersion: expectedVersion,
        id: commandId,
      ),
    );
    return _card(session, lotId);
  });

  /// The lot [lotId] with every bid on it, retracted ones included, in
  /// ledger order.
  ///
  /// Throws `AGGREGATE_NOT_FOUND` for an unknown lot.
  Future<LotDetail> detail(Session session, UuidValue lotId) =>
      rethrowAsTaroDomainException(() async {
        final card = await _card(session, lotId);
        final auction = await AuctionView.db.findFirstRow(
          session,
          where: (t) => t.auctionId.equals(card.auctionId),
        );
        final ledger = await LedgerEntry.db.find(
          session,
          where: (t) => t.lotId.equals(lotId),
          orderBy: (t) => t.sequence,
        );
        return LotDetail(
          lot: card,
          ledger: ledger,
          closeAt: auction!.closeAt,
          serverNow: DateTime.now().toUtc(),
        );
      });

  Future<LotCard> _card(Session session, UuidValue lotId) async =>
      await LotCard.db.findFirstRow(
        session,
        where: (t) => t.lotId.equals(lotId),
      ) ??
      (throw AggregateNotFoundError(
        'Lot ${lotId.uuid} not found',
        context: {'aggregateType': 'Lot', 'aggregateId': lotId.uuid},
      ));
}
