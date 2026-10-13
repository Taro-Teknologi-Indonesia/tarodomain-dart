import 'package:serverpod/serverpod.dart';

/// Closes auctions at their deadline, independently of any client.
///
/// `close` is scheduled per auction when it is created, with the identifier
/// `close-<auctionId>`.
class AuctionCloseCalls extends FutureCall {
  /// Closes the auction [auctionId].
  Future<void> close(Session session, UuidValue auctionId) async {
    // UC-08 dispatches CloseAuction here.
    session.log('Close time reached for auction $auctionId');
  }
}
