import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/core/auction_controller.dart';
import 'package:gavel_flutter/core/failures.dart';
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

  UpdateArrived lotChanged(LotCard lot, {LedgerEntry? ledgerEntry}) =>
      UpdateArrived(
        LiveUpdate(
          kind: LiveUpdateKind.lotChanged,
          lot: lot,
          ledgerEntry: ledgerEntry,
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

  test('a code that cannot be a join code fails without asking the server', () {
    final bad = AuctionController(Client('http://localhost:8080/'), 'ABCO34')
      ..start();
    addTearDown(bad.dispose);

    expect(bad.failure, isA<AuctionNotFound>());
  });

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

  group('ledgerFor', () {
    late List<Completer<LotDetail>> fetches;

    LotDetail detail(List<LedgerEntry> ledger, {LotCard? lot}) => LotDetail(
      lot: lot ?? lotCard(version: ledger.length + 1),
      ledger: ledger,
      closeAt: auction.closeAt,
      serverNow: DateTime.now(),
    );

    List<int>? sequences() =>
        controller.ledgerFor(lotId)?.map((e) => e.sequence).toList();

    setUp(() {
      controller.dispose();
      fetches = [];
      controller = AuctionController(
        Client('http://localhost:8080/'),
        'ABC234',
        detail: (_) {
          final fetch = Completer<LotDetail>();
          fetches.add(fetch);
          return fetch.future;
        },
      )..apply(snapshot([lotCard()]));
    });

    test('fetches once and is null until the answer', () async {
      expect(controller.ledgerFor(lotId), isNull);
      expect(controller.ledgerFor(lotId), isNull);
      expect(fetches, hasLength(1));

      fetches.single.complete(detail([ledgerEntry(1), ledgerEntry(2)]));
      await pumpEventQueue();

      expect(sequences(), [1, 2]);
      expect(fetches, hasLength(1));
    });

    test('takes the card the fetch brought if it is newer', () async {
      controller.ledgerFor(lotId);
      fetches.single.complete(
        detail([ledgerEntry(1)], lot: lotCard(version: 2, currentPrice: 1)),
      );
      await pumpEventQueue();

      expect(controller.lot(lotId)?.currentPrice, 1);
    });

    test('adds pushed bids, even those that arrive during the '
        'fetch', () async {
      controller
        ..ledgerFor(lotId)
        ..apply(lotChanged(lotCard(version: 3), ledgerEntry: ledgerEntry(2)));
      fetches.single.complete(detail([ledgerEntry(1)]));
      await pumpEventQueue();
      controller.apply(
        lotChanged(lotCard(version: 4), ledgerEntry: ledgerEntry(3)),
      );

      expect(sequences(), [1, 2, 3]);
    });

    test('a stale fetch never unstrikes a retracted row', () async {
      controller
        ..ledgerFor(lotId)
        ..apply(
          lotChanged(
            lotCard(version: 3),
            ledgerEntry: ledgerEntry(1, retracted: true),
          ),
        );
      fetches.single.complete(detail([ledgerEntry(1)]));
      await pumpEventQueue();

      expect(controller.ledgerFor(lotId)?.single.retracted, isTrue);
    });

    test('a reconnect snapshot fetches it again', () async {
      controller.ledgerFor(lotId);
      fetches.single.complete(detail([ledgerEntry(1)]));
      await pumpEventQueue();

      controller.apply(snapshot([lotCard(version: 3)]));
      expect(fetches, hasLength(2));
      fetches.last.complete(detail([ledgerEntry(1), ledgerEntry(2)]));
      await pumpEventQueue();

      expect(sequences(), [1, 2]);
    });

    test('ignores pushed bids of lots nobody opened', () {
      controller.apply(
        lotChanged(lotCard(version: 2), ledgerEntry: ledgerEntry(1)),
      );

      expect(fetches, isEmpty);
      expect(controller.ledgerFor(lotId), isNull);
    });
  });
}
