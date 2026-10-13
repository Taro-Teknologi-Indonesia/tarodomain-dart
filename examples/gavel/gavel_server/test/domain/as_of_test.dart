import 'package:gavel_server/src/domain/auction.dart';
import 'package:gavel_server/src/domain/auction_commands.dart';
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
  late LotId lotId;
  final now = DateTime.now().toUtc();
  const tick = Duration(milliseconds: 1);

  Future<ParticipantId> join(AuctionId auctionId, String name) async {
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

  Future<List<DomainEvent>> events() =>
      gavel.eventStore.loadStream('Lot-${lotId.uuid}');

  /// Events are stamped by the wall clock and [Lot.asOf] counts to the end
  /// of a millisecond, so each one gets a millisecond of its own.
  Future<void> dispatch(Command command) async {
    await gavel.dispatch(command);
    await Future<void>.delayed(const Duration(milliseconds: 3));
  }

  // Bids at t1 < t2 < t3, then the t3 bid retracted at t4.
  late DateTime created, t1, t2, t3, t4;

  setUp(() async {
    gavel = registerGavel(
      TaroDomain.builder().useLocal(),
    ).build().createRuntime();
    final auctionId = AuctionId.generate();
    await gavel.dispatch(
      CreateAuction(
        auctionId,
        title: 'Bonsai night',
        closeAt: now.add(const Duration(hours: 2)),
        code: 'ABC234',
        organizerKeyHash: hashKey('organizer-secret'),
        timestamp: now,
      ),
    );
    final budi = await join(auctionId, 'Budi');
    final sari = await join(auctionId, 'Sari');
    lotId = LotId.generate();
    await dispatch(
      AddLot(
        auctionId,
        lotId,
        organizerKey: 'organizer-secret',
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
    var version = 1;
    for (final (who, amount) in [
      (budi, 175000),
      (sari, 225000),
      (budi, 325000),
    ]) {
      await dispatch(
        PlaceBid(
          lotId,
          who,
          amount: amount,
          expectedVersion: version++,
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }
    await dispatch(
      RetractBid(
        lotId,
        budi,
        expectedVersion: version,
        timestamp: DateTime.now().toUtc(),
      ),
    );
    [created, t1, t2, t3, t4] = [for (final e in await events()) e.occurredAt];
  });

  Future<Lot> asOf(DateTime at) async => Lot.asOf(lotId, await events(), at);

  test('as of t2 the second bid leads', () async {
    final lot = await asOf(t2);

    expect(lot.currentPrice, 225000);
    expect(lot.lastValidBid?.bidderName, 'Sari');
    expect(lot.bids, hasLength(2));
  });

  test('just before t4 the later-retracted bid still leads', () async {
    final lot = await asOf(t4.subtract(tick));

    expect(lot.currentPrice, 325000);
    expect(lot.lastValidBid?.bidderName, 'Budi');
    expect(lot.bids.every((b) => !b.retracted), isTrue);
  });

  test('as of t4 the retraction has restored the price before it', () async {
    final lot = await asOf(t4);

    expect(lot.currentPrice, 225000);
    expect(lot.lastValidBid?.bidderName, 'Sari');
    expect([for (final b in lot.bids) b.retracted], [false, false, true]);
    expect(lot.version, 5);
  });

  test('between creation and t1 there are no bids yet', () async {
    final lot = await asOf(t1.subtract(tick));

    expect(lot.currentPrice, 150000);
    expect(lot.lastValidBid, isNull);
    expect(lot.version, 1);
  });

  test('before the lot was created it is not found', () async {
    await expectLater(
      asOf(created.subtract(tick)),
      throwsA(isA<AggregateNotFoundError>()),
    );
  });

  test('the replay ends where the repository does', () async {
    final lot = await asOf(DateTime.now().toUtc());
    final loaded = await gavel.repository<Lot, LotId>().load(lotId);

    expect(lot.version, loaded.version);
    expect(lot.toSnapshot(), loaded.toSnapshot());
    expect(t1.isBefore(t2) && t2.isBefore(t3) && t3.isBefore(t4), isTrue);
  });
}
