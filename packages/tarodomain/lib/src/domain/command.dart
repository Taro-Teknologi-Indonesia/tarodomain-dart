import 'dart:async';

import 'package:uuid/uuid.dart';

import '../errors/error_codes.dart';
import 'execution_context.dart';
import 'metadata.dart';
import 'uuids.dart';

/// Intent to change system state (spec §2.2). Unlike an event, a command can
/// be rejected.
///
/// Subclasses declare their business fields as `final` and forward the
/// envelope parameters they want callers to set:
///
/// ```dart
/// class Deposit extends Command {
///   Deposit({required this.accountId, required this.cents, super.id});
///
///   final String accountId;
///   final int cents;
/// }
/// ```
///
/// Envelope fields not passed default from [ExecutionContext.current], so a
/// command created while handling an event is linked to it. Outside any
/// context, the command starts a new trace.
abstract class Command {
  /// Creates the command envelope. [metadata] values must be primitives.
  Command({
    UuidValue? id,
    UuidValue? correlationId,
    UuidValue? causationId,
    Map<String, Object?>? metadata,
    DateTime? timestamp,
  }) : id = id ?? _nextDerivedId() ?? newUuidV7(),
       correlationId =
           correlationId ??
           ExecutionContext.current?.correlationId ??
           newUuidV7(),
       causationId = causationId ?? ExecutionContext.current?.causationId,
       metadata = freezeMetadata(
         metadata ?? ExecutionContext.current?.metadata ?? const {},
       ),
       timestamp = (timestamp ?? DateTime.timestamp()).toUtc();

  /// Unique ID, also used as the idempotency key (spec §14.1). Generated as a
  /// UUIDv7 by default, or derived inside [withDerivedIds]; client-supplied
  /// IDs may be any UUID version.
  final UuidValue id;

  /// End-to-end trace ID.
  final UuidValue correlationId;

  /// ID of the event or command that caused this one, or null at the root.
  final UuidValue? causationId;

  /// Free-form metadata, such as user or tenant ID.
  final Map<String, Object?> metadata;

  /// When the command was created, in UTC.
  final DateTime timestamp;

  static final Object _derivedIdsKey = Object();

  static UuidValue? _nextDerivedId() {
    final slot = Zone.current[_derivedIdsKey] as _DerivedIds?;
    if (slot == null) return null;
    return derivedUuidV7(slot.time, '${slot.seed}/${slot.next++}');
  }

  /// Calls [create] so that commands constructed in it without an explicit
  /// ID get a UUIDv7 derived from [seed], [time] and the order they are
  /// constructed in. [time] is the ID's timestamp.
  ///
  /// Running the same deterministic [create] again with the same [seed] and
  /// [time] gives the same IDs, so command idempotency (spec §14.1)
  /// recognizes the commands as already processed. Sagas use it with the
  /// event they handle as the seed and its `occurredAt` as the time, so an
  /// event delivered again doesn't run its commands twice.
  static R withDerivedIds<R>(
    String seed,
    R Function() create, {
    required DateTime time,
  }) => runZoned(create, zoneValues: {_derivedIdsKey: _DerivedIds(seed, time)});

  /// Parses a client-supplied command ID.
  ///
  /// Throws [InvalidCommandIdError] if [input] is not a valid UUID.
  static UuidValue parseId(String input) =>
      tryParseUuid(input) ??
      (throw InvalidCommandIdError(
        'Not a valid command ID: "$input"',
        context: {'value': input},
      ));

  /// Parses a client-supplied correlation ID, such as an `x-request-id`.
  ///
  /// Throws [InvalidCommandCorrelationIdError] if [input] is not a valid UUID.
  static UuidValue parseCorrelationId(String input) =>
      tryParseUuid(input) ??
      (throw InvalidCommandCorrelationIdError(
        'Not a valid command correlation ID: "$input"',
        context: {'value': input},
      ));

  /// Parses a client-supplied causation ID.
  ///
  /// Throws [InvalidCommandCausationIdError] if [input] is not a valid UUID.
  static UuidValue parseCausationId(String input) =>
      tryParseUuid(input) ??
      (throw InvalidCommandCausationIdError(
        'Not a valid command causation ID: "$input"',
        context: {'value': input},
      ));
}

class _DerivedIds {
  _DerivedIds(this.seed, this.time);

  final String seed;
  final DateTime time;
  int next = 0;
}
