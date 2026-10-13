import 'package:gavel_server/src/domain/auction.dart';
import 'package:gavel_server/src/domain/auction_commands.dart';
import 'package:gavel_server/src/domain/keys.dart';
import 'package:gavel_server/src/domain/lot.dart';
import 'package:gavel_server/src/domain/lot_commands.dart';
import 'package:gavel_server/src/future_calls/auction_close_calls.dart';
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
    'Given a closed auction where one of two Budis won',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      late Session session;
      late TaroDomainServerpod taro;
      late AuctionId auctionId;
      late DateTime closeAt;
      late LotId pirus;
      late LotId juniper;
      late JoinResult budi;
      late JoinResult otherBudi;
      const code = 'WIN234';
      const organizerKey = 'organizer-secret';

      Future<LotId> addLot(String name) async {
        final id = LotId.generate();
        await taro.dispatch(
          session,
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
          ),
        );
        return id;
      }

      Future<String?> winnerCode(JoinResult who, LotId lot, {String? key}) =>
          endpoints.lot.winnerCode(
            sessionBuilder,
            lot.value,
            who.participantId,
            key ?? who.participantKey,
          );

      Future<void> close() async {
        // Timers round down to whole milliseconds; loop past closeAt.
        while (DateTime.now().toUtc().isBefore(closeAt)) {
          final wait = closeAt.difference(DateTime.now().toUtc());
          await Future<void>.delayed(wait + const Duration(milliseconds: 1));
        }
        // Not the sweep: it logs a failed close, and this should throw.
        await closeAuction(session, auctionId.value);
      }

      Matcher failsWith(String code) => throwsA(
        isA<TaroDomainException>().having((e) => e.code, 'code', code),
      );

      setUp(() async {
        session = sessionBuilder.build();
        await clearTables(session);
        taro = TaroDomainServerpod(gavelServerDefinition())..install();
        auctionId = AuctionId.generate();
        // The 5-minute lead is checked against the command's timestamp, so
        // a backdated create gets an auction that closes in 2 seconds.
        closeAt = DateTime.now().toUtc().add(const Duration(seconds: 2));
        await taro.dispatch(
          session,
          CreateAuction(
            auctionId,
            title: 'Bonsai night',
            closeAt: closeAt,
            code: code,
            organizerKeyHash: hashKey(organizerKey),
            timestamp: closeAt.subtract(const Duration(minutes: 10)),
          ),
        );
        pirus = await addLot('Natural Pirus Hubei');
        juniper = await addLot('Shimpaku juniper');
        budi = await endpoints.auction.join(sessionBuilder, code, 'Budi');
        otherBudi = await endpoints.auction.join(sessionBuilder, code, 'budi');
        await endpoints.lot.placeBid(
          sessionBuilder,
          pirus.value,
          otherBudi.participantId,
          otherBudi.participantKey,
          175000,
          1,
          const Uuid().v7obj(),
        );
        await endpoints.lot.placeBid(
          sessionBuilder,
          pirus.value,
          budi.participantId,
          budi.participantKey,
          200000,
          2,
          const Uuid().v7obj(),
        );
      });

      test('the winner gets a code, the namesake who lost gets none', () async {
        await close();

        final code = await winnerCode(budi, pirus);
        expect(code, matches(RegExp(r'^[0-9A-Z]{3}-[0-9A-Z]{3}$')));
        expect(await winnerCode(budi, pirus), code);
        expect(await winnerCode(otherBudi, pirus), isNull);
      });

      test('an open lot has no code yet', () async {
        expect(await winnerCode(budi, pirus), isNull);
      });

      test('a passed lot has no code', () async {
        await close();

        expect(await winnerCode(budi, juniper), isNull);
      });

      test(
        "the winner's ID with the namesake's key is NOT_PARTICIPANT",
        () async {
          await expectLater(
            winnerCode(budi, pirus, key: otherBudi.participantKey),
            failsWith('NOT_PARTICIPANT'),
          );
        },
      );

      test("the organizer sees the winner's code for every SOLD lot", () async {
        await close();

        final codes = await endpoints.auction.winnerCodes(
          sessionBuilder,
          code.toLowerCase(),
          organizerKey,
        );

        expect(codes, {pirus.uuid: await winnerCode(budi, pirus)});
      });

      test('a wrong organizer key is NOT_ORGANIZER', () async {
        await expectLater(
          endpoints.auction.winnerCodes(sessionBuilder, code, 'guess'),
          failsWith('NOT_ORGANIZER'),
        );
      });

      test('no event carries a winner code', () async {
        await close();
        final code = (await winnerCode(budi, pirus))!;

        final events = await TaroEventRow.db.find(session);
        expect(events, isNotEmpty);
        for (final event in events) {
          expect(event.toJson().toString(), isNot(contains(code)));
        }
      });
    },
  );
}
