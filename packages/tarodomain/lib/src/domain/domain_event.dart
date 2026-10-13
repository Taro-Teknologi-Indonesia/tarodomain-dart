import 'dart:async';

import 'package:uuid/uuid.dart';

import 'event_envelope.dart';
import 'execution_context.dart';
import 'serialized_event.dart';

/// Immutable record of something that happened in the domain (spec §2.1).
///
/// Subclasses declare business fields as `final` constructor parameters and
/// name the event:
///
/// ```dart
/// class MoneyDeposited extends DomainEvent {
///   MoneyDeposited({required this.cents});
///
///   final int cents;
///
///   @override
///   String get eventName => 'MoneyDeposited';
///
///   @override
///   Map<String, Object?> toData() => {'cents': cents};
/// }
/// ```
///
/// The [envelope] is assigned on construction and never changes. Its tracing
/// IDs and metadata come from [ExecutionContext.current], so an event raised
/// while a command is handled is linked to that command without any extra
/// step. To give an event a specific envelope, as rehydration from storage
/// does, construct it inside [withEnvelope].
abstract class DomainEvent {
  /// Creates the event with an envelope taken from [withEnvelope] if one is
  /// pending, otherwise from [ExecutionContext.current].
  DomainEvent() : envelope = _takePending() ?? EventEnvelope.fromContext();

  /// Framework-owned fields: ID, tracing IDs, metadata and timestamp.
  final EventEnvelope envelope;

  /// Type name stored with the event. Use a literal, not `runtimeType`,
  /// which changes under obfuscation.
  String get eventName;

  /// Schema version in semver form, used by upcasters. Override when the
  /// business fields change.
  String get eventVersion => '1.0.0';

  /// The business fields as JSON-safe data.
  Map<String, Object?> toData();

  /// Globally unique, time-ordered event ID.
  UuidValue get id => envelope.id;

  /// End-to-end trace ID.
  UuidValue get correlationId => envelope.correlationId;

  /// ID of the command or event that caused this event, or null at the root.
  UuidValue? get causationId => envelope.causationId;

  /// The causation ID of the command that raised this event, if any; see
  /// [EventEnvelope.commandCausationId].
  UuidValue? get commandCausationId => envelope.commandCausationId;

  /// Free-form metadata, such as user or tenant ID.
  Map<String, Object?> get metadata => envelope.metadata;

  /// When the event was raised, in UTC.
  DateTime get occurredAt => envelope.occurredAt;

  /// The event in storable form.
  SerializedEvent serialize() => SerializedEvent(
    eventType: eventName,
    eventVersion: eventVersion,
    envelope: envelope,
    data: toData(),
  );

  static final Object _pendingKey = Object();

  static EventEnvelope? _takePending() {
    final slot = Zone.current[_pendingKey] as _EnvelopeSlot?;
    final envelope = slot?.envelope;
    slot?.envelope = null;
    return envelope;
  }

  /// Calls [create] so that the event it constructs gets [envelope].
  ///
  /// Only the first event constructed inside [create] takes the envelope.
  /// Throws [StateError] if [create] returns an event without it.
  static E withEnvelope<E extends DomainEvent>(
    EventEnvelope envelope,
    E Function() create,
  ) {
    final event = runZoned(
      create,
      zoneValues: {_pendingKey: _EnvelopeSlot(envelope)},
    );
    if (!identical(event.envelope, envelope)) {
      throw StateError(
        'withEnvelope: the returned ${event.eventName} was not the first '
        'event constructed inside create',
      );
    }
    return event;
  }

  @override
  String toString() => '$eventName(${toData()}, id: $id)';
}

class _EnvelopeSlot {
  _EnvelopeSlot(this.envelope);

  EventEnvelope? envelope;
}
