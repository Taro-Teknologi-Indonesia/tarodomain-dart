import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late Store s;
  late SubscriptionManager manager;

  setUp(() {
    s = Store();
    manager = s.subscriptions;
  });

  test('ensureAllSubscriptions creates the missing ones', () async {
    manager
      ..register('all')
      ..register('wallets', streamId: 'Wallet');
    await s.adapter.subscribe('all');

    expect(await manager.ensureAllSubscriptions(), ['wallets']);
    expect(await manager.ensureAllSubscriptions(), isEmpty);
    expect((await manager.get('wallets'))!.streamId, 'Wallet');
    expect(
      [for (final sub in await manager.list()) sub.name],
      ['all', 'wallets'],
    );
  });

  test('registering a name for another stream is an error', () {
    manager
      ..register('p', streamId: 'Wallet')
      ..register('p', streamId: 'Wallet');

    expect(
      () => manager.register('p'),
      throwsA(isA<InvalidConfigurationError>()),
    );
  });

  test('advance moves the cursor and isCaughtUp follows it', () async {
    manager.register('p');
    final events = await s.deposit([1, 2]);
    await manager.ensure('p');

    expect(await manager.isCaughtUp('p'), isFalse);
    await manager.advance('p', events[0].id);
    expect((await manager.get('p'))!.lastSeen, events[0].id);
    expect(await manager.isCaughtUp('p'), isFalse);
    await manager.advance('p', events[1].id);
    expect(await manager.isCaughtUp('p'), isTrue);
    await manager.advance('p', events[1].id);
    expect(await manager.areAllCaughtUp(), isTrue);
  });

  test('a category subscription only counts its own streams', () async {
    manager.register('wallets', streamId: 'Wallet');
    await manager.ensureAllSubscriptions();
    await s.deposit([1], stream: 'Other-x');

    expect(await manager.isCaughtUp('wallets'), isTrue);
    await s.deposit([1], stream: 'Wallet-x');
    expect(await manager.isCaughtUp('wallets'), isFalse);
  });

  test('getLagReport counts pending events up to the limit', () async {
    manager
      ..register('a')
      ..register('b');
    await manager.ensureAllSubscriptions();
    final events = await s.deposit([1, 2, 3]);
    await manager.advance('b', events.last.id);

    final report = await manager.getLagReport(countLimit: 2);

    expect([for (final l in report.subscriptions) l.name], ['a', 'b']);
    expect(report.subscriptions[0].pending, 2);
    expect(report.subscriptions[0].isCapped, isTrue);
    expect(report.subscriptions[1].isCaughtUp, isTrue);
    expect(report.allCaughtUp, isFalse);
    expect(report.totalPending, 2);
  });

  test('reset starts the subscription from the first event', () async {
    manager.register('p', streamId: 'Wallet');
    final events = await s.deposit([1]);
    await manager.ensure('p');
    await manager.advance('p', events.single.id);

    final reset = await manager.reset('p');

    expect(reset.lastSeen, isNull);
    expect(reset.streamId, 'Wallet');
    expect(await manager.isCaughtUp('p'), isFalse);
  });

  test(
    'resetAll covers stored subscriptions that are not registered',
    () async {
      final events = await s.deposit([1]);
      await s.adapter.subscribe('legacy', streamId: 'Wallet');
      await s.adapter.ackSubscription('legacy', events.single.id);

      await manager.resetAll();

      final legacy = (await manager.get('legacy'))!;
      expect(legacy.lastSeen, isNull);
      expect(legacy.streamId, 'Wallet');
    },
  );

  test('unknown subscriptions are configuration errors', () async {
    final unknown = throwsA(isA<InvalidConfigurationError>());
    await expectLater(manager.ensure('nope'), unknown);
    await expectLater(manager.advance('nope', MoneyDeposited(1).id), unknown);
    await expectLater(manager.isCaughtUp('nope'), unknown);
    await expectLater(manager.reset('nope'), unknown);
  });
}
