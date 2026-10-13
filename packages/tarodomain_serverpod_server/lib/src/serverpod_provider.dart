import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';

import 'adapters/serverpod_dead_letter_store.dart';
import 'adapters/serverpod_event_store_adapter.dart';
import 'adapters/serverpod_idempotency_stores.dart';
import 'adapters/serverpod_saga_store_adapter.dart';
import 'adapters/serverpod_snapshot_store_adapter.dart';
import 'serverpod_unit_of_work.dart';

/// Schedules a catch-up run on [session]'s server after [delay], usually a
/// future call (see `TaroDomainFutureCall`).
typedef CatchUpScheduler =
    Future<void> Function(Session session, Duration delay);

/// The Serverpod provider (spec §24): every store on the module's tables
/// through [session]'s database, a unit of work on Serverpod transactions,
/// and an eventual event bus that schedules catch-up.
///
/// It is bound to one [Session], so create one per request; runtimes are
/// cheap to create from a `FrameworkDefinition`. `TaroDomainServerpod` does
/// both.
final class ServerpodProvider extends Provider {
  /// Creates a provider on [session].
  ///
  /// [scheduleCatchUp] is called after an eventual command stores events;
  /// without it, those events wait for the next recurring catch-up. [clock]
  /// supplies the timestamps the stores record.
  ServerpodProvider(this.session, {this.scheduleCatchUp, this.clock});

  /// The request's session.
  final Session session;

  /// Schedules catch-up after an eventual command, or null.
  final CatchUpScheduler? scheduleCatchUp;

  /// The clock of the stores' timestamps, or null for the system clock.
  final DateTime Function()? clock;

  @override
  String get type => 'serverpod';

  @override
  EventStoreAdapter createEventStoreAdapter() =>
      ServerpodEventStoreAdapter(session, clock: clock);

  @override
  SnapshotStoreAdapter createSnapshotStoreAdapter() =>
      ServerpodSnapshotStoreAdapter(session, clock: clock);

  @override
  SagaStoreAdapter createSagaStoreAdapter() =>
      ServerpodSagaStoreAdapter(session, clock: clock);

  @override
  ProcessedEventStore createProcessedEventStore() =>
      ServerpodProcessedEventStore(session, clock: clock);

  @override
  CommandIdempotencyStore createCommandIdempotencyStore() =>
      ServerpodCommandIdempotencyStore(session, clock: clock);

  @override
  DeadLetterStore createDeadLetterStore() =>
      ServerpodDeadLetterStore(session, clock: clock);

  /// An [InMemoryEventBus] for strong consistency, which delivers inside the
  /// command's transaction, and a [FutureCallEventBus] for eventual
  /// consistency.
  @override
  EventBus createEventBus(EventBusConfig config) =>
      switch (config.consistency) {
        ConsistencyMode.strong => InMemoryEventBus(name: 'serverpod-strong'),
        ConsistencyMode.eventual => FutureCallEventBus(
          session,
          schedule: scheduleCatchUp,
        ),
      };

  @override
  UnitOfWork createUnitOfWork() => ServerpodUnitOfWork(session);
}

/// The eventual event bus (spec §10.3) of [ServerpodProvider].
///
/// The event store already holds the events durably, so publishing only
/// schedules an immediate catch-up run, which positions them and delivers
/// them to projections and sagas through their subscriptions. A recurring catch-up is the safety net if
/// scheduling fails or there is no scheduler. No external queue is needed.
final class FutureCallEventBus extends EventBus {
  /// Creates the bus. [schedule] is called with [delay] once per
  /// [publishAll] of at least one event.
  FutureCallEventBus(this.session, {this.schedule, this.delay = Duration.zero});

  /// The request's session.
  final Session session;

  /// Schedules catch-up, or null to rely on the recurring catch-up.
  final CatchUpScheduler? schedule;

  /// How long to wait before catching up.
  final Duration delay;

  @override
  String get name => 'serverpod-future-call';

  @override
  Future<void> publishAll(List<DomainEvent> events) async {
    if (events.isEmpty) return;
    await schedule?.call(session, delay);
  }
}
