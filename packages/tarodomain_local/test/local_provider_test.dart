import 'dart:async';

import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';
import 'package:tarodomain_testing/tarodomain_testing.dart';
import 'package:test/test.dart';

void main() {
  late TestEvents events;

  setUp(() => events = TestEvents());

  test('type is local, and every adapter shares one database', () async {
    final provider = LocalProvider();
    final streamId = events.streamId();

    await provider.createEventStoreAdapter().appendToStream(
      streamId,
      events.events(1),
      0,
    );

    expect(provider.type, 'local');
    expect(
      await provider.createEventStoreAdapter().streamExists(streamId),
      isTrue,
    );
  });

  test('timestamps come from the injected clock, in UTC', () async {
    var now = DateTime(2026, 1, 1, 12);
    final provider = LocalProvider(database: LocalDatabase(clock: () => now));
    final commands = provider.createCommandIdempotencyStore();
    final old = events.nextId();
    final recent = events.nextId();

    await commands.markProcessed(old, 'Deposit', 'DepositHandler');
    now = now.add(const Duration(days: 8));
    await commands.markProcessed(recent, 'Deposit', 'DepositHandler');

    expect(
      await commands.getProcessedAt(old),
      DateTime(2026, 1, 1, 12).toUtc(),
    );
    expect(await commands.deleteOld(now.subtract(const Duration(days: 7))), 1);
    expect(await commands.exists(recent), isTrue);
  });

  test('concurrent units of work run one at a time', () async {
    final provider = LocalProvider();
    final unitOfWork = provider.createUnitOfWork();
    final store = provider.createEventStoreAdapter();
    final committed = events.streamId();
    final rolledBack = events.streamId();
    final firstStarted = Completer<void>();
    final release = Completer<void>();

    final first = unitOfWork.execute(() async {
      await store.appendToStream(rolledBack, events.events(1), 0);
      firstStarted.complete();
      await release.future;
      throw StateError('rollback');
    });
    await firstStarted.future;
    final second = unitOfWork.execute(
      () => store.appendToStream(committed, events.events(1), 0),
    );
    release.complete();

    await expectLater(first, throwsStateError);
    await second;
    expect(await store.streamExists(committed), isTrue);
    expect(await store.streamExists(rolledBack), isFalse);
  });

  test('createEventBus returns a new in-memory bus per call', () {
    final provider = LocalProvider();
    const strong = EventBusConfig(consistency: ConsistencyMode.strong);
    final bus = provider.createEventBus(strong);

    expect(bus, isA<InMemoryEventBus>());
    expect(bus.name, 'local-strong');
    expect(provider.createEventBus(strong), isNot(same(bus)));
    expect(
      provider
          .createEventBus(
            const EventBusConfig(consistency: ConsistencyMode.eventual),
          )
          .name,
      'local-eventual',
    );
  });
}
