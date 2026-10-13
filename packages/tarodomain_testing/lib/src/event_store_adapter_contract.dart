import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Tests that the adapters [create] makes follow the [EventStoreAdapter]
/// contract (spec §3, §7, §18.1).
void eventStoreAdapterContract(ContractFactory<EventStoreAdapter> create) {
  group('EventStoreAdapter contract', () {
    late EventStoreAdapter store;
    late TestEvents events;

    setUp(() async {
      store = await create();
      events = TestEvents();
    });

    group('appendToStream', () {
      test('starts a new stream at version 1', () async {
        final streamId = events.streamId();
        final appended = events.events(3);

        final result = await store.appendToStream(streamId, appended, 0);

        expect(result.streamId, streamId);
        expect(result.version, 3);
        expect(await store.getStreamVersion(streamId), 3);
        expect(await store.loadStream(streamId), appended);
      });

      test('continues from the expected version', () async {
        final streamId = events.streamId();
        await store.appendToStream(streamId, events.events(2), 0);

        final result = await store.appendToStream(
          streamId,
          events.events(1),
          2,
        );

        expect(result.version, 3);
      });

      test('throws OptimisticConcurrencyError on a stale version', () async {
        final streamId = events.streamId();
        await store.appendToStream(streamId, events.events(2), 0);

        await expectLater(
          store.appendToStream(streamId, events.events(1), 1),
          throwsA(isA<OptimisticConcurrencyError>()),
        );
        expect(await store.getStreamVersion(streamId), 2);
        expect(await store.loadStream(streamId), hasLength(2));
      });

      test('throws OptimisticConcurrencyError when creating an existing '
          'stream', () async {
        final streamId = events.streamId();
        await store.appendToStream(streamId, events.events(1), 0);

        await expectLater(
          store.appendToStream(streamId, events.events(1), 0),
          throwsA(isA<OptimisticConcurrencyError>()),
        );
      });

      test('throws OptimisticConcurrencyError when expecting a version of a '
          'missing stream', () async {
        final streamId = events.streamId();

        await expectLater(
          store.appendToStream(streamId, events.events(1), 3),
          throwsA(isA<OptimisticConcurrencyError>()),
        );
        expect(await store.streamExists(streamId), isFalse);
      });

      test('lets exactly one of two racing appends win', () async {
        final streamId = events.streamId();
        await store.appendToStream(streamId, events.events(1), 0);

        final results = await Future.wait([
          _outcome(store.appendToStream(streamId, events.events(1), 1)),
          _outcome(store.appendToStream(streamId, events.events(1), 1)),
        ]);

        expect(results.whereType<AppendResult>(), hasLength(1));
        expect(results.whereType<OptimisticConcurrencyError>(), hasLength(1));
        expect(await store.getStreamVersion(streamId), 2);
      });

      test('with no events checks the version and writes nothing', () async {
        final streamId = events.streamId();

        final result = await store.appendToStream(streamId, const [], 0);

        expect(result.version, 0);
        expect(await store.streamExists(streamId), isFalse);
        await expectLater(
          store.appendToStream(streamId, const [], 1),
          throwsA(isA<OptimisticConcurrencyError>()),
        );
      });

      test('keeps every envelope and data field', () async {
        final streamId = events.streamId();
        final event = events.event(
          type: 'FundsDeposited',
          causationId: events.nextId(),
          data: {
            'cents': 1250,
            'tags': ['a', 'b'],
            'nested': {'ok': true, 'none': null},
          },
        );

        await store.appendToStream(streamId, [event], 0);
        final [loaded] = await store.loadStream(streamId);

        expect(loaded, event);
        expect(loaded.eventType, 'FundsDeposited');
        expect(loaded.causationId, event.causationId);
        expect(loaded.metadata, {'tenant': 't1'});
        expect(loaded.occurredAt, event.occurredAt);
      });
    });

    group('loadStream', () {
      test('is empty for a missing stream', () async {
        expect(await store.loadStream(events.streamId()), isEmpty);
      });

      test('returns only events after fromVersion', () async {
        final streamId = events.streamId();
        final appended = events.events(5);
        await store.appendToStream(streamId, appended, 0);

        expect(
          idsOf(await store.loadStream(streamId, fromVersion: 3)),
          idsOf(appended.skip(3)),
        );
      });

      test('returns at most maxCount events', () async {
        final streamId = events.streamId();
        final appended = events.events(5);
        await store.appendToStream(streamId, appended, 0);

        expect(
          idsOf(await store.loadStream(streamId, fromVersion: 1, maxCount: 2)),
          idsOf(appended.skip(1).take(2)),
        );
      });

      test('returns events in version order across appends', () async {
        final streamId = events.streamId();
        final first = events.events(2);
        final second = events.events(2);
        await store.appendToStream(streamId, first, 0);
        await store.appendToStream(events.streamId(), events.events(1), 0);
        await store.appendToStream(streamId, second, 2);

        expect(
          idsOf(await store.loadStream(streamId)),
          idsOf([...first, ...second]),
        );
      });
    });

    group('loadStreamAfterEvent', () {
      test('reads one aggregate stream after the cursor', () async {
        final streamId = events.streamId();
        final appended = events.events(4);
        await store.appendToStream(streamId, appended, 0);
        await store.appendToStream(events.streamId(), events.events(2), 0);

        expect(
          idsOf(await store.loadStreamAfterEvent(streamId)),
          idsOf(appended),
        );
        expect(
          idsOf(
            await store.loadStreamAfterEvent(
              streamId,
              afterEventId: appended[1].eventId,
            ),
          ),
          idsOf(appended.skip(2)),
        );
      });

      test('reads a whole category', () async {
        final category = events.category();
        final a = events.events(2);
        final other = events.events(1);
        final b = events.events(2);
        await store.appendToStream(events.streamId(category), a, 0);
        await store.appendToStream(events.streamId(), other, 0);
        await store.appendToStream(events.streamId(category), b, 0);

        expect(
          idsOf(await store.loadStreamAfterEvent(category)),
          idsOf([...a, ...b]),
        );
        expect(
          idsOf(
            await store.loadStreamAfterEvent(
              category,
              afterEventId: a.last.eventId,
              maxCount: 1,
            ),
          ),
          [b.first.eventId],
        );
      });

      test(r'reads every stream for $all', () async {
        final a = events.events(2);
        final b = events.events(2);
        await store.appendToStream(events.streamId(), a, 0);
        await store.appendToStream(events.streamId('Other'), b, 0);

        expect(
          idsOf(await store.loadStreamAfterEvent(StreamIds.all)),
          idsOf([...a, ...b]),
        );
      });

      test('is empty for a missing stream', () async {
        expect(await store.loadStreamAfterEvent(events.streamId()), isEmpty);
      });
    });

    group('loadAll', () {
      test('pages through every event with a cursor', () async {
        final a = events.events(3);
        final b = events.events(2);
        await store.appendToStream(events.streamId(), a, 0);
        await store.appendToStream(events.streamId('Other'), b, 0);

        final pages = <List<UuidValue>>[];
        UuidValue? cursor;
        while (true) {
          final page = await store.loadAll(afterEventId: cursor, maxCount: 2);
          if (page.isEmpty) break;
          pages.add(idsOf(page));
          cursor = page.last.eventId;
        }

        expect(pages.expand((p) => p), idsOf([...a, ...b]));
        expect(pages.map((p) => p.length), [2, 2, 1]);
      });

      test('is empty after the last event', () async {
        final appended = events.events(2);
        await store.appendToStream(events.streamId(), appended, 0);

        expect(
          await store.loadAll(afterEventId: appended.last.eventId),
          isEmpty,
        );
      });

      test('returns events in append order even when IDs from one '
          'millisecond sort the other way', () async {
        final (first, second) = events.descendingIdsInOneMillisecond();
        final appended = [events.event(id: first), events.event(id: second)];
        await store.appendToStream(events.streamId(), appended, 0);

        expect(idsOf(await store.loadAll()), [first, second]);
        expect(idsOf(await store.loadAll(afterEventId: first)), [second]);
      });

      test('keeps append order across streams even when IDs from one '
          'millisecond sort the other way', () async {
        // A cause in one stream and its effect in another: the effect must
        // not come first just because its ID sorts lower.
        final correlationId = events.nextId();
        final (first, second) = events.descendingIdsInOneMillisecond();
        await store.appendToStream(events.streamId(), [
          events.event(id: first, correlationId: correlationId),
        ], 0);
        await store.appendToStream(events.streamId('Other'), [
          events.event(id: second, correlationId: correlationId),
        ], 0);

        expect(idsOf(await store.loadAll()), [first, second]);
        expect(idsOf(await store.loadAll(afterEventId: first)), [second]);
        expect(idsOf(await store.loadByCorrelationId(correlationId)), [
          first,
          second,
        ]);
      });
    });

    test('loadByCorrelationId returns the trace in order', () async {
      final correlationId = events.nextId();
      final a = events.events(2, correlationId: correlationId);
      final b = events.events(1, correlationId: correlationId);
      await store.appendToStream(events.streamId(), a, 0);
      await store.appendToStream(events.streamId(), events.events(2), 0);
      await store.appendToStream(events.streamId('Other'), b, 0);

      expect(
        idsOf(await store.loadByCorrelationId(correlationId)),
        idsOf([...a, ...b]),
      );
      expect(await store.loadByCorrelationId(events.nextId()), isEmpty);
    });

    group('stream metadata', () {
      test('describes a missing stream', () async {
        final streamId = events.streamId();

        expect(await store.streamExists(streamId), isFalse);
        expect(await store.getStreamVersion(streamId), 0);
        expect(await store.getStreamMetadata(streamId), isNull);
      });

      test('tracks creation and the last append', () async {
        final streamId = events.streamId();
        final before = DateTime.timestamp();
        await store.appendToStream(streamId, events.events(1), 0);
        final created = (await store.getStreamMetadata(streamId))!;
        await tick();
        await store.appendToStream(streamId, events.events(2), 1);

        final metadata = (await store.getStreamMetadata(streamId))!;
        expect(await store.streamExists(streamId), isTrue);
        expect(metadata.streamId, streamId);
        expect(metadata.version, 3);
        expect(metadata.createdAt, created.createdAt);
        expect(metadata.createdAt.isBefore(before), isFalse);
        expect(metadata.updatedAt.isAfter(created.updatedAt), isTrue);
        expect(metadata.createdAt.isUtc, isTrue);
      });
    });

    group('deleteStream', () {
      test('removes the stream and its events', () async {
        final streamId = events.streamId();
        final kept = events.events(1);
        await store.appendToStream(streamId, events.events(2), 0);
        await store.appendToStream(events.streamId(), kept, 0);

        await store.deleteStream(streamId);

        expect(await store.streamExists(streamId), isFalse);
        expect(await store.getStreamVersion(streamId), 0);
        expect(await store.loadStream(streamId), isEmpty);
        expect(idsOf(await store.loadAll()), idsOf(kept));
      });

      test('lets the stream start again from version 0', () async {
        final streamId = events.streamId();
        await store.appendToStream(streamId, events.events(2), 0);
        await store.deleteStream(streamId);

        final result = await store.appendToStream(
          streamId,
          events.events(1),
          0,
        );

        expect(result.version, 1);
      });

      test('does nothing for a missing stream', () async {
        await store.deleteStream(events.streamId());
      });
    });

    group('subscriptions', () {
      test('subscribe creates a cursor at the start', () async {
        final before = DateTime.timestamp();

        final subscription = await store.subscribe('projection-a');

        expect(subscription.name, 'projection-a');
        expect(subscription.streamId, isNull);
        expect(subscription.lastSeen, isNull);
        expect(subscription.createdAt.isBefore(before), isFalse);
        expect(subscription.createdAt.isUtc, isTrue);
      });

      test('subscribe returns an existing subscription unchanged', () async {
        await store.subscribe('projection-a', streamId: 'Account');
        final lastSeen = events.nextId();
        await store.ackSubscription('projection-a', lastSeen);

        final again = await store.subscribe('projection-a', streamId: 'Other');

        expect(again.streamId, 'Account');
        expect(again.lastSeen, lastSeen);
      });

      test('ack moves the cursor', () async {
        await store.subscribe('projection-a', streamId: 'Account');
        final first = events.nextId();
        final second = events.nextId();

        await store.ackSubscription('projection-a', first);
        expect((await store.getSubscription('projection-a'))!.lastSeen, first);
        await store.ackSubscription('projection-a', second);

        final subscription = (await store.getSubscription('projection-a'))!;
        expect(subscription.lastSeen, second);
        expect(subscription.streamId, 'Account');
      });

      test('ack of a missing subscription throws StateError', () async {
        await expectLater(
          store.ackSubscription('missing', events.nextId()),
          throwsStateError,
        );
      });

      test('getSubscription returns null when missing', () async {
        expect(await store.getSubscription('missing'), isNull);
      });

      test('list is ordered by name, and delete removes one', () async {
        await store.subscribe('c');
        await store.subscribe('a');
        await store.subscribe('b', streamId: 'Account');

        expect(
          [for (final s in await store.listSubscriptions()) s.name],
          ['a', 'b', 'c'],
        );

        await store.deleteSubscription('a');
        await store.deleteSubscription('missing');

        expect(
          [for (final s in await store.listSubscriptions()) s.name],
          ['b', 'c'],
        );
        expect(await store.getSubscription('a'), isNull);
      });
    });
  });
}

Future<Object> _outcome(Future<AppendResult> append) async {
  try {
    return await append;
  } on OptimisticConcurrencyError catch (e) {
    return e;
  }
}
