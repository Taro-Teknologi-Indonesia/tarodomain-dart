import 'dart:async';

import 'package:gavel_server/src/domain/lot.dart';
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
        created = await endpoints.auction.create(
          sessionBuilder,
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
            buyNowPrice: null,
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

      Future<LotCard> placeBid(
        JoinResult who,
        int amount, {
        int? expectedVersion,
        String? key,
        UuidValue? commandId,
      }) => endpoints.lot.placeBid(
        sessionBuilder,
        lot.lotId,
        who.participantId,
        key ?? who.participantKey,
        amount,
        expectedVersion ?? lot.version,
        commandId ?? const Uuid().v7obj(),
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

      test('a bid returns the fresh card, writes the ledger and pushes '
          'both', () async {
        final received = await watch();

        final card = await placeBid(budi, 250000);
        await settle();

        expect(card.currentPrice, 250000);
        expect(card.leaderId, budi.participantId);
        expect(card.leaderName, 'Budi');
        expect(card.bidCount, 1);
        expect(card.version, lot.version + 1);
        final stored = await taro
            .runtime(session)
            .repository<Lot, LotId>()
            .load(LotId.fromExisting(lot.lotId.uuid));
        expect(card.version, stored.version);

        final entry = (await LedgerEntry.db.find(session)).single;
        expect(entry.lotId, lot.lotId);
        expect(entry.sequence, 1);
        expect(entry.participantId, budi.participantId);
        expect(entry.bidderName, 'Budi');
        expect(entry.amount, 250000);
        expect(entry.retracted, isFalse);

        final update = received.singleWhere(
          (u) => u.kind == LiveUpdateKind.lotChanged,
        );
        expect(update.lot?.currentPrice, 250000);
        expect(update.lot?.version, card.version);
        expect(update.ledgerEntry?.sequence, 1);
        expect(update.ledgerEntry?.bidderName, 'Budi');
      });

      test('a wrong key is NOT_PARTICIPANT and stores nothing', () async {
        final received = await watch();

        await expectLater(
          placeBid(budi, 175000, key: sari.participantKey),
          failsWith('NOT_PARTICIPANT'),
        );
        await settle();

        expect(await lotEvents(), ['LotCreated']);
        expect(await LedgerEntry.db.count(session), 0);
        expect(received, isEmpty);
      });

      test('a valid key from another auction is NOT_PARTICIPANT', () async {
        final other = await endpoints.auction.create(
          sessionBuilder,
          'Batik night',
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        );
        final tono = await endpoints.auction.join(
          sessionBuilder,
          other.code,
          'Tono',
        );

        await expectLater(placeBid(tono, 175000), failsWith('NOT_PARTICIPANT'));
        expect(await lotEvents(), ['LotCreated']);
      });

      test('an off-ladder raise is INVALID_INCREMENT', () async {
        await expectLater(
          placeBid(budi, 220000),
          throwsA(
            isA<TaroDomainException>()
                .having((e) => e.code, 'code', 'INVALID_INCREMENT')
                .having((e) => e.context, 'context', contains('150000')),
          ),
        );
        expect(await lotEvents(), ['LotCreated']);
      });

      test('an unknown lot is AGGREGATE_NOT_FOUND', () async {
        await expectLater(
          endpoints.lot.placeBid(
            sessionBuilder,
            const Uuid().v4obj(),
            budi.participantId,
            budi.participantKey,
            175000,
            1,
            const Uuid().v7obj(),
          ),
          failsWith('AGGREGATE_NOT_FOUND'),
        );
      });

      test('a resend with the same command ID places one bid', () async {
        final commandId = const Uuid().v7obj();

        final first = await placeBid(budi, 175000, commandId: commandId);
        final again = await placeBid(budi, 175000, commandId: commandId);

        expect(again.version, first.version);
        expect(await LedgerEntry.db.count(session), 1);
        expect(await lotEvents(), ['LotCreated', 'BidPlaced']);
      });

      test('two bids on one version: one card, one ledger row, one '
          'OUTBID', () async {
        final results = await Future.wait([
          for (final (who, amount) in [(budi, 250000), (sari, 175000)])
            placeBid(
              who,
              amount,
            ).then<Object>((card) => card, onError: (Object e) => e),
        ]);

        final card = results.whereType<LotCard>().single;
        final outbid = results.whereType<TaroDomainException>().single;
        expect(outbid.code, 'OUTBID');
        expect(outbid.context, contains('${card.currentPrice}'));
        expect(outbid.context, contains(card.leaderName));
        expect(await LedgerEntry.db.count(session), 1);
        expect(await lotEvents(), ['LotCreated', 'BidPlaced']);
        final stored = (await LotCard.db.findFirstRow(
          session,
          where: (t) => t.lotId.equals(lot.lotId),
        ))!;
        expect(stored.bidCount, 1);
        expect(stored.version, card.version);
      });
    },
  );
}
