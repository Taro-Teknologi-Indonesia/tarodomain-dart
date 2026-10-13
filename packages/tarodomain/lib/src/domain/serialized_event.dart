import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../errors/error_codes.dart';
import 'event_envelope.dart';

/// A [DomainEvent] in storable form (spec §2.1): its type, schema version,
/// envelope and business fields as JSON-safe data.
///
/// Adapters store and return this type. `EventStore` converts between it and
/// typed events.
final class SerializedEvent {
  /// Creates a serialized event. [data] is copied into an unmodifiable map.
  SerializedEvent({
    required this.eventType,
    required this.eventVersion,
    required this.envelope,
    required Map<String, Object?> data,
  }) : data = Map.unmodifiable(data);

  /// Reads an event written by [toJson], such as a queue message.
  ///
  /// Throws [SerializationError] when the type, version or data is missing,
  /// and the errors of [EventEnvelope.fromJson] when the envelope is
  /// malformed.
  factory SerializedEvent.fromJson(Map<String, Object?> json) {
    final envelope = EventEnvelope.fromJson(json);
    final (eventType, eventVersion, data) = (
      json['eventType'],
      json['eventVersion'],
      json['data'],
    );
    if (eventType is! String ||
        eventVersion is! String ||
        data is! Map<String, Object?>) {
      throw SerializationError(
        'Malformed serialized event',
        context: {'eventId': envelope.id.uuid},
      );
    }
    return SerializedEvent(
      eventType: eventType,
      eventVersion: eventVersion,
      envelope: envelope,
      data: data,
    );
  }

  /// The event's `eventName`.
  final String eventType;

  /// The schema version the [data] was written with.
  final String eventVersion;

  /// ID, tracing IDs, metadata and timestamp.
  final EventEnvelope envelope;

  /// The business fields.
  final Map<String, Object?> data;

  /// Globally unique, time-ordered event ID.
  UuidValue get eventId => envelope.id;

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

  /// Returns a copy with a different schema version and data, as an upcaster
  /// produces.
  SerializedEvent withData(String eventVersion, Map<String, Object?> data) =>
      SerializedEvent(
        eventType: eventType,
        eventVersion: eventVersion,
        envelope: envelope,
        data: data,
      );

  /// JSON-safe form, read back by [SerializedEvent.fromJson].
  Map<String, Object?> toJson() => {
    'eventType': eventType,
    'eventVersion': eventVersion,
    ...envelope.toJson(),
    'data': data,
  };

  static const _equality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      other is SerializedEvent &&
      other.eventType == eventType &&
      other.eventVersion == eventVersion &&
      other.envelope == envelope &&
      _equality.equals(other.data, data);

  @override
  int get hashCode =>
      Object.hash(eventType, eventVersion, envelope, _equality.hash(data));

  @override
  String toString() =>
      'SerializedEvent($eventType@$eventVersion, id: $eventId, data: $data)';
}
