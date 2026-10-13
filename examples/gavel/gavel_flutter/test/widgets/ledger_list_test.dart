import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/widgets/ledger_list.dart';

import '../support.dart';

final _closeAt = DateTime.utc(2026, 10, 14, 22, 3);

Widget _app(
  List<LedgerEntry> entries, {
  LotCard? lot,
  UuidValue? me,
  LotAsOf? asOf,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: SizedBox(
        width: 360,
        child: LedgerList(
          lot: lot ?? lotCard(),
          entries: entries,
          closeAt: _closeAt,
          me: me,
          asOf: asOf,
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

/// The decoration the row starting with [text] is drawn with.
TextDecoration? _decoration(WidgetTester tester, String text) =>
    DefaultTextStyle.of(
      tester.element(find.textContaining(text).first),
    ).style.decoration;

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
    expect(_decoration(tester, '#2 · Siti'), TextDecoration.lineThrough);
    expect(_decoration(tester, '#1 · Budi'), TextDecoration.none);
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

  testWidgets('a retraction fades the row into strike-through and keeps '
      'it', (tester) async {
    await tester.pumpWidget(_app([ledgerEntry(1)]));
    await tester.pumpWidget(_app([ledgerEntry(1, retracted: true)]));

    expect(find.byType(LedgerRow), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_decoration(tester, '#1 · Budi'), TextDecoration.lineThrough);
  });

  group('as of a past moment', () {
    // #3 placed 22:01:03, retracted 22:01:08.
    final entries = [
      ledgerEntry(1),
      ledgerEntry(2, by: siti, name: 'Siti'),
      ledgerEntry(3, retracted: true),
    ];
    LotAsOf asOf(DateTime at, {String status = 'OPEN'}) => LotAsOf(
      at: at,
      price: 175000,
      status: status,
      bidCount: 1,
      retractedCount: 0,
      lastSequence: 1,
      version: 2,
    );
    double opacity(WidgetTester tester, int sequence) => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.textContaining('#$sequence ·'),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    testWidgets('dims the bids placed after it', (tester) async {
      await tester.pumpWidget(
        _app(entries, asOf: asOf(DateTime.utc(2026, 10, 14, 22, 1, 1))),
      );

      expect(opacity(tester, 1), 1);
      expect(opacity(tester, 2), 0.3);
      expect(opacity(tester, 3), 0.3);
    });

    testWidgets('a bid retracted after it stands un-struck', (tester) async {
      await tester.pumpWidget(
        _app(entries, asOf: asOf(DateTime.utc(2026, 10, 14, 22, 1, 5))),
      );
      await tester.pumpAndSettle();

      expect(opacity(tester, 3), 1);
      expect(_decoration(tester, '#3 ·'), TextDecoration.none);
      expect(find.textContaining('retracted'), findsNothing);

      await tester.pumpWidget(
        _app(entries, asOf: asOf(DateTime.utc(2026, 10, 14, 22, 1, 8))),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester, '#3 ·'), TextDecoration.lineThrough);
    });

    testWidgets('a closed lot has no closing line before it closed', (
      tester,
    ) async {
      final sold = lotCard(
        status: 'SOLD',
        leaderId: siti,
        winnerName: 'Siti',
        closedAt: _closeAt,
      );
      await tester.pumpWidget(
        _app(
          entries,
          lot: sold,
          asOf: asOf(DateTime.utc(2026, 10, 14, 22, 1, 5)),
        ),
      );

      expect(find.textContaining('🔨 Closed'), findsNothing);
    });
  });
}
