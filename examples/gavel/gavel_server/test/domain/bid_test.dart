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
  late TaroDomain gavel;
  late AuctionId auctionId;
  late LotId lotId;
  late ParticipantId budi;
  late ParticipantId sari;
  final now = DateTime.utc(2026, 10, 14, 12, 0);
  final closeAt = now.add(const Duration(hours: 2));
  const organizerKey = 'organizer-secret';

  Future<ParticipantId> join(String name, {AuctionId? auction}) async {
    final id = ParticipantId.generate();
    await gavel.dispatch(
      JoinAuction(
        id,
        auctionId: (auction ?? auctionId).uuid,
        displayName: name,
        keyHash: hashKey('$name-key'),
      ),
    );
    return id;
  }

  Future<AuctionId> createAuction(String code) async {
    final id = AuctionId.generate();
    await gavel.dispatch(
      CreateAuction(
        id,
        title: 'Bonsai night',
        closeAt: closeAt,
        code: code,
        organizerKeyHash: hashKey(organizerKey),
        timestamp: now,
      ),
    );
    return id;
  }

  setUp(() async {
    gavel = registerGavel(
      TaroDomain.builder().useLocal(),
    ).build().createRuntime();
    auctionId = await createAuction('ABC234');
    lotId = LotId.generate();
    await gavel.dispatch(
      AddLot(
        auctionId,
        lotId,
        organizerKey: organizerKey,
        name: 'Natural Pirus Hubei',
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
    budi = await join('Budi');
    sari = await join('Sari');
  });

  Future<Lot> loadLot() => gavel.repository<Lot, LotId>().load(lotId);

  Future<List<String>> lotEvents() async => [
    for (final e in await gavel.eventStore.loadStream('Lot-${lotId.uuid}'))
      e.eventName,
  ];

  PlaceBid bid(
    ParticipantId who,
    int amount, {
    required int expectedVersion,
    DateTime? at,
  }) => PlaceBid(
    lotId,
    who,
    amount: amount,
    expectedVersion: expectedVersion,
    timestamp: at ?? now.add(const Duration(minutes: 1)),
  );

  test('+100k on 150k places a bid at 250k and leads', () async {
    await gavel.dispatch(bid(budi, 250000, expectedVersion: 1));

    final lot = await loadLot();
    expect(lot.version, 2);
    expect(lot.currentPrice, 250000);
    expect(lot.lastValidBid?.bidder, budi.uuid);
    expect(lot.lastValidBid?.bidderName, 'Budi');
    expect(lot.lastValidBid?.sequence, 1);

    final placed =
        (await gavel.eventStore.loadStream('Lot-${lotId.uuid}')).last
            as BidPlaced;
    expect(placed.amount, 250000);
    expect(placed.participantId, budi.uuid);
    expect(placed.bidderName, 'Budi');
    expect(placed.sequence, 1);
  });

  test('bids build on the price before them', () async {
    await gavel.dispatch(bid(budi, 175000, expectedVersion: 1));
    await gavel.dispatch(bid(sari, 225000, expectedVersion: 2));

    final lot = await loadLot();
    expect(lot.currentPrice, 225000);
    expect([for (final b in lot.bids) b.sequence], [1, 2]);
    expect(lot.lastValidBid?.bidderName, 'Sari');
  });

  test('the leader may raise their own bid', () async {
    await gavel.dispatch(bid(budi, 175000, expectedVersion: 1));
    await gavel.dispatch(bid(budi, 200000, expectedVersion: 2));

    expect((await loadLot()).currentPrice, 200000);
  });

  test('an off-ladder raise is INVALID_INCREMENT', () async {
    await expectLater(
      gavel.dispatch(bid(budi, 220000, expectedVersion: 1)),
      throwsA(
        isA<InvalidIncrementError>().having((e) => e.context, 'context', {
          'allowedIncrements': [25000, 50000, 100000],
          'currentPrice': 150000,
        }),
      ),
    );
    expect(await lotEvents(), ['LotCreated']);
  });

  test('a bid at the open bid itself is INVALID_INCREMENT', () async {
    await expectLater(
      gavel.dispatch(bid(budi, 150000, expectedVersion: 1)),
      throwsA(isA<InvalidIncrementError>()),
    );
  });

  test('a stale view is OUTBID, naming the leader', () async {
    await gavel.dispatch(bid(sari, 200000, expectedVersion: 1));

    await expectLater(
      gavel.dispatch(bid(budi, 175000, expectedVersion: 1)),
      throwsA(
        isA<OutbidError>().having((e) => e.context, 'context', {
          'currentPrice': 200000,
          'leaderName': 'Sari',
          'leaderId': sari.uuid,
          'version': 2,
        }),
      ),
    );
    expect(await lotEvents(), ['LotCreated', 'BidPlaced']);
  });

  test('a double tap by the leader is OUTBID naming themselves', () async {
    await gavel.dispatch(bid(budi, 175000, expectedVersion: 1));

    await expectLater(
      gavel.dispatch(bid(budi, 175000, expectedVersion: 1)),
      throwsA(
        isA<OutbidError>().having(
          (e) => e.context['leaderId'],
          'leaderId',
          budi.uuid,
        ),
      ),
    );
  });

  test('the same command sent twice places one bid', () async {
    final command = bid(budi, 175000, expectedVersion: 1);
    await gavel.dispatch(command);
    await gavel.dispatch(command);

    expect(await lotEvents(), ['LotCreated', 'BidPlaced']);
  });

  test('a bid at the close time is LOT_CLOSED', () async {
    await expectLater(
      gavel.dispatch(bid(budi, 175000, expectedVersion: 1, at: closeAt)),
      throwsA(
        isA<LotClosedError>().having(
          (e) => e.context['closedAt'],
          'closedAt',
          closeAt.toIso8601String(),
        ),
      ),
    );
    expect(await lotEvents(), ['LotCreated']);
  });

  test('a bid a microsecond before the close is accepted', () async {
    await gavel.dispatch(
      bid(
        budi,
        175000,
        expectedVersion: 1,
        at: closeAt.subtract(const Duration(microseconds: 1)),
      ),
    );

    expect((await loadLot()).currentPrice, 175000);
  });

  test('a closed lot beats a stale view', () async {
    await gavel.dispatch(bid(sari, 175000, expectedVersion: 1));

    await expectLater(
      gavel.dispatch(bid(budi, 175000, expectedVersion: 1, at: closeAt)),
      throwsA(isA<LotClosedError>()),
    );
  });

  test('a participant of another auction is NOT_PARTICIPANT', () async {
    final other = await join('Tono', auction: await createAuction('XYZ789'));

    await expectLater(
      gavel.dispatch(bid(other, 175000, expectedVersion: 1)),
      throwsA(isA<NotParticipantError>()),
    );
    expect(await lotEvents(), ['LotCreated']);
  });

  test('an unknown participant is NOT_PARTICIPANT', () async {
    await expectLater(
      gavel.dispatch(bid(ParticipantId.generate(), 175000, expectedVersion: 1)),
      throwsA(isA<NotParticipantError>()),
    );
  });

  test('two bids on the same version: one lands, one is OUTBID', () async {
    final results = await Future.wait([
      for (final (who, amount) in [(budi, 250000), (sari, 175000)])
        gavel
            .dispatch(bid(who, amount, expectedVersion: 1))
            .then<Object?>((_) => null, onError: (Object e) => e),
    ]);

    expect(results.where((r) => r == null), hasLength(1));
    final outbid = results.whereType<OutbidError>().single;
    final lot = await loadLot();
    expect(lot.bids, hasLength(1));
    expect(outbid.context['leaderId'], lot.lastValidBid?.bidder);
    expect(outbid.context['currentPrice'], lot.currentPrice);
    expect(await lotEvents(), ['LotCreated', 'BidPlaced']);
  });

  test('a snapshot keeps the bids, and older ones restore with none', () async {
    await gavel.dispatch(bid(budi, 175000, expectedVersion: 1));
    final lot = await loadLot();
    final snapshot = lot.toSnapshot();

    final restored = Lot(lotId)..restoreSnapshotState(snapshot);
    expect(restored.toSnapshot(), snapshot);
    expect(restored.currentPrice, 175000);
    expect(
      (Lot(lotId)..restoreSnapshotState({...snapshot}..remove('bids'))).bids,
      isEmpty,
    );
  });

  group('retract', () {
    late ParticipantId tono;

    setUp(() async => tono = await join('Tono'));

    RetractBid retract(
      ParticipantId who, {
      required int expectedVersion,
      DateTime? at,
    }) => RetractBid(
      lotId,
      who,
      expectedVersion: expectedVersion,
      timestamp: at ?? now.add(const Duration(minutes: 2)),
    );

    test('a fat-fingered bid comes back off: the one before leads '
        'again', () async {
      await gavel.dispatch(bid(budi, 175000, expectedVersion: 1));
      await gavel.dispatch(bid(sari, 275000, expectedVersion: 2));
      await gavel.dispatch(retract(sari, expectedVersion: 3));

      final lot = await loadLot();
      expect(lot.currentPrice, 175000);
      expect(lot.lastValidBid?.bidder, budi.uuid);
      expect([for (final b in lot.bids) b.retracted], [false, true]);
      expect(await lotEvents(), [
        'LotCreated',
        'BidPlaced',
        'BidPlaced',
        'BidRetracted',
      ]);
      final retracted =
          (await gavel.eventStore.loadStream('Lot-${lotId.uuid}')).last
              as BidRetracted;
      expect(retracted.participantId, sari.uuid);
      expect(retracted.retractedSequence, 2);
    });

    test("someone else's latest bid is NOT_LATEST", () async {
      await gavel.dispatch(bid(budi, 175000, expectedVersion: 1));
      await gavel.dispatch(bid(sari, 275000, expectedVersion: 2));

      for (final who in [tono, budi]) {
        await expectLater(
          gavel.dispatch(retract(who, expectedVersion: 3)),
          throwsA(
            isA<RetractNotAllowedError>().having(
              (e) => e.context['reason'],
              'reason',
              'NOT_LATEST',
            ),
          ),
        );
      }
      expect((await loadLot()).bids.any((b) => b.retracted), isFalse);
    });

    test('a lot with no bids is NO_BIDS', () async {
      await expectLater(
        gavel.dispatch(retract(budi, expectedVersion: 1)),
        throwsA(
          isA<RetractNotAllowedError>().having(
            (e) => e.context['reason'],
            'reason',
            'NO_BIDS',
          ),
        ),
      );
    });

    test('at the close time is LOT_CLOSED', () async {
      await gavel.dispatch(bid(budi, 175000, expectedVersion: 1));

      await expectLater(
        gavel.dispatch(retract(budi, expectedVersion: 2, at: closeAt)),
        throwsA(isA<LotClosedError>()),
      );
      expect(await lotEvents(), ['LotCreated', 'BidPlaced']);
    });

    test('a stale view of my own lead is OUTBID', () async {
      await gavel.dispatch(bid(budi, 175000, expectedVersion: 1));
      await gavel.dispatch(bid(budi, 200000, expectedVersion: 2));

      await expectLater(
        gavel.dispatch(retract(budi, expectedVersion: 2)),
        throwsA(
          isA<OutbidError>().having((e) => e.context['version'], 'version', 3),
        ),
      );
      expect(await lotEvents(), ['LotCreated', 'BidPlaced', 'BidPlaced']);
    });

    test('retracting every bid returns to the open bid with no '
        'leader', () async {
      await gavel.dispatch(bid(budi, 175000, expectedVersion: 1));
      await gavel.dispatch(bid(sari, 200000, expectedVersion: 2));
      await gavel.dispatch(retract(sari, expectedVersion: 3));
      await gavel.dispatch(retract(budi, expectedVersion: 4));

      final lot = await loadLot();
      expect(lot.currentPrice, 150000);
      expect(lot.lastValidBid, isNull);
      expect(lot.bids, hasLength(2));
    });

    test('the next bid builds on the restored price', () async {
      await gavel.dispatch(bid(budi, 175000, expectedVersion: 1));
      await gavel.dispatch(bid(sari, 275000, expectedVersion: 2));
      await gavel.dispatch(retract(sari, expectedVersion: 3));

      await expectLater(
        gavel.dispatch(bid(sari, 300000, expectedVersion: 4)),
        throwsA(isA<InvalidIncrementError>()),
      );
      await gavel.dispatch(bid(sari, 200000, expectedVersion: 4));

      final lot = await loadLot();
      expect(lot.currentPrice, 200000);
      expect(lot.lastValidBid?.sequence, 3);
    });

    test('a snapshot keeps the retraction', () async {
      await gavel.dispatch(bid(budi, 175000, expectedVersion: 1));
      await gavel.dispatch(retract(budi, expectedVersion: 2));

      final restored = Lot(lotId)
        ..restoreSnapshotState((await loadLot()).toSnapshot());
      expect(restored.bids.single.retracted, isTrue);
      expect(restored.currentPrice, 150000);
    });
  });
}
