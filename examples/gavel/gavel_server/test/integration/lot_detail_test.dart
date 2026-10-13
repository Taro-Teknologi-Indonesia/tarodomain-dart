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
    'Given a lot with bids on PostgreSQL',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      late Session session;
      late TaroDomainServerpod taro;
      late CreatedAuction created;
      late LotCard lot;

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
        final budi = await endpoints.auction.join(
          sessionBuilder,
          created.code,
          'Budi',
        );
        final sari = await endpoints.auction.join(
          sessionBuilder,
          created.code,
          'Sari',
        );
        for (final (who, amount) in [
          (budi, 175000),
          (sari, 225000),
          (budi, 250000),
        ]) {
          lot = await endpoints.lot.placeBid(
            sessionBuilder,
            lot.lotId,
            who.participantId,
            who.participantKey,
            amount,
            lot.version,
            const Uuid().v7obj(),
          );
        }
      });

      List<(int, String, int)> rows(LotDetail detail) => [
        for (final e in detail.ledger) (e.sequence, e.bidderName, e.amount),
      ];

      test('detail returns the card, every bid by sequence and the '
          'close', () async {
        final detail = await endpoints.lot.detail(sessionBuilder, lot.lotId);

        expect(detail.lot.version, lot.version);
        expect(detail.lot.currentPrice, 250000);
        expect(rows(detail), [
          (1, 'Budi', 175000),
          (2, 'Sari', 225000),
          (3, 'Budi', 250000),
        ]);
        expect(detail.ledger.every((e) => !e.retracted), isTrue);
        final board = await endpoints.auction.board(
          sessionBuilder,
          created.code,
        );
        expect(detail.closeAt, board.auction.closeAt);
      });

      test('an unknown lot is AGGREGATE_NOT_FOUND', () async {
        await expectLater(
          endpoints.lot.detail(sessionBuilder, const Uuid().v4obj()),
          throwsA(
            isA<TaroDomainException>().having(
              (e) => e.code,
              'code',
              'AGGREGATE_NOT_FOUND',
            ),
          ),
        );
      });

      test('a late joiner sees the ledger the events rebuild', () async {
        final before = await endpoints.lot.detail(sessionBuilder, lot.lotId);

        final runtime = taro.runtime(session);
        final result = await runtime.projectionRebuilder.rebuild(
          runtime.projection('lots'),
        );
        expect(result.completed, isTrue, reason: '${result.error}');

        final after = await endpoints.lot.detail(sessionBuilder, lot.lotId);
        expect(rows(after), rows(before));
        expect(
          [for (final e in after.ledger) (e.participantId, e.placedAt)],
          [for (final e in before.ledger) (e.participantId, e.placedAt)],
        );
        expect(
          after.lot.toJson()..remove('id'),
          before.lot.toJson()..remove('id'),
        );
      });
    },
  );
}
