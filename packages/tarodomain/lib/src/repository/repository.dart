import '../domain/aggregate_root.dart';
import '../domain/aggregate_id.dart';
import '../domain/domain_event.dart';
import '../errors/error_codes.dart';

/// Loads and saves aggregates of type [A] (spec §6.1). Command handlers see
/// only this interface, whatever the persistence mode.
abstract interface class Repository<
  A extends AggregateRoot<TId, DomainEvent>,
  TId extends AggregateId
> {
  /// Loads the aggregate with [id].
  ///
  /// Throws [AggregateNotFoundError] if it doesn't exist.
  Future<A> load(TId id);

  /// Stores the aggregate's uncommitted events or state, publishes the
  /// events, and marks them committed. Does nothing if there are no
  /// uncommitted events.
  ///
  /// Throws [OptimisticConcurrencyError] if the aggregate changed since it
  /// was loaded.
  Future<void> save(A aggregate);

  /// Whether an aggregate with [id] exists.
  Future<bool> exists(TId id);
}
