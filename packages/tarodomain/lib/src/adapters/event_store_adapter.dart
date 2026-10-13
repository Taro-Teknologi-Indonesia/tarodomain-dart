import 'package:uuid/uuid.dart';

import '../domain/aggregate_id.dart';
import '../domain/serialized_event.dart';
import '../errors/error_codes.dart';

/// Stream ID conventions (spec §3.1).
abstract final class StreamIds {
  /// The global stream of every event.
  static const all = r'$all';

  /// The stream of one aggregate, such as `BankAccount-01909e3c-…`.
  ///
  /// [aggregateType] is also the stream's category, so it must not contain
  /// `-`.
  static String forAggregate(String aggregateType, AggregateId id) =>
      '$aggregateType-${id.uuid}';

  /// The category of [streamId]: the part before the first `-`.
  static String categoryOf(String streamId) => streamId.split('-').first;
}

/// Result of [EventStoreAdapter.appendToStream].
final class AppendResult {
  /// Creates the result.
  const AppendResult({required this.streamId, required this.version});

  /// The stream appended to.
  final String streamId;

  /// The stream version after the append: the version of its last event.
  final int version;

  @override
  String toString() => 'AppendResult($streamId, version: $version)';
}

/// Metadata about one stream.
final class StreamMetadata {
  /// Creates the metadata.
  const StreamMetadata({
    required this.streamId,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  /// The stream ID.
  final String streamId;

  /// The version of the stream's last event.
  final int version;

  /// When the first event was appended, in UTC.
  final DateTime createdAt;

  /// When the last event was appended, in UTC.
  final DateTime updatedAt;
}

/// A persistent catch-up cursor (spec §18.1).
final class Subscription {
  /// Creates the subscription.
  const Subscription({
    required this.name,
    this.streamId,
    this.lastSeen,
    required this.createdAt,
  });

  /// Unique subscription name.
  final String name;

  /// The stream followed: an aggregate stream, a category, or null for
  /// [StreamIds.all].
  final String? streamId;

  /// ID of the last processed event, or null before the first ack.
  final UuidValue? lastSeen;

  /// When the subscription was created, in UTC.
  final DateTime createdAt;

  @override
  String toString() =>
      'Subscription($name, streamId: $streamId, lastSeen: $lastSeen)';
}

/// Storage for the append-only event log (spec §3.2).
///
/// Versions count from 1: a stream that doesn't exist has version 0, and its
/// first event has version 1.
///
/// Reads across streams return events in global append order. Event IDs are
/// UUIDv7, so that order matches event ID order except between events from
/// the same millisecond, which UUIDv7 doesn't order. A cursor event ID
/// (`afterEventId`) marks a position in that order.
///
/// Every method is asynchronous. Under a unit of work, implementations join
/// the active transaction.
abstract interface class EventStoreAdapter {
  /// Appends [events] to [streamId], all or nothing.
  ///
  /// [expectedVersion] is the version the caller last saw (0 for a new
  /// stream). Throws [OptimisticConcurrencyError] if the stream's version is
  /// different. An empty [events] still checks the version but writes
  /// nothing.
  Future<AppendResult> appendToStream(
    String streamId,
    List<SerializedEvent> events,
    int expectedVersion,
  );

  /// The events of [streamId] with a version greater than [fromVersion], in
  /// version order, at most [maxCount] of them. Empty if the stream doesn't
  /// exist.
  Future<List<SerializedEvent>> loadStream(
    String streamId, {
    int fromVersion = 0,
    int? maxCount,
  });

  /// The events of [streamId] after the event [afterEventId] (from the start
  /// if null), in append order, at most [maxCount] of them.
  ///
  /// [streamId] is an aggregate stream, a category (every stream whose ID
  /// starts with `category-`), or [StreamIds.all].
  Future<List<SerializedEvent>> loadStreamAfterEvent(
    String streamId, {
    UuidValue? afterEventId,
    int? maxCount,
  });

  /// Every event after [afterEventId] (from the start if null), in append
  /// order, at most [maxCount] of them.
  Future<List<SerializedEvent>> loadAll({
    UuidValue? afterEventId,
    int? maxCount,
  });

  /// Every event with [correlationId], in append order.
  Future<List<SerializedEvent>> loadByCorrelationId(UuidValue correlationId);

  /// Whether [streamId] has at least one event.
  Future<bool> streamExists(String streamId);

  /// The version of [streamId], or 0 if it doesn't exist.
  Future<int> getStreamVersion(String streamId);

  /// Metadata of [streamId], or null if it doesn't exist.
  Future<StreamMetadata?> getStreamMetadata(String streamId);

  /// Deletes [streamId] and its events. Does nothing if it doesn't exist.
  Future<void> deleteStream(String streamId);

  /// Creates the subscription [name] following [streamId] (null for
  /// [StreamIds.all]), or returns it unchanged if it already exists.
  Future<Subscription> subscribe(String name, {String? streamId});

  /// The subscription [name], or null if it doesn't exist.
  Future<Subscription?> getSubscription(String name);

  /// Moves the cursor of subscription [name] to [lastSeenEventId].
  ///
  /// Throws [StateError] if the subscription doesn't exist.
  Future<void> ackSubscription(String name, UuidValue lastSeenEventId);

  /// Deletes the subscription [name]. Does nothing if it doesn't exist.
  Future<void> deleteSubscription(String name);

  /// Every subscription, ordered by name.
  Future<List<Subscription>> listSubscriptions();
}
