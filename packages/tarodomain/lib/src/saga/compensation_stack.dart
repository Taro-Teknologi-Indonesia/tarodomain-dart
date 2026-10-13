import '../domain/command.dart';
import '../errors/error_codes.dart';

/// Creates the commands that undo one saga step.
typedef CompensationFactory = List<Command> Function();

/// LIFO stack of the steps a saga can undo (spec §13.5, §17).
///
/// Compensations are defined once, by name, with a factory; each completed
/// step then pushes the name of its compensation. A factory runs only when
/// its entry is popped, so it sees the saga's state at compensation time.
///
/// Unlike the spec, the stack is persisted with the saga, as the list of
/// [names]: a saga is loaded from the saga store for each event, so a stack
/// of closures registered while handling an earlier event would be gone by
/// the time a later event triggers compensation. Persisting names instead of
/// closures keeps the factories in code.
final class CompensationStack {
  final _factories = <String, CompensationFactory>{};
  final _stack = <String>[];

  /// Defines the compensation called [name].
  ///
  /// Throws [InvalidConfigurationError] if [name] is already defined.
  void define(String name, CompensationFactory factory) {
    if (_factories.containsKey(name)) {
      throw InvalidConfigurationError(
        'Compensation "$name" is already defined',
        context: {'compensation': name},
      );
    }
    _factories[name] = factory;
  }

  /// The defined compensation names.
  Iterable<String> get defined => _factories.keys;

  /// Pushes the compensation called [name].
  ///
  /// Throws [InvalidConfigurationError] if it isn't defined.
  void push(String name) {
    _check(name);
    _stack.add(name);
  }

  /// Pops every entry, most recent first, and returns the commands of each
  /// in that order.
  List<Command> takeAll() {
    final commands = <Command>[];
    while (_stack.isNotEmpty) {
      commands.addAll(pop());
    }
    return commands;
  }

  /// Pops the most recent entry and returns its commands, or returns an
  /// empty list if the stack is empty.
  List<Command> pop() =>
      _stack.isEmpty ? const [] : _factories[_stack.removeLast()]!();

  /// The pushed names, oldest first. This is what the saga store keeps.
  List<String> get names => List.unmodifiable(_stack);

  /// How many entries are on the stack.
  int get length => _stack.length;

  /// Whether the stack is empty.
  bool get isEmpty => _stack.isEmpty;

  /// Replaces the stack with [names], oldest first, as loaded from storage.
  ///
  /// Throws [InvalidConfigurationError] if a name isn't defined, for example
  /// because a compensation was renamed while sagas were running.
  void restore(List<String> names) {
    names.forEach(_check);
    _stack
      ..clear()
      ..addAll(names);
  }

  void _check(String name) {
    if (!_factories.containsKey(name)) {
      throw InvalidConfigurationError(
        'Compensation "$name" is not defined',
        context: {
          'compensation': name,
          'defined': [..._factories.keys],
        },
      );
    }
  }
}
