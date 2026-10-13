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
  late TaroDomain gavel;
  late AuctionId auctionId;
  late LotId lotId;
  late ParticipantId budi;
  late ParticipantId sari;
  final now = DateTime.utc(2026, 10, 14, 12, 0);
  final closeAt = now.add(const Duration(hours: 2));
  final soon = now.add(const Duration(minutes: 1));
  const organizerKey = 'organizer-secret';
  const bn = 1500000;

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

  Future<LotId> addLot({int? buyNowPrice = bn}) async {
    final id = LotId.generate();
    await gavel.dispatch(
      AddLot(
        auctionId,
        id,
        organizerKey: organizerKey,
        name: 'Natural Pirus Hubei',
        openBid: 150000,
        increments: const [25000, 50000, 100000],
        buyNowPrice: buyNowPrice,
        description: '',
        imageUrl: null,
        tileEmoji: '💎',
        tileColor: '#2E7D6B',
        timestamp: now,
      ),
    );
    return id;
  }

  void build(ConsistencyMode mode) {
    gavel = registerGavel(
      TaroDomain.builder().useLocal().consistency(mode),
    ).build().createRuntime();
  }

  Future<void> setUpAuction() async {
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
    lotId = await addLot();
    budi = await join('Budi');
    sari = await join('Sari');
  }

  setUp(() async {
    build(ConsistencyMode.eventual);
    await setUpAuction();
  });

  Future<Lot> loadLot([LotId? id]) =>
      gavel.repository<Lot, LotId>().load(id ?? lotId);

  Future<List<DomainEvent>> lotEvents([LotId? id]) =>
      gavel.eventStore.loadStream('Lot-${(id ?? lotId).uuid}');

  BuyNow buy(
    ParticipantId who, {
    required int expectedVersion,
    LotId? lot,
    DateTime? at,
  }) => BuyNow(
    lot ?? lotId,
    who,
    expectedVersion: expectedVersion,
    timestamp: at ?? soon,
  );

  PlaceBid bid(ParticipantId who, int amount, {required int expectedVersion}) =>
      PlaceBid(
        lotId,
        who,
        amount: amount,
        expectedVersion: expectedVersion,
        timestamp: soon,
      );

  Matcher validation(String reason) => throwsA(
    isA<CommandValidationError>().having(
      (e) => e.context['reason'],
      'reason',
      reason,
    ),
  );

  test('BN on an open lot bids the BN price and closes it SOLD', () async {
    await gavel.dispatch(bid(budi, 250000, expectedVersion: 1));
    await gavel.dispatch(buy(sari, expectedVersion: 2));

    final events = await lotEvents();
    expect(
      [for (final e in events) e.eventName],
      ['LotCreated', 'BidPlaced', 'BidPlaced', 'LotClosed'],
    );
    final placed = events[2] as BidPlaced;
    expect(placed.amount, bn);
    expect(placed.buyNow, isTrue);
    expect(placed.participantId, sari.uuid);
    expect(placed.bidderName, 'Sari');
    expect(placed.sequence, 2);
    expect((events[1] as BidPlaced).buyNow, isFalse);

    final closed = events[3] as LotClosed;
    expect(closed.outcome, LotStatus.sold);
    expect(closed.cause, LotCloseCause.buyNow);
    expect(closed.winnerId, sari.uuid);
    expect(closed.winnerName, 'Sari');
    expect(closed.finalPrice, bn);
    expect(closed.closedAt, soon);

    final lot = await loadLot();
    expect(lot.status, LotStatus.sold);
    expect(lot.closedAt, soon);
    expect(lot.lastValidBid?.buyNow, isTrue);
  });

  test('a lot with no BN price is NO_BUY_NOW', () async {
    final plain = await addLot(buyNowPrice: null);
    await expectLater(
      gavel.dispatch(buy(budi, expectedVersion: 1, lot: plain)),
      validation('NO_BUY_NOW'),
    );
    expect(await lotEvents(plain), hasLength(1));
  });

  test('a price at the BN price is BUY_NOW_PASSED', () async {
    final lot = LotId.generate();
    await gavel.dispatch(
      AddLot(
        auctionId,
        lot,
        organizerKey: organizerKey,
        name: 'Shohin juniper',
        openBid: 150000,
        increments: const [50000],
        buyNowPrice: 200000,
        description: '',
        imageUrl: null,
        tileEmoji: '🌲',
        tileColor: '#2E7D6B',
        timestamp: now,
      ),
    );
    await gavel.dispatch(
      PlaceBid(lot, budi, amount: 200000, expectedVersion: 1, timestamp: soon),
    );
    // A chip bid that reaches BN is just a bid: the lot stays open.
    expect((await loadLot(lot)).status, LotStatus.open);

    await expectLater(
      gavel.dispatch(buy(sari, expectedVersion: 2, lot: lot)),
      validation('BUY_NOW_PASSED'),
    );
  });

  test('a stale version is OUTBID with the leader', () async {
    await gavel.dispatch(bid(budi, 250000, expectedVersion: 1));
    await expectLater(
      gavel.dispatch(buy(sari, expectedVersion: 1)),
      throwsA(
        isA<OutbidError>().having((e) => e.context, 'context', {
          'currentPrice': 250000,
          'leaderName': 'Budi',
          'leaderId': budi.uuid,
          'version': 2,
        }),
      ),
    );
    expect((await loadLot()).status, LotStatus.open);
  });

  test('BN at the close time is LOT_CLOSED', () async {
    await expectLater(
      gavel.dispatch(buy(sari, expectedVersion: 1, at: closeAt)),
      throwsA(isA<LotClosedError>()),
    );
  });

  test('BN after BN is LOT_CLOSED with the first close time', () async {
    await gavel.dispatch(buy(budi, expectedVersion: 1));
    await expectLater(
      gavel.dispatch(buy(sari, expectedVersion: 3)),
      throwsA(
        isA<LotClosedError>().having((e) => e.context, 'context', {
          'closedAt': soon.toIso8601String(),
          'winnerName': 'Budi',
        }),
      ),
    );
  });

  test('a BN bid cannot be retracted', () async {
    await gavel.dispatch(buy(budi, expectedVersion: 1));
    await expectLater(
      gavel.dispatch(
        RetractBid(lotId, budi, expectedVersion: 3, timestamp: soon),
      ),
      throwsA(isA<LotClosedError>()),
    );
  });

  test('an unknown participant is NOT_PARTICIPANT', () async {
    await expectLater(
      gavel.dispatch(buy(ParticipantId.generate(), expectedVersion: 1)),
      throwsA(isA<NotParticipantError>()),
    );
    expect(await lotEvents(), hasLength(1));
  });

  test('old events and snapshots read as no BN', () {
    final placed = BidPlaced.fromData(
      BidPlaced(
        lotId.uuid,
        participantId: budi.uuid,
        bidderName: 'Budi',
        amount: 175000,
        sequence: 1,
      ).toData()..remove('buyNow'),
    );
    expect(placed.buyNow, isFalse);
    final bid = Bid.fromJson(
      Bid(
        sequence: 1,
        bidder: budi.uuid,
        bidderName: 'Budi',
        amount: 175000,
        at: now,
        buyNow: true,
      ).toJson()..remove('buyNow'),
    );
    expect(bid.buyNow, isFalse);
  });

  for (final mode in ConsistencyMode.values) {
    test('BN and a chip on one version: one wins, no bid after the close, '
        '${mode.name}', () async {
      build(mode);
      await setUpAuction();

      final results = await Future.wait([
        gavel
            .dispatch(buy(sari, expectedVersion: 1))
            .then<Object?>((_) => null, onError: (Object e) => e),
        gavel
            .dispatch(bid(budi, 250000, expectedVersion: 1))
            .then<Object?>((_) => null, onError: (Object e) => e),
      ]);

      expect(results.where((r) => r == null), hasLength(1));
      final loser = results.whereType<DomainError>().single;
      final names = [for (final e in await lotEvents()) e.eventName];
      if (results.first == null) {
        expect(loser, isA<LotClosedError>());
        expect(names, ['LotCreated', 'BidPlaced', 'LotClosed']);
      } else {
        expect(loser, isA<OutbidError>());
        expect(names, ['LotCreated', 'BidPlaced']);
      }
    });
  }

  test('an auction with a bought lot and an open lot closes at the '
      'deadline', () async {
    build(ConsistencyMode.strong);
    await setUpAuction();
    final open = await addLot();
    await gavel.dispatch(buy(sari, expectedVersion: 1));

    final close = CloseAuction(auctionId, timestamp: closeAt);
    await gavel.dispatch(close);

    final auctions = gavel.repository<Auction, AuctionId>();
    expect((await auctions.load(auctionId)).status, AuctionStatus.closing);
    final openLot = await loadLot(open);
    expect(openLot.status, LotStatus.passed);
    expect(
      (await lotEvents(open)).whereType<LotClosed>().single.cause,
      LotCloseCause.deadline,
    );

    // The bought lot's LotClosed came before the saga, so the timeout
    // finalizes it.
    final saga = await gavel.sagaStore.load(
      'AuctionCloseSaga',
      close.correlationId,
    );
    final handler = AuctionCloseSaga()..restore(saga!);
    for (final c in handler.handle(
      SagaTimeout.forRecord(saga, const Duration(seconds: 30)),
    )) {
      await gavel.dispatch(c);
    }
    expect((await auctions.load(auctionId)).status, AuctionStatus.closed);

    final bought = await lotEvents();
    expect(bought.whereType<LotClosed>().single.cause, LotCloseCause.buyNow);
  });
}
