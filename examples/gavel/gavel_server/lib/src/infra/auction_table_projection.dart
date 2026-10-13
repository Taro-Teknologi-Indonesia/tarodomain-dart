import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../domain/auction.dart';
import '../generated/protocol.dart';
import 'live_channels.dart';

/// Keeps the `gavel_auctions` table up to date.
///
/// Every write passes the active unit of work's transaction, so under
/// strong consistency the row commits with the command. A duplicate join
/// code fails the insert and so rolls the whole command back.
class AuctionTableProjection extends Projection {
  /// Creates the projection on [session].
  AuctionTableProjection(this.session, {required super.processedEvents}) {
    on<AuctionCreated>((e) async {
      final view = await AuctionView.db.insertRow(
        session,
        AuctionView(
          auctionId: UuidValue.fromString(e.auctionId),
          code: e.code,
          title: e.title,
          closeAt: e.closeAt,
          status: AuctionStatus.open.code,
          lotCount: 0,
        ),
        transaction: _transaction,
      );
      await _postAuction(view);
    });
    on<LotRegistered>((e) async {
      final view = await _find(e.auctionId);
      await _postAuction(
        await AuctionView.db.updateRow(
          session,
          view.copyWith(lotCount: view.lotCount + 1),
          transaction: _transaction,
        ),
      );
    });
  }

  Future<AuctionView> _find(String auctionId) async =>
      (await AuctionView.db.findFirstRow(
        session,
        where: (t) => t.auctionId.equals(UuidValue.fromString(auctionId)),
        transaction: _transaction,
      ))!;

  /// The request's session.
  final Session session;

  @override
  String get name => 'auctions';

  /// Whether a rebuild is replaying events.
  bool _rebuilding = false;

  Transaction? get _transaction => ServerpodUnitOfWork.transactionOf(session);

  /// Tells the auction's watchers it changed, once the command commits.
  ///
  /// A rebuild replays old events, so it posts nothing.
  Future<void> _postAuction(AuctionView view) async {
    if (_rebuilding) return;
    await postLive(
      session,
      view.code,
      LiveUpdate(
        kind: LiveUpdateKind.auctionChanged,
        auction: view,
        serverNow: DateTime.now().toUtc(),
      ),
    );
  }

  @override
  Future<void> onRebuildStart() async {
    _rebuilding = true;
    await AuctionView.db.deleteWhere(
      session,
      where: (_) => Constant.bool(true),
      transaction: _transaction,
    );
  }

  @override
  Future<void> onRebuildComplete() async {
    _rebuilding = false;
  }
}
