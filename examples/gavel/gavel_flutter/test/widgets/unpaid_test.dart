import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/widgets/ledger_list.dart';
import 'package:gavel_flutter/widgets/lot_card_widget.dart';
import 'package:gavel_flutter/widgets/unpaid.dart';

import '../support.dart';

final _closeAt = DateTime.utc(2026, 10, 14, 22, 3);
final _markedAt = DateTime.utc(2026, 10, 15, 10, 12);

LotCard _sold({bool unpaid = false, String? note}) =>
    lotCard(
      status: 'SOLD',
      leaderId: budi,
      leaderName: 'Budi',
      winnerName: 'Budi',
      finalPrice: 175000,
      currentPrice: 175000,
      closedAt: _closeAt,
    ).copyWith(
      unpaid: unpaid,
      unpaidAt: unpaid ? _markedAt : null,
      unpaidNote: note,
    );

Widget _ledger(LotCard lot, {LotAsOf? asOf}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: LedgerList(
        lot: lot,
        entries: [ledgerEntry(1)],
        closeAt: _closeAt,
        asOf: asOf,
      ),
    ),
  ),
);

LotAsOf _asOf(DateTime at) => LotAsOf(
  at: at,
  price: 175000,
  status: 'SOLD',
  bidCount: 1,
  retractedCount: 0,
  lastSequence: 1,
  version: 3,
);

void main() {
  group('unpaidLine', () {
    test('is null for a lot not marked', () {
      expect(unpaidLine(_sold()), isNull);
    });

    test('names when, with the note', () {
      expect(
        unpaidLine(_sold(unpaid: true, note: 'no reply after 24 h')),
        startsWith('⚠ Winner did not pay — marked by organizer '),
      );
      expect(
        unpaidLine(_sold(unpaid: true, note: 'no reply after 24 h')),
        endsWith(" · 'no reply after 24 h'"),
      );
      expect(unpaidLine(_sold(unpaid: true)), isNot(contains("'")));
    });

    test('is null as of a moment before the mark', () {
      final lot = _sold(unpaid: true);
      expect(
        unpaidLine(lot, asOf: _markedAt.subtract(const Duration(hours: 1))),
        isNull,
      );
      expect(unpaidLine(lot, asOf: _markedAt), isNotNull);
    });
  });

  testWidgets('the board card shows UNPAID next to SOLD', (tester) async {
    for (final unpaid in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: LotCardWidget(_sold(unpaid: unpaid)),
            ),
          ),
        ),
      );
      expect(find.text('SOLD'), findsOneWidget);
      expect(find.text('UNPAID'), unpaid ? findsOneWidget : findsNothing);
    }
  });

  testWidgets('the ledger shows the mark above the closing line', (
    tester,
  ) async {
    await tester.pumpWidget(_ledger(_sold(unpaid: true, note: 'no reply')));

    final mark = find.textContaining('Winner did not pay');
    final closing = find.textContaining('🔨 Closed');
    expect(mark, findsOneWidget);
    expect(tester.getTopLeft(mark).dy, lessThan(tester.getTopLeft(closing).dy));

    await tester.pumpWidget(
      _ledger(
        _sold(unpaid: true),
        asOf: _asOf(_markedAt.subtract(const Duration(minutes: 1))),
      ),
    );
    expect(find.textContaining('Winner did not pay'), findsNothing);
  });

  testWidgets('the confirm dialog returns the trimmed note, or nothing on '
      'cancel', (tester) async {
    late ({bool confirmed, String? note}) result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                result = await confirmMarkUnpaid(context, _sold()),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('This is public and permanent.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result.confirmed, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  no reply after 24 h ');
    await tester.tap(find.widgetWithText(FilledButton, 'Mark unpaid'));
    await tester.pumpAndSettle();
    expect(result, (confirmed: true, note: 'no reply after 24 h'));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Mark unpaid'));
    await tester.pumpAndSettle();
    expect(result, (confirmed: true, note: null));
  });
}
