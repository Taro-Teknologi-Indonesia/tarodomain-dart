import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/pages/lot_page.dart';

import '../support.dart';

Widget _app(
  LotCard lot,
  List<LedgerEntry>? ledger, {
  UuidValue? me,
  VoidCallback? onShare,
}) => MaterialApp(
  home: Scaffold(
    body: LotDetailBody(
      lot: lot,
      ledger: ledger,
      closeAt: DateTime.utc(2026, 10, 14, 22, 3),
      me: me,
      onShare: onShare,
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

    testWidgets('celebrates with the winner, who can share it', (tester) async {
      var shared = 0;
      await tester.pumpWidget(
        _app(soldToBudi, [ledgerEntry(1)], me: budi, onShare: () => shared++),
      );

      expect(
        find.text('🔨 You won Batik tulis Lasem — Rp 175.000'),
        findsOneWidget,
      );
      await tester.tap(find.text('Share result'));
      expect(shared, 1);
    });

    testWidgets('names the winner to everyone else', (tester) async {
      await tester.pumpWidget(
        _app(soldToBudi, [ledgerEntry(1)], me: siti, onShare: () {}),
      );

      expect(find.textContaining('You won'), findsNothing);
      expect(find.text('SOLD to Budi — Rp 175.000'), findsOneWidget);
    });
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
}
