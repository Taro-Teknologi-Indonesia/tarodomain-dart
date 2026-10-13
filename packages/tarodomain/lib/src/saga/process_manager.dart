import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import '../adapters/saga_store_adapter.dart';
import '../domain/command.dart';
import '../domain/domain_event.dart';
import '../domain/execution_context.dart';
import '../errors/error_codes.dart';
import 'compensation_stack.dart';
import 'saga_state_machine.dart';

/// Reacts to one event type in a [ProcessManager] and returns the commands
/// to dispatch.
typedef SagaHandler<E extends DomainEvent> = List<Command> Function(E event);

/// A handler registered on a [ProcessManager].
final class SagaRoute<E extends DomainEvent> {
  SagaRoute._(this.kind, this._handler);

  /// The kind of handler.
  final SagaHandlerKind kind;

  final SagaHandler<E> _handler;

  /// The event type it handles, including subtypes.
  Type get eventType => E;

  /// Whether it handles [event].
  bool matches(DomainEvent event) => event is E;

  /// The step name recorded as the saga's `currentStep`, such as
  /// `continueWhenMoneyWithdrawn`.
  String stepFor(DomainEvent event) => '${kind.name}${event.eventName}';

  List<Command> _call(DomainEvent event) => _handler(event as E);
}

/// A saga: coordinates a business process across aggregates by reacting to
/// events with commands (spec §13).
///
/// Subclasses register handlers in their constructor. Each returns the
/// commands to dispatch:
///
/// ```dart
/// class TransferSaga extends ProcessManager<TransferState> {
///   TransferSaga() : super(TransferState.empty) {
///     startsWhen<TransferRequested>((e) {
///       state = TransferState(e.from, e.to, e.cents);
///       return [Withdraw(e.from, e.cents)];
///     });
///     continueWhen<MoneyWithdrawn>((e) {
///       registerCompensation('refund');
///       return [Deposit(state.to, state.cents)];
///     });
///     compensateWhen<DepositRejected>((e) => getCompensationCommands());
///     completedWhen<MoneyDeposited>((e) => []);
///     defineCompensation('refund', () => [Refund(state.from, state.cents)]);
///   }
///   …
/// }
/// ```
///
/// The saga ID is the correlation ID of the starting event, and every event
/// and command in the process shares it (spec §13.4). Handlers run in the
/// event's [ExecutionContext], so the commands they create carry the saga ID
/// as correlation ID and the event as cause.
///
/// Commands created in a handler get UUIDv7 IDs derived from the saga type,
/// the event's ID and timestamp, and their order (see
/// [Command.withDerivedIds]). Handlers must
/// therefore be deterministic: given the same state and event, create the
/// same commands in the same order. Then an event handled again, after a
/// crash between dispatching and saving the saga, dispatches the same
/// command IDs, and the pipeline skips them as duplicates.
///
/// After [handle] throws, discard the instance: its state may be partly
/// updated.
abstract class ProcessManager<TState> {
  /// Creates a saga that hasn't started, with [initialState].
  ProcessManager(TState initialState) : state = initialState;

  /// The saga type name, stored with every instance.
  String get sagaType;

  /// The process state, kept between events. Handlers may change it or
  /// replace it.
  TState state;

  /// The state as JSON-safe data, for the saga store.
  Map<String, Object?> stateToJson(TState state);

  /// The state read back from [stateToJson]'s output.
  TState stateFromJson(Map<String, Object?> json);

  UuidValue? _sagaId;
  SagaState _state = SagaState.initial;
  String? _currentStep;
  String? _failureReason;
  String? _pendingFailure;
  final _routes = <SagaRoute>[];

  /// The steps this saga can undo.
  final compensations = CompensationStack();

  /// The saga ID: the correlation ID of the starting event. Null until the
  /// saga starts.
  UuidValue? get sagaId => _sagaId;

  /// The state-machine state.
  SagaState get sagaState => _state;

  /// The stored status, or null if the saga hasn't started.
  SagaStatus? get status => _state.status;

  /// The step of the last handler that ran, or null.
  String? get currentStep => _currentStep;

  /// Why the saga failed, if it did.
  String? get failureReason => _failureReason;

  /// Whether the saga has completed or failed.
  bool get isTerminal => _state.isTerminal;

  /// The registered handlers, in registration order.
  List<SagaRoute> get routes => List.unmodifiable(_routes);

  /// Registers a handler that starts the saga on events of type [E].
  @protected
  void startsWhen<E extends DomainEvent>(SagaHandler<E> handler) =>
      _register(SagaRoute<E>._(SagaHandlerKind.startsWhen, handler));

  /// Registers a handler for an intermediate step on events of type [E].
  @protected
  void continueWhen<E extends DomainEvent>(SagaHandler<E> handler) =>
      _register(SagaRoute<E>._(SagaHandlerKind.continueWhen, handler));

  /// Registers a handler that compensates on events of type [E], moving the
  /// saga to `COMPENSATING`.
  @protected
  void compensateWhen<E extends DomainEvent>(SagaHandler<E> handler) =>
      _register(SagaRoute<E>._(SagaHandlerKind.compensateWhen, handler));

  /// Registers a handler that completes the saga on events of type [E].
  @protected
  void completedWhen<E extends DomainEvent>(SagaHandler<E> handler) =>
      _register(SagaRoute<E>._(SagaHandlerKind.completedWhen, handler));

