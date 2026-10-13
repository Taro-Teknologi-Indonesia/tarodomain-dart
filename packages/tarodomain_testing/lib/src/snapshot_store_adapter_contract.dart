import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Tests that the adapters [create] makes follow the [SnapshotStoreAdapter]
/// contract (spec §8).
void snapshotStoreAdapterContract(
  ContractFactory<SnapshotStoreAdapter> create,
) {
  group('SnapshotStoreAdapter contract', () {
    late SnapshotStoreAdapter store;
    late TestEvents ids;
    late UuidValue account;

    setUp(() async {
      store = await create();
      ids = TestEvents();
      account = ids.nextId();
    });

    SnapshotInput snapshot(
      int version, {
      UuidValue? uuid,
      String type = 'BankAccount',
      Map<String, Object?> data = const {},
    }) => SnapshotInput(
      sourceUuid: uuid ?? account,
      sourceType: type,
      sourceVersion: version,
      data: {'version': version, ...data},
      metadata: {'reason': 'test'},
    );

    List<int> versions(List<Snapshot> snapshots) => [
      for (final s in snapshots) s.sourceVersion,
    ];

    test('saves and loads every field', () async {
      final before = DateTime.timestamp();
      await store.save(
        snapshot(
          5,
          data: {
            'balance': 1250,
            'owners': ['ann', 'bob'],
            'limits': {'daily': 100, 'note': null},
          },
        ),
      );

      final loaded = (await store.loadAtVersion(account, 'BankAccount', 5))!;
      expect(loaded.sourceUuid, account);
      expect(loaded.sourceType, 'BankAccount');
      expect(loaded.sourceVersion, 5);
      expect(loaded.data, {
        'version': 5,
        'balance': 1250,
        'owners': ['ann', 'bob'],
        'limits': {'daily': 100, 'note': null},
      });
      expect(loaded.metadata, {'reason': 'test'});
      expect(loaded.createdAt.isBefore(before), isFalse);
      expect(loaded.createdAt.isUtc, isTrue);
    });

    test('loadLatest returns the highest version', () async {
      await store.save(snapshot(10));
      await store.save(snapshot(30));
      await store.save(snapshot(20));

      expect(
        (await store.loadLatest(account, 'BankAccount'))!.sourceVersion,
        30,
      );
    });

    test('loads nothing for an unknown aggregate, type or version', () async {
      await store.save(snapshot(10));

      expect(await store.loadLatest(ids.nextId(), 'BankAccount'), isNull);
      expect(await store.loadLatest(account, 'Other'), isNull);
      expect(await store.loadAtVersion(account, 'BankAccount', 11), isNull);
      expect(await store.loadAtVersion(account, 'Other', 10), isNull);
    });

    test('save replaces the snapshot at the same version', () async {
      await store.save(snapshot(10, data: {'balance': 1}));
      await store.save(snapshot(10, data: {'balance': 2}));

      expect(await store.count(account, 'BankAccount'), 1);
      expect((await store.loadAtVersion(account, 'BankAccount', 10))!.data, {
        'version': 10,
        'balance': 2,
      });
    });

    test('list is newest first and honours limit', () async {
      for (final v in [10, 30, 20]) {
        await store.save(snapshot(v));
      }
      await store.save(snapshot(40, uuid: ids.nextId()));

      expect(versions(await store.list(account, 'BankAccount')), [30, 20, 10]);
      expect(versions(await store.list(account, 'BankAccount', limit: 2)), [
        30,
        20,
      ]);
      expect(await store.list(ids.nextId(), 'BankAccount'), isEmpty);
    });

    test('deleteBefore removes older versions and counts them', () async {
      final other = ids.nextId();
      for (final v in [10, 20, 30]) {
        await store.save(snapshot(v));
      }
      await store.save(snapshot(10, uuid: other));

      expect(await store.deleteBefore(account, 'BankAccount', 30), 2);
      expect(versions(await store.list(account, 'BankAccount')), [30]);
      expect(await store.count(other, 'BankAccount'), 1);
      expect(await store.deleteBefore(account, 'BankAccount', 30), 0);
    });

    test('deleteAll removes one aggregate only', () async {
      final other = ids.nextId();
      await store.save(snapshot(10));
      await store.save(snapshot(20));
      await store.save(snapshot(10, uuid: other));

      await store.deleteAll(account, 'BankAccount');

      expect(await store.count(account, 'BankAccount'), 0);
      expect(await store.loadLatest(account, 'BankAccount'), isNull);
      expect(await store.count(other, 'BankAccount'), 1);
      await store.deleteAll(ids.nextId(), 'BankAccount');
    });

    test('count is per aggregate', () async {
      expect(await store.count(account, 'BankAccount'), 0);
      await store.save(snapshot(10));
      await store.save(snapshot(20));

      expect(await store.count(account, 'BankAccount'), 2);
    });
  });
}
