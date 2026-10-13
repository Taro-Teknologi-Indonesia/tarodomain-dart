import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';

import '../saga/fixtures.dart';

export '../saga/fixtures.dart';

/// An event store over a fresh local provider, with the transfer events
/// registered, plus helpers to append wallet events.
class Store {
  Store() {
    provider = LocalProvider();
    adapter = provider.createEventStoreAdapter();
    eventStore = EventStore(adapter, transferRegistry());
    subscriptions = SubscriptionManager(adapter);
    deadLetters = provider.createDeadLetterStore();
    processedEvents = provider.createProcessedEventStore();
  }

  late final LocalProvider provider;
  late final EventStoreAdapter adapter;
  late final EventStore eventStore;
  late final SubscriptionManager subscriptions;
  late final DeadLetterStore deadLetters;
  late final ProcessedEventStore processedEvents;

  final _versions = <String, int>{};

  /// Appends one event per amount in [cents] to the wallet [stream], and
  /// returns them.
  Future<List<DomainEvent>> deposit(
    List<int> cents, {
    String stream = 'Wallet-a',
  }) async {
    final events = [for (final c in cents) MoneyDeposited(c)];
    await appendRaw(stream, [for (final e in events) e.serialize()]);
    return events;
  }

  Future<void> appendRaw(String stream, List<SerializedEvent> events) async {
    final version = _versions[stream] ?? 0;
    await adapter.appendToStream(stream, events, version);
    _versions[stream] = version + events.length;
  }

  /// A serialized event of a type the registry doesn't know.
  SerializedEvent unknownEvent() => SerializedEvent(
    eventType: 'Mystery',
    eventVersion: '1.0.0',
    envelope: MoneyDeposited(0).envelope,
    data: const {},
  );
}

/// Records the events it handles, and throws what [failOn] returns.
class RecordingHandler implements EventHandler {
  RecordingHandler(this.name);

  @override
  final String name;

  final handled = <DomainEvent>[];

  /// The error to throw for an event, or null to handle it.
  Object? Function(DomainEvent event)? failOn;

  /// Called while handling, for example to check the zone.
  void Function()? onHandle;

  List<int> get cents => [
    for (final e in handled)
      if (e is WalletEvent) e.cents,
  ];

  @override
  Future<void> handle(DomainEvent event) async {
    if (failOn?.call(event) case final error?) throw error;
    onHandle?.call();
    handled.add(event);
  }
}

/// A read model: per event type, how many events and their total cents.
class TotalsDb {
  final counts = <String, int>{};
  final cents = <String, int>{};
  final eventIds = <UuidValue>{};

  void record(WalletEvent event) {
    counts.update(event.eventName, (n) => n + 1, ifAbsent: () => 1);
    cents.update(
      event.eventName,
      (n) => n + event.cents,
      ifAbsent: () => event.cents,
    );
    eventIds.add(event.id);
  }

  void clear() {
    counts.clear();
    cents.clear();
    eventIds.clear();
  }

  Map<String, Object> snapshot() => {
    'counts': Map.of(counts),
    'cents': Map.of(cents),
    'eventIds': Set.of(eventIds),
  };
}

/// Totals every wallet event, so a rebuild can be compared with live
/// delivery.
class TotalsProjection extends Projection {
  TotalsProjection(this.db, {required super.processedEvents}) {
    on<WalletEvent>((event) {
      if (failOn?.call(event) case final error?) throw error;
      db.record(event);
    });
  }

  final TotalsDb db;
  final hooks = <String>[];

  /// The error to throw for an event, or null to handle it.
  Object? Function(WalletEvent event)? failOn;

  @override
  String get name => 'totals';

  @override
  Future<void> onRebuildStart() async {
    hooks.add('start');
    db.clear();
  }

  @override
  Future<void> onRebuildComplete() async => hooks.add('complete');
}

/// A shard of [TotalsProjection], keyed by the event's cents.
class TotalsShard extends ShardProjection {
  TotalsShard(
    this.db, {
    required super.processedEvents,
    required super.shardIndex,
    required super.shardCount,
  }) {
    on<WalletEvent>(db.record);
  }

  final TotalsDb db;

  @override
  String get projectionName => 'totals';

  @override
  String? shardKey(DomainEvent event) =>
      event is WalletEvent ? '${event.cents}' : null;

  @override
  Future<void> onRebuildStart() async => db.clear();
}

/// A domain error, which is not retryable.
DomainError domainError() => InvalidAggregateStateError('bad event');

/// An infrastructure error, which is retryable.
InfrastructureError retryableError() => EventStoreError('store busy');
