import 'package:gavel_client/rules.dart';
import 'package:gavel_server/src/domain/auction.dart';
import 'package:gavel_server/src/domain/lot.dart';
import 'package:gavel_server/src/domain/participant.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

/// Holds the app's input rules (X5) to the domain's: the same limits, and
/// the same `field`, `reason` and message for every input in the tables.

final _now = DateTime.utc(2026, 10, 14, 12);

/// What the domain refused [run] with, or null if it took it.
FieldError? _domain(void Function() run) {
  try {
    run();
    return null;
  } on CommandValidationError catch (e) {
    return FieldError(
      e.context['field']! as String,
      e.context['reason']! as String,
      e.message,
    );
  }
}

typedef _Auction = ({String title, Duration lead});

typedef _Lot = ({
  String name,
  int openBid,
  int? buyNowPrice,
  List<int> increments,
  String description,
  String? imageUrl,
  String tileEmoji,
  String tileColor,
});

_Lot _lot({
  String name = 'Natural Pirus Hubei',
  int openBid = 150000,
  int? buyNowPrice,
  List<int> increments = const [25000, 50000],
  String description = 'Berat: 12 g',
  String? imageUrl,
  String tileEmoji = '💎',
  String tileColor = '#2E7D6B',
}) => (
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
  test('the limits are the same', () {
    expect(AuctionRules.maxTitleLength, Auction.maxTitleLength);
    expect(AuctionRules.minimumLeadTime, Auction.minimumLeadTime);
    expect(AuctionRules.maxLots, Auction.maxLots);
    expect(LotRules.maxNameLength, Lot.maxNameLength);
    expect(LotRules.maxDescriptionLength, Lot.maxDescriptionLength);
    expect(LotRules.maxEmojiLength, Lot.maxEmojiLength);
    expect(LotRules.maxUnpaidNoteLength, Lot.maxUnpaidNoteLength);
    expect(ParticipantRules.maxNameLength, Participant.maxNameLength);
    expect(JoinCodeRules.alphabet, Auction.codeAlphabet);
    expect(JoinCodeRules.length, Auction.codeLength);
  });

  group('Auction.create', () {
    final cases = <String, _Auction>{
      'valid': (title: 'Bonsai night', lead: const Duration(hours: 1)),
      'exactly 5 minutes ahead': (
        title: 'Bonsai night',
        lead: const Duration(minutes: 5),
      ),
      '80 characters, trimmed': (
        title: ' ${'a' * 80} ',
        lead: const Duration(hours: 1),
      ),
      'empty title': (title: '  ', lead: const Duration(hours: 1)),
      '81 characters': (title: 'a' * 81, lead: const Duration(hours: 1)),
      'too soon': (
        title: 'Bonsai night',
        lead: const Duration(minutes: 4, seconds: 59),
      ),
      'in the past': (title: 'Bonsai night', lead: const Duration(hours: -1)),
      'both wrong': (title: '', lead: Duration.zero),
    };
    for (final MapEntry(key: name, value: input) in cases.entries) {
      test(name, () {
        final closeAt = _now.add(input.lead);
        final domain = _domain(
          () => Auction.create(
            AuctionId.generate(),
            title: input.title,
            closeAt: closeAt,
            code: 'ABC234',
            organizerKeyHash: 'hash',
            now: _now,
          ),
        );
        final client = [
          ?AuctionRules.title(input.title),
          ?AuctionRules.closeAt(closeAt, now: _now),
        ];
        expect(client.firstOrNull, domain);
      });
    }
  });

  test('Auction.registerLot takes at most maxLots', () {
    final auction = Auction.create(
      AuctionId.generate(),
      title: 'Bonsai night',
      closeAt: _now.add(const Duration(hours: 1)),
      code: 'ABC234',
      organizerKeyHash: 'hash',
      now: _now,
    );
    for (var count = 0; count <= Auction.maxLots; count++) {
      final domain = _domain(
        () => auction.registerLot(LotId.generate().uuid, _now),
      );
      expect(AuctionRules.lotCount(count), domain, reason: '$count lots');
    }
  });

  group('Lot.create', () {
    final cases = <String, _Lot>{
      'valid': _lot(),
      'valid with every option': _lot(
        buyNowPrice: 150001,
        imageUrl: ' https://example.com/a.jpg ',
        description: 'a' * 2000,
        name: ' ${'a' * 80} ',
        tileColor: '#abcdef',
      ),
      'empty image URL': _lot(imageUrl: '  '),
      'empty name': _lot(name: ' '),
      '81-character name': _lot(name: 'a' * 81),
      'zero open bid': _lot(openBid: 0),
      'negative open bid': _lot(openBid: -1),
      'BN at the open bid': _lot(buyNowPrice: 150000),
      'BN under the open bid': _lot(buyNowPrice: 1000),
      'no steps': _lot(increments: []),
      'a zero step': _lot(increments: [0, 25000]),
      'a duplicate step': _lot(increments: [25000, 25000]),
      '2001-character description': _lot(description: 'a' * 2001),
      'ftp image': _lot(imageUrl: 'ftp://x'),
      'image without a host': _lot(imageUrl: 'https://'),
      'image without a scheme': _lot(imageUrl: 'example.com/a.jpg'),
      'empty emoji': _lot(tileEmoji: ' '),
      'emoji over 16 units': _lot(tileEmoji: '💎' * 9),
      'named color': _lot(tileColor: 'red'),
      'short hex color': _lot(tileColor: '#abc'),
      'several wrong': _lot(name: '', openBid: 0, tileColor: 'red'),
    };
    for (final MapEntry(key: name, value: input) in cases.entries) {
      test(name, () {
        final domain = _domain(
          () => Lot.create(
            LotId.generate(),
            auctionId: AuctionId.generate().uuid,
            code: 'ABC234',
            name: input.name,
            openBid: input.openBid,
            increments: input.increments,
            buyNowPrice: input.buyNowPrice,
            description: input.description,
            imageUrl: input.imageUrl,
            tileEmoji: input.tileEmoji,
            tileColor: input.tileColor,
            closeAt: _now.add(const Duration(hours: 1)),
            position: 0,
          ),
        );
        final client = LotRules.newLot(
          name: input.name,
          openBid: input.openBid,
          buyNowPrice: input.buyNowPrice,
          increments: input.increments,
          description: input.description,
          imageUrl: input.imageUrl,
          tileEmoji: input.tileEmoji,
          tileColor: input.tileColor,
        );
        expect(client.firstOrNull, domain);
      });
    }
  });

  group('Participant.join', () {
    // Seven runes, one grapheme.
    const family = '👨‍👩‍👧‍👦';
    final cases = <String, String>{
      'valid': 'Budi',
      '24 runes with a ZWJ emoji': '${'a' * 17}$family',
      'trimmed': '  Siti  ',
      'empty': '   ',
      '25 runes with a ZWJ emoji': '${'a' * 18}$family',
      'a bell': 'Bu\u0007di',
      'a C1 control': 'Bu\u0085di',
      'DEL': 'Budi\u007F',
    };
    for (final MapEntry(key: name, value: input) in cases.entries) {
      test(name, () {
        final domain = _domain(
          () => Participant.join(
            ParticipantId.generate(),
            auctionId: AuctionId.generate().uuid,
            displayName: input,
            keyHash: 'hash',
          ),
        );
        expect(ParticipantRules.displayName(input), domain);
      });
    }
  });
}
