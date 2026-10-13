import 'dart:developer' as developer;

import '../command/command_dispatcher.dart';
import '../domain/command.dart';
import '../domain/domain_event.dart';
import '../errors/error_codes.dart';
import '../event_sourcing/event_registry.dart';
import '../projection/projection.dart';
import '../saga/saga_state_machine.dart';
import '../saga/saga_timeout.dart';
import 'taro_domain.dart';

/// Receives validation warnings.
typedef ValidationLogger = void Function(String message);

/// Logs [message] through `dart:developer` under the name `tarodomain`.
void defaultValidationLogger(String message) =>
    developer.log(message, name: 'tarodomain');

/// The issues [FrameworkValidator] found.
final class ValidationReport {
  /// Creates the report.
  ValidationReport({
    List<String> errors = const [],
    List<String> warnings = const [],
  }) : errors = List.unmodifiable(errors),
       warnings = List.unmodifiable(warnings);

  /// Problems that make the configuration unusable.
  final List<String> errors;

  /// Problems that are probably mistakes but don't stop the framework.
  final List<String> warnings;

  /// Whether there are no [errors].
  bool get isValid => errors.isEmpty;

  /// Throws [InvalidConfigurationError] listing every error, if there are
  /// any.
  void throwIfInvalid() {
    if (isValid) return;
    throw InvalidConfigurationError(
      'Invalid TaroDomain configuration:\n- ${errors.join('\n- ')}',
      context: {'issues': errors},
    );
  }
}

/// Checks a framework configuration at startup (spec §29.1).
///
/// [validate] runs during `TaroDomainBuilder.build`. Projections are created
/// from the provider's resources, so [validateProjections] runs when the
/// first runtime is created.
final class FrameworkValidator {
  /// Creates the validator.
  const FrameworkValidator();

  /// Checks the aggregates, commands and sagas of [definition]:
  ///
  /// - no aggregate, command or saga is registered twice;
  /// - every aggregate has a factory or a state repository;
  /// - every saga has a `startsWhen` handler and a positive timeout, if it
  ///   has one;
  /// - every event type a saga handles is registered.
  ValidationReport validate(FrameworkDefinition definition) {
    final errors = <String>[];
    final warnings = <String>[];

    final aggregateClasses = <Type>{};
    final aggregateTypes = <String>{};
    for (final aggregate in definition.aggregates) {
      final name = aggregate.aggregateType;
      if (!aggregateClasses.add(aggregate.aggregateClass)) {
        errors.add('Aggregate ${aggregate.aggregateClass} is registered twice');
      }
      if (!aggregateTypes.add(name)) {
        errors.add('Aggregate type "$name" is registered twice');
      }
      if (name.isEmpty || name.contains('-')) {
        errors.add(
          'Aggregate type "$name" must be non-empty and contain no "-"',
        );
      }
      if (!aggregate.isStateBased && !aggregate.hasFactory) {
        errors.add(
          'Aggregate "$name" needs a factory, or a state repository for '
          'state-based storage',
        );
      }
      if (aggregate.snapshotEvery < 0) {
        errors.add('Aggregate "$name" has a negative snapshotEvery');
      } else if (aggregate.snapshotEvery > 0 && aggregate.isStateBased) {
        warnings.add(
          'Aggregate "$name" uses a state repository, so snapshotEvery is '
          'ignored',
        );
      }
    }

    final commandClasses = <Type>{};
    final commandTypes = <String>{};
    for (final command in definition.commands) {
      final name = command.commandType;
      if (command.commandClass == Command) {
        errors.add('Command "$name" needs a concrete command class');
      } else if (!commandClasses.add(command.commandClass)) {
        errors.add('Command ${command.commandClass} is registered twice');
      }
      if (name.isEmpty) {
        errors.add('Command ${command.commandClass} has an empty type name');
      } else if (!commandTypes.add(name)) {
        errors.add('Command type "$name" is registered twice');
      }
    }

    final sagaTypes = <String>{};
    for (final saga in definition.sagas) {
      final prototype = saga.prototype;
      final name = prototype.sagaType;
      if (!sagaTypes.add(name)) {
        errors.add('Saga "$name" is registered twice');
      }
      final kinds = {for (final route in prototype.routes) route.kind};
      if (!kinds.contains(SagaHandlerKind.startsWhen)) {
        errors.add('Saga "$name" has no startsWhen handler');
      }
      if (!kinds.contains(SagaHandlerKind.completedWhen)) {
        warnings.add(
          'Saga "$name" has no completedWhen handler, so it never '
          'completes',
        );
      }
      for (final type in prototype.unregisteredEventTypes(definition.events)) {
        if (type == SagaTimeout) continue;
        errors.add('Saga "$name" handles $type, which is not registered');
      }
      final timeout = saga.timeout;
      if (timeout != null && timeout <= Duration.zero) {
        errors.add('Saga "$name" has a timeout that is not positive');
      }
      final handlesTimeout = prototype.routes.any(
        (route) => route.eventType == SagaTimeout,
      );
      if (handlesTimeout && timeout == null) {
        warnings.add(
          'Saga "$name" handles SagaTimeout but has no timeout, so it never '
          'times out',
        );
      }
    }

    return ValidationReport(errors: errors, warnings: warnings);
  }

