import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late InMemoryEventBus bus;
  late RecordingProjection first;
  late RecordingProjection second;
  final opened = AccountOpened(owner: 'ann');
  final deposited = FundsDeposited(cents: 5);

  setUp(() {
    bus = InMemoryEventBus(name: 'test');
    first = RecordingProjection('first');
    second = RecordingProjection('second');
  });

  test('delivers each event to every handler in subscription order', () async {
    final order = <String>[];
    bus
      ..subscribe(_Callback('a', (e) => order.add('a:${e.eventName}')))
      ..subscribe(_Callback('b', (e) => order.add('b:${e.eventName}')));

    await bus.publishAll([opened, deposited]);

    expect(order, [
      'a:AccountOpened',
      'b:AccountOpened',
      'a:FundsDeposited',
      'b:FundsDeposited',
    ]);
  });

  test('publish delivers one event', () async {
    bus.subscribe(first);
    await bus.publish(opened);
    expect(first.seen, [opened]);
  });

  test('subscribing the same handler twice is a no-op', () async {
    bus
      ..subscribe(first)
      ..subscribe(first);
    await bus.publish(opened);
    expect(first.seen, hasLength(1));
    expect(bus.handlers, [first]);
  });

  test('a different handler with a taken name is rejected', () {
    bus.subscribe(first);
    expect(
      () => bus.subscribe(RecordingProjection('first')),
      throwsA(isA<InvalidConfigurationError>()),
    );
  });

  test('unsubscribe stops delivery', () async {
    bus
      ..subscribe(first)
      ..unsubscribe(first)
      ..unsubscribe(second);
    await bus.publish(opened);
    expect(first.seen, isEmpty);
    expect(bus.handlers, isEmpty);
  });

  group('publishAll', () {
    test('stops at the first failure and wraps it', () async {
      final boom = StateError('boom');
      first.failWith = boom;
      bus
        ..subscribe(first)
        ..subscribe(second);

      await expectLater(
        bus.publishAll([opened, deposited]),
        throwsA(
          isA<EventHandlerFailedError>()
              .having((e) => e.cause, 'cause', boom)
              .having((e) => e.context['handler'], 'handler', 'first')
              .having((e) => e.context['eventId'], 'eventId', opened.id.uuid),
        ),
      );
      expect(first.seen, [opened]);
      expect(second.seen, isEmpty);
    });

    test('rethrows framework errors unchanged', () async {
      first.failWith = OptimisticConcurrencyError('conflict');
      bus.subscribe(first);
      await expectLater(
        bus.publish(opened),
        throwsA(isA<OptimisticConcurrencyError>()),
      );
    });
  });

  test('publishAllWithResults delivers everything and reports each', () async {
    final boom = StateError('boom');
    first.failWith = boom;
    bus
      ..subscribe(first)
      ..subscribe(second);

    final results = await bus.publishAllWithResults([opened, deposited]);

    expect(results.map((r) => (r.event, r.handlerName, r.succeeded)).toList(), [
      (opened, 'first', false),
      (opened, 'second', true),
      (deposited, 'first', false),
      (deposited, 'second', true),
    ]);
    expect(results.first.error, boom);
    expect(second.seen, [opened, deposited]);
  });
}

class _Callback implements EventHandler {
  _Callback(this.name, this.callback);

  @override
  final String name;
  final void Function(DomainEvent) callback;

  @override
  Future<void> handle(DomainEvent event) async => callback(event);
}
