import 'package:meta/meta.dart';

import '../adapters/idempotency_stores.dart';
import '../adapters/unit_of_work.dart';
import '../bus/event_bus.dart';
import '../domain/command.dart';
import '../domain/execution_context.dart';
import 'command_dispatch_result.dart';
import 'command_handler.dart';
import 'command_registry.dart';
import 'concurrency_checker.dart';

/// Runs commands for one consistency mode (spec §11).
///
/// Each attempt runs in the command's [ExecutionContext], skips the command
/// if its ID was already processed, runs a fresh handler, and records the
/// ID. Attempts are retried after an optimistic concurrency conflict, and
/// each retry checks the ID again (spec §14.1).
abstract base class CommandPipeline {
  /// Creates the pipeline.
  CommandPipeline({
    required this.eventBus,
    required this.idempotencyStore,
    ConcurrencyChecker? concurrency,
  }) : concurrency = concurrency ?? ConcurrencyChecker();

  /// The consistency mode this pipeline provides.
  ConsistencyMode get consistency;

  /// The bus the handlers' repositories publish to.
  final EventBus eventBus;

  /// Records processed command IDs.
  final CommandIdempotencyStore idempotencyStore;

  /// Retries attempts after concurrency conflicts.
  final ConcurrencyChecker concurrency;

  /// Runs [command] with the handler from [registration].
  Future<CommandDispatchResult> dispatch(
    Command command,
    CommandRegistration registration,
  ) {
    var attempts = 0;
    return concurrency.withRetry(
      () => runAttempt(() => _attempt(command, registration, ++attempts)),
    );
  }

  /// Runs one [attempt]. Subclasses wrap it, for example in a unit of work.
  @protected
  Future<CommandDispatchResult> runAttempt(
    Future<CommandDispatchResult> Function() attempt,
  ) => attempt();

  Future<CommandDispatchResult> _attempt(
    Command command,
    CommandRegistration registration,
    int attempt,
  ) => ExecutionContext.run(ExecutionContext.forCommand(command), () async {
    CommandDispatchResult result(CommandDispatchStatus status) =>
        CommandDispatchResult(
          commandId: command.id,
          commandType: registration.commandType,
          handlerName: registration.handlerName,
          consistency: consistency,
          status: status,
          attempts: attempt,
        );

    if (await idempotencyStore.exists(command.id)) {
      return result(CommandDispatchStatus.duplicate);
    }
    await registration.handle(
      CommandHandlerContext(consistency: consistency, eventBus: eventBus),
      command,
    );
    await idempotencyStore.markProcessed(
      command.id,
      registration.commandType,
      registration.handlerName,
    );
    return result(CommandDispatchStatus.processed);
  });
}

/// Runs each attempt in a [UnitOfWork], so the events, the handlers on
/// [eventBus] and the idempotency record commit together or not at all
/// (spec §11.1, §15.1).
///
/// [eventBus] should deliver in the caller's zone, as [InMemoryEventBus]
/// does, so that projections and sagas write inside the unit of work. A
/// handler that throws rolls back the whole command.
///
/// When a unit of work is already active, as when a saga dispatches a
/// command from inside another strong command, the command joins it and is
/// not retried here: after a conflict the outer transaction must restart.
final class StrongConsistencyPipeline extends CommandPipeline {
  /// Creates the pipeline.
  StrongConsistencyPipeline({
    required this.unitOfWork,
    required super.eventBus,
    required super.idempotencyStore,
    super.concurrency,
  });

  /// Makes each attempt atomic.
  final UnitOfWork unitOfWork;

  @override
  ConsistencyMode get consistency => ConsistencyMode.strong;

  @override
  Future<CommandDispatchResult> dispatch(
    Command command,
    CommandRegistration registration,
  ) {
    if (!unitOfWork.isActive) return super.dispatch(command, registration);
    return runAttempt(() => _attempt(command, registration, 1));
  }

  @override
  Future<CommandDispatchResult> runAttempt(
    Future<CommandDispatchResult> Function() attempt,
  ) => unitOfWork.execute(attempt);
}

/// Runs each attempt without a unit of work (spec §11.2, §15.2).
///
/// Appending the events is atomic by itself; [eventBus] then hands them to a
/// queue. If publishing fails, the events are already stored and a catch-up
/// subscription delivers them later. The idempotency record is written after
/// the handler, so a crash between the two lets a retry run the command
/// again.
final class EventualConsistencyPipeline extends CommandPipeline {
  /// Creates the pipeline.
  EventualConsistencyPipeline({
    required super.eventBus,
    required super.idempotencyStore,
    super.concurrency,
  });

  @override
  ConsistencyMode get consistency => ConsistencyMode.eventual;
}
