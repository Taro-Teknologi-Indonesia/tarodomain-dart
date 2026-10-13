import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/core/bidding.dart';
import 'package:gavel_flutter/core/identity.dart';
import 'package:gavel_flutter/widgets/bid_bar.dart';

import '../support.dart';

final _me = Identity(
  participantId: budi,
  participantKey: 'budi-key',
  displayName: 'Budi',
);

Object _outbid(UuidValue leader, String name) => domainError('OUTBID', {
  'currentPrice': 175000,
  'leaderName': name,
  'leaderId': leader.uuid,
  'version': 2,
});

void main() {
  late Completer<LotCard> answer;
  late List<int> amounts;
  late List<LotCard> accepted;
  late int stale;
  late int lost;

  setUp(() {
    amounts = [];
    accepted = [];
    stale = 0;
    lost = 0;
  });

  Future<void> pump(WidgetTester tester, {LotCard? lot, DateTime? closeAt}) {
    // Made in the test's fake-async zone, so pump() delivers its answer.
    answer = Completer();
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: SizedBox(
            width: 360,
            child: BidBar(
              lot: lot ?? lotCard(),
              identity: _me,
              closeAt:
                  closeAt ??
                  DateTime.now().toUtc().add(const Duration(hours: 1)),
              offset: ValueNotifier(Duration.zero),
              bidder: Bidder(({
                required lotId,
                required identity,
                required amount,
                required expectedVersion,
                required commandId,
              }) {
                amounts.add(amount);
                return answer.future;
              }),
              onAccepted: accepted.add,
              onStale: () => stale++,
              onNotParticipant: () => lost++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows a chip per step with the price it bids', (tester) async {
    await pump(tester);

    expect(find.text('+25k'), findsOneWidget);
    expect(find.text('Rp 175.000'), findsOneWidget);
    expect(find.text('+50k'), findsOneWidget);
    expect(find.text('Rp 200.000'), findsOneWidget);
  });

  testWidgets('a tap bids at once and disables every chip until the '
      'answer', (tester) async {
    await pump(tester);

    await tester.tap(find.text('+50k'));
    await tester.pump();

    expect(amounts, [200000]);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final chips = tester.widgetList<ActionChip>(find.byType(ActionChip));
    expect(chips.every((c) => c.onPressed == null), isTrue);

    await tester.tap(find.text('+25k'), warnIfMissed: false);
    expect(amounts, [200000]);

    answer.complete(lotCard(version: 2, currentPrice: 200000, leaderId: budi));
    await tester.pump();

    expect(accepted.single.currentPrice, 200000);
    expect(find.text("You're the high bidder — Rp 200.000"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(BidBar.bannerTime);
    expect(find.textContaining('high bidder'), findsNothing);
  });

  testWidgets('outbid names who bid first and asks for the new price', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('+25k'));
    answer.completeError(_outbid(siti, 'Siti'));
    await tester.pump();

    expect(find.text('Outbid — Siti bid first'), findsOneWidget);
    expect(stale, 1);
    expect(
      tester
          .widgetList<ActionChip>(find.byType(ActionChip))
          .every((c) => c.onPressed != null),
      isTrue,
    );
    await tester.pump(BidBar.bannerTime);
  });

  testWidgets('outbid by my own earlier tap says I already lead', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('+25k'));
    answer.completeError(_outbid(budi, 'Budi'));
    await tester.pump();

    expect(find.text("You're already the high bidder"), findsOneWidget);
    await tester.pump(BidBar.bannerTime);
  });

  testWidgets('a closed lot hides the chips', (tester) async {
    await pump(tester);

    await tester.tap(find.text('+25k'));
    answer.completeError(
      domainError('LOT_CLOSED', {'closedAt': '2026-10-14T14:03:00.000Z'}),
    );
    await tester.pump();

    expect(find.textContaining("your bid didn't count"), findsOneWidget);
    expect(find.byType(ActionChip), findsNothing);
    await tester.pump(BidBar.bannerTime);
  });

  testWidgets('a forgotten identity asks to join again', (tester) async {
    await pump(tester);

    await tester.tap(find.text('+25k'));
    answer.completeError(domainError('NOT_PARTICIPANT'));
    await tester.pump();

    expect(lost, 1);
  });

  testWidgets('a lost answer says to try again and re-enables the chips', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('+25k'));
    answer.completeError(TimeoutException('lost'));
    await tester.pump();

    expect(find.text("Couldn't reach the server — try again"), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(2));
    await tester.pump(BidBar.bannerTime);
  });

  testWidgets('the chips go away at the close time', (tester) async {
    await pump(
      tester,
      closeAt: DateTime.now().toUtc().add(const Duration(seconds: 2)),
    );
    expect(find.byType(ActionChip), findsNWidgets(2));

    await tester.pump(const Duration(seconds: 3));

    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('Bidding closed'), findsOneWidget);
  });
}
