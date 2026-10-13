import 'package:tarodomain/tarodomain.dart';

import 'in_memory_dead_letter_store.dart';
import 'in_memory_event_store_adapter.dart';
import 'in_memory_idempotency_stores.dart';
import 'in_memory_saga_store_adapter.dart';
import 'in_memory_snapshot_store_adapter.dart';
import 'in_memory_unit_of_work.dart';
import 'local_database.dart';

/// The in-memory provider (spec §24.2 `LocalProvider`), for tests and local
/// development. Everything it creates shares one [LocalDatabase], so a unit
/// of work covers every adapter.
final class LocalProvider extends Provider {
  /// Creates a provider over [database], or over a new empty one.
  LocalProvider({LocalDatabase? database})
    : database = database ?? LocalDatabase();

  /// The database every adapter reads and writes.
  final LocalDatabase database;

  @override
  String get type => 'local';

  @override
  EventStoreAdapter createEventStoreAdapter() =>
      InMemoryEventStoreAdapter(database);

  @override
  SnapshotStoreAdapter createSnapshotStoreAdapter() =>
      InMemorySnapshotStoreAdapter(database);

  @override
  SagaStoreAdapter createSagaStoreAdapter() =>
      InMemorySagaStoreAdapter(database);

  @override
  ProcessedEventStore createProcessedEventStore() =>
      InMemoryProcessedEventStore(database);

  @override
  CommandIdempotencyStore createCommandIdempotencyStore() =>
      InMemoryCommandIdempotencyStore(database);

  @override
  DeadLetterStore createDeadLetterStore() => InMemoryDeadLetterStore(database);

  /// A new [InMemoryEventBus] for either consistency mode.
  ///
  /// There is no queue locally, so an eventual bus also delivers at once, in
  /// the caller's zone. It runs outside any unit of work, because the
  /// eventual pipeline has none, so a handler that fails leaves the command's
  /// events stored.
  @override
  EventBus createEventBus(EventBusConfig config) =>
      InMemoryEventBus(name: 'local-${config.consistency.name}');

  @override
  UnitOfWork createUnitOfWork() => InMemoryUnitOfWork(database);
}
