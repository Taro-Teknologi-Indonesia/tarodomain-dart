import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Closes auctions at their deadline, independently of any client.
///
/// `close` is scheduled per auction when it is created, with the identifier
/// `close-<auctionId>`, where future calls are enabled.
class AuctionCloseCalls extends FutureCall {
  /// Closes the auction [auctionId].
  Future<void> close(Session session, UuidValue auctionId) =>
      closeAuction(session, auctionId);
}

/// Closes the auction [auctionId].
Future<void> closeAuction(Session session, UuidValue auctionId) async {
  // UC-08 dispatches CloseAuction here.
  session.log('Close time reached for auction $auctionId');
}

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
