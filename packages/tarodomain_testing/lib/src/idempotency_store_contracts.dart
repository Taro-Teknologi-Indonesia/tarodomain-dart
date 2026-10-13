import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Tests that the stores [create] makes follow the [ProcessedEventStore]
/// contract (spec §12.3, §14.2).
void processedEventStoreContract(ContractFactory<ProcessedEventStore> create) {
  group('ProcessedEventStore contract', () {
    late ProcessedEventStore store;
    late TestEvents ids;

    setUp(() async {
      store = await create();
      ids = TestEvents();
    });

    test('records an event per handler and instance', () async {
      final event = ids.nextId();

      await store.markProcessed('Balances', 'Balances', event);

      expect(await store.exists('Balances', 'Balances', event), isTrue);
      expect(await store.exists('Balances', 'shard-1', event), isFalse);
      expect(await store.exists('Other', 'Balances', event), isFalse);
      expect(await store.exists('Balances', 'Balances', ids.nextId()), isFalse);
    });

    test('recording twice is not an error', () async {
      final event = ids.nextId();

      await store.markProcessed('Balances', 'Balances', event);
      await store.markProcessed('Balances', 'Balances', event);

      expect(await store.count('Balances'), 1);
    });

    test('count and deleteByHandler filter by instance', () async {
      for (final instance in ['saga-1', 'saga-1', 'saga-2']) {
        await store.markProcessed('Transfer', instance, ids.nextId());
      }
      await store.markProcessed('Other', 'saga-1', ids.nextId());

      expect(await store.count('Transfer'), 3);
      expect(await store.count('Transfer', handlerInstance: 'saga-1'), 2);
      expect(await store.count('Missing'), 0);

      expect(
        await store.deleteByHandler('Transfer', handlerInstance: 'saga-1'),
        2,
      );
      expect(await store.count('Transfer'), 1);
      expect(await store.deleteByHandler('Transfer'), 1);
      expect(await store.count('Transfer'), 0);
      expect(await store.count('Other'), 1);
    });

    test('deleteOld removes records written before the cutoff', () async {
      final old = ids.nextId();
      await store.markProcessed('Balances', 'Balances', old);
      await tick();
      final cutoff = DateTime.timestamp();
      await tick();
      final recent = ids.nextId();
      await store.markProcessed('Balances', 'Balances', recent);

      expect(await store.deleteOld(cutoff), 1);
      expect(await store.exists('Balances', 'Balances', old), isFalse);
      expect(await store.exists('Balances', 'Balances', recent), isTrue);
      expect(await store.deleteOld(cutoff), 0);
    });
  });
}

/// Tests that the stores [create] makes follow the [CommandIdempotencyStore]
/// contract (spec §14.1).
void commandIdempotencyStoreContract(
  ContractFactory<CommandIdempotencyStore> create,
) {
  group('CommandIdempotencyStore contract', () {
    late CommandIdempotencyStore store;
    late TestEvents ids;

    setUp(() async {
      store = await create();
      ids = TestEvents();
    });

    test('records a command', () async {
      final command = ids.nextId();
      final before = DateTime.timestamp();

      expect(await store.exists(command), isFalse);
      expect(await store.getProcessedAt(command), isNull);
      await store.markProcessed(command, 'OpenAccount', 'OpenAccountHandler');

      expect(await store.exists(command), isTrue);
      final processedAt = (await store.getProcessedAt(command))!;
      expect(processedAt.isBefore(before), isFalse);
      expect(processedAt.isUtc, isTrue);
    });

    test('recording twice keeps the first record', () async {
      final command = ids.nextId();
      await store.markProcessed(command, 'OpenAccount', 'OpenAccountHandler');
      final first = await store.getProcessedAt(command);
      await tick();

      await store.markProcessed(command, 'Other', 'OtherHandler');

      expect(await store.getProcessedAt(command), first);
      expect(await store.count(), 1);
      expect(await store.count(handlerName: 'OtherHandler'), 0);
    });

    test('list is newest first, per handler, and honours limit', () async {
      final a = ids.nextId();
      final b = ids.nextId();
      final c = ids.nextId();
      await store.markProcessed(a, 'Deposit', 'DepositHandler');
      await tick();
      await store.markProcessed(b, 'Deposit', 'DepositHandler');
      await tick();
      await store.markProcessed(ids.nextId(), 'Withdraw', 'WithdrawHandler');
      await store.markProcessed(c, 'Deposit', 'DepositHandler');

      final listed = await store.list('DepositHandler');
      expect([for (final p in listed) p.commandId], [c, b, a]);
      expect(listed.first.commandType, 'Deposit');
      expect(listed.first.handlerName, 'DepositHandler');
      expect(
        [
          for (final p in await store.list('DepositHandler', limit: 2))
            p.commandId,
        ],
        [c, b],
      );
      expect(await store.list('Missing'), isEmpty);
    });

    test('count filters by handler', () async {
      await store.markProcessed(ids.nextId(), 'Deposit', 'DepositHandler');
      await store.markProcessed(ids.nextId(), 'Deposit', 'DepositHandler');
      await store.markProcessed(ids.nextId(), 'Withdraw', 'WithdrawHandler');

      expect(await store.count(), 3);
      expect(await store.count(handlerName: 'DepositHandler'), 2);
    });

    test('deleteOld removes records written before the cutoff', () async {
      final old = ids.nextId();
      await store.markProcessed(old, 'Deposit', 'DepositHandler');
      await tick();
      final cutoff = DateTime.timestamp();
      await tick();
      final recent = ids.nextId();
      await store.markProcessed(recent, 'Deposit', 'DepositHandler');

      expect(await store.deleteOld(cutoff), 1);
      expect(await store.exists(old), isFalse);
      expect(await store.exists(recent), isTrue);
    });
  });
}
