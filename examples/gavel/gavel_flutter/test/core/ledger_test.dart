import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_flutter/core/ledger.dart';

import '../support.dart';

void main() {
  group('lastValid', () {
    test('is the latest bid', () {
      final ledger = [ledgerEntry(1), ledgerEntry(2, by: siti, name: 'Siti')];

      expect(ledger.lastValid?.sequence, 2);
    });

    test('skips retracted bids', () {
      final ledger = [
        ledgerEntry(1),
        ledgerEntry(2, by: siti, name: 'Siti', retracted: true),
      ];

      expect(ledger.lastValid?.sequence, 1);
    });

    test('is null when every bid was retracted', () {
      expect([ledgerEntry(1, retracted: true)].lastValid, isNull);
    });
  });

  group('canRetract', () {
    final ledger = [ledgerEntry(1), ledgerEntry(2, by: siti, name: 'Siti')];
    final closeAt = DateTime.utc(2026, 10, 14, 23);
    final now = closeAt.subtract(const Duration(minutes: 1));

    test('only for the owner of the latest valid bid', () {
      expect(
        ledger.canRetract(lotCard(), siti, closeAt: closeAt, now: now),
        isTrue,
      );
      expect(
        ledger.canRetract(lotCard(), budi, closeAt: closeAt, now: now),
        isFalse,
      );
      expect(
        ledger.canRetract(lotCard(), null, closeAt: closeAt, now: now),
        isFalse,
      );
    });

    test('passes to the previous bidder after a retraction', () {
      final after = [
        ledgerEntry(1),
        ledgerEntry(2, by: siti, name: 'Siti', retracted: true),
      ];

      expect(
        after.canRetract(lotCard(), budi, closeAt: closeAt, now: now),
        isTrue,
      );
      expect(
        after.canRetract(lotCard(), siti, closeAt: closeAt, now: now),
        isFalse,
      );
    });

    test('never once the lot closed', () {
      expect(
        ledger.canRetract(
          lotCard(status: 'SOLD', winnerName: 'Siti'),
          siti,
          closeAt: closeAt,
          now: now,
        ),
        isFalse,
      );
    });
  });

  test('canRetract is false once closeAt passes, though still OPEN', () {
    final ledger = [ledgerEntry(1, by: siti, name: 'Siti')];
    final closeAt = DateTime.utc(2026, 10, 14, 23);

    expect(
      ledger.canRetract(lotCard(), siti, closeAt: closeAt, now: closeAt),
      isFalse,
    );
  });

  test('hasValidBidBy ignores retracted bids', () {
    final ledger = [ledgerEntry(1, retracted: true)];

    expect(ledger.hasValidBidBy(budi), isFalse);
    expect([ledgerEntry(1)].hasValidBidBy(budi), isTrue);
    expect([ledgerEntry(1)].hasValidBidBy(null), isFalse);
  });
}
