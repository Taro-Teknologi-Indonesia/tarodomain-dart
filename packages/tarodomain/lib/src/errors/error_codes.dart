// Error classes for every code in spec §22.2, grouped by category.

import 'framework_error.dart';

// Domain (19 codes)

/// An event ID is not a valid UUIDv7.
final class InvalidEventIdError extends DomainError {
  /// Creates the error with a human-readable [message].
  InvalidEventIdError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'INVALID_EVENT_ID';
}

/// An event correlation ID is not a valid UUID.
final class InvalidCorrelationIdError extends DomainError {
  /// Creates the error with a human-readable [message].
  InvalidCorrelationIdError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'INVALID_CORRELATION_ID';
}

/// An event causation ID is not a valid UUID.
final class InvalidCausationIdError extends DomainError {
  /// Creates the error with a human-readable [message].
  InvalidCausationIdError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'INVALID_CAUSATION_ID';
}

/// An aggregate with this ID already exists.
final class AggregateAlreadyExistsError extends DomainError {
  /// Creates the error with a human-readable [message].
  AggregateAlreadyExistsError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'AGGREGATE_ALREADY_EXISTS';
}

/// No aggregate exists with this ID.
final class AggregateNotFoundError extends DomainError {
  /// Creates the error with a human-readable [message].
  AggregateNotFoundError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'AGGREGATE_NOT_FOUND';
}

/// The aggregate is in a state that does not allow the operation.
final class InvalidAggregateStateError extends DomainError {
  /// Creates the error with a human-readable [message].
  InvalidAggregateStateError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'INVALID_AGGREGATE_STATE';
}

/// A command failed validation.
final class CommandValidationError extends DomainError {
  /// Creates the error with a human-readable [message].
  CommandValidationError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'COMMAND_VALIDATION';
}

/// A command ID is not a valid UUID.
final class InvalidCommandIdError extends DomainError {
  /// Creates the error with a human-readable [message].
  InvalidCommandIdError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'INVALID_COMMAND_ID';
}

/// A command correlation ID is not a valid UUID.
final class InvalidCommandCorrelationIdError extends DomainError {
  /// Creates the error with a human-readable [message].
  InvalidCommandCorrelationIdError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'INVALID_COMMAND_CORRELATION_ID';
}

/// A command causation ID is not a valid UUID.
final class InvalidCommandCausationIdError extends DomainError {
  /// Creates the error with a human-readable [message].
  InvalidCommandCausationIdError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'INVALID_COMMAND_CAUSATION_ID';
}

/// The saga has already reached a terminal state.
final class SagaAlreadyCompletedError extends DomainError {
  /// Creates the error with a human-readable [message].
  SagaAlreadyCompletedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'SAGA_ALREADY_COMPLETED';
}

/// A saga with this correlation ID has already started.
final class SagaAlreadyStartedError extends DomainError {
  /// Creates the error with a human-readable [message].
  SagaAlreadyStartedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'SAGA_ALREADY_STARTED';
}

/// No saga has started for this correlation ID.
final class SagaNotStartedError extends DomainError {
  /// Creates the error with a human-readable [message].
  SagaNotStartedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'SAGA_NOT_STARTED';
}

/// A compensating command failed.
final class CompensationFailedError extends DomainError {
  /// Creates the error with a human-readable [message].
  CompensationFailedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'COMPENSATION_FAILED';
}

/// The saga did not complete before its timeout.
final class SagaTimeoutError extends DomainError {
  /// Creates the error with a human-readable [message].
  SagaTimeoutError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'SAGA_TIMEOUT';
}

/// The saga state machine does not allow this transition.
final class InvalidSagaTransitionError extends DomainError {
  /// Creates the error with a human-readable [message].
  InvalidSagaTransitionError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'INVALID_SAGA_TRANSITION';
}

/// A value object failed its invariants.
final class ValueObjectInvalidError extends DomainError {
  /// Creates the error with a human-readable [message].
  ValueObjectInvalidError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'VALUE_OBJECT_INVALID';
}

/// Two value objects of different types were compared.
final class IncomparableValueError extends DomainError {
  /// Creates the error with a human-readable [message].
  IncomparableValueError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'INCOMPARABLE_VALUE';
}

/// Value object validation threw an unexpected error.
final class ValueObjectConstructionFailedError extends DomainError {
  /// Creates the error with a human-readable [message].
  ValueObjectConstructionFailedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'VALUE_OBJECT_CONSTRUCTION_FAILED';
}

// Concurrency (3 codes)

/// The stream moved past the expected version.
final class OptimisticConcurrencyError extends ConcurrencyError {
  /// Creates the error with a human-readable [message].
  OptimisticConcurrencyError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'OPTIMISTIC_CONCURRENCY';
}

/// A command with this ID has already been processed.
final class CommandAlreadyProcessedError extends ConcurrencyError {
  /// Creates the error with a human-readable [message].
  CommandAlreadyProcessedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'COMMAND_ALREADY_PROCESSED';
}

/// A record was modified concurrently.
///
/// Not named `ConcurrentModificationError`, which would shadow the
/// `dart:core` class of the same name.
final class ConcurrentModificationConflictError extends ConcurrencyError {
  /// Creates the error with a human-readable [message].
  ConcurrentModificationConflictError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'CONCURRENT_MODIFICATION';
}

// Infrastructure (18 codes)

