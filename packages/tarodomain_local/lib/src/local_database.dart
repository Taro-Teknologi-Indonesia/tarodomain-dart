import 'package:meta/meta.dart';
import 'package:tarodomain/tarodomain.dart';

/// The in-memory storage shared by the adapters of one `LocalProvider`.
///
/// Every value it holds is immutable, so [InMemoryUnitOfWork] can take a
/// cheap copy on begin and put it back on rollback.
final class LocalDatabase {
  /// Creates an empty database. [clock] supplies the timestamps the adapters
  /// record, such as `createdAt`; it defaults to the current time in UTC.
  LocalDatabase({DateTime Function()? clock})
    : _clock = clock ?? DateTime.timestamp;

  final DateTime Function() _clock;

  /// The current time in UTC, from the clock.
  DateTime now() => _clock().toUtc();

  /// The live tables. Adapters read and write these.
  @internal
  LocalTables tables = LocalTables();

  /// Identifies this database's active unit of work in a zone.
  @internal
  final Object unitOfWorkKey = Object();

  /// The tail of the queue of units of work waiting to begin. Units of work
  /// on one database run one at a time, so a rollback can't undo another
  /// unit's writes.
  @internal
  Future<void> unitOfWorkQueue = Future.value();
}

/// One row of the events table: the event plus its place in the log.
@internal
final class StoredEvent {
  /// Creates the row.
  const StoredEvent(this.position, this.streamId, this.version, this.event);

  /// Global append position, increasing across the whole store.
  final int position;

  /// The stream the event was appended to.
  final String streamId;

  /// The event's version within its stream.
  final int version;

  /// The event.
  final SerializedEvent event;
}

/// The tables of a [LocalDatabase]. [copy] copies the collections but shares
/// the immutable rows.
@internal
final class LocalTables {
  /// Creates empty tables.
  LocalTables();

  LocalTables._copy(LocalTables other)
    : nextPosition = other.nextPosition,
      events = [...other.events],
      eventsById = {...other.eventsById},
      streamEvents = {
        for (final MapEntry(:key, :value) in other.streamEvents.entries)
          key: [...value],
      },
      streams = {...other.streams},
      subscriptions = {...other.subscriptions},
      snapshots = {...other.snapshots},
      sagas = {...other.sagas},
      processedEvents = {...other.processedEvents},
      processedCommands = {...other.processedCommands},
      deadLetters = [...other.deadLetters],
      nextDeadLetterId = other.nextDeadLetterId;

  /// The position the next appended event gets.
  int nextPosition = 1;

  /// Every event, in append order.
  List<StoredEvent> events = [];

  /// Every event, by event ID.
  Map<String, StoredEvent> eventsById = {};

  /// The events of each stream, in version order.
  Map<String, List<StoredEvent>> streamEvents = {};

  /// Stream metadata, by stream ID.
  Map<String, StreamMetadata> streams = {};

  /// Subscriptions, by name.
  Map<String, Subscription> subscriptions = {};

  /// Snapshots, by source UUID and version.
  Map<(String, int), Snapshot> snapshots = {};

  /// Sagas, by saga type and saga ID.
  Map<(String, String), SagaRecord> sagas = {};

  /// When each event was recorded as handled, by handler name, handler
  /// instance and event ID.
  Map<(String, String, String), DateTime> processedEvents = {};

  /// Processed commands, by command ID.
  Map<String, ProcessedCommand> processedCommands = {};

  /// Dead letters, in write order.
  List<DeadLetterEntry> deadLetters = [];

  /// The ID the next dead letter gets.
  int nextDeadLetterId = 1;

  /// A copy that later writes to either side don't affect.
  LocalTables copy() => LocalTables._copy(this);
}

/// [rows] sorted by [time], oldest first or [newestFirst]. Rows with equal
/// times keep their order, reversed when [newestFirst], so the most recently
/// written comes first.
@internal
List<T> sortedByTime<T>(
  Iterable<T> rows,
  DateTime Function(T) time, {
  bool newestFirst = false,
  int? limit,
}) {
  final indexed = rows.indexed.toList()
    ..sort((a, b) {
      final byTime = time(a.$2).compareTo(time(b.$2));
      return byTime != 0 ? byTime : a.$1.compareTo(b.$1);
    });
  final sorted = (newestFirst ? indexed.reversed : indexed).map((r) => r.$2);
  return (limit == null ? sorted : sorted.take(limit)).toList();
}
