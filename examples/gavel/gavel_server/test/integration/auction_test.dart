import 'package:gavel_server/src/domain/auction.dart';
import 'package:gavel_server/src/domain/auction_commands.dart';
import 'package:gavel_server/src/domain/keys.dart';
import 'package:gavel_server/src/gavel.dart';
import 'package:gavel_server/src/generated/protocol.dart';
import 'package:serverpod/protocol.dart' show FutureCallEntry;
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
      final auctions = endpoints.auction;
      late Session session;
      late TaroDomainServerpod taro;

      setUp(() async {
        session = sessionBuilder.build();
        await clearTables(session);
        taro = TaroDomainServerpod(gavelServerDefinition())..install();
      });

      DateTime inAnHour() =>
          DateTime.now().toUtc().add(const Duration(hours: 1));

      test('create stores an open auction and schedules its close', () async {
        final requested = inAnHour();
        final closeAt = requested.subtract(
          Duration(microseconds: requested.microsecondsSinceEpoch % 1000000),
        );

        final created = await endpoints.organizer.create(
          signedIn(sessionBuilder),
          'Bonsai night',
          requested,
        );

        expect(created.code, matches(RegExp(r'^[A-HJKMNP-Z2-9]{6}$')));
        expect(created.closeAt, closeAt);
        expect(created.organizerKey, hasLength(43));

        final view = await AuctionView.db.findFirstRow(
          session,
          where: (t) => t.auctionId.equals(created.auctionId),
        );
        expect(view?.code, created.code);
        expect(view?.title, 'Bonsai night');
        expect(view?.status, 'OPEN');
        expect(view?.lotCount, 0);
        expect(view?.closeAt, closeAt);

        final calls = await FutureCallEntry.db.find(
          session,
          where: (t) => t.identifier.equals('close-${created.auctionId.uuid}'),
        );
        expect(calls, hasLength(1));
        expect(calls.single.name, 'AuctionCloseCallsCloseFutureCall');
        expect(calls.single.time, closeAt);

        final auction = await taro
            .runtime(session)
            .repository<Auction, AuctionId>()
            .load(AuctionId.fromExisting(created.auctionId.uuid));
        expect(auction.isOrganizer(created.organizerKey), isTrue);
        expect(auction.organizerKeyHash, hashKey(created.organizerKey));
      });

      test('a close time too soon is a typed validation error', () async {
        await expectLater(
          endpoints.organizer.create(
            signedIn(sessionBuilder),
            'Bonsai night',
            DateTime.now().toUtc().add(const Duration(minutes: 2)),
          ),
          throwsA(
            isA<TaroDomainException>()
                .having((e) => e.code, 'code', 'COMMAND_VALIDATION')
                .having((e) => e.context, 'context', contains('TOO_SOON')),
          ),
        );

        expect(await AuctionView.db.count(session), 0);
        expect(await FutureCallEntry.db.count(session), 0);
      });

      test('a taken join code rolls the whole command back', () async {
        // What the endpoint's retry relies on.
        CreateAuction withCode(AuctionId id) => CreateAuction(
          id,
          title: 'Bonsai night',
          closeAt: inAnHour(),
          code: 'ABC234',
          organizerKeyHash: hashKey('key'),
        );
        await taro.dispatch(session, withCode(AuctionId.generate()));
        final second = AuctionId.generate();

        await expectLater(
          taro.dispatch(session, withCode(second)),
          throwsA(
            isA<TaroDomainException>().having(
              (e) => e.code,
              'code',
              'PROJECTION_HANDLER_FAILED',
            ),
          ),
        );

        expect(
          await taro
              .runtime(session)
              .repository<Auction, AuctionId>()
              .exists(second),
          isFalse,
        );
      });

      test('board finds the auction by code, in any case', () async {
        final created = await endpoints.organizer.create(
          signedIn(sessionBuilder),
          'Bonsai night',
          inAnHour(),
        );

        final board = await auctions.board(
          sessionBuilder,
          ' ${created.code.toLowerCase()} ',
        );

        expect(board.auction.auctionId, created.auctionId);
        expect(
          board.serverNow.difference(DateTime.now().toUtc()).abs(),
          lessThan(const Duration(seconds: 5)),
        );
      });

      test('board on an unknown code is AUCTION_NOT_FOUND', () async {
        await expectLater(
          auctions.board(sessionBuilder, 'ZZZZZZ'),
          throwsA(
            isA<TaroDomainException>().having(
              (e) => e.code,
              'code',
              'AUCTION_NOT_FOUND',
            ),
          ),
        );
      });
    },
  );
}
