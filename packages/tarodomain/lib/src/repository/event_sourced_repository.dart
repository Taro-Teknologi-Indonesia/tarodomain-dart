import '../adapters/event_store_adapter.dart';
import '../adapters/snapshot_store_adapter.dart';
import '../domain/aggregate_root.dart';
import '../bus/event_bus.dart';
import '../domain/aggregate_id.dart';
import '../domain/domain_event.dart';
import '../errors/error_codes.dart';
import '../event_sourcing/event_store.dart';
import 'repository.dart';

/// Called when a snapshot can't be loaded or saved. Snapshots are an
/// optimization, so the repository carries on without them.
typedef SnapshotErrorHandler =
    void Function(Object error, StackTrace stackTrace);

/// Repository that stores aggregates as their event streams (spec §6.2).
///
/// With a [snapshotStore] and a positive [snapshotEvery], it saves a snapshot
/// each time the version crosses a multiple of [snapshotEvery], and loads
/// from the latest snapshot plus the events after it.
class EventSourcedRepository<
  A extends AggregateRoot<TId, DomainEvent>,
  TId extends AggregateId
>
    implements Repository<A, TId> {
  /// Creates the repository. [factory] builds an empty aggregate for an ID,
  /// and [aggregateType] names its streams and snapshots.
  ///
  /// Throws [InvalidConfigurationError] if [aggregateType] contains `-`, or
  /// [snapshotEvery] is negative.
  EventSourcedRepository({
    required this.eventStore,
    required this.eventBus,
    required this.factory,
    required this.aggregateType,
    this.snapshotStore,
    this.snapshotEvery = 0,
    SnapshotErrorHandler? onSnapshotError,
  }) : _onSnapshotError = onSnapshotError ?? _ignore {
    if (aggregateType.isEmpty || aggregateType.contains('-')) {
      throw InvalidConfigurationError(
        'Aggregate type "$aggregateType" must be non-empty and contain no "-"',
        context: {'aggregateType': aggregateType},
      );
    }
    if (snapshotEvery < 0) {
      throw InvalidConfigurationError(
        'snapshotEvery must not be negative: $snapshotEvery',
        context: {'aggregateType': aggregateType},
      );
    }
  }

  /// Where the events are stored.
  final EventStore eventStore;

  /// Where saved events are published.
  final EventBus eventBus;

  /// Builds an empty aggregate for an ID.
  final A Function(TId id) factory;

  /// The aggregate type, used in stream IDs and as the snapshot source type.
  final String aggregateType;

  /// Where snapshots are stored, if snapshots are enabled.
  final SnapshotStoreAdapter? snapshotStore;

  /// Take a snapshot every this many events; 0 disables snapshots.
  final int snapshotEvery;

  final SnapshotErrorHandler _onSnapshotError;

  static void _ignore(Object error, StackTrace stackTrace) {}

  bool get _snapshotsEnabled => snapshotStore != null && snapshotEvery > 0;

  /// The stream ID of the aggregate with [id].
  String streamIdFor(TId id) => StreamIds.forAggregate(aggregateType, id);

  @override
  Future<A> load(TId id) async {
    final aggregate = await _fromSnapshot(id) ?? factory(id);
    final events = await eventStore.loadStream(
      streamIdFor(id),
      fromVersion: aggregate.version,
    );
    if (aggregate.version == 0 && events.isEmpty) {
      throw AggregateNotFoundError(
        '$aggregateType ${id.uuid} not found',
        context: {'aggregateType': aggregateType, 'id': id.uuid},
      );
    }
    aggregate.loadFromHistory(events);
    return aggregate;
  }

  /// The aggregate restored from its latest snapshot, or null if there is
  /// none or it can't be used.
  Future<A?> _fromSnapshot(TId id) async {
    final store = snapshotStore;
    if (store == null) return null;
    try {
      final snapshot = await store.loadLatest(id.value, aggregateType);
      if (snapshot == null) return null;
      return factory(id)
        ..restoreSnapshot(snapshot.data, snapshot.sourceVersion);
    } catch (error, stackTrace) {
      _onSnapshotError(error, stackTrace);
      return null;
    }
  }

  @override
  Future<void> save(A aggregate) async {
    final changes = aggregate.getUncommittedChanges();
    if (changes.isEmpty) return;
    final committedVersion = aggregate.committedVersion;
    await eventStore.appendToStream(
      streamIdFor(aggregate.id),
      changes,
      committedVersion,
    );
    await eventBus.publishAll(changes);
    aggregate.markChangesAsCommitted();

    if (_snapshotsEnabled &&
        aggregate.version ~/ snapshotEvery >
            committedVersion ~/ snapshotEvery) {
      await _saveSnapshot(aggregate);
    }
  }

  Future<void> _saveSnapshot(A aggregate) async {
    try {
      await snapshotStore!.save(
        SnapshotInput(
          sourceUuid: aggregate.id.value,
          sourceType: aggregateType,
          sourceVersion: aggregate.version,
          data: aggregate.toSnapshot(),
        ),
      );
    } catch (error, stackTrace) {
      _onSnapshotError(error, stackTrace);
    }
  }

  @override
  Future<bool> exists(TId id) => eventStore.streamExists(streamIdFor(id));
}
