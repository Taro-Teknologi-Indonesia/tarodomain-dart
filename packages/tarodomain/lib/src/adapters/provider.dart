import '../bus/event_bus.dart';
import 'dead_letter_store.dart';
import 'event_store_adapter.dart';
import 'idempotency_stores.dart';
import 'saga_store_adapter.dart';
import 'snapshot_store_adapter.dart';
import 'unit_of_work.dart';

/// Creates the storage and messaging pieces for one platform (spec §24.1).
abstract class Provider {
  /// Platform name, such as `local` or `serverpod`.
  String get type;

  /// Creates the event store adapter.
  EventStoreAdapter createEventStoreAdapter();

  /// Creates the snapshot store adapter.
  SnapshotStoreAdapter createSnapshotStoreAdapter();

  /// Creates the saga store adapter.
  SagaStoreAdapter createSagaStoreAdapter();

  /// Creates the store for projection and saga idempotency.
  ProcessedEventStore createProcessedEventStore();

  /// Creates the store for command idempotency.
  CommandIdempotencyStore createCommandIdempotencyStore();

  /// Creates the dead letter store.
  DeadLetterStore createDeadLetterStore();

  /// Creates an event bus for [config].
  EventBus createEventBus(EventBusConfig config);

  /// Creates a unit of work, or returns null if the platform has none.
  UnitOfWork? createUnitOfWork();

  /// Prepares storage, for example by running migrations. Does nothing by
  /// default.
  Future<void> initialize() async {}
}
