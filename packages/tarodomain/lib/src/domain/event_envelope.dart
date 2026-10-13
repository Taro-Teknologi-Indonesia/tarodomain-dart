import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../errors/error_codes.dart';
import '../errors/framework_error.dart';
import 'execution_context.dart';
import 'metadata.dart';
import 'uuids.dart';

/// The framework-owned fields of a [DomainEvent] (spec §2.1, §28.1).
final class EventEnvelope {
  /// Creates an envelope. [metadata] values must be primitives, and
  /// [occurredAt] is stored in UTC.
  ///
  /// Throws [InvalidEventIdError] if [id] is not a UUIDv7.
  EventEnvelope({
    required this.id,
    required this.correlationId,
    this.causationId,
    this.commandCausationId,
    Map<String, Object?> metadata = const {},
    required DateTime occurredAt,
  }) : metadata = freezeMetadata(metadata),
       occurredAt = occurredAt.toUtc() {
    if (!isUuidV7(id)) {
      throw InvalidEventIdError(
        'Event ID must be a UUIDv7: $id',
        context: {'value': id.uuid},
      );
    }
  }

  /// A new envelope for an event raised now: a fresh UUIDv7 ID, with tracing
  /// IDs and metadata from [context] (by default [ExecutionContext.current]).
  /// Without a context, the event starts a new trace.
  factory EventEnvelope.fromContext([ExecutionContext? context]) {
    context ??= ExecutionContext.current;
    return EventEnvelope(
      id: newUuidV7(),
      correlationId: context?.correlationId ?? newUuidV7(),
      causationId: context?.causationId,
      commandCausationId: context?.commandCausationId,
      metadata: context?.metadata ?? const {},
      occurredAt: DateTime.timestamp(),
    );
  }

  /// Reads an envelope written by [toJson], such as one loaded from storage.
  ///
  /// Throws [InvalidEventIdError], [InvalidCorrelationIdError] or
  /// [InvalidCausationIdError] when an ID is missing or malformed, and
  /// [SerializationError] when the timestamp or metadata is.
  factory EventEnvelope.fromJson(Map<String, Object?> json) {
    final id = _parseId(json['eventId'], 'eventId', InvalidEventIdError.new);
    final correlationId = _parseId(
      json['correlationId'],
      'correlationId',
      InvalidCorrelationIdError.new,
    );
    final causation = json['causationId'];
    final causationId = causation == null
        ? null
        : _parseId(causation, 'causationId', InvalidCausationIdError.new);
    final commandCausation = json['commandCausationId'];
    final commandCausationId = commandCausation == null
        ? null
        : _parseId(
            commandCausation,
            'commandCausationId',
            InvalidCausationIdError.new,
          );

    final occurredAt = switch (json['occurredAt']) {
      final String s => DateTime.tryParse(s),
      _ => null,
    };
    final metadata = json['metadata'] ?? const <String, Object?>{};
    if (occurredAt == null || metadata is! Map<String, Object?>) {
      throw SerializationError(
        'Malformed event envelope',
        context: {'eventId': id.uuid},
      );
    }
    return EventEnvelope(
      id: id,
      correlationId: correlationId,
      causationId: causationId,
      commandCausationId: commandCausationId,
      metadata: metadata,
      occurredAt: occurredAt,
    );
  }

  static UuidValue _parseId(
    Object? input,
    String field,
    FrameworkError Function(String, {Map<String, Object?> context}) error,
  ) {
    final uuid = input is String ? tryParseUuid(input) : null;
    if (uuid == null) {
      throw error('Invalid $field: $input', context: {'value': '$input'});
    }
    return uuid;
  }

  /// Globally unique, time-ordered event ID.
  final UuidValue id;

  /// End-to-end trace ID, inherited from the command.
  final UuidValue correlationId;

  /// ID of the command or event that caused this event, or null at the root.
  final UuidValue? causationId;

  /// When a command raised this event, that command's own causation ID,
  /// such as the event a saga reacted to; see
  /// [ExecutionContext.commandCausationId]. Lets a trace link the command
  /// in [causationId] back to its cause, since commands aren't stored.
  final UuidValue? commandCausationId;

  /// Free-form metadata, such as user or tenant ID.
  final Map<String, Object?> metadata;

  /// When the event was raised, in UTC.
  final DateTime occurredAt;

  /// JSON-safe form, read back by [EventEnvelope.fromJson].
  Map<String, Object?> toJson() => {
    'eventId': id.uuid,
    'correlationId': correlationId.uuid,
    'causationId': causationId?.uuid,
    if (commandCausationId case final id?) 'commandCausationId': id.uuid,
    'metadata': metadata,
    'occurredAt': occurredAt.toIso8601String(),
  };

  static const _mapEquality = MapEquality<String, Object?>();

  @override
  bool operator ==(Object other) =>
      other is EventEnvelope &&
      other.id == id &&
      other.correlationId == correlationId &&
      other.causationId == causationId &&
      other.commandCausationId == commandCausationId &&
      other.occurredAt == occurredAt &&
      _mapEquality.equals(other.metadata, metadata);

  @override
  int get hashCode => Object.hash(
    id,
    correlationId,
    causationId,
    commandCausationId,
    occurredAt,
    _mapEquality.hash(metadata),
  );

  @override
  String toString() =>
      'EventEnvelope(id: $id, correlationId: $correlationId, '
      'causationId: $causationId, occurredAt: $occurredAt)';
}
