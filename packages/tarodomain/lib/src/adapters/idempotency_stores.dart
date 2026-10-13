import 'package:uuid/uuid.dart';

/// Records which events each projection or saga has handled (spec §12.3,
/// §14.2), keyed by `(handlerName, handlerInstance, eventId)`.
///
/// For a projection, both names are the projection name (or the shard name
/// as the instance). For a saga, [handlerName] is the saga type and
/// `handlerInstance` the saga ID.
abstract interface class ProcessedEventStore {
  /// Whether the event was already handled.
  Future<bool> exists(
    String handlerName,
    String handlerInstance,
    UuidValue eventId,
  );

  /// Records the event as handled. Recording it twice is not an error.
  Future<void> markProcessed(
    String handlerName,
    String handlerInstance,
    UuidValue eventId,
  );

  /// How many events [handlerName] has handled, optionally for one instance.
  Future<int> count(String handlerName, {String? handlerInstance});

  /// Forgets the events [handlerName] handled, optionally for one instance,
  /// as a rebuild does. Returns how many records were deleted.
  Future<int> deleteByHandler(String handlerName, {String? handlerInstance});

  /// Deletes records written before [olderThan] and returns how many.
  Future<int> deleteOld(DateTime olderThan);
}

/// A command recorded by [CommandIdempotencyStore].
final class ProcessedCommand {
  /// Creates the record.
  const ProcessedCommand({
    required this.commandId,
    required this.commandType,
    required this.handlerName,
    required this.processedAt,
  });

  /// The command's ID.
  final UuidValue commandId;

  /// The command type name.
  final String commandType;

  /// The handler that processed it.
  final String handlerName;

  /// When it was recorded, in UTC.
  final DateTime processedAt;
}

/// Records processed command IDs so a retried command is not applied twice
/// (spec §14.1). Records are kept for 7 days.
abstract interface class CommandIdempotencyStore {
  /// Whether [commandId] was already processed.
  Future<bool> exists(UuidValue commandId);

  /// Records [commandId] as processed. Recording it twice keeps the first
  /// record.
  Future<void> markProcessed(
    UuidValue commandId,
    String commandType,
    String handlerName,
  );

  /// When [commandId] was processed, or null if it wasn't.
  Future<DateTime?> getProcessedAt(UuidValue commandId);

  /// How many commands were recorded, optionally for one handler.
  Future<int> count({String? handlerName});

  /// The commands [handlerName] processed, newest first, at most [limit].
  Future<List<ProcessedCommand>> list(String handlerName, {int? limit});

  /// Deletes records written before [olderThan] and returns how many.
  Future<int> deleteOld(DateTime olderThan);
}
