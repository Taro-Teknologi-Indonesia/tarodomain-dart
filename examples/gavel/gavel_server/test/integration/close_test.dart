import 'dart:async';

import 'package:gavel_server/src/domain/auction.dart';
import 'package:gavel_server/src/domain/auction_commands.dart';
import 'package:gavel_server/src/domain/keys.dart';
import 'package:gavel_server/src/domain/lot.dart';
import 'package:gavel_server/src/domain/lot_commands.dart';
import 'package:gavel_server/src/future_calls/auction_close_calls.dart';
import 'package:gavel_server/src/gavel.dart';
import 'package:gavel_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart' show SagaStatus;
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Protocol;
import 'package:test/test.dart';

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
      late AuctionId auctionId;
      late DateTime closeAt;
      late LotId pirus;
      late LotId juniper;
      late JoinResult budi;
      const code = 'CLS234';
      const organizerKey = 'organizer-secret';

      Future<LotId> addLot(String name) async {
        final id = LotId.generate();
        await taro.dispatch(
          session,
          AddLot(
            auctionId,
            id,
            organizerKey: organizerKey,
            name: name,
            openBid: 150000,
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

      Future<LotCard> card(LotId id) async => (await LotCard.db.findFirstRow(
        session,
        where: (t) => t.lotId.equals(id.value),
      ))!;

      Future<AuctionView> view() async => (await AuctionView.db.findFirstRow(
        session,
        where: (t) => t.code.equals(code),
      ))!;

      Future<List<String>> events(String stream) async => [
        for (final e
            in await taro.runtime(session).eventStore.loadStream(stream))
          e.eventName,
      ];

      // Timers round down to whole milliseconds, so one delay can wake up
      // just before closeAt; loop until the clock has actually passed it.
      Future<void> waitUntilClosed() async {
        while (DateTime.now().toUtc().isBefore(closeAt)) {
          final wait = closeAt.difference(DateTime.now().toUtc());
          await Future<void>.delayed(wait + const Duration(milliseconds: 1));
        }
      }

      setUp(() async {
        session = sessionBuilder.build();
        await clearTables(session);
        taro = TaroDomainServerpod(gavelServerDefinition())..install();
        auctionId = AuctionId.generate();
        // The 5-minute lead is checked against the command's timestamp, so
        // a backdated create gets an auction that closes in 2 seconds.
        closeAt = DateTime.now().toUtc().add(const Duration(seconds: 2));
        await taro.dispatch(
          session,
          CreateAuction(
            auctionId,
            title: 'Bonsai night',
            closeAt: closeAt,
            code: code,
            organizerKeyHash: hashKey(organizerKey),
            timestamp: closeAt.subtract(const Duration(minutes: 10)),
          ),
        );
        pirus = await addLot('Natural Pirus Hubei');
        juniper = await addLot('Shimpaku juniper');
        budi = await endpoints.auction.join(sessionBuilder, code, 'Budi');
      });

      test('the sweep sells the lot bid on, passes the other and closes '
          'the auction, with no client involved', () async {
        await endpoints.lot.placeBid(
          sessionBuilder,
          pirus.value,
          budi.participantId,
          budi.participantKey,
          175000,
          1,
          const Uuid().v7obj(),
        );
        await waitUntilClosed();

        await closeDueAuctions(session);

        final sold = await card(pirus);
        expect(sold.status, 'SOLD');
        expect(sold.winnerName, 'Budi');
        expect(sold.leaderId, budi.participantId);
        expect(sold.finalPrice, 175000);
        expect(sold.closeCause, 'DEADLINE');
        expect(sold.closedAt, closeAt);
        expect(sold.version, 3);

        final passed = await card(juniper);
        expect(passed.status, 'PASSED');
        expect(passed.winnerName, isNull);

        expect((await view()).status, 'CLOSED');
        final sagas = taro.runtime(session).sagaStore;
        expect(await sagas.count(sagaType: 'AuctionCloseSaga'), 1);
        expect(
          await sagas.count(
            sagaType: 'AuctionCloseSaga',
            status: SagaStatus.completed,
          ),
          1,
        );
      });

      test('two closes at once raise one AuctionClosed and one LotClosed '
          'per lot', () async {
        await waitUntilClosed();

        await Future.wait([
          closeAuction(session, auctionId.value),
          closeAuction(sessionBuilder.build(), auctionId.value),
        ]);

        final auctionEvents = await events('Auction-${auctionId.uuid}');
        expect(auctionEvents.where((e) => e == 'AuctionClosed'), hasLength(1));
        expect(
          auctionEvents.where((e) => e == 'AuctionFinalized'),
          hasLength(1),
        );
        for (final lot in [pirus, juniper]) {
          expect(
            (await events('Lot-${lot.uuid}')).where((e) => e == 'LotClosed'),
            hasLength(1),
          );
        }
        expect((await view()).status, 'CLOSED');
      });

      test('the sweep skips an auction still open', () async {
        await closeDueAuctions(session);
        expect((await view()).status, 'OPEN');
        expect((await card(pirus)).status, 'OPEN');
      });
    },
  );
}
