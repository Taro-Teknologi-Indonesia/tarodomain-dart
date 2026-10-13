import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/core/auction_controller.dart';
import 'package:gavel_flutter/core/live.dart';

import '../support.dart';

void main() {
  late AuctionController controller;
  late int notified;

  final auction = AuctionView(
    auctionId: UuidValue.fromString('00000000-0000-4000-8000-0000000000a1'),
    code: 'ABC234',
    title: 'Lelang amal',
    closeAt: DateTime.utc(2026, 10, 14, 22),
    status: 'OPEN',
    lotCount: 1,
  );

  SnapshotArrived snapshot(List<LotCard> lots) => SnapshotArrived(
    BoardSnapshot(auction: auction, lots: lots, serverNow: DateTime.now()),
  );

  UpdateArrived lotChanged(LotCard lot) => UpdateArrived(
    LiveUpdate(
      kind: LiveUpdateKind.lotChanged,
      lot: lot,
      serverNow: DateTime.now(),
    ),
  );

  setUp(() {
    // Never started, so it never connects.
    controller = AuctionController(Client('http://localhost:8080/'), 'ABC234');
    notified = 0;
    controller.addListener(() => notified++);
  });

  tearDown(() => controller.dispose());

  test('a snapshot sets the auction and its lots', () {
    controller.apply(snapshot([lotCard()]));

    expect(controller.auction, auction);
    expect(controller.lots.map((l) => l.lotId), [lotId]);
    expect(notified, 1);
  });

  test('a newer version of a lot replaces it', () {
    controller
      ..apply(snapshot([lotCard()]))
      ..apply(lotChanged(lotCard(version: 2, currentPrice: 175000)));

    expect(controller.lot(lotId)?.currentPrice, 175000);
    expect(controller.lot(lotId)?.version, 2);
  });

  test('an older or equal version of a lot is ignored', () {
    controller
      ..apply(snapshot([lotCard(version: 3, currentPrice: 200000)]))
      ..apply(lotChanged(lotCard(version: 2, currentPrice: 175000)))
      ..apply(lotChanged(lotCard(version: 3, currentPrice: 1)));

    expect(controller.lot(lotId)?.currentPrice, 200000);
    expect(controller.lot(lotId)?.version, 3);
  });

  test('a new lot is added in position order', () {
    final second = lotCard().copyWith(
      lotId: UuidValue.fromString('00000000-0000-4000-8000-000000000002'),
      position: 1,
    );
    controller
      ..apply(snapshot([]))
      ..apply(lotChanged(second))
      ..apply(lotChanged(lotCard()));

    expect(controller.lots.map((l) => l.position), [0, 1]);
  });

  test('a command result merges without rolling a live update back', () {
    controller
      ..apply(snapshot([]))
      ..apply(lotChanged(lotCard(version: 2, currentPrice: 175000)));
    notified = 0;

    controller.merge(lotCard());

    expect(controller.lot(lotId)?.version, 2);
    expect(notified, 0);
  });
}
