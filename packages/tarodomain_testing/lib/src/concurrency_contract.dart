import 'dart:math';

import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Tests that the event store of the providers [create] makes keeps cursor
/// reads complete while appends run concurrently, some in units of work that
/// stay open for a while.
///
/// A provider whose database has one writer, such as SQLite, runs these
/// appends one at a time, so the suite checks that nothing waits forever or
/// fails rather than that the appends overlap.
void concurrencyContract(ContractFactory<Provider> create) {
  group('concurrency contract', () {
    late Provider provider;
    late EventStoreAdapter store;
    late TestEvents events;

    setUp(() async {
      provider = await create();
      store = provider.createEventStoreAdapter();
      events = TestEvents();
    });

    UnitOfWork unitOfWork() =>
        provider.createUnitOfWork() ??
        fail('${provider.type} provider has no unit of work');

    test('a cursor reader sees every event exactly once while appenders '
        'hold their units of work open', () async {
      final random = Random(7);
      final appended = <UuidValue>[];
      var appending = true;
      final appenders = Future.wait([
        for (var i = 0; i < 12; i++)
          () async {
            await Future<void>.delayed(
              Duration(milliseconds: random.nextInt(60)),
            );
            final batch = events.events(1 + i % 3);
            appended.addAll(idsOf(batch));
            final streamId = events.streamId();
            if (i.isEven) {
              await unitOfWork().execute(() async {
                await store.appendToStream(streamId, batch, 0);
                await Future<void>.delayed(
                  Duration(milliseconds: random.nextInt(120)),
                );
              });
            } else {
              await store.appendToStream(streamId, batch, 0);
            }
          }(),
      ]).whenComplete(() => appending = false);

      final seen = <UuidValue>[];
      UuidValue? cursor;
      Future<int> read() async {
        final page = await store.loadAll(afterEventId: cursor, maxCount: 4);
        seen.addAll(idsOf(page));
        if (page.isNotEmpty) cursor = page.last.eventId;
        return page.length;
      }

      while (appending) {
        await read();
        await Future<void>.delayed(const Duration(milliseconds: 3));
      }
      await appenders;
      while (await read() > 0) {}

      expect(seen.toSet(), hasLength(seen.length), reason: 'duplicates');
      expect(seen.toSet(), appended.toSet());
    });

    test('concurrent readers racing appenders never fail and together '
        'see every event', () async {
      final appended = <UuidValue>[];
      var appending = true;
      final appenders = Future.wait([
        for (var i = 0; i < 8; i++)
          () async {
            for (var j = 0; j < 5; j++) {
              final batch = events.events(2);
              appended.addAll(idsOf(batch));
              await store.appendToStream(events.streamId(), batch, 0);
            }
          }(),
      ]).whenComplete(() => appending = false);

      // On a provider that orders events after commit, every read may do
      // work of its own, so these compete with each other and the appends.
      final readers = Future.wait([
        for (var i = 0; i < 16; i++)
          () async {
            while (appending) {
              await store.loadAll(maxCount: 1);
            }
          }(),
      ]);
      await appenders;
      await readers;

      expect(idsOf(await store.loadAll()).toSet(), appended.toSet());
    });
  });
}
