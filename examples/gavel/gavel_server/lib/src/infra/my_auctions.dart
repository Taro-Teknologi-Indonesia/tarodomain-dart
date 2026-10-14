import 'package:serverpod/serverpod.dart';

import '../domain/auction.dart';
import '../domain/lot.dart';
import '../generated/protocol.dart';

/// The auctions [userId] created, with their sales so far (UC-15).
///
/// Running ones (OPEN or CLOSING) come first, soonest close first, then
/// closed ones, most recent close first. Auctions without a creator (the
/// demo and those created before X6) never appear.
///
/// The sales come from one read of the SOLD lots, summed here: an
/// organizer has tens of auctions, not thousands.
Future<MyAuctions> listMyAuctions(Session session, String userId) async {
  final views = await AuctionView.db.find(
    session,
    where: (t) => t.organizerUserId.equals(userId),
  );
  final sold = views.isEmpty
      ? const <LotCard>[]
      : await LotCard.db.find(
          session,
          where: (t) =>
              t.code.inSet({for (final v in views) v.code}) &
              t.status.equals(LotStatus.sold.code),
        );

  final soldCount = <String, int>{};
  final soldTotal = <String, int>{};
  final unpaidCount = <String, int>{};
  for (final lot in sold) {
    soldCount.update(lot.code, (n) => n + 1, ifAbsent: () => 1);
    soldTotal.update(
      lot.code,
      (n) => n + (lot.finalPrice ?? 0),
      ifAbsent: () => lot.finalPrice ?? 0,
    );
    if (lot.unpaid) {
      unpaidCount.update(lot.code, (n) => n + 1, ifAbsent: () => 1);
    }
  }

  bool closed(AuctionView v) => v.status == AuctionStatus.closed.code;
  views.sort((a, b) {
    if (closed(a) != closed(b)) return closed(a) ? 1 : -1;
    return closed(a)
        ? b.closeAt.compareTo(a.closeAt)
        : a.closeAt.compareTo(b.closeAt);
  });

  return MyAuctions(
    auctions: [
      for (final v in views)
        MyAuction(
          auction: v,
          soldCount: soldCount[v.code] ?? 0,
          soldTotal: soldTotal[v.code] ?? 0,
          unpaidCount: unpaidCount[v.code] ?? 0,
        ),
    ],
    serverNow: DateTime.now().toUtc(),
  );
}
