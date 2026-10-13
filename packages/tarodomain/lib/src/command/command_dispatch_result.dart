import 'package:uuid/uuid.dart';

import '../bus/event_bus.dart';
import '../domain/command.dart';

/// What happened to a dispatched command.
enum CommandDispatchStatus {
  /// The handler ran and its changes were saved.
  processed,

  /// The command ID was already processed, so nothing ran (spec §14.1).
  duplicate,
}

/// The result of dispatching one command.
final class CommandDispatchResult {
  /// Creates the result.
  const CommandDispatchResult({
    required this.commandId,
    required this.commandType,
    required this.handlerName,
    required this.consistency,
    required this.status,
    required this.attempts,
  });

  /// The command's ID.
  final UuidValue commandId;

  /// The command type name.
  final String commandType;

  /// The handler that ran, or would have run.
  final String handlerName;

  /// The pipeline the command went through.
  final ConsistencyMode consistency;

  /// Whether the command ran or was a duplicate.
  final CommandDispatchStatus status;

  /// How many times the handler was tried: 1 plus the number of retries
  /// after concurrency conflicts.
  final int attempts;

  /// Whether the command was skipped as already processed.
  bool get isDuplicate => status == CommandDispatchStatus.duplicate;
}

/// The outcome of one command in a batch: a result, or the error it threw.
final class CommandOutcome {
  /// An outcome for a command that completed.
  const CommandOutcome.succeeded(
    this.command,
    CommandDispatchResult this.result,
  ) : error = null,
      stackTrace = null;

  /// An outcome for a command that threw.
  const CommandOutcome.failed(
    this.command,
    Object this.error,
    StackTrace this.stackTrace,
  ) : result = null;

  /// The dispatched command.
  final Command command;

  /// The result, if the command completed.
  final CommandDispatchResult? result;

  /// What the command threw, if it failed.
  final Object? error;

  /// Where [error] was thrown.
  final StackTrace? stackTrace;

  /// Whether the command completed.
  bool get succeeded => error == null;
}

/// The result of dispatching several commands in order.
final class BatchDispatchResult {
  /// Creates the result.
  BatchDispatchResult({
    required List<CommandOutcome> outcomes,
    List<Command> skipped = const [],
  }) : outcomes = List.unmodifiable(outcomes),
       skipped = List.unmodifiable(skipped);

  /// One outcome per command that was dispatched, in order.
  final List<CommandOutcome> outcomes;

  /// Commands not dispatched because an earlier one failed and the batch
  /// stopped.
  final List<Command> skipped;

  /// The outcomes of commands that completed.
  Iterable<CommandOutcome> get succeeded =>
      outcomes.where((outcome) => outcome.succeeded);

  /// The outcomes of commands that threw.
  Iterable<CommandOutcome> get failed =>
      outcomes.where((outcome) => !outcome.succeeded);

  /// Whether every command was dispatched and completed.
  bool get allSucceeded => skipped.isEmpty && failed.isEmpty;
}
