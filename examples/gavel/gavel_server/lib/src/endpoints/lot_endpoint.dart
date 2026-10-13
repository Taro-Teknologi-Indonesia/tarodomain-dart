import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../domain/auction.dart';
import '../domain/keys.dart' as keys;
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
  Future<LotCard> retractBid(
    Session session,
    UuidValue lotId,
    UuidValue participantId,
    String participantKey,
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
      RetractBid(
        LotId.fromExisting(lotId.uuid),
        ParticipantId.fromExisting(participantId.uuid),
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

  /// [participantId]'s winner code for the lot [lotId] (UC-09), or null
  /// unless the lot is SOLD to them. The seller compares it before handing
  /// the lot over, so a namesake can't claim the win.
  ///
  /// A read: nothing is dispatched and the code is never stored or logged.
  ///
  /// Throws `NOT_PARTICIPANT` unless [participantKey] is the key of a
  /// participant of the lot's auction, and `AGGREGATE_NOT_FOUND` for an
  /// unknown lot.
  Future<String?> winnerCode(
    Session session,
    UuidValue lotId,
    UuidValue participantId,
    String participantKey,
  ) => rethrowAsTaroDomainException(() async {
    final card = await _card(session, lotId);
    final participant = await verifyParticipant(
      session,
      card.auctionId,
      participantId,
      participantKey,
    );
    if (card.status != 'SOLD' || card.leaderId != participantId) return null;
    return keys.winnerCode(participant.keyHash, lotId.uuid);
  });

  /// The lot [lotId] as it stood at [at] (UC-10): its events up to [at]
  /// replayed through the [Lot] aggregate, not read from the projection.
  ///
  /// A read: nothing is dispatched or stored.
  ///
  /// Throws `AGGREGATE_NOT_FOUND` for an unknown lot, or one not yet
  /// created at [at].
  Future<LotAsOf> asOf(Session session, UuidValue lotId, DateTime at) =>
      rethrowAsTaroDomainException(() async {
        final id = LotId.fromExisting(lotId.uuid);
        final events = await _taro
            .runtime(session)
            .eventStore
            .loadStream(StreamIds.forAggregate('Lot', id));
        final lot = Lot.asOf(id, events, at);
        final leader = lot.lastValidBid;
        return LotAsOf(
          at: at.toUtc(),
          price: lot.currentPrice,
          leaderId: leader == null ? null : UuidValue.fromString(leader.bidder),
          leaderName: leader?.bidderName,
          status: lot.status.code,
          bidCount: lot.bids.length,
          retractedCount: lot.bids.where((b) => b.retracted).length,
          lastSequence: lot.bids.lastOrNull?.sequence ?? 0,
          version: lot.version,
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
