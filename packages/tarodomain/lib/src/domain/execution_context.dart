import 'dart:async';

import 'package:uuid/uuid.dart';

import 'command.dart';
import 'domain_event.dart';
import 'metadata.dart';

/// Tracing IDs for the command or event being handled (spec §5.5).
///
/// The pipeline runs each handler inside [run]. Events and commands created
/// in that scope default their `correlationId`, `causationId` and `metadata`
/// to the context's, which links them to their cause (spec §28.2).
///
/// The context is stored in a [Zone], so each request has its own and
/// concurrent requests can't see each other's. This removes the caveat in
/// spec §5.5.
final class ExecutionContext {
  /// Creates a context. [metadata] values must be primitives.
  ExecutionContext({
    required this.correlationId,
    this.causationId,
    this.commandCausationId,
    Map<String, Object?> metadata = const {},
  }) : metadata = freezeMetadata(metadata);

  /// The context for handling [command]: its correlation ID, with the
  /// command as the cause, and the command's own cause as
  /// [commandCausationId].
  factory ExecutionContext.forCommand(Command command) => ExecutionContext(
    correlationId: command.correlationId,
    causationId: command.id,
    commandCausationId: command.causationId,
    metadata: command.metadata,
  );

  /// The context for reacting to [event], for example in a saga: its
  /// correlation ID, with the event as the cause.
  factory ExecutionContext.forEvent(DomainEvent event) => ExecutionContext(
    correlationId: event.correlationId,
    causationId: event.id,
    metadata: event.metadata,
  );

  static final Object _zoneKey = Object();

  /// The context of the current zone, or null outside [run].
  static ExecutionContext? get current =>
      Zone.current[_zoneKey] as ExecutionContext?;

  /// Runs [body] with [context] as [current], including any asynchronous
  /// work [body] starts.
  static R run<R>(ExecutionContext context, R Function() body) =>
      runZoned(body, zoneValues: {_zoneKey: context});

  /// End-to-end trace ID shared by everything in one business transaction.
  final UuidValue correlationId;

  /// ID of the command or event being handled, or null at the root.
  final UuidValue? causationId;

  /// While a command is handled, the command's own `causationId`, such as
  /// the event a saga reacted to. Events record it, because commands aren't
  /// stored, so that a trace can link each command back to its cause
  /// (spec §28.3). Null outside a command, or for a root command.
  final UuidValue? commandCausationId;

  /// Metadata, such as user or tenant ID, inherited by new messages.
  final Map<String, Object?> metadata;
}
