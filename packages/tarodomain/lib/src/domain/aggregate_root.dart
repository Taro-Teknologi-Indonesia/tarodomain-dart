import 'package:meta/meta.dart';

import 'aggregate_id.dart';
import 'domain_event.dart';
import '../errors/error_codes.dart';

/// Consistency boundary that changes state only by raising events (spec §5).
///
/// [E] is the aggregate's event family, normally a `sealed` class, so that
/// [apply] can `switch` over it exhaustively:
///
/// ```dart
/// class BankAccount extends AggregateRoot<AccountId, AccountEvent> {
///   BankAccount(super.id);
///
///   factory BankAccount.open(AccountId id, String owner) =>
///       BankAccount(id)..raise(AccountOpened(owner: owner));
///
///   int balance = 0;
///
///   void deposit(int cents) => raise(MoneyDeposited(cents: cents));
///
///   @override
///   void apply(AccountEvent event) => switch (event) {
///     AccountOpened() => null,
///     MoneyDeposited(:final cents) => balance += cents,
///   };
///
///   @override
///   Map<String, Object?> toSnapshot() => {'balance': balance};
///
///   @override
///   void restoreSnapshotState(Map<String, Object?> data) =>
///       balance = data['balance']! as int;
/// }
/// ```
///
/// Every aggregate implements [toSnapshot] and [restoreSnapshotState], so
/// any of them can be snapshotted (spec §5.4). Dart can't enumerate fields,
/// so the aggregate lists its state itself.
///
/// The constructor takes only the ID and must not raise events, because
/// repositories use it to rehydrate (spec §5.3). Events need no enrichment
/// when raised: they take their tracing IDs from the execution context on
/// construction.
abstract class AggregateRoot<TId extends AggregateId, E extends DomainEvent> {
  /// Creates an empty aggregate at version 0.
  AggregateRoot(this.id);

  /// The aggregate's identifier.
  final TId id;

  int _version = 0;
  final _uncommitted = <E>[];

  /// The number of events applied, including uncommitted ones.
  int get version => _version;

  /// The version as last stored, used as the expected version on save.
  int get committedVersion => _version - _uncommitted.length;

  /// Whether events were raised since the last save.
  bool get hasUncommittedChanges => _uncommitted.isNotEmpty;

  /// Updates state for [event]. Must not raise events or throw for a valid
  /// event; validation belongs in the method that raises it.
  @protected
  void apply(E event);

  /// Applies [event] and queues it for persistence.
  @protected
  void raise(E event) {
    apply(event);
    _version++;
    _uncommitted.add(event);
  }

  /// Replays stored [events] on top of the current state, without queueing
  /// them. Replay continues from the current [version], which is 0, or the
  /// snapshot version after [restoreSnapshot].
  ///
  /// Throws [MissingEventHandlerError] for an event outside the family [E],
  /// and [StateError] if there are uncommitted changes.
  void loadFromHistory(Iterable<DomainEvent> events) {
    _checkNoUncommitted('loadFromHistory');
    for (final event in events) {
      if (event is! E) {
        throw MissingEventHandlerError(
          '$runtimeType has no handler for ${event.eventName}',
          context: {
            'aggregate': '$runtimeType',
            'eventType': event.eventName,
            'eventId': event.id.uuid,
          },
        );
      }
      apply(event);
      _version++;
    }
  }

  /// The events raised since the last save, oldest first.
  List<E> getUncommittedChanges() => List.unmodifiable(_uncommitted);

  /// Clears the uncommitted events after they were stored.
  void markChangesAsCommitted() => _uncommitted.clear();

  /// The business state as JSON-safe data, excluding the ID and version
  /// (spec §5.4).
  Map<String, Object?> toSnapshot();

  /// Restores the state written by [toSnapshot]. Called by
  /// [restoreSnapshot] on a freshly constructed aggregate.
  @protected
  void restoreSnapshotState(Map<String, Object?> data);

  /// Restores the state from a snapshot taken at [version].
  ///
  /// Throws [StateError] if there are uncommitted changes.
  void restoreSnapshot(Map<String, Object?> data, int version) {
    restoreVersion(version);
    restoreSnapshotState(data);
  }

  /// Sets the version of an aggregate rebuilt from stored state rather than
  /// events, such as a row loaded by a state repository.
  ///
  /// Throws [StateError] if there are uncommitted changes.
  @protected
  void restoreVersion(int version) {
    _checkNoUncommitted('restoreVersion');
    _version = version;
  }

  void _checkNoUncommitted(String method) {
    if (_uncommitted.isNotEmpty) {
      throw StateError('$method on $runtimeType with uncommitted changes');
    }
  }

  @override
  String toString() => '$runtimeType($id, version: $_version)';
}
