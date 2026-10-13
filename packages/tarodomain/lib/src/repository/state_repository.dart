import 'package:meta/meta.dart';

import '../domain/aggregate_root.dart';
import '../bus/event_bus.dart';
import '../domain/aggregate_id.dart';
import '../domain/domain_event.dart';
import '../errors/error_codes.dart';
import 'repository.dart';

/// Base class for repositories that store an aggregate's current state in a
/// dedicated table instead of its events (spec §6.3, §15.4). The events are
/// still published, so projections and sagas run as usual.
///
/// Subclasses implement [load], [exists] and [saveState]. To rebuild the
/// aggregate, they call [AggregateRoot.restoreSnapshot] or a constructor that
/// uses `restoreVersion`.
abstract class StateRepository<
  A extends AggregateRoot<TId, DomainEvent>,
  TId extends AggregateId
>
    implements Repository<A, TId> {
  /// Creates the repository.
  StateRepository(this.eventBus);

  /// Where saved events are published.
  final EventBus eventBus;

  /// Writes the aggregate's current state.
  ///
  /// Must check optimistic concurrency: the stored version has to equal
  /// `aggregate.committedVersion` (0 when inserting), otherwise throw
  /// [OptimisticConcurrencyError]. The new stored version is
  /// `aggregate.version`.
  @protected
  Future<void> saveState(A aggregate);

  @override
  Future<void> save(A aggregate) async {
    final changes = aggregate.getUncommittedChanges();
    if (changes.isEmpty) return;
    await saveState(aggregate);
    await eventBus.publishAll(changes);
    aggregate.markChangesAsCommitted();
  }

  /// Loads the aggregate with [id], or returns null if it doesn't exist.
  Future<A?> loadOrNull(TId id) async {
    try {
      return await load(id);
    } on AggregateNotFoundError {
      return null;
    }
  }
}
