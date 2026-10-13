import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Tests that the stores [create] makes follow the [DeadLetterStore]
/// contract (spec §21.1).
void deadLetterStoreContract(ContractFactory<DeadLetterStore> create) {
  group('DeadLetterStore contract', () {
    late DeadLetterStore store;
    late TestEvents events;

    setUp(() async {
      store = await create();
      events = TestEvents();
    });

    DeadLetterInput entry(
      SerializedEvent event, {
      String handler = 'Balances',
      String message = 'boom',
      int attempts = 3,
    }) => DeadLetterInput(
      handlerName: handler,
      event: event,
      errorMessage: message,
      errorCode: 'PROJECTION_HANDLER_FAILED',
      attempts: attempts,
    );

    test('writes an entry and assigns it an ID', () async {
      final event = events.event(data: {'cents': 100});
      final before = DateTime.timestamp();

      await store.write(entry(event));

      final stored = (await store.get(event.eventId, 'Balances'))!;
      expect(stored.handlerName, 'Balances');
      expect(stored.event, event);
      expect(stored.eventId, event.eventId);
      expect(stored.errorMessage, 'boom');
      expect(stored.errorCode, 'PROJECTION_HANDLER_FAILED');
      expect(stored.attempts, 3);
      expect(stored.createdAt.isBefore(before), isFalse);
      expect(stored.createdAt.isUtc, isTrue);
      expect((await store.getById(stored.id))?.eventId, event.eventId);
    });

    test('keeps a null error code', () async {
      final event = events.event();
      await store.write(
        DeadLetterInput(
          handlerName: 'Balances',
          event: event,
          errorMessage: 'StateError',
          attempts: 1,
        ),
      );

      expect((await store.get(event.eventId, 'Balances'))!.errorCode, isNull);
    });

    test('get returns the newest entry for the event and handler', () async {
      final event = events.event();
      await store.write(entry(event, message: 'first'));
      await tick();
      await store.write(entry(event, message: 'second'));
      await store.write(entry(event, handler: 'Other', message: 'other'));

      expect(
        (await store.get(event.eventId, 'Balances'))!.errorMessage,
        'second',
      );
      expect(await store.get(event.eventId, 'Missing'), isNull);
      expect(await store.get(events.nextId(), 'Balances'), isNull);
    });

    test('list is newest first, per handler, and honours limit', () async {
      for (final message in ['a', 'b', 'c']) {
        await store.write(entry(events.event(), message: message));
        await tick();
      }
      await store.write(entry(events.event(), handler: 'Other'));

      expect(
        [for (final e in await store.list('Balances')) e.errorMessage],
        ['c', 'b', 'a'],
      );
      expect(
        [
          for (final e in await store.list('Balances', limit: 2))
            e.errorMessage,
        ],
        ['c', 'b'],
      );
      expect(await store.list('Missing'), isEmpty);
    });

    test('delete removes one entry', () async {
      final event = events.event();
      await store.write(entry(event));
      await store.write(entry(events.event()));
      final stored = (await store.get(event.eventId, 'Balances'))!;

      await store.delete(stored.id);
      await store.delete(stored.id);

      expect(await store.getById(stored.id), isNull);
      expect(await store.count(), 1);
    });

    test('count filters by handler', () async {
      await store.write(entry(events.event()));
      await store.write(entry(events.event()));
      await store.write(entry(events.event(), handler: 'Other'));

      expect(await store.count(), 3);
      expect(await store.count(handlerName: 'Balances'), 2);
      expect(await store.count(handlerName: 'Missing'), 0);
    });

    test('deleteOld removes entries written before the cutoff', () async {
      final old = events.event();
      await store.write(entry(old));
      await tick();
      final cutoff = DateTime.timestamp();
      await tick();
      final recent = events.event();
      await store.write(entry(recent));

      expect(await store.deleteOld(cutoff), 1);
      expect(await store.get(old.eventId, 'Balances'), isNull);
      expect(await store.get(recent.eventId, 'Balances'), isNotNull);
    });
  });
}
