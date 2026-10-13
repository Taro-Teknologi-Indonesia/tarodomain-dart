import 'package:gavel_server/src/domain/auction.dart';
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
    group('marking a lot unpaid, ${mode.name}', () {
      late TaroDomain gavel;
      late AuctionId auctionId;
      late LotId pirus;
      late LotId juniper;
      final now = DateTime.utc(2026, 10, 14, 12, 0);
      final closeAt = now.add(const Duration(hours: 2));
      final markedAt = closeAt.add(const Duration(hours: 20));
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
            increments: const [25000, 50000],
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

      Future<void> close() => gavel.dispatch(
        CloseAuction(
          auctionId,
          timestamp: closeAt.add(const Duration(seconds: 2)),
        ),
      );

      Future<void> markUnpaid(
        LotId lot, {
        String key = organizerKey,
        String? note,
      }) => gavel.dispatch(
        MarkUnpaid(lot, organizerKey: key, note: note, timestamp: markedAt),
      );

      Future<List<String>> events(LotId lot) async => [
        for (final e in await gavel.eventStore.loadStream('Lot-${lot.uuid}'))
          e.eventName,
      ];

      Matcher refusedWith(String reason) => throwsA(
        isA<CommandValidationError>().having(
          (e) => e.context['reason'],
          'reason',
          reason,
        ),
      );

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
        final sari = ParticipantId.generate();
        await gavel.dispatch(
          JoinAuction(
            sari,
            auctionId: auctionId.uuid,
            displayName: 'Sari',
            keyHash: hashKey('sari-key'),
          ),
        );
        await gavel.dispatch(
          PlaceBid(
            pirus,
            sari,
            amount: 175000,
            expectedVersion: 1,
            timestamp: now.add(const Duration(minutes: 1)),
          ),
        );
      });

      test(
        'a SOLD lot gets the mark after the sale, naming the winner',
        () async {
          await close();
          await markUnpaid(pirus, note: '  no reply after 24 h ');

          expect(await events(pirus), [
            'LotCreated',
            'BidPlaced',
            'LotClosed',
            'LotMarkedUnpaid',
          ]);
          final marked =
              (await gavel.eventStore.loadStream('Lot-${pirus.uuid}')).last
                  as LotMarkedUnpaid;
          expect(marked.winnerName, 'Sari');
          expect(marked.markedAt, markedAt);
          expect(marked.note, 'no reply after 24 h');

          final lot = await gavel.repository<Lot, LotId>().load(pirus);
          expect(lot.unpaid, isTrue);
          expect(lot.status, LotStatus.sold);
        },
      );

      test('a blank note is no note', () async {
        await close();
        await markUnpaid(pirus, note: '   ');

        final marked =
            (await gavel.eventStore.loadStream('Lot-${pirus.uuid}')).last
                as LotMarkedUnpaid;
        expect(marked.note, isNull);
      });

      test('marking twice raises one event', () async {
        await close();
        await markUnpaid(pirus);
        await markUnpaid(pirus, note: 'again');

        expect(
          (await events(pirus)).where((e) => e == 'LotMarkedUnpaid'),
          hasLength(1),
        );
      });

      test('an OPEN lot is NOT_SOLD', () async {
        await expectLater(markUnpaid(pirus), refusedWith('NOT_SOLD'));
      });

      test('a PASSED lot is NOT_SOLD', () async {
        await close();
        await expectLater(markUnpaid(juniper), refusedWith('NOT_SOLD'));
        expect(await events(juniper), isNot(contains('LotMarkedUnpaid')));
      });

      test('a note over 140 characters is TOO_LONG', () async {
        await close();
        await expectLater(
          markUnpaid(pirus, note: 'x' * 141),
          refusedWith('TOO_LONG'),
        );
      });

      test('the wrong organizer key is NOT_ORGANIZER', () async {
        await close();
        await expectLater(
          markUnpaid(pirus, key: 'guess'),
          throwsA(isA<NotOrganizerError>()),
        );
        expect(await events(pirus), isNot(contains('LotMarkedUnpaid')));
      });
    });
  }

  test('a snapshot keeps the winner and the mark', () {
    final id = LotId.generate();
    final lot = Lot(id)
      ..winnerId = 'p1'
      ..winnerName = 'Sari'
      ..unpaid = true;
    final restored = Lot(id)..restoreSnapshotState(lot.toSnapshot());
    expect(restored.winnerId, 'p1');
    expect(restored.winnerName, 'Sari');
    expect(restored.unpaid, isTrue);

    // Snapshots from before UC-14 read as not marked.
    final old = lot.toSnapshot()..remove('unpaid');
    expect((Lot(id)..restoreSnapshotState(old)).unpaid, isFalse);
  });
}
