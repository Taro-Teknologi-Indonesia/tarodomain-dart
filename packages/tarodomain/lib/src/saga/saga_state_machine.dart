import '../adapters/saga_store_adapter.dart';
import '../errors/error_codes.dart';
import '../errors/framework_error.dart';

/// The kinds of saga handler (spec §13.1), in increasing priority: when one
/// event matches several, the last kind listed wins.
enum SagaHandlerKind {
  /// Starts a new saga.
  startsWhen,

  /// An intermediate step.
  continueWhen,

  /// Starts or continues compensation.
  compensateWhen,

  /// Finishes the saga.
  completedWhen,
}

/// The states of the saga state machine (spec §13.2): the stored
/// [SagaStatus] values plus [initial], for a saga that hasn't started.
enum SagaState {
  /// Not started; never stored.
  initial,

  /// See [SagaStatus.running].
  running,

  /// See [SagaStatus.compensating].
  compensating,

  /// See [SagaStatus.completed].
  completed,

  /// See [SagaStatus.failed].
  failed;

  /// The state for a stored [status], or [initial] for null.
  static SagaState of(SagaStatus? status) => switch (status) {
    null => initial,
    SagaStatus.running => running,
    SagaStatus.compensating => compensating,
    SagaStatus.completed => completed,
    SagaStatus.failed => failed,
  };

  /// The stored status, or null for [initial].
  SagaStatus? get status => switch (this) {
    initial => null,
    running => SagaStatus.running,
    compensating => SagaStatus.compensating,
    completed => SagaStatus.completed,
    failed => SagaStatus.failed,
  };

  /// Whether no further transitions are allowed.
  bool get isTerminal => this == completed || this == failed;
}

/// The saga transition table (spec §13.2).
///
/// | From | startsWhen | continueWhen | compensateWhen | completedWhen |
/// |---|---|---|---|---|
/// | initial | running | not started | not started | not started |
/// | running | already started | running | compensating | completed |
/// | compensating | invalid | compensating | compensating | completed |
/// | completed, failed | already completed | ← | ← | ← |
///
/// The spec doesn't list `compensating + startsWhen`; it is an
/// [InvalidSagaTransitionError] here.
abstract final class SagaStateMachine {
  /// The state after a [kind] handler runs in [from].
  ///
  /// Throws [SagaNotStartedError], [SagaAlreadyStartedError],
  /// [SagaAlreadyCompletedError] or [InvalidSagaTransitionError] for a
  /// transition the table doesn't allow. [context] is added to the error.
  static SagaState transition(
    SagaState from,
    SagaHandlerKind kind, {
    Map<String, Object?> context = const {},
  }) {
    final details = {...context, 'state': from.name, 'handler': kind.name};
    return switch ((from, kind)) {
      (.initial, .startsWhen) => .running,
      (.initial, _) => throw SagaNotStartedError(
        'A ${kind.name} handler cannot run before the saga starts',
        context: details,
      ),
      (.running, .startsWhen) => throw SagaAlreadyStartedError(
        'The saga has already started',
        context: details,
      ),
      (.compensating, .startsWhen) => throw InvalidSagaTransitionError(
        'A compensating saga cannot start again',
        context: details,
      ),
      (.running || .compensating, .continueWhen) => from,
      (.running || .compensating, .compensateWhen) => .compensating,
      (.running || .compensating, .completedWhen) => .completed,
      (.completed || .failed, _) => throw SagaAlreadyCompletedError(
        'The saga has already ${from.name}',
        context: details,
      ),
    };
  }

  /// Whether a [kind] handler may run in [from].
  static bool canTransition(SagaState from, SagaHandlerKind kind) {
    try {
      transition(from, kind);
      return true;
    } on FrameworkError {
      return false;
    }
  }
}