/// The event store failed.
final class EventStoreError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  EventStoreError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'EVENT_STORE_ERROR';
}

/// Appending events to a stream failed.
final class EventAppendFailedError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  EventAppendFailedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'EVENT_APPEND_FAILED';
}

/// Loading events failed.
final class EventLoadFailedError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  EventLoadFailedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'EVENT_LOAD_FAILED';
}

/// The event stream does not exist.
final class StreamNotFoundError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  StreamNotFoundError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'STREAM_NOT_FOUND';
}

/// The snapshot store failed.
final class SnapshotStoreError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  SnapshotStoreError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'SNAPSHOT_STORE_ERROR';
}

/// Loading a snapshot failed.
final class SnapshotLoadFailedError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  SnapshotLoadFailedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'SNAPSHOT_LOAD_FAILED';
}

/// Saving a snapshot failed.
final class SnapshotSaveFailedError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  SnapshotSaveFailedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'SNAPSHOT_SAVE_FAILED';
}

/// The event bus failed.
final class EventBusError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  EventBusError(super.message, {super.context, super.cause, super.stackTrace});

  @override
  String get code => 'EVENT_BUS_ERROR';
}

/// Publishing an event failed.
final class EventPublishFailedError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  EventPublishFailedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'EVENT_PUBLISH_FAILED';
}

/// An event handler threw.
final class EventHandlerFailedError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  EventHandlerFailedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'EVENT_HANDLER_FAILED';
}

/// The saga store failed.
final class SagaStoreError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  SagaStoreError(super.message, {super.context, super.cause, super.stackTrace});

  @override
  String get code => 'SAGA_STORE_ERROR';
}

/// A projection failed.
final class ProjectionError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  ProjectionError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'PROJECTION_ERROR';
}

/// A projection handler threw.
final class ProjectionHandlerFailedError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  ProjectionHandlerFailedError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'PROJECTION_HANDLER_FAILED';
}

/// A projection processed the same event twice.
final class ProjectionIdempotencyViolationError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  ProjectionIdempotencyViolationError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'PROJECTION_IDEMPOTENCY_VIOLATION';
}

/// The message queue failed.
final class QueueError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  QueueError(super.message, {super.context, super.cause, super.stackTrace});

  @override
  String get code => 'QUEUE_ERROR';
}

/// Serializing or deserializing a message failed.
final class SerializationError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  SerializationError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'SERIALIZATION_ERROR';
}

/// An operation timed out.
final class OperationTimeoutError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  OperationTimeoutError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'OPERATION_TIMEOUT';
}

/// A message was moved to the dead letter queue.
final class DeadLetterError extends InfrastructureError {
  /// Creates the error with a human-readable [message].
  DeadLetterError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'DEAD_LETTER';
}

// Configuration (11 codes)

/// An aggregate has no handler for an event it raised or loaded.
final class MissingEventHandlerError extends ConfigurationError {
  /// Creates the error with a human-readable [message].
  MissingEventHandlerError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'MISSING_EVENT_HANDLER';
}

/// No event is registered under this type name.
final class UnknownEventTypeError extends ConfigurationError {
  /// Creates the error with a human-readable [message].
  UnknownEventTypeError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'UNKNOWN_EVENT_TYPE';
}

/// An event type and version were registered twice.
final class DuplicateEventRegistrationError extends ConfigurationError {
  /// Creates the error with a human-readable [message].
  DuplicateEventRegistrationError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'DUPLICATE_EVENT_REGISTRATION';
}

/// No upcaster chain leads from the stored version to the registered one.
final class EventVersionMismatchError extends ConfigurationError {
  /// Creates the error with a human-readable [message].
  EventVersionMismatchError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'EVENT_VERSION_MISMATCH';
}

/// No handler is registered for this command.
final class CommandHandlerNotRegisteredError extends ConfigurationError {
  /// Creates the error with a human-readable [message].
  CommandHandlerNotRegisteredError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'COMMAND_HANDLER_NOT_REGISTERED';
}

/// The framework configuration is invalid.
final class InvalidConfigurationError extends ConfigurationError {
  /// Creates the error with a human-readable [message].
  InvalidConfigurationError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'INVALID_CONFIGURATION';
}

/// A dependency was not registered in the container.
final class MissingDependencyError extends ConfigurationError {
  /// Creates the error with a human-readable [message].
  MissingDependencyError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'MISSING_DEPENDENCY';
}

/// The aggregate type is not registered.
final class AggregateNotRegisteredError extends ConfigurationError {
  /// Creates the error with a human-readable [message].
  AggregateNotRegisteredError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'AGGREGATE_NOT_REGISTERED';
}

/// The projection is not registered.
final class ProjectionNotRegisteredError extends ConfigurationError {
  /// Creates the error with a human-readable [message].
  ProjectionNotRegisteredError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'PROJECTION_NOT_REGISTERED';
}

/// The saga is not registered.
final class SagaNotRegisteredError extends ConfigurationError {
  /// Creates the error with a human-readable [message].
  SagaNotRegisteredError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'SAGA_NOT_REGISTERED';
}

/// The container found a dependency cycle.
final class CircularDependencyError extends ConfigurationError {
  /// Creates the error with a human-readable [message].
  CircularDependencyError(
    super.message, {
    super.context,
    super.cause,
    super.stackTrace,
  });

  @override
  String get code => 'CIRCULAR_DEPENDENCY';
}
