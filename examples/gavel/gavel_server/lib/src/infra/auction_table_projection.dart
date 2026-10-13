import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../domain/auction.dart';
import '../generated/protocol.dart';

/// Keeps the `gavel_auctions` table up to date.
///
/// Every write passes the active unit of work's transaction, so under
/// strong consistency the row commits with the command. A duplicate join
/// code fails the insert and so rolls the whole command back.
class AuctionTableProjection extends Projection {
  /// Creates the projection on [session].
  AuctionTableProjection(this.session, {required super.processedEvents}) {
    on<AuctionCreated>(
      (e) => AuctionView.db.insertRow(
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
      ),
    );
  }

  /// The request's session.
  final Session session;

  @override
  String get name => 'auctions';

  Transaction? get _transaction => ServerpodUnitOfWork.transactionOf(session);

  @override
  Future<void> onRebuildStart() async {
    await AuctionView.db.deleteWhere(
      session,
      where: (_) => Constant.bool(true),
      transaction: _transaction,
    );
  }
}
