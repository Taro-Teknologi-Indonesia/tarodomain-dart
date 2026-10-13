import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/core/names.dart';
import 'package:gavel_flutter/pages/lot_page.dart';
import 'package:gavel_flutter/widgets/ledger_list.dart';
import 'package:gavel_flutter/widgets/won_banner.dart';

import '../support.dart';

Widget _app(
  LotCard lot,
  List<LedgerEntry>? ledger, {
  UuidValue? me,
  VoidCallback? onShare,
  LoadWinnerCode? loadWinnerCode,
  String? organizerCode,
  Set<String> sharedNames = const {},
  LotAsOf? asOf,
  VoidCallback? onAsOf,
}) => MaterialApp(
  home: Scaffold(
    body: LotDetailBody(
      lot: lot,
      ledger: ledger,
      closeAt: DateTime.utc(2026, 10, 14, 22, 3),
      me: me,
      onShare: onShare,
      loadWinnerCode: loadWinnerCode,
      organizerCode: organizerCode,
      sharedNames: sharedNames,
      asOf: asOf,
      onAsOf: onAsOf,
    ),
  ),
);

void main() {
  final sitiLeads = lotCard(
    version: 3,
    currentPrice: 200000,
    leaderId: siti,
    leaderName: 'Siti',
  );

  testWidgets('says I was outbid when I have a bid and someone else '
      'leads', (tester) async {
    await tester.pumpWidget(
      _app(sitiLeads, [
        ledgerEntry(1),
        ledgerEntry(2, by: siti, name: 'Siti', amount: 200000),
      ], me: budi),
    );

    expect(find.text('Outbid — Siti leads at Rp 200.000'), findsOneWidget);
  });

  testWidgets('just names the leader when I never bid', (tester) async {
    await tester.pumpWidget(
      _app(sitiLeads, [
        ledgerEntry(1, by: siti, name: 'Siti', amount: 200000),
      ], me: budi),
    );

    expect(find.text('Siti leads'), findsOneWidget);
  });

  testWidgets('says I lead when I do', (tester) async {
    final lot = lotCard(
      version: 2,
      currentPrice: 175000,
      leaderId: budi,
      leaderName: 'Budi',
    );
    await tester.pumpWidget(_app(lot, [ledgerEntry(1)], me: budi));

    expect(find.text("You're the high bidder — Rp 175.000"), findsOneWidget);
  });

  group('a SOLD lot', () {
    final soldToBudi = lotCard(
      version: 3,
      status: 'SOLD',
      currentPrice: 175000,
      leaderId: budi,
      leaderName: 'Budi',
      winnerName: 'Budi',
      finalPrice: 175000,
      closeCause: 'DEADLINE',
      closedAt: DateTime.utc(2026, 10, 14, 22, 3),
    );

    testWidgets('celebrates with the winner, who can share it and gets '
        'their tag and winner code', (tester) async {
      var shared = 0;
      await tester.pumpWidget(
        _app(
          soldToBudi,
          [ledgerEntry(1)],
          me: budi,
          onShare: () => shared++,
          loadWinnerCode: () async => '7KQ-2XM',
        ),
      );
      await tester.pump();

      expect(
        find.text('🔨 You won Batik tulis Lasem — Rp 175.000'),
        findsOneWidget,
      );
      expect(find.text("You're Budi · #00b1 on the receipt"), findsOneWidget);
      expect(
        find.textContaining('7KQ-2XM', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(find.text('Share result'));
      expect(shared, 1);
    });

    testWidgets('shows the tagged result block to everyone else, with no '
        'chips, no code and the record note', (tester) async {
      await tester.pumpWidget(
        _app(
          soldToBudi,
          [ledgerEntry(1)],
          me: siti,
          onShare: () {},
          loadWinnerCode: () async => fail('only the winner asks'),
        ),
      );
      await tester.pump();

      expect(find.textContaining('You won'), findsNothing);
      expect(find.text('🔨 SOLD to Budi · #00b1'), findsOneWidget);
      expect(find.text('Rp 175.000'), findsOneWidget);
      expect(
        find.text('Closed ${formatClock(soldToBudi.closedAt!)} · by deadline'),
        findsOneWidget,
      );
      expect(find.textContaining('Next bid'), findsNothing);
      // One name in the auction: the ledger keeps it plain.
      expect(
        find.text(
          '🔨 Closed ${formatClock(soldToBudi.closedAt!)} — '
          'SOLD to Budi',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('· Budi ·'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('append-only'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('append-only'), findsOneWidget);
    });

    testWidgets('shows the organizer the winner code under the '
        'result', (tester) async {
      await tester.pumpWidget(
        _app(soldToBudi, [ledgerEntry(1)], organizerCode: '7KQ-2XM'),
      );

      expect(find.text('Budi · #00b1 · code 7KQ-2XM'), findsOneWidget);
    });

    testWidgets('tags both Budis in the ledger when they share the '
        'name', (tester) async {
      final ledger = [
        ledgerEntry(1, by: otherBudi, name: 'budi'),
        ledgerEntry(2),
      ];
      await tester.pumpWidget(
        _app(
          soldToBudi,
          ledger,
          sharedNames: sharedNames([
            for (final e in ledger) (e.bidderName, e.participantId),
          ]),
        ),
      );

      expect(find.textContaining('· budi · #00b2 ·'), findsOneWidget);
      expect(find.textContaining('· Budi · #00b1 ·'), findsOneWidget);
      expect(find.textContaining('SOLD to Budi · #00b1'), findsNWidgets(2));
    });
  });

  testWidgets('a PASSED lot says so, greyed, with no price', (tester) async {
    final passed = lotCard(
      version: 2,
      status: 'PASSED',
      closeCause: 'DEADLINE',
      closedAt: DateTime.utc(2026, 10, 14, 22, 3),
    );
    await tester.pumpWidget(_app(passed, const []));

    expect(find.text('🔨 PASSED — no bids'), findsOneWidget);
    expect(find.text('Rp 150.000'), findsNothing);
  });

  testWidgets('the share bar shares', (tester) async {
    var shared = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ShareResultBar(onShare: () => shared++),
        ),
      ),
    );

    await tester.tap(find.text('Share result'));
    expect(shared, 1);
  });

  testWidgets('shows the next bid and a spinner while the ledger '
      'loads', (tester) async {
    await tester.pumpWidget(_app(lotCard(), null));

    expect(find.text('Next bid from Rp 175.000'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('fits a phone without overflow', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 740)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final lot = lotCard(
      version: 3,
      currentPrice: 12500000,
      leaderId: siti,
      leaderName: 'Siti',
    );
    await tester.pumpWidget(
      _app(lot, [
        for (var i = 1; i <= 20; i++) ledgerEntry(i, retracted: i == 4),
      ], me: budi),
    );

    expect(tester.takeException(), isNull);
  });

  group('as of a past moment', () {
    // Live: Budi leads at 250k after Siti's 200k.
    final budiLeads = lotCard(
      version: 4,
      currentPrice: 250000,
      leaderId: budi,
      leaderName: 'Budi',
    );
    final ledger = [
      ledgerEntry(1),
      ledgerEntry(2, by: siti, name: 'Siti', amount: 200000),
      ledgerEntry(3, amount: 250000),
    ];
    final at = DateTime.utc(2026, 10, 14, 22, 1, 2);
    final sitiLed = LotAsOf(
      at: at,
      price: 200000,
      leaderId: siti,
      leaderName: 'Siti',
      status: 'OPEN',
      bidCount: 2,
      retractedCount: 0,
      lastSequence: 2,
      version: 3,
    );

    testWidgets("shows the server's price and leader, not the live "
        'ones', (tester) async {
      await tester.pumpWidget(_app(budiLeads, ledger, me: budi, asOf: sitiLed));

      expect(find.text('Rp 200.000'), findsOneWidget);
      expect(find.text('Siti led'), findsOneWidget);
      expect(find.text('Rp 250.000'), findsNothing);
      expect(find.textContaining('high bidder'), findsNothing);
      expect(find.textContaining('Next bid'), findsNothing);
    });

    testWidgets('the As of… chip opens the picker once there are bids', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(_app(budiLeads, ledger, onAsOf: () => opened++));

      await tester.tap(find.text('As of…'));
      expect(opened, 1);

      // A ledger only grows, so start a fresh tree for the empty one.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(lotCard(), const [], onAsOf: () {}));
      expect(find.text('As of…'), findsNothing);
    });

    testWidgets('the bar shows the badge and LIVE returns', (tester) async {
      var live = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AsOfBar(at: at, onLive: () => live++),
          ),
        ),
      );

      expect(find.text('AS OF ${formatClock(at)}'), findsOneWidget);
      await tester.tap(find.text('LIVE'));
      expect(live, 1);
    });
  });
}
