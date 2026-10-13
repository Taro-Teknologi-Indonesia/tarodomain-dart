import 'package:tarodomain/tarodomain.dart';

import '../domain/fixtures.dart' show AccountId;

export '../domain/fixtures.dart' show AccountId;

sealed class AccountEvent extends DomainEvent {}

class AccountOpened extends AccountEvent {
  AccountOpened({required this.owner});

  factory AccountOpened.fromData(Map<String, Object?> data) =>
      AccountOpened(owner: data['owner']! as String);

  final String owner;

  @override
  String get eventName => 'AccountOpened';

  @override
  Map<String, Object?> toData() => {'owner': owner};
}

/// Version 1.2.0: v1.0.0 stored `amount`, v1.1.0 added `currency`, and
/// v1.2.0 renamed `amount` to `cents`.
class FundsDeposited extends AccountEvent {
  FundsDeposited({required this.cents, this.currency = 'USD'});

  factory FundsDeposited.fromData(Map<String, Object?> data) => FundsDeposited(
    cents: data['cents']! as int,
    currency: data['currency']! as String,
  );

  final int cents;
  final String currency;

  @override
  String get eventName => 'FundsDeposited';

  @override
  String get eventVersion => '1.2.0';

  @override
  Map<String, Object?> toData() => {'cents': cents, 'currency': currency};
}

/// An event from another family, which [BankAccount] can't apply.
class UnrelatedHappened extends DomainEvent {
  @override
  String get eventName => 'UnrelatedHappened';

  @override
  Map<String, Object?> toData() => {};
}

class BankAccount extends AggregateRoot<AccountId, AccountEvent> {
  BankAccount(super.id);

  factory BankAccount.open(AccountId id, String owner) =>
      BankAccount(id)..raise(AccountOpened(owner: owner));

  /// Rebuilt from a state row rather than events.
  BankAccount.fromState(
    super.id, {
    required this.owner,
    required this.balance,
    required int version,
  }) {
    restoreVersion(version);
  }

  String? owner;
  int balance = 0;

  void deposit(int cents) => raise(FundsDeposited(cents: cents));

  @override
  void apply(AccountEvent event) => switch (event) {
    AccountOpened(:final owner) => this.owner = owner,
    FundsDeposited(:final cents) => balance += cents,
  };

  @override
  Map<String, Object?> toSnapshot() => {'owner': owner, 'balance': balance};

  @override
  void restoreSnapshotState(Map<String, Object?> data) {
    owner = data['owner'] as String?;
    balance = data['balance']! as int;
  }
}

EventRegistry accountRegistry() => EventRegistry()
  ..register('AccountOpened', AccountOpened.fromData)
  ..register('FundsDeposited', FundsDeposited.fromData, version: '1.2.0')
  ..registerUpcaster(
    'FundsDeposited',
    '1.0.0',
    '1.1.0',
    (data) => {...data, 'currency': 'USD'},
  )
  ..registerUpcaster(
    'FundsDeposited',
    '1.1.0',
    '1.2.0',
    (data) => {'cents': data['amount'], 'currency': data['currency']},
  );

/// Records published events; can be told to fail.
class RecordingEventBus extends EventBus {
  final published = <DomainEvent>[];
  Object? failWith;

  @override
  String get name => 'recording';

  @override
  Future<void> publishAll(List<DomainEvent> events) async {
    if (failWith case final error?) throw error;
    published.addAll(events);
  }
}

/// Minimal event store for repository tests. The real in-memory adapter and
/// its contract tests come in Phase 3.
class FakeEventStoreAdapter implements EventStoreAdapter {
  final streams = <String, List<SerializedEvent>>{};
  int appendCalls = 0;
  int? lastLoadFromVersion;

  @override
  Future<AppendResult> appendToStream(
    String streamId,
    List<SerializedEvent> events,
    int expectedVersion,
  ) async {
    appendCalls++;
    final stream = streams[streamId] ?? [];
    if (stream.length != expectedVersion) {
      throw OptimisticConcurrencyError(
        'Expected $expectedVersion, found ${stream.length}',
        context: {'streamId': streamId},
      );
    }
    streams[streamId] = [...stream, ...events];
    return AppendResult(streamId: streamId, version: streams[streamId]!.length);
  }

  @override
  Future<List<SerializedEvent>> loadStream(
    String streamId, {
    int fromVersion = 0,
    int? maxCount,
  }) async {
    lastLoadFromVersion = fromVersion;
    final events = (streams[streamId] ?? []).skip(fromVersion);
    return (maxCount == null ? events : events.take(maxCount)).toList();
  }

  @override
  Future<bool> streamExists(String streamId) async =>
      streams[streamId]?.isNotEmpty ?? false;

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// Minimal snapshot store; can be told to fail.
class FakeSnapshotStore implements SnapshotStoreAdapter {
  final saved = <SnapshotInput>[];
  Object? failWith;

  @override
  Future<void> save(SnapshotInput input) async {
    if (failWith case final error?) throw error;
    saved.add(input);
  }

  @override
  Future<Snapshot?> loadLatest(UuidValue sourceUuid, String sourceType) async {
    if (failWith case final error?) throw error;
    final matching = saved.where(
      (s) => s.sourceUuid == sourceUuid && s.sourceType == sourceType,
    );
    if (matching.isEmpty) return null;
    final latest = matching.reduce(
      (a, b) => a.sourceVersion >= b.sourceVersion ? a : b,
    );
    return Snapshot(
      sourceUuid: latest.sourceUuid,
      sourceType: latest.sourceType,
      sourceVersion: latest.sourceVersion,
      data: latest.data,
      createdAt: DateTime.timestamp(),
    );
  }

  @override
  Never noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
