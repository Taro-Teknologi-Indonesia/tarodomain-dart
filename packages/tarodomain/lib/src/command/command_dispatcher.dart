import '../bus/event_bus.dart';
import '../domain/command.dart';
import '../errors/error_codes.dart';
import 'command_dispatch_result.dart';
import 'command_pipeline.dart';
import 'command_registry.dart';

/// Resolves a command's registration and sends it through the pipeline for
/// its consistency mode (spec §4.2, §11.3).
///
/// A command uses the consistency mode it was registered with, or
/// [defaultConsistency].
final class CommandDispatcher {
  /// Creates the dispatcher. At least the pipeline for [defaultConsistency]
  /// is required.
  ///
  /// Throws [InvalidConfigurationError] if it is missing.
  CommandDispatcher({
    required this.registry,
    required this.defaultConsistency,
    StrongConsistencyPipeline? strong,
    EventualConsistencyPipeline? eventual,
  }) : _pipelines = {
         ConsistencyMode.strong: ?strong,
         ConsistencyMode.eventual: ?eventual,
       } {
    if (!_pipelines.containsKey(defaultConsistency)) {
      throw InvalidConfigurationError(
        'No ${defaultConsistency.name} pipeline for the default consistency',
        context: {'consistency': defaultConsistency.name},
      );
    }
  }

  /// The command registrations.
  final CommandRegistry registry;

  /// The consistency mode of commands registered without one.
  final ConsistencyMode defaultConsistency;

  final Map<ConsistencyMode, CommandPipeline> _pipelines;

  /// The registration for [command].
  ///
  /// Throws [CommandHandlerNotRegisteredError] if there is none.
  CommandRegistration resolve(Command command) => registry.resolve(command);

  /// The consistency mode [command] is dispatched with.
  ///
  /// Throws [CommandHandlerNotRegisteredError] if it isn't registered.
  ConsistencyMode consistencyFor(Command command) =>
      resolve(command).consistency ?? defaultConsistency;

  /// Whether [command] is registered and its pipeline exists.
  bool canDispatch(Command command) =>
      registry.isRegistered(command) &&
      _pipelines.containsKey(consistencyFor(command));

  /// Runs [command] through its pipeline.
  ///
  /// A command whose ID was already processed is not run again; its result
  /// has [CommandDispatchStatus.duplicate]. Errors from the handler are
  /// rethrown after any retries.
  ///
  /// Throws [CommandHandlerNotRegisteredError] if [command] isn't
  /// registered, and [InvalidConfigurationError] if its pipeline is missing.
  Future<CommandDispatchResult> dispatch(Command command) async {
    final registration = resolve(command);
    final consistency = registration.consistency ?? defaultConsistency;
    final pipeline =
        _pipelines[consistency] ??
        (throw InvalidConfigurationError(
          '${registration.commandType} needs the ${consistency.name} '
          'pipeline, which is not configured',
          context: {
            'commandType': registration.commandType,
            'consistency': consistency.name,
          },
        ));
    return pipeline.dispatch(command, registration);
  }

  /// Dispatches [commands] one after another and reports each outcome.
  /// Never throws.
  ///
  /// By default the batch stops at the first command that throws, and the
  /// commands after it are reported as skipped. With [continueOnError], every
  /// command is dispatched. Each command commits on its own: a later failure
  /// doesn't undo earlier commands.
  Future<BatchDispatchResult> dispatchAll(
    List<Command> commands, {
    bool continueOnError = false,
  }) async {
    final outcomes = <CommandOutcome>[];
    for (final (index, command) in commands.indexed) {
      try {
        outcomes.add(
          CommandOutcome.succeeded(command, await dispatch(command)),
        );
      } catch (error, stackTrace) {
        outcomes.add(CommandOutcome.failed(command, error, stackTrace));
        if (!continueOnError) {
          return BatchDispatchResult(
            outcomes: outcomes,
            skipped: commands.sublist(index + 1),
          );
        }
      }
    }
    return BatchDispatchResult(outcomes: outcomes);
  }
}
