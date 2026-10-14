import 'dart:async';
import 'dart:io';

import 'package:gavel_server/src/demo/demo_auctions.dart';
import 'package:gavel_server/src/domain/auction.dart';
import 'package:gavel_server/src/domain/auction_commands.dart';
import 'package:gavel_server/src/domain/keys.dart';
import 'package:gavel_server/src/domain/lot.dart';
import 'package:gavel_server/src/domain/lot_commands.dart';
import 'package:gavel_server/src/future_calls/auction_close_calls.dart';
import 'package:gavel_server/src/gavel.dart';
import 'package:gavel_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Protocol;
import 'package:test/test.dart';

import 'organizer_session.dart';
import 'tables.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  // Commands run in real transactions, which the default per-test rollback
  // (one shared transaction) doesn't allow.
  withServerpod(
    'Given Gavel on PostgreSQL',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      late Session session;
      late TaroDomainServerpod taro;
      const organizerKey = 'organizer-secret';
      const otherOrganizer = 'organizer-2';

      setUp(() async {
        session = sessionBuilder.build();
        await clearTables(session);
        taro = TaroDomainServerpod(gavelServerDefinition())..install();
      });

      /// Creates the auction [code] for [userId], closing at [closeAt].
      Future<AuctionId> create(
        String code,
        DateTime closeAt, {
        String? userId = organizerUserId,
      }) async {
        final id = AuctionId.generate();
        await taro.dispatch(
          session,
          CreateAuction(
            id,
            title: 'Auction $code',
            closeAt: closeAt,
            code: code,
            organizerKeyHash: hashKey(organizerKey),
            organizerUserId: userId,
            // Backdated, so an auction can close seconds from now.
            timestamp: closeAt.subtract(const Duration(minutes: 10)),
          ),
        );
        return id;
      }

      Future<LotId> addLot(
        AuctionId auctionId,
        String name, {
        int openBid = 100000,
      }) async {
        final id = LotId.generate();
        await taro.dispatch(
          session,
          AddLot(
            auctionId,
            id,
            organizerKey: organizerKey,
            name: name,
            openBid: openBid,
            increments: const [25000, 50000],
            buyNowPrice: null,
            description: '',
            imageUrl: null,
            tileEmoji: '💎',
            tileColor: '#2E7D6B',
          ),
        );
        return id;
      }

      Future<void> bid(String code, LotId lot, String name, int amount) async {
        final p = await endpoints.auction.join(sessionBuilder, code, name);
        await endpoints.lot.placeBid(
          sessionBuilder,
          lot.value,
          p.participantId,
          p.participantKey,
          amount,
          1,
          const Uuid().v7obj(),
        );
      }

      /// Closes [auctionId] once [closeAt] has passed.
      Future<void> close(AuctionId auctionId, DateTime closeAt) async {
        // Timers round down to whole milliseconds; loop past closeAt.
        while (DateTime.now().toUtc().isBefore(closeAt)) {
          final wait = closeAt.difference(DateTime.now().toUtc());
          await Future<void>.delayed(wait + const Duration(milliseconds: 1));
        }
        await closeAuction(session, auctionId.value);
      }

      Future<List<String>> codesOf(String userId) async => [
        for (final a in (await endpoints.organizer.myAuctions(
          signedIn(sessionBuilder, userId: userId),
        )).auctions)
          a.auction.code,
      ];

      DateTime inHours(int hours) =>
          DateTime.now().toUtc().add(Duration(hours: hours));

      test('myAuctions without a signed-in user is refused', () async {
        await expectLater(
          endpoints.organizer.myAuctions(sessionBuilder),
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );
      });

      test('each organizer sees only their own auctions', () async {
        await create('AAA222', inHours(1));
        await create('BBB333', inHours(2));
        await create('CCC444', inHours(1), userId: otherOrganizer);

        expect(await codesOf(organizerUserId), ['AAA222', 'BBB333']);
        expect(await codesOf(otherOrganizer), ['CCC444']);
      });

      test('the demo auction never appears', () async {
        await ensureDemoOpen(session);
        await create('AAA222', inHours(1));

        expect(await codesOf(organizerUserId), ['AAA222']);
        expect(await codesOf(otherOrganizer), isEmpty);
      });

      test('running auctions come soonest close first, then closed ones '
          'most recent close first', () async {
        final now = DateTime.now().toUtc();
        final firstClose = now.add(const Duration(seconds: 1));
        final lastClose = now.add(const Duration(seconds: 2));
        final first = await create('FIR222', firstClose);
        final last = await create('LAS333', lastClose);
        await create('LATE44', inHours(2));
        await create('SOON55', inHours(1));

        expect(await codesOf(organizerUserId), [
          'FIR222',
          'LAS333',
          'SOON55',
          'LATE44',
        ]);

        await close(first, firstClose);
        await close(last, lastClose);

        final mine = await endpoints.organizer.myAuctions(
          signedIn(sessionBuilder),
        );
        expect(
          [for (final a in mine.auctions) a.auction.code],
          ['SOON55', 'LATE44', 'LAS333', 'FIR222'],
        );
        expect(
          [for (final a in mine.auctions) a.auction.status],
          ['OPEN', 'OPEN', 'CLOSED', 'CLOSED'],
        );
      });

      test('a closed auction counts its sold lots, total and unpaid '
          'marks', () async {
        const code = 'SAL234';
        final closeAt = DateTime.now().toUtc().add(const Duration(seconds: 2));
        final auctionId = await create(code, closeAt);
        // A first bid is the open bid plus a raise of 50.000.
        final pirus = await addLot(
          auctionId,
          'Natural Pirus Hubei',
          openBid: 250000,
        );
        final juniper = await addLot(
          auctionId,
          'Shimpaku juniper',
          openBid: 150000,
        );
        await addLot(auctionId, 'Ficus');
        await bid(code, pirus, 'Sari', 300000);
        await bid(code, juniper, 'Budi', 200000);
        await close(auctionId, closeAt);
        await endpoints.lot.markUnpaid(
          sessionBuilder,
          juniper.value,
          organizerKey,
          null,
        );

        final mine = await endpoints.organizer.myAuctions(
          signedIn(sessionBuilder),
        );

        final sold = mine.auctions.single;
        expect(sold.auction.lotCount, 3);
        expect(sold.soldCount, 2);
        expect(sold.soldTotal, 500000);
        expect(sold.unpaidCount, 1);
      });

      test('the board and the live push never carry the creator', () async {
        const code = 'PRV234';
        final auctionId = await create(code, inHours(1));
        final received = <LiveUpdate>[];
        final subscription = endpoints.live
            .watch(sessionBuilder, code)
            .listen(received.add);
        await flushEventQueue();
        await addLot(auctionId, 'Natural Pirus Hubei');
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await subscription.cancel();

        final board = await endpoints.auction.board(sessionBuilder, code);
        expect(
          board.toJsonForProtocol()['auction'],
          isNot(contains('organizerUserId')),
        );
        final pushed = received.firstWhere((u) => u.auction != null);
        expect(
          pushed.toJsonForProtocol()['auction'],
          isNot(contains('organizerUserId')),
        );
      });

      test('the migration backfills the creator from the AuctionCreated '
          'event', () async {
        await create('OLD234', inHours(1));
        await create('DEM345', inHours(1), userId: null);
        // As the row was before UC-15: no creator in the read model.
        await session.db.unsafeExecute(
          'UPDATE "gavel_auctions" SET "organizerUserId" = NULL',
        );
        expect(await codesOf(organizerUserId), isEmpty);

        await session.db.unsafeExecute(_backfill());

        expect(await codesOf(organizerUserId), ['OLD234']);
        final demo = await AuctionView.db.findFirstRow(
          session,
          where: (t) => t.code.equals('DEM345'),
        );
        expect(demo!.organizerUserId, isNull);
      });
    },
  );
}

/// The backfill `UPDATE` from the UC-15 migration, as it runs on deploy.
String _backfill() {
  final sql = File(
    'migrations/20261013202643957/migration.sql',
  ).readAsStringSync();
  final start = sql.indexOf('UPDATE "gavel_auctions"');
  return sql.substring(start, sql.indexOf(';', start) + 1);
}
