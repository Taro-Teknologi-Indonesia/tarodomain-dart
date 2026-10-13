import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Protocol;

import '../domain/auction.dart';
import '../domain/lot.dart';
import '../domain/lot_commands.dart';
import '../generated/protocol.dart';
import '../infra/auction_creation.dart';
import 'seed_lots.dart';

/// The rolling public demo (X2): there is always an OPEN demo auction a
/// judge can bid in, and a fresh one opens as the last closes. Closed demos
/// stay browsable.

/// The demo auctions' title.
const demoTitle = 'Gavel live demo — batu akik';

/// A demo closing sooner than this gets a successor already, so `/demo`
/// never lands on an auction about to close.
const demoMinimumLeft = Duration(minutes: 2);

/// The demo's close time for one opened at [now]: the next quarter hour at
/// least [Auction.minimumLeadTime] ahead, e.g. 22:15 or 22:30.
DateTime demoCloseAt(DateTime now) {
  final earliest = now.toUtc().add(Auction.minimumLeadTime);
  final quarter = DateTime.utc(
    earliest.year,
    earliest.month,
    earliest.day,
    earliest.hour,
    earliest.minute - earliest.minute % 15,
  );
  return quarter.isBefore(earliest)
      ? quarter.add(const Duration(minutes: 15))
      : quarter;
}

/// Opens a demo auction unless one is open, fully seeded and at least
/// [demoMinimumLeft] from its close at [now], and returns the code of the
/// one that is.
///
/// The demo goes through the normal commands, `CreateAuction` then an
/// `AddLot` per seed lot, so it is in the event store like any other
/// auction. Its organizer key is thrown away: nobody can add lots to it.
/// [now] is the commands' timestamp; tests pin it.
Future<String> ensureDemoOpen(Session session, {DateTime? now}) async {
  final at = (now ?? DateTime.now()).toUtc();
  final open = await _newestOpenDemo(
    session,
    closingAfter: at.add(demoMinimumLeft),
  );
  if (open != null) return open.code;

  final created = await createAuction(
    session,
    title: demoTitle,
    closeAt: demoCloseAt(at),
    isDemo: true,
    now: at,
  );
  final auctionId = AuctionId.fromExisting(created.auctionId.uuid);
  for (final lot in demoLots) {
    await TaroDomainServerpod.instance.dispatch(
      session,
      AddLot(
        auctionId,
        LotId.generate(),
        organizerKey: created.organizerKey,
        name: lot.name,
        openBid: lot.openBid,
        increments: lot.increments,
        buyNowPrice: lot.buyNowPrice,
        description: lot.description,
        imageUrl: lot.imageUrl,
        tileEmoji: lot.tileEmoji,
        tileColor: lot.tileColor,
        timestamp: at,
      ),
    );
  }
  return created.code;
}

/// The code of the newest open demo auction, opening one first if there is
/// none, as when the demo job hasn't run yet.
Future<String> currentDemoCode(Session session) async {
  final open = await _newestOpenDemo(
    session,
    closingAfter: DateTime.now().toUtc(),
  );
  return open?.code ?? await ensureDemoOpen(session);
}

/// The newest OPEN demo auction with all its lots that closes after
/// [closingAfter], if any. A demo whose seeding failed halfway never
/// counts, so the next run replaces it.
Future<AuctionView?> _newestOpenDemo(
  Session session, {
  required DateTime closingAfter,
}) async => (await AuctionView.db.find(
  session,
  where: (t) =>
      t.isDemo.equals(true) &
      t.status.equals(AuctionStatus.open.code) &
      (t.closeAt > closingAfter) &
      t.lotCount.equals(demoLots.length),
  orderBy: (t) => t.closeAt.desc(),
  limit: 1,
)).firstOrNull;
