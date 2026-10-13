import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late Store s;
  late RecordingHandler a;
  late RecordingHandler b;
  late CronDispatcher cron;
  late DateTime now;
  late List<Duration> sleeps;

  BackpressureController controller({
    Duration maxDuration = const Duration(seconds: 25),
    int maxEventsPerRun = 10000,
    int maxPassesPerSubscription = 100,
    Duration throttle = Duration.zero,
    void Function(BackpressureProgress)? onProgress,
  }) => BackpressureController(
    cron,
    maxDuration: maxDuration,
    maxEventsPerRun: maxEventsPerRun,
    maxPassesPerSubscription: maxPassesPerSubscription,
    throttle: throttle,
    onProgress: onProgress,
    clock: () => now,
    sleep: (d) async => sleeps.add(d),
  );

  setUp(() async {
    s = Store();
    a = RecordingHandler('a');
    b = RecordingHandler('b');
    cron =
        CronDispatcher(
            eventStore: s.eventStore,
            subscriptions: s.subscriptions,
            batchSize: 2,
          )
          ..register(a)
          ..register(b);
    now = DateTime.utc(2026, 10, 12);
    sleeps = [];
    await s.deposit([1, 2, 3, 4, 5]);
  });

  test('catches up every subscription, one batch each in turn', () async {
    final order = <String>[];

    final report = await controller(
      onProgress: (p) => order.add(p.batch.subscription),
    ).run();

    expect(report.reason, BackpressureStopReason.completed);
    expect(order, ['a', 'b', 'a', 'b', 'a', 'b']);
    expect(a.cents, [1, 2, 3, 4, 5]);
    expect(b.cents, [1, 2, 3, 4, 5]);
    expect(report.eventsProcessed, 10);
    expect(report.hasMore, isFalse);
    expect([for (final r in report.subscriptions) r.passes], [3, 3]);
  });

  test('stops at the event budget', () async {
    final report = await controller(maxEventsPerRun: 3).run();

    expect(report.reason, BackpressureStopReason.eventBudget);
    expect(report.eventsProcessed, 3);
    expect(a.cents, [1, 2]);
    expect(b.cents, [1]);
    expect(report.hasMore, isTrue);
  });

  test('stops at the time budget', () async {
    final report = await controller(
      maxDuration: const Duration(seconds: 10),
      onProgress: (_) => now = now.add(const Duration(seconds: 4)),
    ).run();

    expect(report.reason, BackpressureStopReason.timeBudget);
    expect(report.eventsProcessed, 6);
    expect(report.elapsed, const Duration(seconds: 12));
    expect(report.eventsPerSecond, 0.5);
  });

  test('limits the passes per subscription', () async {
    final report = await controller(maxPassesPerSubscription: 1).run();

    expect(report.reason, BackpressureStopReason.completed);
    expect(report.eventsProcessed, 4);
    expect(report.subscriptions.every((r) => r.hasMore), isTrue);
  });

  test('drops a subscription that stops at an error', () async {
    b.failOn = (_) => retryableError();

    final report = await controller().run();

    expect(a.cents, [1, 2, 3, 4, 5]);
    final runB = report.subscriptions.last;
    expect(runB.passes, 1);
    expect(runB.error, isA<EventStoreError>());
    expect(runB.hasMore, isTrue);
  });

  test('throttles between batches', () async {
    await controller(throttle: const Duration(milliseconds: 50)).run();

    expect(sleeps, hasLength(5));
    expect(sleeps.toSet(), {const Duration(milliseconds: 50)});
  });

  test('runs only the named subscriptions', () async {
    final report = await controller().run(only: ['b']);

    expect(a.handled, isEmpty);
    expect(b.cents, [1, 2, 3, 4, 5]);
    expect([for (final r in report.subscriptions) r.subscription], ['b']);
  });

  test('rejects invalid limits', () {
    expect(
      () => controller(maxEventsPerRun: 0),
      throwsA(isA<InvalidConfigurationError>()),
    );
    expect(
      () => controller(maxDuration: Duration.zero),
      throwsA(isA<InvalidConfigurationError>()),
    );
  });
}
