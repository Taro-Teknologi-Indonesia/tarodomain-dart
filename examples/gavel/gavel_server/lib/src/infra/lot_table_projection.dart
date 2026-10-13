import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../domain/lot.dart';
import '../generated/protocol.dart';
import 'live_channels.dart';

/// Keeps the `gavel_lot_cards` and `gavel_ledger_entries` tables up to
/// date, and tells the auction's watchers about every changed lot.
///
/// TaroDomain doesn't give projections the event's stream position, so a
/// card's `version` starts at 1 on `LotCreated` and goes up by one on every
/// later lot event. It matches `Lot.version` as long as every lot event
/// passes through here.
///
/// Every write passes the active unit of work's transaction, so under
/// strong consistency the rows commit with the command.
class LotTableProjection extends Projection {
  /// Creates the projection on [session].
  LotTableProjection(this.session, {required super.processedEvents}) {
    on<LotCreated>((e) async {
      final card = await LotCard.db.insertRow(
        session,
        LotCard(
          lotId: UuidValue.fromString(e.lotId),
          auctionId: UuidValue.fromString(e.auctionId),
          code: e.code,
          position: e.position,
          name: e.name,
          description: e.description,
          imageUrl: e.imageUrl,
          tileEmoji: e.tileEmoji,
          tileColor: e.tileColor,
          openBid: e.openBid,
          increments: e.increments,
          buyNowPrice: e.buyNowPrice,
          currentPrice: e.openBid,
          bidCount: 0,
          status: LotStatus.open.code,
          version: 1,
        ),
        transaction: _transaction,
      );
      await _postLot(card);
    });
    on<BidPlaced>((e) async {
      final entry = await LedgerEntry.db.insertRow(
        session,
        LedgerEntry(
          lotId: UuidValue.fromString(e.lotId),
          sequence: e.sequence,
          participantId: UuidValue.fromString(e.participantId),
          bidderName: e.bidderName,
          amount: e.amount,
          placedAt: e.occurredAt,
          retracted: false,
        ),
        transaction: _transaction,
      );
      final card = await _card(e.lotId);
      final updated = await LotCard.db.updateRow(
        session,
        card.copyWith(
          currentPrice: e.amount,
          leaderId: entry.participantId,
          leaderName: e.bidderName,
          bidCount: card.bidCount + 1,
          version: card.version + 1,
        ),
        transaction: _transaction,
      );
      await _postLot(updated, ledgerEntry: entry);
    });
    on<BidRetracted>((e) async {
      final lotId = UuidValue.fromString(e.lotId);
      final ledger = await LedgerEntry.db.find(
        session,
        where: (t) => t.lotId.equals(lotId),
        orderBy: (t) => t.sequence,
        transaction: _transaction,
      );
      final i = ledger.indexWhere((l) => l.sequence == e.retractedSequence);
      if (i < 0) throw StateError('No ledger entry ${e.retractedSequence}');
      final entry = await LedgerEntry.db.updateRow(
        session,
        ledger[i].copyWith(retracted: true, retractedAt: e.occurredAt),
        transaction: _transaction,
      );
      ledger[i] = entry;
      final standing = [
        for (final l in ledger)
          if (!l.retracted) l,
      ];
      final leader = standing.lastOrNull;
      final card = await _card(e.lotId);
      final updated = await LotCard.db.updateRow(
        session,
        card.copyWith(
          currentPrice: leader?.amount ?? card.openBid,
          leaderId: leader?.participantId,
          leaderName: leader?.bidderName,
          bidCount: standing.length,
          version: card.version + 1,
        ),
        transaction: _transaction,
      );
      await _postLot(updated, ledgerEntry: entry);
    });
    on<LotClosed>((e) async {
      final card = await _card(e.lotId);
      await _postLot(
        await LotCard.db.updateRow(
          session,
          card.copyWith(
            status: e.outcome.code,
            winnerName: e.winnerName,
            finalPrice: e.finalPrice,
            closeCause: e.cause.code,
            closedAt: e.closedAt,
            version: card.version + 1,
          ),
          transaction: _transaction,
        ),
      );
    });
  }

  /// The request's session.
  final Session session;

  @override
  String get name => 'lots';

  /// Whether a rebuild is replaying events.
  bool _rebuilding = false;

  Transaction? get _transaction => ServerpodUnitOfWork.transactionOf(session);

  /// The card of the lot [lotId], which its `LotCreated` wrote.
  Future<LotCard> _card(String lotId) async =>
      await LotCard.db.findFirstRow(
        session,
        where: (t) => t.lotId.equals(UuidValue.fromString(lotId)),
        transaction: _transaction,
      ) ??
      (throw StateError('No card for lot $lotId'));

  /// Tells the lot's auction watchers it changed, with the [ledgerEntry]
  /// the change added if any, once the command commits.
  ///
  /// A rebuild replays old events, so it posts nothing.
  Future<void> _postLot(LotCard card, {LedgerEntry? ledgerEntry}) async {
    if (_rebuilding) return;
    await postLive(
      session,
      card.code,
      LiveUpdate(
        kind: LiveUpdateKind.lotChanged,
        lot: card,
        ledgerEntry: ledgerEntry,
        serverNow: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<void> onRebuildStart() async {
    _rebuilding = true;
    final everything = Constant.bool(true);
    await LedgerEntry.db.deleteWhere(
      session,
      where: (_) => everything,
      transaction: _transaction,
    );
    await LotCard.db.deleteWhere(
      session,
      where: (_) => everything,
      transaction: _transaction,
    );
  }

  @override
  Future<void> onRebuildComplete() async {
    _rebuilding = false;
  }
}
