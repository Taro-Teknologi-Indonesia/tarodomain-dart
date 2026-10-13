import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/core/bidding.dart';
import 'package:gavel_flutter/core/identity.dart';
import 'package:gavel_flutter/widgets/bid_bar.dart';
import 'package:gavel_flutter/widgets/ledger_list.dart';

import '../support.dart';

final _me = Identity(
  participantId: budi,
  participantKey: 'budi-key',
  displayName: 'Budi',
);

final _buyNow = find.text('BUY NOW · Rp 1.500.000');

void main() {
  late Completer<LotCard> answer;
  late List<(int, UuidValue)> buys;
  late List<LotCard> accepted;
  late int stale;

  setUp(() {
    buys = [];
    accepted = [];
    stale = 0;
  });

  Future<void> pump(WidgetTester tester, LotCard lot) {
    answer = Completer();
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: SizedBox(
            width: 360,
            child: BidBar(
              lot: lot,
              identity: _me,
              closeAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
              offset: ValueNotifier(Duration.zero),
              bidder: Bidder(
                ({
                  required lotId,
                  required identity,
                  required amount,
                  required expectedVersion,
                  required commandId,
                }) => answer.future,
                ({
                  required lotId,
                  required identity,
                  required expectedVersion,
                  required commandId,
                }) {
                  buys.add((expectedVersion, commandId));
                  return answer.future;
                },
              ),
              onAccepted: accepted.add,
              onStale: () => stale++,
              onNotParticipant: () {},
            ),
          ),
        ),
      ),
    );
  }

  LotCard bnLot({int version = 1, int currentPrice = 150000}) => lotCard(
    version: version,
    currentPrice: currentPrice,
    buyNowPrice: 1500000,
  );

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(_buyNow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buy for Rp 1.500.000'));
    await tester.pump();
  }

  group('canBuyNow', () {
    test('only while open and below the BN price', () {
      expect(canBuyNow(bnLot()), isTrue);
      expect(canBuyNow(lotCard()), isFalse);
      expect(canBuyNow(bnLot(currentPrice: 1500000)), isFalse);
      expect(
        canBuyNow(lotCard(version: 3, status: 'SOLD', buyNowPrice: 1500000)),
        isFalse,
      );
    });
  });

  testWidgets('no BN price, no button', (tester) async {
    await pump(tester, lotCard());
    expect(find.textContaining('BUY NOW'), findsNothing);
  });

  testWidgets('asks first, and Cancel sends nothing', (tester) async {
    await pump(tester, bnLot());

    await tester.tap(_buyNow);
    await tester.pumpAndSettle();
    expect(find.textContaining("you can't retract it"), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(buys, isEmpty);
  });

  testWidgets('a confirmed BN disables everything, then says I bought it', (
    tester,
  ) async {
    await pump(tester, bnLot(version: 4));
    await confirm(tester);

    expect(buys.single.$1, 4);
    expect(
      tester
          .widgetList<ActionChip>(find.byType(ActionChip))
          .every((c) => c.onPressed == null),
      isTrue,
    );

    answer.complete(
      lotCard(
        version: 6,
        status: 'SOLD',
        currentPrice: 1500000,
        finalPrice: 1500000,
        buyNowPrice: 1500000,
        leaderId: budi,
      ),
    );
    await tester.pump();

    expect(accepted.single.status, 'SOLD');
    expect(find.text('🔨 You bought it — Rp 1.500.000'), findsOneWidget);
    await tester.pump(BidBar.bannerTime);
  });

  testWidgets('outbid says the price moved and does not retry', (tester) async {
    await pump(tester, bnLot());
    await confirm(tester);

    answer.completeError(
      domainError('OUTBID', {
        'currentPrice': 450000,
        'leaderName': 'Sari',
        'leaderId': siti.uuid,
        'version': 2,
      }),
    );
    await tester.pump();

    expect(find.text('Price moved — Sari bid Rp 450.000'), findsOneWidget);
    expect(stale, 1);
    expect(buys, hasLength(1));
    await tester.pump(BidBar.bannerTime);
  });

  testWidgets('another BN first names the buyer', (tester) async {
    await pump(tester, bnLot());
    await confirm(tester);

    answer.completeError(
      domainError('LOT_CLOSED', {
        'closedAt': '2026-10-14T14:03:00.000Z',
        'winnerName': 'Sari',
      }),
    );
    await tester.pump();

    expect(find.text('Sold — Sari bought it first'), findsOneWidget);
    await tester.pump(BidBar.bannerTime);
  });

  testWidgets('BUY_NOW_PASSED hides BN and keeps the chips', (tester) async {
    await pump(tester, bnLot());
    await confirm(tester);

    answer.completeError(
      domainError('COMMAND_VALIDATION', {'reason': 'BUY_NOW_PASSED'}),
    );
    await tester.pump();

    expect(
      find.text('Bidding passed the BN price — keep bidding'),
      findsOneWidget,
    );
    expect(_buyNow, findsNothing);
    expect(find.byType(ActionChip), findsNWidgets(2));
    await tester.pump(BidBar.bannerTime);
  });

  testWidgets('a lost answer resends with the same command ID', (tester) async {
    await pump(tester, bnLot());
    await confirm(tester);
    answer.completeError(TimeoutException('lost'));
    await tester.pump();
    expect(find.text("Couldn't reach the server — try again"), findsOneWidget);

    answer = Completer();
    await confirm(tester);

    expect(buys, hasLength(2));
    expect(buys.last.$2, buys.first.$2);
    answer.completeError(TimeoutException('lost'));
    await tester.pump(BidBar.bannerTime);
  });

  testWidgets('the ledger marks a BN row', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LedgerRow(
            ledgerEntry(1, amount: 1500000).copyWith(buyNow: true),
          ),
        ),
      ),
    );
    expect(find.textContaining('Rp 1.500.000 (BN)'), findsOneWidget);
  });
}
