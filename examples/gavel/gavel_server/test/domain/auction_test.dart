import 'package:gavel_server/src/domain/auction.dart';
import 'package:gavel_server/src/domain/auction_commands.dart';
import 'package:gavel_server/src/domain/gavel_domain.dart';
import 'package:gavel_server/src/domain/keys.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';
import 'package:test/test.dart';

void main() {
  late TaroDomain gavel;
  final now = DateTime.utc(2026, 10, 14, 12, 0);
  const organizerKey = 'organizer-secret';

  setUp(() {
    gavel = registerGavel(
      TaroDomain.builder().useLocal(),
    ).build().createRuntime();
  });

  CreateAuction create({
    AuctionId? id,
    String title = 'Bonsai night',
    required DateTime closeAt,
    String? organizerUserId,
  }) => CreateAuction(
    id ?? AuctionId.generate(),
    title: title,
    closeAt: closeAt,
    code: 'ABC234',
    organizerKeyHash: hashKey(organizerKey),
    organizerUserId: organizerUserId,
    timestamp: now,
  );

  Future<Auction> load(AuctionId id) =>
      gavel.repository<Auction, AuctionId>().load(id);

  Matcher invalid(String field, [String? reason]) =>
      isA<CommandValidationError>().having(
        (e) => e.context,
        'context',
        allOf([
          containsPair('field', field),
          if (reason != null) containsPair('reason', reason),
        ]),
      );

  group('the close time', () {
    test('4 minutes ahead is too soon', () async {
      await expectLater(
        gavel.dispatch(create(closeAt: now.add(const Duration(minutes: 4)))),
        throwsA(invalid('closeAt', 'TOO_SOON')),
      );
    });

    test('in the past is too soon', () async {
      await expectLater(
        gavel.dispatch(create(closeAt: now.subtract(const Duration(hours: 1)))),
        throwsA(invalid('closeAt', 'TOO_SOON')),
      );
    });

    test('5 minutes ahead is accepted', () async {
      final command = create(closeAt: now.add(const Duration(minutes: 5)));
      await gavel.dispatch(command);

      expect(
        (await load(command.auctionId)).closeAt,
        now.add(const Duration(minutes: 5)),
      );
    });

    test('an odd minute such as 22:03 is accepted', () async {
      final closeAt = DateTime.utc(2026, 10, 14, 22, 3);
      final command = create(closeAt: closeAt);
      await gavel.dispatch(command);

      expect((await load(command.auctionId)).closeAt, closeAt);
    });
  });

  group('the title', () {
    final closeAt = now.add(const Duration(hours: 1));

    test('must not be empty', () async {
      await expectLater(
        gavel.dispatch(create(title: '   ', closeAt: closeAt)),
        throwsA(invalid('title', 'EMPTY')),
      );
    });

    test('must be at most 80 characters', () async {
      await expectLater(
        gavel.dispatch(create(title: 'x' * 81, closeAt: closeAt)),
        throwsA(invalid('title', 'TOO_LONG')),
      );
    });

    test('is trimmed', () async {
      final command = create(title: '  Bonsai night  ', closeAt: closeAt);
      await gavel.dispatch(command);

      expect((await load(command.auctionId)).title, 'Bonsai night');
    });
  });

  test('a new auction is open with no lots', () async {
    final command = create(closeAt: now.add(const Duration(hours: 1)));
    await gavel.dispatch(command);

    final auction = await load(command.auctionId);
    expect(auction.status, AuctionStatus.open);
    expect(auction.lotIds, isEmpty);
    expect(auction.code, 'ABC234');
  });

  test('AuctionCreated stores the key hash and never the key', () async {
    final command = create(closeAt: now.add(const Duration(hours: 1)));
    await gavel.dispatch(command);

    final events = await gavel.eventStore.loadStream(
      'Auction-${command.auctionId.uuid}',
    );
    expect([for (final e in events) e.eventName], ['AuctionCreated']);
    final data = (events.single as AuctionCreated).toData();
    expect(data['organizerKeyHash'], hashKey(organizerKey));
    expect(data.values, isNot(contains(organizerKey)));
  });

  test('the auction records who created it (X6)', () async {
    final command = create(
      closeAt: now.add(const Duration(hours: 1)),
      organizerUserId: 'organizer-1',
    );
    await gavel.dispatch(command);

    expect((await load(command.auctionId)).organizerUserId, 'organizer-1');
  });

  test('AuctionCreated round-trips organizerUserId', () {
    final event = AuctionCreated(
      'auction-1',
      code: 'ABC234',
      title: 'Bonsai night',
      closeAt: now,
      organizerKeyHash: 'hash',
      organizerUserId: 'organizer-1',
    );

    final restored = AuctionCreated.fromData(event.toData());

    expect(restored.organizerUserId, 'organizer-1');
  });

  test('AuctionCreated from before X6 has no creator', () {
    final data = AuctionCreated(
      'auction-1',
      code: 'ABC234',
      title: 'Bonsai night',
      closeAt: now,
      organizerKeyHash: 'hash',
    ).toData()..remove('organizerUserId');

    expect(AuctionCreated.fromData(data).organizerUserId, isNull);
  });

  test('only the organizer key matches', () async {
    final command = create(closeAt: now.add(const Duration(hours: 1)));
    await gavel.dispatch(command);

    final auction = await load(command.auctionId);
    expect(auction.isOrganizer(organizerKey), isTrue);
    expect(auction.isOrganizer('someone-else'), isFalse);
    expect(auction.isOrganizer(''), isFalse);
  });

  test('creating the same auction twice is rejected', () async {
    final id = AuctionId.generate();
    final closeAt = now.add(const Duration(hours: 1));
    await gavel.dispatch(create(id: id, closeAt: closeAt));

    await expectLater(
      gavel.dispatch(create(id: id, closeAt: closeAt)),
      throwsA(isA<AggregateAlreadyExistsError>()),
    );
  });

  test('a snapshot restores the state', () async {
    final command = create(
      closeAt: now.add(const Duration(hours: 1)),
      organizerUserId: 'organizer-1',
    );
    await gavel.dispatch(command);
    final original = await load(command.auctionId);

    final restored = Auction(command.auctionId)
      ..restoreSnapshotState(original.toSnapshot());

    expect(restored.toSnapshot(), original.toSnapshot());
  });
}
