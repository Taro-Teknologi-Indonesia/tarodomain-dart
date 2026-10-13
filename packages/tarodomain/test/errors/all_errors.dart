// One row per error code in spec §22.2.

import 'package:tarodomain/tarodomain.dart';

/// A constructor, its expected code and category.
typedef ErrorRow = (
  FrameworkError Function(String) create,
  String code,
  ErrorCategory category,
);

/// Every concrete error class.
final List<ErrorRow> allErrors = [
  (InvalidEventIdError.new, 'INVALID_EVENT_ID', ErrorCategory.domain),
  (
    InvalidCorrelationIdError.new,
    'INVALID_CORRELATION_ID',
    ErrorCategory.domain,
  ),
  (InvalidCausationIdError.new, 'INVALID_CAUSATION_ID', ErrorCategory.domain),
  (
    AggregateAlreadyExistsError.new,
    'AGGREGATE_ALREADY_EXISTS',
    ErrorCategory.domain,
  ),
  (AggregateNotFoundError.new, 'AGGREGATE_NOT_FOUND', ErrorCategory.domain),
  (
    InvalidAggregateStateError.new,
    'INVALID_AGGREGATE_STATE',
    ErrorCategory.domain,
  ),
  (CommandValidationError.new, 'COMMAND_VALIDATION', ErrorCategory.domain),
  (InvalidCommandIdError.new, 'INVALID_COMMAND_ID', ErrorCategory.domain),
  (
    InvalidCommandCorrelationIdError.new,
    'INVALID_COMMAND_CORRELATION_ID',
    ErrorCategory.domain,
  ),
  (
    InvalidCommandCausationIdError.new,
    'INVALID_COMMAND_CAUSATION_ID',
    ErrorCategory.domain,
  ),
  (
    SagaAlreadyCompletedError.new,
    'SAGA_ALREADY_COMPLETED',
    ErrorCategory.domain,
  ),
  (SagaAlreadyStartedError.new, 'SAGA_ALREADY_STARTED', ErrorCategory.domain),
  (SagaNotStartedError.new, 'SAGA_NOT_STARTED', ErrorCategory.domain),
  (CompensationFailedError.new, 'COMPENSATION_FAILED', ErrorCategory.domain),
  (SagaTimeoutError.new, 'SAGA_TIMEOUT', ErrorCategory.domain),
  (
    InvalidSagaTransitionError.new,
    'INVALID_SAGA_TRANSITION',
    ErrorCategory.domain,
  ),
  (ValueObjectInvalidError.new, 'VALUE_OBJECT_INVALID', ErrorCategory.domain),
  (IncomparableValueError.new, 'INCOMPARABLE_VALUE', ErrorCategory.domain),
  (
    ValueObjectConstructionFailedError.new,
    'VALUE_OBJECT_CONSTRUCTION_FAILED',
    ErrorCategory.domain,
  ),
  (
    OptimisticConcurrencyError.new,
    'OPTIMISTIC_CONCURRENCY',
    ErrorCategory.concurrency,
  ),
  (
    CommandAlreadyProcessedError.new,
    'COMMAND_ALREADY_PROCESSED',
    ErrorCategory.concurrency,
  ),
  (
    ConcurrentModificationConflictError.new,
    'CONCURRENT_MODIFICATION',
    ErrorCategory.concurrency,
  ),
  (EventStoreError.new, 'EVENT_STORE_ERROR', ErrorCategory.infrastructure),
  (
    EventAppendFailedError.new,
    'EVENT_APPEND_FAILED',
    ErrorCategory.infrastructure,
  ),
  (EventLoadFailedError.new, 'EVENT_LOAD_FAILED', ErrorCategory.infrastructure),
  (StreamNotFoundError.new, 'STREAM_NOT_FOUND', ErrorCategory.infrastructure),
  (
    SnapshotStoreError.new,
    'SNAPSHOT_STORE_ERROR',
    ErrorCategory.infrastructure,
  ),
  (
    SnapshotLoadFailedError.new,
    'SNAPSHOT_LOAD_FAILED',
    ErrorCategory.infrastructure,
  ),
  (
    SnapshotSaveFailedError.new,
    'SNAPSHOT_SAVE_FAILED',
    ErrorCategory.infrastructure,
  ),
  (EventBusError.new, 'EVENT_BUS_ERROR', ErrorCategory.infrastructure),
  (
    EventPublishFailedError.new,
    'EVENT_PUBLISH_FAILED',
    ErrorCategory.infrastructure,
  ),
  (
    EventHandlerFailedError.new,
    'EVENT_HANDLER_FAILED',
    ErrorCategory.infrastructure,
  ),
  (SagaStoreError.new, 'SAGA_STORE_ERROR', ErrorCategory.infrastructure),
  (ProjectionError.new, 'PROJECTION_ERROR', ErrorCategory.infrastructure),
  (
    ProjectionHandlerFailedError.new,
    'PROJECTION_HANDLER_FAILED',
    ErrorCategory.infrastructure,
  ),
  (
    ProjectionIdempotencyViolationError.new,
    'PROJECTION_IDEMPOTENCY_VIOLATION',
    ErrorCategory.infrastructure,
  ),
  (QueueError.new, 'QUEUE_ERROR', ErrorCategory.infrastructure),
  (SerializationError.new, 'SERIALIZATION_ERROR', ErrorCategory.infrastructure),
  (
    OperationTimeoutError.new,
    'OPERATION_TIMEOUT',
    ErrorCategory.infrastructure,
  ),
  (DeadLetterError.new, 'DEAD_LETTER', ErrorCategory.infrastructure),
  (
    MissingEventHandlerError.new,
    'MISSING_EVENT_HANDLER',
    ErrorCategory.configuration,
  ),
  (
    UnknownEventTypeError.new,
    'UNKNOWN_EVENT_TYPE',
    ErrorCategory.configuration,
  ),
  (
    DuplicateEventRegistrationError.new,
    'DUPLICATE_EVENT_REGISTRATION',
    ErrorCategory.configuration,
  ),
  (
    EventVersionMismatchError.new,
    'EVENT_VERSION_MISMATCH',
    ErrorCategory.configuration,
  ),
  (
    CommandHandlerNotRegisteredError.new,
    'COMMAND_HANDLER_NOT_REGISTERED',
    ErrorCategory.configuration,
  ),
  (
    InvalidConfigurationError.new,
    'INVALID_CONFIGURATION',
    ErrorCategory.configuration,
  ),
  (
    MissingDependencyError.new,
    'MISSING_DEPENDENCY',
    ErrorCategory.configuration,
  ),
  (
    AggregateNotRegisteredError.new,
    'AGGREGATE_NOT_REGISTERED',
    ErrorCategory.configuration,
  ),
  (
    ProjectionNotRegisteredError.new,
    'PROJECTION_NOT_REGISTERED',
    ErrorCategory.configuration,
  ),
  (
    SagaNotRegisteredError.new,
    'SAGA_NOT_REGISTERED',
    ErrorCategory.configuration,
  ),
  (
    CircularDependencyError.new,
    'CIRCULAR_DEPENDENCY',
    ErrorCategory.configuration,
  ),
];
