import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

class FailingAdapter extends FakeEventStoreAdapter {
  @override
  Future<AppendResult> appendToStream(
    String streamId,
    List<SerializedEvent> events,
    int expectedVersion,
  ) => throw Exception('disk full');

  @override
  Future<List<SerializedEvent>> loadStream(
    String streamId, {
    int fromVersion = 0,
    int? maxCount,
  }) => throw Exception('offline');
}

void main() {
  group('EventStore', () {
    late FakeEventStoreAdapter adapter;
    late EventStore store;

    setUp(() {
      adapter = FakeEventStoreAdapter();
      store = EventStore(adapter, accountRegistry());
    });

    test('serializes on append and deserializes on load', () async {
      final events = [AccountOpened(owner: 'ann'), FundsDeposited(cents: 4)];
      final result = await store.appendToStream('BankAccount-1', events, 0);
      expect(result.version, 2);
      expect(adapter.streams['BankAccount-1'], [
        for (final e in events) e.serialize(),
      ]);

      final loaded = await store.loadStream('BankAccount-1');
      expect(loaded.map((e) => e.id), events.map((e) => e.id));
      expect((loaded[1] as FundsDeposited).cents, 4);
    });

    test('upcasts old events on load', () async {
      final old = FundsDeposited(
        cents: 0,
      ).serialize().withData('1.0.0', {'amount': 12});
      adapter.streams['BankAccount-1'] = [old];
      final loaded = await store.loadStream('BankAccount-1');
      expect((loaded.single as FundsDeposited).cents, 12);
    });

    test('rejects unregistered events before writing', () async {
      await expectLater(
        store.appendToStream('BankAccount-1', [UnrelatedHappened()], 0),
        throwsA(isA<UnknownEventTypeError>()),
      );
      expect(adapter.appendCalls, 0);
    });

    test('rejects an event whose version is not the registered one', () async {
      final registry = EventRegistry()
        ..register('FundsDeposited', FundsDeposited.fromData);
      await expectLater(
        EventStore(
          adapter,
          registry,
        ).appendToStream('BankAccount-1', [FundsDeposited(cents: 1)], 0),
        throwsA(isA<EventVersionMismatchError>()),
      );
      expect(adapter.appendCalls, 0);
    });

    test('passes optimistic concurrency errors through', () async {
      await expectLater(
        store.appendToStream('BankAccount-1', [AccountOpened(owner: 'a')], 3),
        throwsA(isA<OptimisticConcurrencyError>()),
      );
    });

    test('wraps other adapter failures', () async {
      final store = EventStore(FailingAdapter(), accountRegistry());
      await expectLater(
        store.appendToStream('S-1', [AccountOpened(owner: 'a')], 0),
        throwsA(
          isA<EventAppendFailedError>()
              .having((e) => e.retryable, 'retryable', isTrue)
              .having((e) => e.context['streamId'], 'streamId', 'S-1'),
        ),
      );
      await expectLater(
        store.loadStream('S-1'),
        throwsA(isA<EventLoadFailedError>()),
      );
    });
  });

  group('StreamIds', () {
    test('builds aggregate streams and reads their category', () {
      final id = AccountId.generate();
      final streamId = StreamIds.forAggregate('BankAccount', id);
      expect(streamId, 'BankAccount-${id.uuid}');
      expect(StreamIds.categoryOf(streamId), 'BankAccount');
      expect(StreamIds.all, r'$all');
    });
  });
}
