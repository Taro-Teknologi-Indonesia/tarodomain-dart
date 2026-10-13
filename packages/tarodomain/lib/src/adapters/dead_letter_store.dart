import 'package:uuid/uuid.dart';

import '../domain/serialized_event.dart';

/// An event a handler gave up on, to quarantine (spec §21.1).
class DeadLetterInput {
  /// Creates the input.
  const DeadLetterInput({
    required this.handlerName,
    required this.event,
    required this.errorMessage,
    this.errorCode,
    required this.attempts,
  });

  /// The handler that failed.
  final String handlerName;

  /// The event it failed on.
  final SerializedEvent event;

  /// The last error's message.
  final String errorMessage;

  /// The last error's `FrameworkError.code`, if it was a framework error.
  final String? errorCode;

  /// How many times the handler was tried.
  final int attempts;

  /// The failed event's ID.
  UuidValue get eventId => event.eventId;
}

/// A quarantined event.
final class DeadLetterEntry extends DeadLetterInput {
  /// Creates the entry.
  const DeadLetterEntry({
    required this.id,
    required super.handlerName,
    required super.event,
    required super.errorMessage,
    super.errorCode,
    required super.attempts,
    required this.createdAt,
  });

  /// Store-assigned ID.
  final int id;

  /// When the entry was written, in UTC.
  final DateTime createdAt;

  @override
  String toString() =>
      'DeadLetterEntry($id, $handlerName, ${event.eventType} $eventId)';
}

/// Quarantine for events that failed after every retry (spec §21.1). Entries
/// are kept for 30 days.
abstract interface class DeadLetterStore {
  /// Stores [entry] and assigns it an ID.
  Future<void> write(DeadLetterInput entry);

  /// The entries for [handlerName], newest first, at most [limit] of them.
  Future<List<DeadLetterEntry>> list(String handlerName, {int? limit});

  /// The newest entry for [eventId] and [handlerName], or null.
  Future<DeadLetterEntry?> get(UuidValue eventId, String handlerName);

  /// The entry with [id], or null.
  Future<DeadLetterEntry?> getById(int id);

  /// Deletes the entry with [id]. Does nothing if it doesn't exist.
  Future<void> delete(int id);

  /// How many entries there are, optionally for one handler.
  Future<int> count({String? handlerName});

  /// Deletes entries written before [olderThan] and returns how many.
  Future<int> deleteOld(DateTime olderThan);
}
