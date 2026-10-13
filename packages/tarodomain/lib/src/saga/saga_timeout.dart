import 'package:uuid/uuid.dart';

import '../adapters/saga_store_adapter.dart';
import '../domain/domain_event.dart';
import '../domain/event_envelope.dart';
import '../domain/uuids.dart';

/// The synthetic event a saga gets when it has made no progress for too
/// long (spec §19.2). It is created by `SagaTimeoutScheduler` and handed
/// straight to the saga, never stored.
///
/// A saga reacts to it like any other event, usually by compensating:
///
/// ```dart
/// compensateWhen<SagaTimeout>((e) => getCompensationCommands());
/// ```
final class SagaTimeout extends DomainEvent {
  SagaTimeout._({required this.sagaType, required this.sagaId, this.lastStep});

  /// The timeout for the saga in [record], which was last updated at
  /// `record.updatedAt` and timed out [timeout] later.
  ///
  /// Its correlation ID is the saga ID. Its ID and timestamp are derived
  /// from the saga and its `updatedAt`, so a saga that times out again from
  /// the same state, after a crash, gets the same event and dispatches the
  /// same command IDs, which the pipeline skips as duplicates.
  factory SagaTimeout.forRecord(SagaRecord record, Duration timeout) {
    final occurredAt = record.updatedAt.add(timeout);
    final id = derivedUuidV7(
      occurredAt,
      'SagaTimeout/${record.sagaType}/${record.sagaId.uuid}/'
      '${record.updatedAt.microsecondsSinceEpoch}',
    );
    return DomainEvent.withEnvelope(
      EventEnvelope(
        id: id,
        correlationId: record.sagaId,
        occurredAt: occurredAt,
      ),
      () => SagaTimeout._(
        sagaType: record.sagaType,
        sagaId: record.sagaId,
        lastStep: record.currentStep,
      ),
    );
  }

  /// The type of the saga that timed out.
  final String sagaType;

  /// The saga that timed out.
  final UuidValue sagaId;

  /// The saga's step when it timed out, if it had one.
  final String? lastStep;

  @override
  String get eventName => 'SagaTimeout';

  @override
  Map<String, Object?> toData() => {
    'sagaType': sagaType,
    'sagaId': sagaId.uuid,
    'lastStep': lastStep,
  };
}
