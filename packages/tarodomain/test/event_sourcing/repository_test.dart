import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late FakeEventStoreAdapter adapter;
  late RecordingEventBus bus;
  late FakeSnapshotStore snapshots;
  late List<Object> snapshotErrors;

  setUp(() {
    adapter = FakeEventStoreAdapter();
    bus = RecordingEventBus();
    snapshots = FakeSnapshotStore();
    snapshotErrors = [];
  });

  EventSourcedRepository<A, AccountId> repository<A extends BankAccount>(
    A Function(AccountId) factory, {
    int snapshotEvery = 0,
  }) => EventSourcedRepository(
    eventStore: EventStore(adapter, accountRegistry()),
    eventBus: bus,
    factory: factory,
    aggregateType: 'BankAccount',
    snapshotStore: snapshotEvery > 0 ? snapshots : null,
    snapshotEvery: snapshotEvery,
    onSnapshotError: (error, _) => snapshotErrors.add(error),
  );

  group('EventSourcedRepository', () {
    final id = AccountId.generate();
    late EventSourcedRepository<BankAccount, AccountId> repo;

    setUp(() => repo = repository(BankAccount.new));

    test('save appends, publishes and marks committed', () async {
      final account = BankAccount.open(id, 'ann')..deposit(5);
      final changes = account.getUncommittedChanges();
      await repo.save(account);

      expect(adapter.streams['BankAccount-${id.uuid}'], hasLength(2));
      expect(bus.published, changes);
      expect(account.hasUncommittedChanges, isFalse);
      expect(account.committedVersion, 2);
    });

    test('save without changes does nothing', () async {
      await repo.save(BankAccount(id));
      expect(adapter.appendCalls, 0);
      expect(bus.published, isEmpty);
    });

    test('load replays the stream', () async {
      await repo.save(BankAccount.open(id, 'ann')..deposit(5));
      final loaded = await repo.load(id);
      expect(loaded.owner, 'ann');
      expect(loaded.balance, 5);
      expect(loaded.version, 2);
      expect(loaded.hasUncommittedChanges, isFalse);
    });

    test('load and save round-trip across several saves', () async {
      await repo.save(BankAccount.open(id, 'ann'));
      final loaded = await repo.load(id);
      await repo.save(loaded..deposit(3));
      expect((await repo.load(id)).balance, 3);
      expect((await repo.load(id)).version, 2);
    });

    test('load throws AggregateNotFoundError for a missing aggregate', () {
      expect(repo.load(id), throwsA(isA<AggregateNotFoundError>()));
    });

    test('exists reflects the stream', () async {
      expect(await repo.exists(id), isFalse);
      await repo.save(BankAccount.open(id, 'ann'));
      expect(await repo.exists(id), isTrue);
    });

    test('a stale aggregate fails with OptimisticConcurrencyError', () async {
      await repo.save(BankAccount.open(id, 'ann'));
      final first = await repo.load(id);
      final second = await repo.load(id);
      await repo.save(first..deposit(1));

      await expectLater(
        repo.save(second..deposit(2)),
        throwsA(isA<OptimisticConcurrencyError>()),
      );
      expect(second.hasUncommittedChanges, isTrue);
      expect(bus.published, hasLength(2));
    });

    test('a failed publish leaves the changes uncommitted', () async {
      bus.failWith = EventPublishFailedError('down');
      final account = BankAccount.open(id, 'ann');
      await expectLater(
        repo.save(account),
        throwsA(isA<EventPublishFailedError>()),
      );
      expect(account.hasUncommittedChanges, isTrue);
    });

    test('rejects an aggregate type containing "-"', () {
      expect(
        () => EventSourcedRepository<BankAccount, AccountId>(
          eventStore: EventStore(adapter, accountRegistry()),
          eventBus: bus,
          factory: BankAccount.new,
          aggregateType: 'Bank-Account',
        ),
        throwsA(isA<InvalidConfigurationError>()),
      );
    });
  });

  group('EventSourcedRepository snapshots', () {
    final id = AccountId.generate();

    test('saves a snapshot when the version crosses snapshotEvery', () async {
      final repo = repository(BankAccount.new, snapshotEvery: 3);
      final account = BankAccount.open(id, 'ann')..deposit(1);
      await repo.save(account); // version 2: no snapshot
      expect(snapshots.saved, isEmpty);

      await repo.save(
        account
          ..deposit(2)
          ..deposit(3),
      ); // version 4: crosses 3
      final snapshot = snapshots.saved.single;
      expect(snapshot.sourceUuid, id.value);
      expect(snapshot.sourceType, 'BankAccount');
      expect(snapshot.sourceVersion, 4);
      expect(snapshot.data, {'owner': 'ann', 'balance': 6});
    });

    test('loads from the snapshot plus later events', () async {
      final repo = repository(BankAccount.new, snapshotEvery: 2);
      final account = BankAccount.open(id, 'ann')..deposit(1);
      await repo.save(account); // snapshot at 2
      await repo.save(account..deposit(10)); // version 3

      final loaded = await repo.load(id);
      expect(adapter.lastLoadFromVersion, 2);
      expect(loaded.balance, 11);
      expect(loaded.version, 3);
    });

    test('falls back to full replay when the snapshot load fails', () async {
      final repo = repository(BankAccount.new, snapshotEvery: 1);
      await repo.save(BankAccount.open(id, 'ann')..deposit(4));
      snapshots.failWith = SnapshotLoadFailedError('corrupt');

      final loaded = await repo.load(id);
      expect(adapter.lastLoadFromVersion, 0);
      expect(loaded.balance, 4);
      expect(snapshotErrors.single, isA<SnapshotLoadFailedError>());
    });

    test('falls back to full replay when the snapshot data is bad', () async {
      final repo = repository(BankAccount.new, snapshotEvery: 1);
      await repo.save(BankAccount.open(id, 'ann')..deposit(4));
      snapshots.saved.add(
        SnapshotInput(
          sourceUuid: id.value,
          sourceType: 'BankAccount',
          sourceVersion: 9,
          data: {'balance': 'not a number'},
        ),
      );

      final loaded = await repo.load(id);
      expect(loaded.balance, 4);
      expect(loaded.version, 2);
      expect(snapshotErrors, hasLength(1));
    });

    test('a failed snapshot save does not fail the save', () async {
      final repo = repository(BankAccount.new, snapshotEvery: 1);
      snapshots.failWith = SnapshotSaveFailedError('full');
      final account = BankAccount.open(id, 'ann');
      await repo.save(account);
      expect(account.hasUncommittedChanges, isFalse);
      expect(bus.published, hasLength(1));
      expect(snapshotErrors.single, isA<SnapshotSaveFailedError>());
    });
  });

  group('StateRepository', () {
    final id = AccountId.generate();

    test('save writes state, publishes and marks committed', () async {
      final repo = InMemoryAccountRepository(bus);
      final account = BankAccount.open(id, 'ann')..deposit(2);
      await repo.save(account);

      expect(repo.rows[id]?.version, 2);
      expect(bus.published, hasLength(2));
      expect(account.hasUncommittedChanges, isFalse);

      final loaded = await repo.load(id);
      expect((loaded.owner, loaded.balance, loaded.version), ('ann', 2, 2));
      await repo.save(loaded..deposit(1));
      expect(repo.rows[id]?.version, 3);
    });

    test('save without changes does nothing', () async {
      final repo = InMemoryAccountRepository(bus);
      await repo.save(BankAccount(id));
      expect(repo.rows, isEmpty);
    });

    test('a stale aggregate fails and publishes nothing', () async {
      final repo = InMemoryAccountRepository(bus);
      await repo.save(BankAccount.open(id, 'ann'));
      final first = await repo.load(id);
      final second = await repo.load(id);
      await repo.save(first..deposit(1));
      bus.published.clear();

      await expectLater(
        repo.save(second..deposit(1)),
        throwsA(isA<OptimisticConcurrencyError>()),
      );
      expect(bus.published, isEmpty);
    });

    test('loadOrNull returns null for a missing aggregate', () async {
      final repo = InMemoryAccountRepository(bus);
      expect(await repo.loadOrNull(id), isNull);
      expect(await repo.exists(id), isFalse);
    });
  });
}

typedef AccountRow = ({String? owner, int balance, int version});

/// A state repository over a map, standing in for a dedicated table.
class InMemoryAccountRepository
    extends StateRepository<BankAccount, AccountId> {
  InMemoryAccountRepository(super.eventBus);

  final rows = <AccountId, AccountRow>{};

  @override
  Future<BankAccount> load(AccountId id) async {
    final row = rows[id];
    if (row == null) throw AggregateNotFoundError('missing');
    return BankAccount.fromState(
      id,
      owner: row.owner,
      balance: row.balance,
      version: row.version,
    );
  }

  @override
  Future<bool> exists(AccountId id) async => rows.containsKey(id);

  @override
  Future<void> saveState(BankAccount aggregate) async {
    final stored = rows[aggregate.id]?.version ?? 0;
    if (stored != aggregate.committedVersion) {
      throw OptimisticConcurrencyError('stale');
    }
    rows[aggregate.id] = (
      owner: aggregate.owner,
      balance: aggregate.balance,
      version: aggregate.version,
    );
  }
}
