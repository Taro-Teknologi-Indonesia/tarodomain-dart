import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_flutter/core/time_travel.dart';

import '../support.dart';

void main() {
  // ledgerEntry(n) is placed at 22:01:0n; a retraction 5 s later.
  final ledger = [
    ledgerEntry(1),
    ledgerEntry(2, by: siti, name: 'Siti'),
    ledgerEntry(3, retracted: true),
  ];
  String clock(DateTime at) =>
      '${at.hour}:${at.minute.toString().padLeft(2, '0')}';

  group('presets', () {
    test('before the first bid, each minute after activity, and before '
        'close', () {
      final closedAt = DateTime.utc(2026, 10, 14, 22, 3);

      final presets = presetsFor(
        ledger,
        end: closedAt,
        closedAt: closedAt,
        clock: clock,
      );

      expect(presets, [
        Moment(DateTime.utc(2026, 10, 14, 22, 1, 0, 999), 'Before first bid'),
        Moment(DateTime.utc(2026, 10, 14, 22, 2), '22:02'),
        Moment(DateTime.utc(2026, 10, 14, 22, 2, 59, 999), 'Just before close'),
      ]);
    });

    test('an open lot has no close pick, nor a minute that is still '
        'live', () {
      final presets = presetsFor(
        ledger,
        end: DateTime.utc(2026, 10, 14, 22, 1, 30),
        closedAt: null,
        clock: clock,
      );

      expect([for (final p in presets) p.label], ['Before first bid']);
    });

    test('no bids, no picks', () {
      expect(
        presetsFor(
          const [],
          end: DateTime.utc(2026),
          closedAt: null,
          clock: clock,
        ),
        isEmpty,
      );
    });
  });

  test('the slider stops at every bid and retraction, in time order', () {
    expect(
      [for (final s in stopsFor(ledger)) s.label],
      ['Before first bid', '#1 Budi', '#2 Siti', '#3 Budi', '#3 retracted'],
    );
  });

  group('a ledger row as of a moment', () {
    final retracted = ledgerEntry(3, retracted: true);
    final placed = retracted.placedAt;
    final taken = retracted.retractedAt!;

    test('is after it only if placed later', () {
      expect(retracted.placedAfter(placed), isFalse);
      expect(
        retracted.placedAfter(placed.subtract(const Duration(milliseconds: 1))),
        isTrue,
      );
    });

    test('stands until the moment it was retracted', () {
      expect(
        retracted.retractedBy(taken.subtract(const Duration(milliseconds: 1))),
        isFalse,
      );
      expect(retracted.retractedBy(taken), isTrue);
      expect(ledgerEntry(1).retractedBy(taken), isFalse);
    });
  });
}
