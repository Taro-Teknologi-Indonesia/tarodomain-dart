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
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Protocol;
import 'package:test/test.dart';

import 'tables.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  // Commands run in real transactions, which the default per-test rollback
  // (one shared transaction) doesn't allow.
  withServerpod(
    'Given a closed auction with one lot sold to Sari',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      late Session session;
      late TaroDomainServerpod taro;
      late AuctionId auctionId;
      late DateTime closeAt;
      late LotId pirus;
      late LotId juniper;
      final subscriptions = <StreamSubscription<LiveUpdate>>[];
      const code = 'UNP234';
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

      Future<void> close() async {
        // Timers round down to whole milliseconds; loop past closeAt.
        while (DateTime.now().toUtc().isBefore(closeAt)) {
          final wait = closeAt.difference(DateTime.now().toUtc());
          await Future<void>.delayed(wait + const Duration(milliseconds: 1));
        }
        await closeAuction(session, auctionId.value);
      }

      Future<LotCard> markUnpaid(
        LotId lot, {
        String key = organizerKey,
        String? note,
      }) => endpoints.lot.markUnpaid(sessionBuilder, lot.value, key, note);

      /// Watches the auction and collects every lot update it gets.
      Future<List<LiveUpdate>> watch() async {
        final received = <LiveUpdate>[];
        subscriptions.add(
          endpoints.live.watch(sessionBuilder, code).listen(received.add),
        );
        await flushEventQueue();
        return received;
      }

      /// Lets posted messages reach the stream listeners.
      Future<void> settle() => Future.delayed(const Duration(milliseconds: 50));

      Matcher failsWith(String code) => throwsA(
        isA<TaroDomainException>().having((e) => e.code, 'code', code),
      );

      setUp(() async {
        session = sessionBuilder.build();
        await clearTables(session);
        taro = TaroDomainServerpod(gavelServerDefinition())..install();
        auctionId = AuctionId.generate();
        // A backdated create gets an auction that closes in 2 seconds.
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
        final sari = await endpoints.auction.join(sessionBuilder, code, 'Sari');
        await endpoints.lot.placeBid(
          sessionBuilder,
          pirus.value,
          sari.participantId,
          sari.participantKey,
          175000,
          1,
          const Uuid().v7obj(),
        );
      });

      tearDown(() async {
        for (final s in subscriptions) {
          await s.cancel();
        }
        subscriptions.clear();
      });

      test('the organizer marks a SOLD lot and every watcher sees it, '
          'the sale kept', () async {
        await close();
        final received = await watch();

        final card = await markUnpaid(pirus, note: 'no reply after 24 h');
        await settle();

        expect(card.status, 'SOLD');
        expect(card.winnerName, 'Sari');
        expect(card.finalPrice, 175000);
        expect(card.unpaid, isTrue);
        expect(card.unpaidAt, isNotNull);
        expect(card.unpaidNote, 'no reply after 24 h');
        final lot = await taro
            .runtime(session)
            .repository<Lot, LotId>()
            .load(pirus);
        expect(card.version, lot.version);

        final pushed = [
          for (final u in received)
            if (u.kind == LiveUpdateKind.lotChanged) u.lot!,
        ];
        expect(pushed, hasLength(1));
        expect(pushed.single.lotId, pirus.value);
        expect(pushed.single.unpaid, isTrue);

        final events = await taro
            .runtime(session)
            .eventStore
            .loadStream('Lot-${pirus.uuid}');
        expect(events.map((e) => e.eventName).skip(2), [
          'LotClosed',
          'LotMarkedUnpaid',
        ]);
      });

      test('a second mark changes nothing', () async {
        await close();
        final first = await markUnpaid(pirus, note: 'no reply');
        final second = await markUnpaid(pirus, note: 'other');

        expect(second.version, first.version);
        expect(second.unpaidNote, 'no reply');
      });

      test('the wrong organizer key is NOT_ORGANIZER', () async {
        await close();
        await expectLater(
          markUnpaid(pirus, key: 'guess'),
          failsWith('NOT_ORGANIZER'),
        );
        final card = await LotCard.db.findFirstRow(
          session,
          where: (t) => t.lotId.equals(pirus.value),
        );
        expect(card!.unpaid, isFalse);
      });

      test('a PASSED lot is refused', () async {
        await close();
        await expectLater(markUnpaid(juniper), failsWith('COMMAND_VALIDATION'));
      });

      test('an unknown lot is AGGREGATE_NOT_FOUND', () async {
        await expectLater(
          markUnpaid(LotId.generate()),
          failsWith('AGGREGATE_NOT_FOUND'),
        );
      });
    },
  );
}
