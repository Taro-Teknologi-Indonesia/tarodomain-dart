import 'package:gavel_server/src/domain/auction.dart';
import 'package:gavel_server/src/domain/auction_commands.dart';
import 'package:gavel_server/src/domain/errors.dart';
import 'package:gavel_server/src/domain/gavel_domain.dart';
import 'package:gavel_server/src/domain/keys.dart';
import 'package:gavel_server/src/domain/lot.dart';
import 'package:gavel_server/src/domain/lot_commands.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';
import 'package:test/test.dart';

void main() {
  late TaroDomain gavel;
  late AuctionId auctionId;
  final now = DateTime.utc(2026, 10, 14, 12, 0);
  final closeAt = now.add(const Duration(hours: 2));
  const organizerKey = 'organizer-secret';
  const ladder = [25000, 50000, 100000, 150000, 200000, 300000];

  setUp(() async {
    gavel = registerGavel(
      TaroDomain.builder().useLocal(),
    ).build().createRuntime();
    auctionId = AuctionId.generate();
    await gavel.dispatch(
      CreateAuction(
        auctionId,
        title: 'Bonsai night',
        closeAt: closeAt,
        code: 'ABC234',
        organizerKeyHash: hashKey(organizerKey),
        timestamp: now,
      ),
    );
  });

  AddLot add({
    LotId? lotId,
    String key = organizerKey,
    String name = 'Natural Pirus Hubei',
    int openBid = 150000,
    List<int> increments = ladder,
    String description = 'Berat: 2 kg\nAsal: Hubei',
    String? imageUrl,
    String tileEmoji = '💎',
    String tileColor = '#2E7D6B',
    DateTime? at,
  }) => AddLot(
    auctionId,
    lotId ?? LotId.generate(),
    organizerKey: key,
    name: name,
    openBid: openBid,
    increments: increments,
    description: description,
    imageUrl: imageUrl,
    tileEmoji: tileEmoji,
    tileColor: tileColor,
    timestamp: at ?? now,
  );

  Future<Lot> loadLot(LotId id) => gavel.repository<Lot, LotId>().load(id);

  Future<Auction> loadAuction() =>
      gavel.repository<Auction, AuctionId>().load(auctionId);

  Future<List<String>> lotEvents(LotId id) async => [
    for (final e in await gavel.eventStore.loadStream('Lot-${id.uuid}'))
      e.eventName,
  ];

  Future<List<String>> auctionEvents() async => [
    for (final e in await gavel.eventStore.loadStream(
      'Auction-${auctionId.uuid}',
    ))
      e.eventName,
  ];

  Matcher invalid(String field, [String? reason]) =>
      isA<CommandValidationError>().having(
        (e) => e.context,
        'context',
        allOf([
          containsPair('field', field),
          if (reason != null) containsPair('reason', reason),
        ]),
      );

  test('a new lot is open at its open bid, with the auction close', () async {
    final command = add(imageUrl: ' https://example.com/pirus.jpg ');
    await gavel.dispatch(command);

    final lot = await loadLot(command.lotId);
    expect(lot.name, 'Natural Pirus Hubei');
    expect(lot.openBid, 150000);
    expect(lot.increments, ladder);
    expect(lot.closeAt, closeAt);
    expect(lot.status, LotStatus.open);
    expect(lot.position, 0);
    expect(lot.auctionId, auctionId.uuid);

    final created =
        (await gavel.eventStore.loadStream('Lot-${command.lotId.uuid}')).single
            as LotCreated;
    expect(created.code, 'ABC234');
    expect(created.imageUrl, 'https://example.com/pirus.jpg');
    expect(created.description, 'Berat: 2 kg\nAsal: Hubei');
  });

  test('the auction records its lots in order', () async {
    final first = add();
    final second = add(name: 'Shohin juniper');
    await gavel.dispatch(first);
    await gavel.dispatch(second);

    expect((await loadAuction()).lotIds, [first.lotId.uuid, second.lotId.uuid]);
    expect((await loadLot(second.lotId)).position, 1);
    expect(await auctionEvents(), [
      'AuctionCreated',
      'LotRegistered',
      'LotRegistered',
    ]);
  });

  group('the open bid', () {
    test('0 is rejected', () async {
      await expectLater(
        gavel.dispatch(add(openBid: 0)),
        throwsA(invalid('openBid', 'NOT_POSITIVE')),
      );
    });

    test('a negative amount is rejected', () async {
      await expectLater(
        gavel.dispatch(add(openBid: -25000)),
        throwsA(invalid('openBid', 'NOT_POSITIVE')),
      );
    });
  });

  group('the kelipatan ladder', () {
    test('must not be empty', () async {
      await expectLater(
        gavel.dispatch(add(increments: [])),
        throwsA(invalid('increments', 'EMPTY')),
      );
    });

    test('must not repeat a step', () async {
      await expectLater(
        gavel.dispatch(add(increments: [50000, 25000, 25000])),
        throwsA(invalid('increments', 'DUPLICATE')),
      );
    });

    test('must have only positive steps', () async {
      await expectLater(
        gavel.dispatch(add(increments: [25000, 0])),
        throwsA(invalid('increments', 'NOT_POSITIVE')),
      );
    });

    test('is stored sorted', () async {
      final command = add(increments: [100000, 25000, 50000]);
      await gavel.dispatch(command);

      expect((await loadLot(command.lotId)).increments, [25000, 50000, 100000]);
    });
  });

  group('the other fields', () {
    test('the name must not be empty', () async {
      await expectLater(
        gavel.dispatch(add(name: '  ')),
        throwsA(invalid('name', 'EMPTY')),
      );
    });

    test('the name must be at most 80 characters', () async {
      await expectLater(
        gavel.dispatch(add(name: 'x' * 81)),
        throwsA(invalid('name', 'TOO_LONG')),
      );
    });

    test('the description must be at most 2000 characters', () async {
      await expectLater(
        gavel.dispatch(add(description: 'x' * 2001)),
        throwsA(invalid('description', 'TOO_LONG')),
      );
    });

    test('the image must be an http(s) URL', () async {
      for (final url in ['ftp://example.com/a.jpg', 'pirus.jpg', 'https://']) {
        await expectLater(
          gavel.dispatch(add(imageUrl: url)),
          throwsA(invalid('imageUrl', 'NOT_A_URL')),
          reason: url,
        );
      }
    });

    test('a blank image URL means no image', () async {
      final command = add(imageUrl: '  ');
      await gavel.dispatch(command);

      final created =
          (await gavel.eventStore.loadStream(
                'Lot-${command.lotId.uuid}',
              )).single
              as LotCreated;
      expect(created.imageUrl, isNull);
    });

    test('the tile color must be #RRGGBB', () async {
      await expectLater(
        gavel.dispatch(add(tileColor: 'green')),
        throwsA(invalid('tileColor')),
      );
    });

    test('the tile emoji must not be empty', () async {
      await expectLater(
        gavel.dispatch(add(tileEmoji: '')),
        throwsA(invalid('tileEmoji')),
      );
    });
  });

  test('the wrong organizer key is rejected and raises no event', () async {
    final command = add(key: 'someone-else');

    await expectLater(
      gavel.dispatch(command),
      throwsA(isA<NotOrganizerError>()),
    );

    expect(await lotEvents(command.lotId), isEmpty);
    expect(await auctionEvents(), ['AuctionCreated']);
  });

  test('a lot added at the close time is LOT_CLOSED', () async {
    final command = add(at: closeAt);

    await expectLater(gavel.dispatch(command), throwsA(isA<LotClosedError>()));
    expect(await lotEvents(command.lotId), isEmpty);
  });

  test('a lot added after the close time is LOT_CLOSED', () async {
    await expectLater(
      gavel.dispatch(add(at: closeAt.add(const Duration(minutes: 1)))),
      throwsA(isA<LotClosedError>()),
    );
  });

  test('an auction takes at most 20 lots', () async {
    for (var i = 0; i < Auction.maxLots; i++) {
      await gavel.dispatch(add(name: 'Lot $i'));
    }

    await expectLater(
      gavel.dispatch(add(name: 'One too many')),
      throwsA(invalid('lots', 'TOO_MANY')),
    );
  });

  test('adding the same lot twice is rejected', () async {
    final lotId = LotId.generate();
    await gavel.dispatch(add(lotId: lotId));

    await expectLater(
      gavel.dispatch(add(lotId: lotId)),
      throwsA(isA<AggregateAlreadyExistsError>()),
    );
    expect((await loadAuction()).lotIds, hasLength(1));
  });

  test('a snapshot restores the state', () async {
    final command = add();
    await gavel.dispatch(command);
    final lot = await loadLot(command.lotId);
    final auction = await loadAuction();

    expect(
      (Lot(command.lotId)..restoreSnapshotState(lot.toSnapshot())).toSnapshot(),
      lot.toSnapshot(),
    );
    expect(
      (Auction(
        auctionId,
      )..restoreSnapshotState(auction.toSnapshot())).toSnapshot(),
      auction.toSnapshot(),
    );
  });
}
