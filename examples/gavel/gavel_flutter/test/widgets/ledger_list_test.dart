import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/widgets/ledger_list.dart';

import '../support.dart';

final _closeAt = DateTime.utc(2026, 10, 14, 22, 3);

Widget _app(List<LedgerEntry> entries, {LotCard? lot, UuidValue? me}) =>
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: LedgerList(
              lot: lot ?? lotCard(),
              entries: entries,
              closeAt: _closeAt,
              me: me,
            ),
          ),
        ),
      ),
    );

/// The rows' first lines, top to bottom.
List<String> _rows(WidgetTester tester) => [
  for (final row in tester.widgetList<LedgerRow>(find.byType(LedgerRow)))
    '#${row.entry.sequence}',
];

void main() {
  testWidgets('shows every bid, newest on top', (tester) async {
    await tester.pumpWidget(
      _app([
        ledgerEntry(1),
        ledgerEntry(2, by: siti, name: 'Siti'),
        ledgerEntry(3),
      ]),
    );

    expect(_rows(tester), ['#3', '#2', '#1']);
    expect(
      find.text(
        '#2 · Siti · Rp 200.000 · '
        '${formatClock(DateTime.utc(2026, 10, 14, 22, 1, 2))}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('strikes a retracted bid through and keeps it', (tester) async {
    final entries = [
      ledgerEntry(1),
      ledgerEntry(2, by: siti, name: 'Siti', retracted: true),
    ];
    await tester.pumpWidget(_app(entries));

    expect(find.byType(LedgerRow), findsNWidgets(2));
    final struck = tester.widget<Text>(find.textContaining('#2 · Siti').first);
    expect(struck.style?.decoration, TextDecoration.lineThrough);
    final kept = tester.widget<Text>(find.textContaining('#1 · Budi').first);
    expect(kept.style?.decoration, isNull);
    expect(
      find.text(
        'retracted ${formatClock(DateTime.utc(2026, 10, 14, 22, 1, 7))}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a retraction arriving later strikes the row in place', (
    tester,
  ) async {
    await tester.pumpWidget(_app([ledgerEntry(1), ledgerEntry(2)]));
    await tester.pumpWidget(
      _app([ledgerEntry(1), ledgerEntry(2, retracted: true)]),
    );
    await tester.pumpAndSettle();

    expect(_rows(tester), ['#2', '#1']);
    expect(find.textContaining('retracted'), findsOneWidget);
  });

  testWidgets('slides a new bid in on top', (tester) async {
    await tester.pumpWidget(_app([ledgerEntry(1)]));
    await tester.pumpWidget(
      _app([ledgerEntry(1), ledgerEntry(2, by: siti, name: 'Siti')]),
    );

    await tester.pump(const Duration(milliseconds: 100));

    final sliding = tester.widget<SizeTransition>(
      find.byType(SizeTransition).first,
    );
    expect(sliding.sizeFactor.value, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(_rows(tester), ['#2', '#1']);
  });

  testWidgets('puts the closing line above the bids', (tester) async {
    await tester.pumpWidget(
      _app(
        [ledgerEntry(1, by: siti, name: 'Siti')],
        lot: lotCard(
          version: 3,
          status: 'SOLD',
          winnerName: 'Siti',
          closedAt: _closeAt,
        ),
      ),
    );

    final closing = '🔨 Closed ${formatClock(_closeAt)} — SOLD to Siti';
    expect(find.text(closing), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(closing)).dy,
      lessThan(tester.getTopLeft(find.byType(LedgerRow)).dy),
    );
  });

  testWidgets('names a Buy Now in the closing line', (tester) async {
    await tester.pumpWidget(
      _app(
        [ledgerEntry(1, by: siti, name: 'Siti')],
        lot: lotCard(
          version: 3,
          status: 'SOLD',
          winnerName: 'Siti',
          closeCause: 'BUY_NOW',
        ),
      ),
    );

    expect(
      find.text('🔨 Closed ${formatClock(_closeAt)} — Bought now by Siti'),
      findsOneWidget,
    );
  });

  testWidgets('says so when nobody bid', (tester) async {
    await tester.pumpWidget(_app([]));

    expect(find.text('No bids yet'), findsOneWidget);
  });
}
