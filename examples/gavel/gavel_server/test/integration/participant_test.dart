import 'package:gavel_server/src/domain/participant.dart';
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

      setUp(() async {
        session = sessionBuilder.build();
        await clearTables(session);
        TaroDomainServerpod(gavelServerDefinition()).install();
      });

      Future<CreatedAuction> createAuction() => endpoints.organizer.create(
        signedIn(sessionBuilder),
        'Bonsai night',
        DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      Matcher failsWith(String code) => throwsA(
        isA<TaroDomainException>().having((e) => e.code, 'code', code),
      );

      test('join stores a row and records ParticipantJoined', () async {
        final created = await createAuction();

        final joined = await endpoints.auction.join(
          sessionBuilder,
          ' ${created.code.toLowerCase()} ',
          '  Budi ',
        );

        expect(joined.displayName, 'Budi');
        expect(joined.auction.auctionId, created.auctionId);
        final row = (await ParticipantRow.db.findById(
          session,
          joined.participantId,
        ))!;
        expect(row.auctionId, created.auctionId);
        expect(row.displayName, 'Budi');
        expect(row.version, 1);

        final events = await TaroEventRow.db.find(
          session,
          where: (t) =>
              t.streamId.equals('Participant-${joined.participantId.uuid}'),
        );
        expect([for (final e in events) e.eventType], ['ParticipantJoined']);
      });

      test('join on an unknown code fails with AUCTION_NOT_FOUND', () async {
        await expectLater(
          endpoints.auction.join(sessionBuilder, 'NOPE42', 'Budi'),
          failsWith('AUCTION_NOT_FOUND'),
        );
        expect(await ParticipantRow.db.count(session), 0);
      });

      test('join with an empty name fails on displayName', () async {
        final created = await createAuction();

        await expectLater(
          endpoints.auction.join(sessionBuilder, created.code, '  '),
          throwsA(
            isA<TaroDomainException>()
                .having((e) => e.code, 'code', 'COMMAND_VALIDATION')
                .having((e) => e.context, 'context', contains('displayName')),
          ),
        );
      });

      test('join on a closed auction still succeeds', () async {
        final created = await createAuction();
        final view = (await AuctionView.db.findFirstRow(
          session,
          where: (t) => t.auctionId.equals(created.auctionId),
        ))!;
        await AuctionView.db.updateRow(
          session,
          view.copyWith(status: 'CLOSED'),
        );

        final joined = await endpoints.auction.join(
          sessionBuilder,
          created.code,
          'Budi',
        );

        expect(joined.auction.status, 'CLOSED');
      });

      test(
        'the row keeps only the key hash; the key is stored nowhere',
        () async {
          final created = await createAuction();
          final joined = await endpoints.auction.join(
            sessionBuilder,
            created.code,
            'Budi',
          );

          final row = (await ParticipantRow.db.findById(
            session,
            joined.participantId,
          ))!;
          expect(row.keyHash, isNotEmpty);
          expect(row.keyHash, isNot(contains(joined.participantKey)));
          expect(
            await ParticipantRow.db.count(
              session,
              where: (t) =>
                  t.displayName.like('%${joined.participantKey}%') |
                  t.keyHash.like('%${joined.participantKey}%'),
            ),
            0,
          );
          final events = await TaroEventRow.db.find(session);
          expect(events, isNotEmpty);
          for (final event in events) {
            expect(event.payload, isNot(contains(joined.participantKey)));
            expect(event.payload, isNot(contains(row.keyHash)));
          }
        },
      );

      group('checkParticipant', () {
        late CreatedAuction created;
        late JoinResult joined;

        setUp(() async {
          created = await createAuction();
          joined = await endpoints.auction.join(
            sessionBuilder,
            created.code,
            'Budi',
          );
        });

        test('accepts the right key', () async {
          expect(
            await endpoints.auction.checkParticipant(
              sessionBuilder,
              created.code.toLowerCase(),
              joined.participantId,
              joined.participantKey,
            ),
            isTrue,
          );
        });

        test('refuses a wrong key', () async {
          expect(
            await endpoints.auction.checkParticipant(
              sessionBuilder,
              created.code,
              joined.participantId,
              'not-the-key',
            ),
            isFalse,
          );
        });

        test("refuses another auction's code", () async {
          final other = await createAuction();

          expect(
            await endpoints.auction.checkParticipant(
              sessionBuilder,
              other.code,
              joined.participantId,
              joined.participantKey,
            ),
            isFalse,
          );
        });

        test('refuses an unknown participant or code', () async {
          expect(
            await endpoints.auction.checkParticipant(
              sessionBuilder,
              created.code,
              ParticipantId.generate().value,
              joined.participantKey,
            ),
            isFalse,
          );
          expect(
            await endpoints.auction.checkParticipant(
              sessionBuilder,
              'NOPE42',
              joined.participantId,
              joined.participantKey,
            ),
            isFalse,
          );
        });
      });
    },
  );
}
