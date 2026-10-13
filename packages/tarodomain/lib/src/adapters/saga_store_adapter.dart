import 'package:uuid/uuid.dart';

/// Stored status of a saga (spec §13.1). The state machine's `INITIAL` state
/// is never stored.
enum SagaStatus {
  /// Started and making progress.
  running('RUNNING'),

  /// Undoing completed steps.
  compensating('COMPENSATING'),

  /// Finished. Terminal.
  completed('COMPLETED'),

  /// Gave up. Terminal.
  failed('FAILED');

  const SagaStatus(this.code);

  /// The stored form, as in the spec.
  final String code;

  /// Whether no further transitions are allowed.
  bool get isTerminal => this == completed || this == failed;

  /// The status whose [code] is [code].
  ///
  /// Throws [ArgumentError] for an unknown code.
  static SagaStatus fromCode(String code) => values.firstWhere(
    (s) => s.code == code,
    orElse: () => throw ArgumentError.value(code, 'code', 'Unknown status'),
  );
}

/// Saga state to store (spec §9.2).
class SagaSaveInput {
  /// Creates the input. [state] is copied into an unmodifiable map.
  SagaSaveInput({
    required this.sagaId,
    required this.sagaType,
    required this.correlationId,
    required Map<String, Object?> state,
    required this.status,
    this.currentStep,
    this.failureReason,
  }) : state = Map.unmodifiable(state);

  /// Saga instance ID, equal to the correlation ID of the starting event.
  final UuidValue sagaId;

  /// The saga type name.
  final String sagaType;

  /// Correlation ID shared by the saga's events and commands.
  final UuidValue correlationId;

  /// The saga's state as JSON-safe data.
  final Map<String, Object?> state;

  /// The current status.
  final SagaStatus status;

  /// Name of the current step, if the saga tracks one.
  final String? currentStep;

  /// Why the saga failed, when [status] is [SagaStatus.failed].
  final String? failureReason;
}

/// A stored saga.
final class SagaRecord extends SagaSaveInput {
  /// Creates the record.
  SagaRecord({
    required super.sagaId,
    required super.sagaType,
    required super.correlationId,
    required super.state,
    required super.status,
    super.currentStep,
    super.failureReason,
    required this.startedAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// When the saga was first saved, in UTC.
  final DateTime startedAt;

  /// When the saga was last saved, in UTC.
  final DateTime updatedAt;

  /// When the saga reached a terminal status, in UTC.
  final DateTime? completedAt;

  @override
  String toString() => 'SagaRecord($sagaType/$sagaId, ${status.code})';
}

/// Storage for saga state (spec §9.1), keyed by `(sagaType, sagaId)`.
abstract interface class SagaStoreAdapter {
  /// Inserts or replaces the saga. An update keeps the original `startedAt`
  /// and sets `updatedAt` to now.
  Future<void> save(SagaSaveInput input);

  /// The saga, or null if it doesn't exist.
  Future<SagaRecord?> load(String sagaType, UuidValue sagaId);

  /// The saga started by the event with [correlationId], or null. Since the
  /// saga ID is that correlation ID, this is a lookup by ID.
  Future<SagaRecord?> loadByCorrelationId(
    String sagaType,
    UuidValue correlationId,
  );

  /// Marks the saga [SagaStatus.completed] and sets `completedAt`. Does
  /// nothing if it is already terminal or doesn't exist.
  Future<void> complete(String sagaType, UuidValue sagaId);

  /// Marks the saga [SagaStatus.failed] with [reason] and sets `completedAt`.
  /// Does nothing if it is already terminal or doesn't exist.
  Future<void> fail(String sagaType, UuidValue sagaId, String reason);

  /// Sagas with [status], oldest `updatedAt` first, at most [limit] of them.
  Future<List<SagaRecord>> loadByStatus(SagaStatus status, {int? limit});

  /// Running or compensating sagas last updated before [before], oldest
  /// first, at most [limit] of them (spec §19.1). With [sagaType], only
  /// sagas of that type.
  Future<List<SagaRecord>> loadTimedOut(
    DateTime before, {
    String? sagaType,
    int? limit,
  });

  /// Deletes the saga. Does nothing if it doesn't exist.
  Future<void> delete(String sagaType, UuidValue sagaId);

  /// How many sagas match [sagaType] and [status]; null matches any.
  Future<int> count({String? sagaType, SagaStatus? status});
}
