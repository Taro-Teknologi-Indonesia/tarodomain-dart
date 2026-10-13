import 'dart:async';

import 'package:gavel_server/src/domain/auction.dart';
import 'package:gavel_server/src/domain/auction_commands.dart';
import 'package:gavel_server/src/domain/keys.dart';
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
    'Given Gavel on SQLite',
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

      /// Watches [code] and collects every update it gets.
      Future<List<LiveUpdate>> watch(String code) async {
        final received = <LiveUpdate>[];
        subscriptions.add(
          endpoints.live.watch(sessionBuilder, code).listen(received.add),
        );
        await flushEventQueue();
        return received;
      }

      Future<void> createAuction(String code) => taro.dispatch(
        session,
        CreateAuction(
          AuctionId.generate(),
          title: 'Bonsai night',
          closeAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          code: code,
          organizerKeyHash: hashKey('secret'),
        ),
      );

      /// Lets posted messages reach the stream listeners.
      Future<void> settle() => Future.delayed(const Duration(milliseconds: 50));

      test('a committed command reaches the watchers of its auction', () async {
        final first = await watch('ABC234');
        final second = await watch('abc234');
        final other = await watch('XYZ789');

        await createAuction('ABC234');
        await settle();

        for (final received in [first, second]) {
          expect(received, hasLength(1));
          expect(received.single.kind, LiveUpdateKind.auctionChanged);
          expect(received.single.auction?.code, 'ABC234');
          expect(received.single.auction?.title, 'Bonsai night');
          expect(received.single.auction?.status, 'OPEN');
        }
        expect(other, isEmpty);
      });

      test('a command that fails in the projection posts nothing', () async {
        await createAuction('ABC234');
        final received = await watch('ABC234');

        // The duplicate code fails the projection's insert.
        await expectLater(
          createAuction('ABC234'),
          throwsA(
            isA<TaroDomainException>().having(
              (e) => e.code,
              'code',
              'PROJECTION_HANDLER_FAILED',
            ),
          ),
        );
        await settle();

        expect(received, isEmpty);
        expect(await AuctionView.db.count(session), 1);
      });

      test('ping reaches every watcher', () async {
        final first = await watch('TEST');
        final second = await watch('TEST');

        await endpoints.live.ping(sessionBuilder, 'test');
        await settle();

        for (final received in [first, second]) {
          expect(received, hasLength(1));
          expect(received.single.kind, LiveUpdateKind.ping);
          expect(received.single.auction, isNull);
        }
      });
    },
  );
}
