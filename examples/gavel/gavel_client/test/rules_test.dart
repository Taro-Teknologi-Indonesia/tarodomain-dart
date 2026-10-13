import 'package:gavel_client/rules.dart';
import 'package:test/test.dart';

List<FieldError> _lot({
  String name = 'Natural Pirus Hubei',
  int openBid = 150000,
  int? buyNowPrice,
  List<int> increments = const [25000, 50000],
  String description = '',
  String? imageUrl,
  String tileEmoji = '💎',
  String tileColor = '#2E7D6B',
}) => LotRules.newLot(
  name: name,
  openBid: openBid,
  buyNowPrice: buyNowPrice,
  increments: increments,
  description: description,
  imageUrl: imageUrl,
  tileEmoji: tileEmoji,
  tileColor: tileColor,
);

void main() {
  group('AuctionRules', () {
    test('title is 1 to 80 characters after trimming', () {
      expect(AuctionRules.title('  ${'a' * 80}  '), isNull);
      expect(AuctionRules.title('a' * 81)?.reason, 'TOO_LONG');
      expect(AuctionRules.title('   ')?.reason, 'EMPTY');
      expect(
        AuctionRules.title('')?.message,
        'The title must be 1 to 80 characters',
      );
    });

    test('closeAt is at least 5 minutes from now', () {
      final now = DateTime.utc(2026, 10, 14, 22);
      final soon = now.add(const Duration(minutes: 5));

      expect(AuctionRules.closeAt(soon, now: now), isNull);
      expect(
        AuctionRules.closeAt(
          soon.subtract(const Duration(seconds: 1)),
          now: now,
        )?.reason,
        'TOO_SOON',
      );
    });

    test('takes 20 lots at most', () {
      expect(AuctionRules.lotCount(19), isNull);
      expect(AuctionRules.lotCount(20)?.reason, 'TOO_MANY');
    });
  });

  group('LotRules', () {
    test('a valid lot has no errors', () {
      expect(
        _lot(buyNowPrice: 150001, imageUrl: 'https://x.id/a.jpg'),
        isEmpty,
      );
    });

    test('lists every bad field, in the server order', () {
      expect(_lot(name: '', openBid: 0, tileColor: 'red').map((e) => e.field), [
        'name',
        'openBid',
        'tileColor',
      ]);
    });

    test('BN must be above the open bid', () {
      expect(_lot(buyNowPrice: 150000).single.reason, 'NOT_ABOVE_OPEN_BID');
      expect(_lot(buyNowPrice: 150001), isEmpty);
    });

    test('image URLs are http(s) with a host', () {
      expect(_lot(imageUrl: 'ftp://x').single.reason, 'NOT_A_URL');
      expect(_lot(imageUrl: 'https://').single.reason, 'NOT_A_URL');
      expect(_lot(imageUrl: '  '), isEmpty);
    });

    test('steps are non-empty, positive and different', () {
      expect(_lot(increments: []).single.reason, 'EMPTY');
      expect(_lot(increments: [0]).single.reason, 'NOT_POSITIVE');
      expect(_lot(increments: [25000, 25000]).single.reason, 'DUPLICATE');
    });

    test('description is at most 2000 characters', () {
      expect(_lot(description: 'a' * 2000), isEmpty);
      expect(_lot(description: 'a' * 2001).single.reason, 'TOO_LONG');
    });

    test('tile emoji is 1 to 16 UTF-16 units', () {
      expect(_lot(tileEmoji: ' ').single.field, 'tileEmoji');
      expect(_lot(tileEmoji: '💎' * 9).single.field, 'tileEmoji');
    });
  });

  group('ParticipantRules', () {
    // A family: four people joined by ZWJs, one grapheme and seven runes.
    const family = '👨‍👩‍👧‍👦';

    test('counts runes, not graphemes', () {
      final fits = '${'a' * 17}$family';
      expect(fits.runes.length, 24);
      expect(ParticipantRules.displayName(fits), isNull);
      expect(ParticipantRules.displayName('a$fits')?.reason, 'TOO_LONG');
    });

    test('refuses an empty name and control characters', () {
      expect(ParticipantRules.displayName('  ')?.reason, 'EMPTY');
      expect(
        ParticipantRules.displayName('Bu\u0007di')?.reason,
        'CONTROL_CHARACTER',
      );
      expect(ParticipantRules.withoutControl('Bu\u0007di\n'), 'Budi');
    });
  });

  group('JoinCodeRules', () {
    test('six characters of the alphabet', () {
      expect(JoinCodeRules.isValid('ABC234'), isTrue);
      expect(JoinCodeRules.isValid('ABC23'), isFalse);
      expect(JoinCodeRules.isValid('ABCO34'), isFalse);
      expect(JoinCodeRules.isValid('abc234'), isFalse);
    });

    test('normalize trims and uppercases', () {
      expect(JoinCodeRules.normalize(' abc234 '), 'ABC234');
    });
  });
}
