import 'package:serverpod/serverpod.dart';

import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Protocol;

import '../domain/auction.dart';
import '../domain/auction_commands.dart';
import '../generated/protocol.dart';

/// Closes auctions at their deadline, independently of any client.
///
/// `close` is scheduled per auction when it is created, with the identifier
/// `close-<auctionId>`, and `sweep` recurs, where future calls are enabled.
class AuctionCloseCalls extends FutureCall {
  /// Closes the auction [auctionId].
  Future<void> close(Session session, UuidValue auctionId) =>
      closeAuction(session, auctionId);

  /// Closes every OPEN auction past its close time, every 5 seconds: the
  /// safety net for a restart over a deadline or a lost scheduled close.
  Future<void> sweep(Session session) => closeDueAuctions(session);
}

/// Closes the auction [auctionId].
///
/// Idempotent: an auction already closing or closed is a no-op, so the
/// future call and the sweep can both fire.
Future<void> closeAuction(Session session, UuidValue auctionId) =>
    TaroDomainServerpod.instance.dispatch(
      session,
      CloseAuction(AuctionId.fromExisting(auctionId.uuid)),
    );

/// Closes every OPEN auction past its close time: the trigger where future
/// calls are disabled, and the safety net where a scheduled close was lost.
Future<void> closeDueAuctions(Session session) async {
  final now = DateTime.now().toUtc();
  final due = await AuctionView.db.find(
    session,
    where: (t) => t.status.equals('OPEN') & (t.closeAt <= now),
  );
  for (final auction in due) {
    try {
      await closeAuction(session, auction.auctionId);
    } catch (e, stackTrace) {
      session.log(
        'Closing auction ${auction.auctionId} failed',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }
}