  void _register(SagaRoute route) {
    if (route.eventType == DomainEvent) {
      throw InvalidConfigurationError(
        'Saga "$sagaType" needs a concrete event type for ${route.kind.name}',
        context: {'sagaType': sagaType},
      );
    }
    final duplicate = _routes.any(
      (r) => r.kind == route.kind && r.eventType == route.eventType,
    );
    if (duplicate) {
      throw InvalidConfigurationError(
        'Saga "$sagaType" already has ${route.kind.name}<${route.eventType}>',
        context: {
          'sagaType': sagaType,
          'handler': route.kind.name,
          'eventType': '${route.eventType}',
        },
      );
    }
    _routes.add(route);
  }

  /// Defines the compensation [name], whose [factory] creates the commands
  /// that undo a step. Call it in the constructor.
  @protected
  void defineCompensation(String name, CompensationFactory factory) =>
      compensations.define(name, factory);

  /// Pushes the compensation [name] for the step that just ran.
  @protected
  void registerCompensation(String name) => compensations.push(name);

  /// Pops every registered compensation and returns their commands, most
  /// recent step first.
  @protected
  List<Command> getCompensationCommands() => compensations.takeAll();

  /// Pops the most recent compensation and returns its commands.
  @protected
  List<Command> popCompensation() => compensations.pop();

  /// Marks the saga `FAILED` with [reason] once the running handler returns.
  @protected
  void markFailed(String reason) => _pendingFailure = reason;

  /// The handler for [event], by priority: `completedWhen`, then
  /// `compensateWhen`, `continueWhen` and `startsWhen` (spec §13.1). Within
  /// one kind, a handler for the event's exact type wins over one for a
  /// supertype.
  SagaRoute? routeFor(DomainEvent event) {
    for (final kind in SagaHandlerKind.values.reversed) {
      final matching = _routes.where((r) => r.kind == kind && r.matches(event));
      if (matching.isEmpty) continue;
      return matching
              .where((r) => r.eventType == event.runtimeType)
              .firstOrNull ??
          matching.first;
    }
    return null;
  }

  /// Whether [event] would start this saga.
  bool canStart(DomainEvent event) =>
      routeFor(event)?.kind == SagaHandlerKind.startsWhen;

  /// Runs the handler for [event] and returns the commands to dispatch
  /// (spec §13.1).
  ///
  /// Returns an empty list for an event with no handler once the saga has
  /// started.
  ///
  /// Throws [SagaAlreadyCompletedError] if the saga is terminal,
  /// [SagaNotStartedError] for an event with no handler before it starts,
  /// and the errors of [SagaStateMachine.transition] for a transition it
  /// doesn't allow.
  List<Command> handle(DomainEvent event) {
    final context = {'sagaType': sagaType, 'eventType': event.eventName};
    if (_state.isTerminal) {
      throw SagaAlreadyCompletedError(
        'Saga "$sagaType" $_sagaId has already ${_state.name}',
        context: {...context, 'sagaId': _sagaId?.uuid},
      );
    }
    final route = routeFor(event);
    if (route == null) {
      if (_state != SagaState.initial) return const [];
      throw SagaNotStartedError(
        'Saga "$sagaType" has no handler to start on ${event.eventName}',
        context: context,
      );
    }
    final next = SagaStateMachine.transition(
      _state,
      route.kind,
      context: {...context, 'sagaId': (_sagaId ?? event.correlationId).uuid},
    );

    _pendingFailure = null;
    final commands = ExecutionContext.run(
      ExecutionContext.forEvent(event),
      () => Command.withDerivedIds(
        '$sagaType/${event.id.uuid}',
        () => route._call(event),
        time: event.occurredAt,
      ),
    );

    _sagaId ??= event.correlationId;
    _currentStep = route.stepFor(event);
    if (_pendingFailure case final reason?) {
      _state = SagaState.failed;
      _failureReason = reason;
      _pendingFailure = null;
    } else {
      _state = next;
    }
    return List.unmodifiable(commands);
  }

  /// Loads the saga from [record].
  ///
  /// Throws [SerializationError] if the stored state is malformed, and
  /// [InvalidConfigurationError] if it names a compensation that isn't
  /// defined.
  void restore(SagaRecord record) {
    final stored = record.state;
    final data = stored['state'];
    final names = stored['compensations'];
    if (data is! Map<String, Object?> ||
        names is! List<Object?> ||
        names.any((n) => n is! String)) {
      throw SerializationError(
        'Malformed state for saga "$sagaType" ${record.sagaId}',
        context: {'sagaType': sagaType, 'sagaId': record.sagaId.uuid},
      );
    }
    state = stateFromJson(data);
    compensations.restore(names.cast<String>());
    _sagaId = record.sagaId;
    _state = SagaState.of(record.status);
    _currentStep = record.currentStep;
    _failureReason = record.failureReason;
  }

  /// The saga in storable form. The stored state holds [state] under
  /// `state` and the compensation stack under `compensations`.
  ///
  /// Throws [StateError] if the saga hasn't started.
  SagaSaveInput toSaveInput() {
    final sagaId = _sagaId;
    final status = _state.status;
    if (sagaId == null || status == null) {
      throw StateError('Saga "$sagaType" has not started');
    }
    return SagaSaveInput(
      sagaId: sagaId,
      sagaType: sagaType,
      correlationId: sagaId,
      state: {
        'state': stateToJson(state),
        'compensations': compensations.names,
      },
      status: status,
      currentStep: _currentStep,
      failureReason: _failureReason,
    );
  }
}