  /// Checks [projections]:
  ///
  /// - no two share a name, and none is named like one of [sagaTypes]
  ///   (they share the event buses);
  /// - each has at least one handler;
  /// - every event type each handles is registered in [events].
  ValidationReport validateProjections(
    List<Projection> projections,
    EventRegistry events, {
    Iterable<String> sagaTypes = const [],
  }) {
    final errors = <String>[];
    final names = {...sagaTypes};
    for (final projection in projections) {
      final name = projection.name;
      if (!names.add(name)) {
        errors.add('Projection "$name" has the name of another handler');
      }
      if (projection.handledEventTypes.isEmpty) {
        errors.add('Projection "$name" has no event handlers');
      }
      for (final type in projection.unregisteredEventTypes(events)) {
        errors.add('Projection "$name" handles $type, which is not registered');
      }
    }
    return ValidationReport(errors: errors);
  }
}

/// What [DispatchGuard] does when a projection receives an event it has no
/// handler for.
enum ProjectionValidationMode {
  /// Skip the event silently, as spec §12.2 says.
  skip,

  /// Skip the event and log a warning, once per projection and event type.
  warn,

  /// Throw [MissingEventHandlerError]: every projection must handle every
  /// event it receives.
  strict,
}

/// Validates at dispatch time (spec §29.2).
final class DispatchGuard {
  /// Creates the guard.
  DispatchGuard({
    required this.dispatcher,
    required this.events,
    this.projectionMode = ProjectionValidationMode.skip,
    ValidationLogger? logger,
  }) : _logger = logger ?? defaultValidationLogger;

  /// Resolves commands.
  final CommandDispatcher dispatcher;

  /// The registered event types.
  final EventRegistry events;

  /// What happens when a projection has no handler for an event.
  final ProjectionValidationMode projectionMode;

  final ValidationLogger _logger;
  final _warned = <(String, String)>{};

  /// Checks that [command] has a handler and a pipeline.
  ///
  /// Throws [CommandHandlerNotRegisteredError] if it has no handler, and
  /// [InvalidConfigurationError] if its consistency mode has no pipeline.
  void validateCommand(Command command) {
    final registration = dispatcher.resolve(command);
    if (!dispatcher.canDispatch(command)) {
      final consistency = dispatcher.consistencyFor(command);
      throw InvalidConfigurationError(
        '${registration.commandType} needs the ${consistency.name} pipeline, '
        'which is not configured',
        context: {
          'commandType': registration.commandType,
          'consistency': consistency.name,
        },
      );
    }
  }

  /// Checks that [event]'s type is registered.
  ///
  /// Throws [UnknownEventTypeError] if it isn't.
  void validateEvent(DomainEvent event) {
    if (events.knows(event.eventName)) return;
    throw UnknownEventTypeError(
      'Event type ${event.eventName} is not registered',
      context: {'eventType': event.eventName, 'eventId': event.id.uuid},
    );
  }

  /// Applies [projectionMode] when [projection] receives [event].
  ///
  /// Throws [MissingEventHandlerError] in strict mode if [projection] has no
  /// handler for [event].
  void validateProjectionDispatch(Projection projection, DomainEvent event) {
    if (projectionMode == ProjectionValidationMode.skip) return;
    if (projection.handles(event)) return;
    final message =
        'Projection "${projection.name}" has no handler for '
        '${event.eventName}';
    switch (projectionMode) {
      case ProjectionValidationMode.skip:
        return;
      case ProjectionValidationMode.warn:
        if (_warned.add((projection.name, event.eventName))) _logger(message);
      case ProjectionValidationMode.strict:
        throw MissingEventHandlerError(
          message,
          context: {
            'projection': projection.name,
            'eventType': event.eventName,
            'eventId': event.id.uuid,
          },
        );
    }
  }
}
