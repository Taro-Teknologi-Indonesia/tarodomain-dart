import 'package:gavel_server/src/domain/auction.dart';
import 'package:gavel_server/src/domain/auction_close_saga.dart';
import 'package:gavel_server/src/domain/auction_commands.dart';
import 'package:gavel_server/src/domain/errors.dart';
import 'package:gavel_server/src/domain/gavel_domain.dart';
import 'package:gavel_server/src/domain/keys.dart';
import 'package:gavel_server/src/domain/lot.dart';
import 'package:gavel_server/src/domain/lot_commands.dart';
import 'package:gavel_server/src/domain/participant.dart';
import 'package:gavel_server/src/domain/participant_commands.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';
import 'package:test/test.dart';

void main() {
  for (final mode in ConsistencyMode.values) {
    group('closing an auction, ${mode.name}', () {
      late TaroDomain gavel;
      late AuctionId auctionId;
      late LotId pirus;
      late LotId juniper;
      late ParticipantId budi;
      late ParticipantId sari;
      final now = DateTime.utc(2026, 10, 14, 12, 0);
      final closeAt = now.add(const Duration(hours: 2));
      const organizerKey = 'organizer-secret';

      Future<LotId> addLot(String name) async {
        final id = LotId.generate();
        await gavel.dispatch(
          AddLot(
            auctionId,
            id,
            organizerKey: organizerKey,
            name: name,
            openBid: 150000,
            increments: const [25000, 50000, 100000],
            buyNowPrice: null,
            description: '',
            imageUrl: null,
            tileEmoji: '💎',
            tileColor: '#2E7D6B',
            timestamp: now,
          ),
        );
        return id;
      }

      Future<ParticipantId> join(String name) async {
        final id = ParticipantId.generate();
        await gavel.dispatch(
          JoinAuction(
            id,
            auctionId: auctionId.uuid,
            displayName: name,
            keyHash: hashKey('$name-key'),
          ),
        );
        return id;
      }

      Future<void> bid(
        LotId lot,
        ParticipantId who,
        int amount,
        int expectedVersion,
      ) => gavel.dispatch(
        PlaceBid(
          lot,
          who,
          amount: amount,
          expectedVersion: expectedVersion,
          timestamp: now.add(const Duration(minutes: 1)),
        ),
      );

      Future<void> close({DateTime? at}) => gavel.dispatch(
        CloseAuction(
          auctionId,
          timestamp: at ?? closeAt.add(const Duration(seconds: 2)),
        ),
      );

      Future<List<String>> events(String stream) async => [
        for (final e in await gavel.eventStore.loadStream(stream)) e.eventName,
      ];

      Future<Lot> loadLot(LotId id) => gavel.repository<Lot, LotId>().load(id);

      Future<Auction> loadAuction() =>
          gavel.repository<Auction, AuctionId>().load(auctionId);

      setUp(() async {
        gavel = registerGavel(
          TaroDomain.builder().useLocal().consistency(mode),
        ).build().createRuntime();
        auctionId = AuctionId.generate();
        await gavel.dispatch(
          CreateAuction(
            auctionId,
            title: 'Bonsai night',
            closeAt: closeAt,
            code: 'ABC234',
            organizerKeyHash: hashKey(organizerKey),
            timestamp: now,
          ),
        );
        pirus = await addLot('Natural Pirus Hubei');
        juniper = await addLot('Shimpaku juniper');
        budi = await join('Budi');
        sari = await join('Sari');
      });

      test('sells a lot to its highest valid bid, passes one with none, '
          'and finalizes the auction', () async {
        await bid(pirus, budi, 175000, 1);
        await bid(pirus, sari, 275000, 2);

        await close();

        final sold = await loadLot(pirus);
        expect(sold.status, LotStatus.sold);
        final closed =
            (await gavel.eventStore.loadStream('Lot-${pirus.uuid}')).last
                as LotClosed;
        expect(closed.outcome, LotStatus.sold);
        expect(closed.winnerId, sari.uuid);
        expect(closed.winnerName, 'Sari');
        expect(closed.finalPrice, 275000);
        expect(closed.cause, LotCloseCause.deadline);
        // Dated at the advertised close time, not when the trigger fired.
        expect(closed.closedAt, closeAt);

        expect((await loadLot(juniper)).status, LotStatus.passed);
        expect((await loadAuction()).status, AuctionStatus.closed);
        expect(await events('Auction-${auctionId.uuid}'), [
          'AuctionCreated',
          'LotRegistered',
          'LotRegistered',
          'AuctionClosed',
          'AuctionFinalized',
        ]);
      });

      test('passes a lot whose every bid was retracted', () async {
        await bid(pirus, budi, 175000, 1);
        await gavel.dispatch(
          RetractBid(
            pirus,
            budi,
            expectedVersion: 2,
            timestamp: now.add(const Duration(minutes: 2)),
          ),
        );

        await close();

        final closed =
            (await gavel.eventStore.loadStream('Lot-${pirus.uuid}')).last
                as LotClosed;
        expect(closed.outcome, LotStatus.passed);
        expect(closed.winnerId, isNull);
        expect(closed.finalPrice, isNull);
      });

      test('a second close raises nothing', () async {
        await close();
        await close(at: closeAt.add(const Duration(seconds: 7)));

        expect(
          (await events(
            'Auction-${auctionId.uuid}',
          )).where((e) => e == 'AuctionClosed'),
          hasLength(1),
        );
        expect(
          (await events('Lot-${pirus.uuid}')).where((e) => e == 'LotClosed'),
          hasLength(1),
        );
      });

      test('a close before the close time is TOO_EARLY', () async {
        await expectLater(
          close(at: closeAt.subtract(const Duration(seconds: 1))),
          throwsA(
            isA<CommandValidationError>().having(
              (e) => e.context['reason'],
              'reason',
              'TOO_EARLY',
            ),
          ),
        );
        expect((await loadAuction()).status, AuctionStatus.open);
      });

      test('a bid on a closed lot names its close time', () async {
        await close();
        await expectLater(
          bid(pirus, budi, 175000, 1),
          throwsA(isA<LotClosedError>()),
        );
      });
    });
  }

  group('AuctionClosed on an auction with no lots', () {
    test('finalizes straight away', () {
      final auctionId = AuctionId.generate();
      final saga = AuctionCloseSaga();
      final commands = saga.handle(AuctionClosed(auctionId.uuid, lotIds: []));
      expect(commands, [isA<FinalizeAuction>()]);
    });
  });

  group('AuctionCloseSaga', () {
    final auctionId = AuctionId.generate();
    final l1 = LotId.generate().uuid;
    final l2 = LotId.generate().uuid;

    LotClosed lotClosed(String lotId) => LotClosed(
      lotId,
      auctionId: auctionId.uuid,
      outcome: LotStatus.passed,
      cause: LotCloseCause.deadline,
      closedAt: DateTime.utc(2026, 10, 14, 22, 3),
    );

    SagaTimeout timeoutFor(AuctionCloseSaga saga) {
      final now = DateTime.timestamp();
      return SagaTimeout.forRecord(
        SagaRecord(
          sagaId: saga.sagaId!,
          sagaType: saga.sagaType,
          correlationId: saga.sagaId!,
          state: saga.toSaveInput().state,
          status: SagaStatus.running,
          startedAt: now,
          updatedAt: now,
        ),
        const Duration(seconds: 30),
      );
    }

    test('closes every lot, then finalizes and completes', () {
      final saga = AuctionCloseSaga();
      final start = saga.handle(
        AuctionClosed(auctionId.uuid, lotIds: [l1, l2]),
      );
      expect([for (final c in start) (c as CloseLot).lotId.uuid], [l1, l2]);
      expect(start.cast<CloseLot>().map((c) => c.cause).toSet(), {
        LotCloseCause.deadline,
      });

      expect(saga.handle(lotClosed(l1)), isEmpty);
      final last = saga.handle(lotClosed(l2));
      expect(last, [isA<FinalizeAuction>()]);
      expect((last.single as FinalizeAuction).auctionId, auctionId);

      saga.handle(AuctionFinalized(auctionId.uuid));
      expect(saga.status, SagaStatus.completed);
    });

    test('a timeout closes the remaining lots again and finalizes', () {
      final saga = AuctionCloseSaga()
        ..handle(AuctionClosed(auctionId.uuid, lotIds: [l1, l2]))
        ..handle(lotClosed(l1));

      final commands = saga.handle(timeoutFor(saga));
      expect(commands, [isA<CloseLot>(), isA<FinalizeAuction>()]);
      expect((commands.first as CloseLot).lotId.uuid, l2);

      // A late LotClosed after the retry asks for nothing more.
      expect(saga.handle(lotClosed(l2)), isEmpty);
      saga.handle(AuctionFinalized(auctionId.uuid));
      expect(saga.status, SagaStatus.completed);
    });

    test('a lot closed outside the saga is finalized through the timeout '
        'end to end', () async {
      final gavel = registerGavel(
        TaroDomain.builder().useLocal().consistency(ConsistencyMode.strong),
      ).build().createRuntime();
      final now = DateTime.utc(2026, 10, 14, 12, 0);
      final closeAt = now.add(const Duration(hours: 2));
      final id = AuctionId.generate();
      await gavel.dispatch(
        CreateAuction(
          id,
          title: 'Bonsai night',
          closeAt: closeAt,
          code: 'XYZ789',
          organizerKeyHash: hashKey('k'),
          timestamp: now,
        ),
      );
      final lot = LotId.generate();
      await gavel.dispatch(
        AddLot(
          id,
          lot,
          organizerKey: 'k',
          name: 'Pirus',
          openBid: 150000,
          increments: const [25000],
          buyNowPrice: null,
          description: '',
          imageUrl: null,
          tileEmoji: '💎',
          tileColor: '#2E7D6B',
          timestamp: now,
        ),
      );
      // Closed by another path first (a Buy Now, UC-13), so the saga's
      // CloseLot raises nothing and no LotClosed reaches it.
      await gavel.dispatch(CloseLot(lot, LotCloseCause.buyNow, timestamp: now));
      final close = CloseAuction(id, timestamp: closeAt);
      await gavel.dispatch(close);

      final auctions = gavel.repository<Auction, AuctionId>();
      expect((await auctions.load(id)).status, AuctionStatus.closing);

      final saga = await gavel.sagaStore.load(
        'AuctionCloseSaga',
        close.correlationId,
      );
      final timeout = SagaTimeout.forRecord(saga!, const Duration(seconds: 30));
      final handler = AuctionCloseSaga()..restore(saga);
      for (final c in handler.handle(timeout)) {
        await gavel.dispatch(c);
      }
      expect((await auctions.load(id)).status, AuctionStatus.closed);
    });
  });
}
