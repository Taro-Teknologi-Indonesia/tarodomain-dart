import 'package:gavel_server/src/demo/demo_auctions.dart';
import 'package:gavel_server/src/domain/auction.dart';
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

      setUp(() async {
        session = sessionBuilder.build();
        await clearTables(session);
        taro = TaroDomainServerpod(gavelServerDefinition())..install();
      });

      DateTime inAnHour() =>
          DateTime.now().toUtc().add(const Duration(hours: 1));

      Future<Auction> load(UuidValue auctionId) => taro
          .runtime(session)
          .repository<Auction, AuctionId>()
          .load(AuctionId.fromExisting(auctionId.uuid));

      test('create without a signed-in user is refused', () async {
        await expectLater(
          endpoints.organizer.create(
            sessionBuilder,
            'Bonsai night',
            inAnHour(),
          ),
          throwsA(isA<ServerpodUnauthenticatedException>()),
        );

        expect(await AuctionView.db.count(session), 0);
      });

      test('create records the signed-in organizer as the creator', () async {
        final created = await endpoints.organizer.create(
          signedIn(sessionBuilder),
          'Bonsai night',
          inAnHour(),
        );

        expect(
          (await load(created.auctionId)).organizerUserId,
          organizerUserId,
        );
      });

      test('the demo auction has no creator', () async {
        final code = await ensureDemoOpen(session);

        final view = await AuctionView.db.findFirstRow(
          session,
          where: (t) => t.code.equals(code),
        );
        expect((await load(view!.auctionId)).organizerUserId, isNull);
      });
    },
  );
}
