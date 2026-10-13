import 'dart:async';

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
  // Commands run in real transactions, which the default per-test rollback
  // (one shared transaction) doesn't allow.
  withServerpod(
    'Given Gavel on PostgreSQL',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      late Session session;
      late TaroDomainServerpod taro;
      late CreatedAuction created;
      late LotCard lot;
      late JoinResult budi;
      late JoinResult sari;
      final subscriptions = <StreamSubscription<LiveUpdate>>[];

      setUp(() async {
        session = sessionBuilder.build();
        await clearTables(session);
        taro = TaroDomainServerpod(gavelServerDefinition())..install();
        created = await endpoints.organizer.create(
          signedIn(sessionBuilder),
          'Bonsai night',
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        );
        lot = await endpoints.lot.add(
          sessionBuilder,
          created.code,
          created.organizerKey,
          NewLot(
            name: 'Natural Pirus Hubei',
            openBid: 150000,
            increments: [25000, 50000, 100000],
            buyNowPrice: 1500000,
            description: '',
            imageUrl: null,
            tileEmoji: '💎',
            tileColor: '#2E7D6B',
          ),
        );
        budi = await endpoints.auction.join(
          sessionBuilder,
          created.code,
          'Budi',
        );
        sari = await endpoints.auction.join(
          sessionBuilder,
          created.code,
          'Sari',
        );
      });

      tearDown(() async {
        for (final s in subscriptions) {
          await s.cancel();
        }
        subscriptions.clear();
      });

      Future<LotCard> buyNow(
        JoinResult who, {
        int? expectedVersion,
        String? key,
        UuidValue? commandId,
      }) => endpoints.lot.buyNow(
        sessionBuilder,
        lot.lotId,
        who.participantId,
        key ?? who.participantKey,
        expectedVersion ?? lot.version,
        commandId ?? const Uuid().v7obj(),
      );

      Future<LotCard> placeBid(JoinResult who, int amount) =>
          endpoints.lot.placeBid(
            sessionBuilder,
            lot.lotId,
            who.participantId,
            who.participantKey,
            amount,
            lot.version,
            const Uuid().v7obj(),
          );

      Future<List<String>> lotEvents() async => [
        for (final e
            in await taro
                .runtime(session)
                .eventStore
                .loadStream('Lot-${lot.lotId.uuid}'))
          e.eventName,
      ];

      Future<List<LiveUpdate>> watch() async {
        final received = <LiveUpdate>[];
        subscriptions.add(
          endpoints.live
              .watch(sessionBuilder, created.code)
              .listen(received.add),
        );
        await flushEventQueue();
        return received;
      }

      Future<void> settle() => Future.delayed(const Duration(milliseconds: 50));

      Matcher failsWith(String code) => throwsA(
        isA<TaroDomainException>().having((e) => e.code, 'code', code),
      );

      test('BN returns the SOLD card, writes a BN ledger row and pushes '
          'both events', () async {
        final received = await watch();

        final card = await buyNow(sari);
        await settle();

        expect(card.status, 'SOLD');
        expect(card.closeCause, 'BUY_NOW');
        expect(card.winnerName, 'Sari');
        expect(card.leaderId, sari.participantId);
        expect(card.finalPrice, 1500000);
        expect(card.currentPrice, 1500000);
        expect(card.closedAt, isNotNull);
        expect(card.version, lot.version + 2);

        final entry = (await LedgerEntry.db.find(session)).single;
        expect(entry.amount, 1500000);
        expect(entry.buyNow, isTrue);
        expect(entry.bidderName, 'Sari');

        final updates = [
          for (final u in received)
            if (u.kind == LiveUpdateKind.lotChanged) u,
        ];
        expect(updates, hasLength(2));
        expect(updates.first.ledgerEntry?.buyNow, isTrue);
        expect(updates.last.lot?.status, 'SOLD');
        expect(updates.last.lot?.closeCause, 'BUY_NOW');
      });

      test('a chip bid writes a ledger row that is not BN', () async {
        await placeBid(budi, 175000);
        expect((await LedgerEntry.db.find(session)).single.buyNow, isFalse);
      });

      test('a wrong key is NOT_PARTICIPANT and stores nothing', () async {
        await expectLater(
          buyNow(budi, key: sari.participantKey),
          failsWith('NOT_PARTICIPANT'),
        );
        expect(await lotEvents(), ['LotCreated']);
        expect(await LedgerEntry.db.count(session), 0);
      });

      test('a resend with the same command ID buys once', () async {
        final commandId = const Uuid().v7obj();

        final first = await buyNow(sari, commandId: commandId);
        final again = await buyNow(sari, commandId: commandId);

        expect(again.version, first.version);
        expect(await lotEvents(), ['LotCreated', 'BidPlaced', 'LotClosed']);
      });

      test('BN after BN is LOT_CLOSED', () async {
        await buyNow(sari);
        await expectLater(
          buyNow(budi, expectedVersion: lot.version + 2),
          failsWith('LOT_CLOSED'),
        );
      });

      test('BN and a chip on one version: one wins, one clean error, never '
          'a bid after the close', () async {
        final results = await Future.wait([
          buyNow(sari).then<Object>((c) => c, onError: (Object e) => e),
          placeBid(
            budi,
            250000,
          ).then<Object>((c) => c, onError: (Object e) => e),
        ]);

        final card = results.whereType<LotCard>().single;
        final error = results.whereType<TaroDomainException>().single;
        final events = await lotEvents();
        if (card.status == 'SOLD') {
          expect(error.code, 'LOT_CLOSED');
          expect(events, ['LotCreated', 'BidPlaced', 'LotClosed']);
        } else {
          expect(error.code, 'OUTBID');
          expect(events, ['LotCreated', 'BidPlaced']);
        }
        expect(await LedgerEntry.db.count(session), 1);
      });
    },
  );
}
