import '../bus/event_bus.dart';
import '../domain/command.dart';
import '../errors/error_codes.dart';
import 'command_handler.dart';

/// How one command class is handled, as registered in a [CommandRegistry].
final class CommandRegistration<C extends Command> {
  CommandRegistration._({
    required this.commandType,
    required this.handlerName,
    required this.consistency,
    required this.createHandler,
  });

  /// The command class.
  Type get commandClass => C;

  /// The command type name, recorded with processed commands and used to
  /// find the class from a serialized command.
  final String commandType;

  /// The handler name, recorded with processed commands.
  final String handlerName;

  /// The consistency mode for this command, or null for the dispatcher's
  /// default (spec §11.3).
  final ConsistencyMode? consistency;

  /// Creates a handler for a pipeline.
  final CommandHandlerFactory<C> createHandler;

  /// Creates a handler for [context] and runs [command] with it.
  ///
  /// Throws [TypeError] if [command] is not a [C].
  Future<void> handle(CommandHandlerContext context, Command command) =>
      createHandler(context).handle(command as C);
}

/// Maps command classes to their handlers, and command type names to
/// classes (spec §4.3).
///
/// Commands are matched on their exact runtime type: a subclass of a
/// registered command needs its own registration.
final class CommandRegistry {
  final _byClass = <Type, CommandRegistration>{};
  final _byName = <String, CommandRegistration>{};

  /// Registers [createHandler] for commands of class [C], named
  /// [commandType]. [handlerName] defaults to `<commandType>Handler`.
  /// [consistency] overrides the dispatcher's default for this command.
  ///
  /// Throws [InvalidConfigurationError] if [C] or [commandType] is already
  /// registered, or [C] is `Command` itself.
  void register<C extends Command>(
    String commandType,
    CommandHandlerFactory<C> createHandler, {
    String? handlerName,
    ConsistencyMode? consistency,
  }) {
    if (C == Command) {
      throw InvalidConfigurationError(
        'register needs a concrete command class for "$commandType"',
        context: {'commandType': commandType},
      );
    }
    if (commandType.isEmpty) {
      throw InvalidConfigurationError('Command type name must not be empty');
    }
    if (_byClass.containsKey(C) || _byName.containsKey(commandType)) {
      throw InvalidConfigurationError(
        'Command $C ("$commandType") is already registered',
        context: {'commandType': commandType},
      );
    }
    final registration = CommandRegistration<C>._(
      commandType: commandType,
      handlerName: handlerName ?? '${commandType}Handler',
      consistency: consistency,
      createHandler: createHandler,
    );
    _byClass[C] = registration;
    _byName[commandType] = registration;
  }

  /// The registration for [command]'s class.
  ///
  /// Throws [CommandHandlerNotRegisteredError] if there is none.
  CommandRegistration resolve(Command command) =>
      _byClass[command.runtimeType] ??
      (throw CommandHandlerNotRegisteredError(
        'No handler registered for ${command.runtimeType}',
        context: {
          'commandClass': '${command.runtimeType}',
          'commandId': command.id.uuid,
        },
      ));

  /// Whether [command]'s class is registered.
  bool isRegistered(Command command) =>
      _byClass.containsKey(command.runtimeType);

  /// The registration for the command type name [commandType], or null.
  CommandRegistration? byName(String commandType) => _byName[commandType];

  /// Every registration, in registration order.
  Iterable<CommandRegistration> get registrations => _byClass.values;
}
