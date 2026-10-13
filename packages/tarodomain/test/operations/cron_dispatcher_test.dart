import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late Store s;
  late RecordingHandler handler;

  CronDispatcher dispatcher({
    int batchSize = 100,
    UnitOfWork? unitOfWork,
    int? maxAttempts,
  }) => CronDispatcher(
    eventStore: s.eventStore,
    subscriptions: s.subscriptions,
    batchSize: batchSize,
    unitOfWork: unitOfWork,
    deadLetters: s.deadLetters,
    maxAttempts: maxAttempts,
  )..register(handler);

  setUp(() {
    s = Store();
    handler = RecordingHandler('p');
  });

  test('hands events to the handler in order and moves the cursor', () async {
    final events = await s.deposit([1, 2, 3]);
    final cron = dispatcher();

    final result = await cron.catchUp('p');

    expect(handler.cents, [1, 2, 3]);
    expect(result.processed, 3);
    expect(result.hasMore, isFalse);
    expect(result.stopped, isFalse);
    expect((await s.subscriptions.get('p'))!.lastSeen, events.last.id);

    await s.deposit([4]);
    await cron.catchUp('p');
    expect(handler.cents, [1, 2, 3, 4]);
  });

  test('pages through batches with hasMore', () async {
    await s.deposit([1, 2, 3, 4, 5]);
    final cron = dispatcher(batchSize: 2);

    final first = await cron.catchUp('p');
    expect((first.processed, first.hasMore), (2, true));
    final second = await cron.catchUp('p');
    expect((second.processed, second.hasMore), (2, true));
    final last = await cron.catchUp('p');
    expect((last.processed, last.hasMore), (1, false));
    expect(handler.cents, [1, 2, 3, 4, 5]);
  });

  test('a full batch with nothing after it has no more', () async {
    await s.deposit([1, 2]);

    final result = await dispatcher(batchSize: 2).catchUp('p');

    expect(result.hasMore, isFalse);
  });

  test('follows only the registered stream', () async {
    await s.deposit([1], stream: 'Wallet-a');
    await s.deposit([2], stream: 'Other-b');
    final cron = CronDispatcher(
      eventStore: s.eventStore,
      subscriptions: s.subscriptions,
    )..register(handler, streamId: 'Wallet');

    await cron.catchUp('p');

    expect(handler.cents, [1]);
  });

  test('a retryable error stops the pass and keeps the cursor', () async {
    final events = await s.deposit([1, 2, 3]);
    handler.failOn = (e) => e.id == events[1].id ? retryableError() : null;
    final cron = dispatcher();

    final result = await cron.catchUp('p');

    expect(result.processed, 1);
    expect(result.stopped, isTrue);
    expect(result.hasMore, isTrue);
    expect(result.error, isA<EventStoreError>());
    expect(result.failedEventId, events[1].id);
    expect((await s.subscriptions.get('p'))!.lastSeen, events[0].id);
    expect(await s.deadLetters.count(), 0);

    handler.failOn = null;
    final retry = await cron.catchUp('p');
    expect(retry.processed, 2);
    expect(handler.cents, [1, 2, 3]);
  });

  group('maxAttempts', () {
    test('without it, a retryable error is retried forever and not '
        'counted', () async {
      final events = await s.deposit([1, 2]);
      handler.failOn = (e) => e.id == events[1].id ? retryableError() : null;
      final cron = dispatcher();

      for (var i = 0; i < 5; i++) {
        expect((await cron.catchUp('p')).stopped, isTrue);
      }

      expect((await s.subscriptions.get('p'))!.failedAttempts, 0);
      expect(await s.deadLetters.count(), 0);
    });

    test('counts each failed run and dead-letters the event at the '
        'limit', () async {
      final events = await s.deposit([1, 2, 3]);
      handler.failOn = (e) => e.id == events[1].id ? retryableError() : null;
      final cron = dispatcher(maxAttempts: 3);

      for (final attempt in [1, 2]) {
        final result = await cron.catchUp('p');
        expect(result.stopped, isTrue);
        expect(result.failedEventId, events[1].id);
        final subscription = (await s.subscriptions.get('p'))!;
        expect(subscription.failedEventId, events[1].id);
        expect(subscription.failedAttempts, attempt);
        expect(subscription.lastSeen, events[0].id);
      }
      final lag = (await s.subscriptions.getLagReport()).subscriptions.single;
      expect(lag.failedAttempts, 2);

      final last = await cron.catchUp('p');

      expect(last.stopped, isFalse);
      expect(last.skipped.single.event.eventId, events[1].id);
      expect(last.skipped.single.error, isA<EventStoreError>());
      expect(handler.cents, [1, 3]);
      final dead = (await s.deadLetters.get(events[1].id, 'p'))!;
      expect(dead.attempts, 3);
      final subscription = (await s.subscriptions.get('p'))!;
      expect(subscription.lastSeen, events[2].id);
      expect(subscription.failedAttempts, 0);
      expect(subscription.failedEventId, isNull);
    });

    test('a success clears the count, so the next stuck event starts '
        'from 1', () async {
      final events = await s.deposit([1, 2, 3]);
      final failing = {events[1].id, events[2].id};
      handler.failOn = (e) => failing.contains(e.id) ? retryableError() : null;
      final cron = dispatcher(maxAttempts: 3);

      await cron.catchUp('p');
      await cron.catchUp('p');
      failing.remove(events[1].id);
      final result = await cron.catchUp('p');

      expect(result.failedEventId, events[2].id);
      final subscription = (await s.subscriptions.get('p'))!;
      expect(subscription.failedEventId, events[2].id);
      expect(subscription.failedAttempts, 1);
      expect(await s.deadLetters.count(), 0);
    });

    test('stopOnError neither counts nor skips', () async {
      final events = await s.deposit([1, 2]);
      handler.failOn = (e) => e.id == events[1].id ? retryableError() : null;
      final cron = dispatcher(maxAttempts: 1);

      final result = await cron.catchUp('p', stopOnError: true);

      expect(result.stopped, isTrue);
      expect((await s.subscriptions.get('p'))!.failedAttempts, 0);
      expect(await s.deadLetters.count(), 0);
    });

    test('a non-retryable error is still skipped at once', () async {
      final events = await s.deposit([1, 2]);
      handler.failOn = (e) => e.id == events[0].id ? domainError() : null;

      final result = await dispatcher(maxAttempts: 3).catchUp('p');

      expect(result.skipped.single.event.eventId, events[0].id);
      expect((await s.deadLetters.get(events[0].id, 'p'))!.attempts, 1);
      expect(handler.cents, [2]);
    });
  });

  test('a non-retryable error dead-letters the event and moves on', () async {
    final events = await s.deposit([1, 2, 3]);
    handler.failOn = (e) => e.id == events[1].id ? domainError() : null;

    final result = await dispatcher().catchUp('p');

    expect(handler.cents, [1, 3]);
    expect(result.processed, 2);
    expect(result.skipped.single.event.eventId, events[1].id);
    expect(result.advanced, 3);
    expect(result.stopped, isFalse);
    final dead = (await s.deadLetters.get(events[1].id, 'p'))!;
    expect(dead.errorCode, 'INVALID_AGGREGATE_STATE');
    expect(dead.attempts, 1);
    expect(await s.subscriptions.isCaughtUp('p'), isTrue);
  });

  test('an event that cannot be deserialized is dead-lettered', () async {
    await s.deposit([1]);
    final unknown = s.unknownEvent();
    await s.appendRaw('Wallet-a', [unknown]);
    await s.deposit([2]);

    final result = await dispatcher().catchUp('p');

    expect(handler.cents, [1, 2]);
    expect(result.skipped.single.error, isA<UnknownEventTypeError>());
    expect(await s.deadLetters.get(unknown.eventId, 'p'), isNotNull);
  });

  test('stopOnError stops at a non-retryable error too', () async {
    final events = await s.deposit([1, 2]);
    handler.failOn = (e) => e.id == events[0].id ? domainError() : null;

    final result = await dispatcher().catchUp('p', stopOnError: true);

    expect(result.stopped, isTrue);
    expect(result.processed, 0);
    expect(await s.deadLetters.count(), 0);
    expect((await s.subscriptions.get('p'))!.lastSeen, isNull);
  });

  test('runs each event in the unit of work', () async {
    await s.deposit([1]);
    final unitOfWork = s.provider.createUnitOfWork();
    final active = <bool>[];
    handler.onHandle = () => active.add(unitOfWork.isActive);

    await dispatcher(unitOfWork: unitOfWork).catchUp('p');

    expect(active, [isTrue]);
  });

  test('runAll catches up every handler and isolates failures', () async {
    await s.deposit([1, 2]);
    final broken = RecordingHandler('broken')..failOn = (_) => retryableError();
    final cron = dispatcher()..register(broken);

    final results = await cron.runAll();

    expect([for (final r in results) r.subscription], ['p', 'broken']);
    expect(results[0].processed, 2);
    expect(results[1].stopped, isTrue);
    expect(handler.cents, [1, 2]);
  });

  test('registration errors', () {
    final cron = dispatcher();
    cron.register(handler);

    expect(
      () => cron.register(RecordingHandler('p')),
      throwsA(isA<InvalidConfigurationError>()),
    );
    expect(cron.catchUp('nope'), throwsA(isA<InvalidConfigurationError>()));
    expect(
      () => CronDispatcher(
        eventStore: s.eventStore,
        subscriptions: s.subscriptions,
        batchSize: 0,
      ),
      throwsA(isA<InvalidConfigurationError>()),
    );
    expect(
      () => CronDispatcher(
        eventStore: s.eventStore,
        subscriptions: s.subscriptions,
        maxAttempts: 0,
      ),
      throwsA(isA<InvalidConfigurationError>()),
    );
  });
}
