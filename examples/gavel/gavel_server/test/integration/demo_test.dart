import 'package:gavel_server/src/demo/demo_auctions.dart';
import 'package:gavel_server/src/demo/seed_lots.dart';
import 'package:gavel_server/src/domain/lot.dart';
import 'package:gavel_server/src/domain/lot_commands.dart';
import 'package:gavel_server/src/domain/participant.dart';
import 'package:gavel_server/src/future_calls/auction_close_calls.dart';
import 'package:gavel_server/src/gavel.dart';
import 'package:gavel_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Protocol;
import 'package:test/test.dart';

import 'tables.dart';
import 'organizer_session.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  test('a demo closes at the next quarter hour at least 5 minutes ahead', () {
    expect(
      demoCloseAt(DateTime.utc(2026, 10, 14, 22, 3, 20)),
      DateTime.utc(2026, 10, 14, 22, 15),
    );
    expect(
      demoCloseAt(DateTime.utc(2026, 10, 14, 22, 10, 1)),
      DateTime.utc(2026, 10, 14, 22, 30),
    );
    expect(
      demoCloseAt(DateTime.utc(2026, 10, 14, 22, 10)),
      DateTime.utc(2026, 10, 14, 22, 15),
    );
    expect(
      demoCloseAt(DateTime.utc(2026, 10, 14, 23, 56)),
      DateTime.utc(2026, 10, 15, 0, 15),
    );
  });

  // Commands run in real transactions, which the default per-test rollback
  // (one shared transaction) doesn't allow.
  withServerpod(
    'Given Gavel on PostgreSQL',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      late Session session;
      late TaroDomainServerpod taro;

      Future<List<AuctionView>> demos() => AuctionView.db.find(
        session,
        where: (t) => t.isDemo.equals(true),
        orderBy: (t) => t.closeAt,
      );

      Future<List<LotCard>> lots(String code) => LotCard.db.find(
        session,
        where: (t) => t.code.equals(code),
        orderBy: (t) => t.position,
      );

      setUp(() async {
        session = sessionBuilder.build();
        await clearTables(session);
        taro = TaroDomainServerpod(gavelServerDefinition())..install();
      });

      test('ensureOpen twice opens one demo auction with the seed lots, '
          'through the commands', () async {
        final first = await ensureDemoOpen(session);
        final second = await ensureDemoOpen(session);

        expect(second, first);
        final [demo] = await demos();
        expect(demo.code, first);
        expect(demo.status, 'OPEN');
        expect(demo.lotCount, demoLots.length);
        expect(demo.closeAt.minute % 15, 0);
        expect(
          [for (final lot in await lots(demo.code)) lot.name],
          [for (final lot in demoLots) lot.name],
        );

        final stream = await taro
            .runtime(session)
            .eventStore
            .loadStream('Auction-${demo.auctionId.uuid}');
        expect(
          [for (final e in stream) e.eventName],
          ['AuctionCreated', 'LotRegistered', 'LotRegistered', 'LotRegistered'],
        );
        expect(await endpoints.auction.currentDemo(sessionBuilder), first);
      });

      test('a regular auction is not a demo', () async {
        final created = await endpoints.organizer.create(
          signedIn(sessionBuilder),
          'Bonsai night',
          DateTime.now().toUtc().add(const Duration(minutes: 30)),
        );

        final view = await AuctionView.db.findFirstRow(
          session,
          where: (t) => t.code.equals(created.code),
        );
        expect(view!.isDemo, isFalse);
      });

      test('currentDemo opens a demo when there is none', () async {
        final code = await endpoints.auction.currentDemo(sessionBuilder);

        final [demo] = await demos();
        expect(demo.code, code);
        expect(demo.status, 'OPEN');
      });

      test('after the close a fresh demo opens, and the closed one keeps '
          'its record', () async {
        // Opened 20 minutes ago, so it closed at the latest quarter hour.
        final openedAt = DateTime.now().toUtc().subtract(
          const Duration(minutes: 20),
        );
        final oldCode = await ensureDemoOpen(session, now: openedAt);
        final [old] = await demos();
        final pirus = (await lots(oldCode)).first;

        final budi = await endpoints.auction.join(
          sessionBuilder,
          oldCode,
          'Budi',
        );
        await taro.dispatch(
          session,
          PlaceBid(
            LotId.fromExisting(pirus.lotId.uuid),
            ParticipantId.fromExisting(budi.participantId.uuid),
            amount: pirus.openBid + pirus.increments.first,
            expectedVersion: pirus.version,
            timestamp: old.closeAt.subtract(const Duration(minutes: 1)),
          ),
        );

        await closeDueAuctions(session);
        final newCode = await ensureDemoOpen(session);

        expect(newCode, isNot(oldCode));
        final [closed, fresh] = await demos();
        expect(closed.code, oldCode);
        expect(closed.status, 'CLOSED');
        expect(fresh.code, newCode);
        expect(fresh.status, 'OPEN');
        expect(fresh.lotCount, demoLots.length);
        expect(await endpoints.auction.currentDemo(sessionBuilder), newCode);

        final sold = (await lots(oldCode)).first;
        expect(sold.status, 'SOLD');
        expect(sold.winnerName, 'Budi');
        final ledger = await endpoints.lot.detail(sessionBuilder, pirus.lotId);
        expect(ledger.ledger, hasLength(1));
      });
    },
  );
}
