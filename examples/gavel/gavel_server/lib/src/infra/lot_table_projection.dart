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
  }

  /// The request's session.
  final Session session;

  @override
  String get name => 'lots';

  /// Whether a rebuild is replaying events.
  bool _rebuilding = false;

  Transaction? get _transaction => ServerpodUnitOfWork.transactionOf(session);

  /// Tells the lot's auction watchers it changed, once the command commits.
  ///
  /// A rebuild replays old events, so it posts nothing.
  Future<void> _postLot(LotCard card) async {
    if (_rebuilding) return;
    await postLive(
      session,
      card.code,
      LiveUpdate(
        kind: LiveUpdateKind.lotChanged,
        lot: card,
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
