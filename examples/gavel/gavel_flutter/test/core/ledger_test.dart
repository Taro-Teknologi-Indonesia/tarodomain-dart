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

    test('only for the owner of the latest valid bid', () {
      expect(ledger.canRetract(lotCard(), siti), isTrue);
      expect(ledger.canRetract(lotCard(), budi), isFalse);
      expect(ledger.canRetract(lotCard(), null), isFalse);
    });

    test('passes to the previous bidder after a retraction', () {
      final after = [
        ledgerEntry(1),
        ledgerEntry(2, by: siti, name: 'Siti', retracted: true),
      ];

      expect(after.canRetract(lotCard(), budi), isTrue);
      expect(after.canRetract(lotCard(), siti), isFalse);
    });

    test('never once the lot closed', () {
      expect(
        ledger.canRetract(lotCard(status: 'SOLD', winnerName: 'Siti'), siti),
        isFalse,
      );
    });
  });

  test('hasValidBidBy ignores retracted bids', () {
    final ledger = [ledgerEntry(1, retracted: true)];

    expect(ledger.hasValidBidBy(budi), isFalse);
    expect([ledgerEntry(1)].hasValidBidBy(budi), isTrue);
    expect([ledgerEntry(1)].hasValidBidBy(null), isFalse);
  });
}
