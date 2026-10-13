import 'dart:async';

import 'package:gavel_server/src/domain/auction.dart';
import 'package:gavel_server/src/domain/lot.dart';
import 'package:gavel_server/src/domain/lot_commands.dart';
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
      final subscriptions = <StreamSubscription<LiveUpdate>>[];

      setUp(() async {
        session = sessionBuilder.build();
        await clearTables(session);
        taro = TaroDomainServerpod(gavelServerDefinition())..install();
      });

      tearDown(() async {
        for (final s in subscriptions) {
          await s.cancel();
        }
        subscriptions.clear();
      });

      Future<CreatedAuction> createAuction() => endpoints.auction.create(
        sessionBuilder,
        'Bonsai night',
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      NewLot pirus({
        String name = 'Natural Pirus Hubei',
        int openBid = 150000,
      }) => NewLot(
        name: name,
        openBid: openBid,
        increments: [50000, 25000, 100000],
        description: 'Berat: 2 kg\nAsal: Hubei',
        imageUrl: 'https://example.com/pirus.jpg',
        tileEmoji: '💎',
        tileColor: '#2e7d6b',
      );

      Future<Lot> loadLot(UuidValue lotId) => taro
          .runtime(session)
          .repository<Lot, LotId>()
          .load(LotId.fromExisting(lotId.uuid));

      Future<AuctionView> view(CreatedAuction created) async =>
          (await AuctionView.db.findFirstRow(
            session,
            where: (t) => t.auctionId.equals(created.auctionId),
          ))!;

      /// Watches [code] and collects every update it gets.
      Future<List<LiveUpdate>> watch(String code) async {
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

      test('add stores an open card and pushes it to the board', () async {
        final created = await createAuction();
        final received = await watch(created.code);

        final card = await endpoints.lot.add(
          sessionBuilder,
          created.code.toLowerCase(),
          created.organizerKey,
          pirus(),
        );
        await settle();

        expect(card.code, created.code);
        expect(card.auctionId, created.auctionId);
        expect(card.position, 0);
        expect(card.name, 'Natural Pirus Hubei');
        expect(card.description, 'Berat: 2 kg\nAsal: Hubei');
        expect(card.increments, [25000, 50000, 100000]);
        expect(card.tileColor, '#2E7D6B');
        expect(card.currentPrice, 150000);
        expect(card.status, 'OPEN');
        expect(card.bidCount, 0);
        expect(card.leaderId, isNull);
        expect(card.version, (await loadLot(card.lotId)).version);

        final lotUpdates = [
          for (final u in received)
            if (u.kind == LiveUpdateKind.lotChanged) u,
        ];
        expect(lotUpdates, hasLength(1));
        expect(lotUpdates.single.lot?.lotId, card.lotId);
        expect(lotUpdates.single.lot?.currentPrice, 150000);
        expect([for (final u in received) u.auction?.lotCount], contains(1));
        expect((await view(created)).lotCount, 1);
      });

      test('board lists the lots in order', () async {
        final created = await createAuction();
        for (final name in ['First', 'Second', 'Third']) {
          await endpoints.lot.add(
            sessionBuilder,
            created.code,
            created.organizerKey,
            pirus(name: name),
          );
        }

        final board = await endpoints.auction.board(
          sessionBuilder,
          created.code,
        );

        expect(
          [for (final lot in board.lots) lot.name],
          ['First', 'Second', 'Third'],
        );
        expect([for (final lot in board.lots) lot.position], [0, 1, 2]);
        expect(board.auction.lotCount, 3);
      });

      test('the wrong organizer key is NOT_ORGANIZER', () async {
        final created = await createAuction();
        final received = await watch(created.code);

        await expectLater(
          endpoints.lot.add(sessionBuilder, created.code, 'guess', pirus()),
          failsWith('NOT_ORGANIZER'),
        );
        await settle();

        expect(await LotCard.db.count(session), 0);
        expect(received, isEmpty);
      });

      test('an open bid of 0 is COMMAND_VALIDATION on openBid', () async {
        final created = await createAuction();

        await expectLater(
          endpoints.lot.add(
            sessionBuilder,
            created.code,
            created.organizerKey,
            pirus(openBid: 0),
          ),
          throwsA(
            isA<TaroDomainException>()
                .having((e) => e.code, 'code', 'COMMAND_VALIDATION')
                .having((e) => e.context, 'context', contains('"openBid"')),
          ),
        );
      });

      test('an unknown code is AUCTION_NOT_FOUND', () async {
        await expectLater(
          endpoints.lot.add(sessionBuilder, 'ZZZZZZ', 'key', pirus()),
          failsWith('AUCTION_NOT_FOUND'),
        );
      });

      test('a failure after the lot append rolls the lot back too', () async {
        final created = await createAuction();
        // Without its row, the auction projection fails on LotRegistered,
        // after the lot's events were appended in the same unit of work.
        await AuctionView.db.deleteWhere(
          session,
          where: (t) => t.auctionId.equals(created.auctionId),
        );
        final lotId = LotId.generate();

        await expectLater(
          taro.dispatch(
            session,
            AddLot(
              AuctionId.fromExisting(created.auctionId.uuid),
              lotId,
              organizerKey: created.organizerKey,
              name: 'Natural Pirus Hubei',
              openBid: 150000,
              increments: [25000],
              description: '',
              imageUrl: null,
              tileEmoji: '💎',
              tileColor: '#2E7D6B',
            ),
          ),
          failsWith('PROJECTION_HANDLER_FAILED'),
        );

        expect(
          await taro.runtime(session).repository<Lot, LotId>().exists(lotId),
          isFalse,
        );
        expect(await LotCard.db.count(session), 0);
        final auction = await taro
            .runtime(session)
            .repository<Auction, AuctionId>()
            .load(AuctionId.fromExisting(created.auctionId.uuid));
        expect(auction.lotIds, isEmpty);
      });

      test('lots added in parallel all land, each in its own place', () async {
        // The losers of the race on the auction stream retry; that only
        // works if their first attempt's lot append was rolled back.
        final created = await createAuction();

        final cards = await Future.wait([
          for (var i = 0; i < 4; i++)
            endpoints.lot.add(
              sessionBuilder,
              created.code,
              created.organizerKey,
              pirus(name: 'Lot $i'),
            ),
        ]);

        expect({for (final c in cards) c.position}, {0, 1, 2, 3});
        expect(await LotCard.db.count(session), 4);
        expect((await view(created)).lotCount, 4);
        final auction = await taro
            .runtime(session)
            .repository<Auction, AuctionId>()
            .load(AuctionId.fromExisting(created.auctionId.uuid));
        expect(auction.lotIds, hasLength(4));
        for (final card in cards) {
          expect(card.version, (await loadLot(card.lotId)).version);
        }
      });
    },
  );
}
