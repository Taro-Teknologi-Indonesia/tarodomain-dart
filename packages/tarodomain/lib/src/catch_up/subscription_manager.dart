import 'package:uuid/uuid.dart';

import '../adapters/event_store_adapter.dart';
import '../errors/error_codes.dart';

/// Tracks the persistent catch-up cursors (spec §18.2).
///
/// Subscriptions are [register]ed in memory at startup, then created in
/// storage by [ensureAllSubscriptions]. Each one follows a stream: an
/// aggregate stream, a category, or every event (a null `streamId`).
final class SubscriptionManager {
  /// Creates the manager over [adapter], which stores the cursors.
  SubscriptionManager(this.adapter);

  /// The event store that holds the cursors and the events they follow.
  final EventStoreAdapter adapter;

  final _registered = <String, String?>{};

  /// The registered subscription names, in registration order.
  List<String> get registeredNames => List.unmodifiable(_registered.keys);

  /// Whether [name] is registered.
  bool isRegistered(String name) => _registered.containsKey(name);

  /// Registers the subscription [name] following [streamId] (null for every
  /// event). Registering the same name and stream again does nothing.
  ///
  /// Throws [InvalidConfigurationError] if [name] is registered with a
  /// different stream.
  void register(String name, {String? streamId}) {
    if (_registered.containsKey(name) && _registered[name] != streamId) {
      throw InvalidConfigurationError(
        'Subscription "$name" is already registered for stream '
        '${_registered[name] ?? StreamIds.all}',
        context: {
          'subscription': name,
          'streamId': streamId,
          'registeredStreamId': _registered[name],
        },
      );
    }
    _registered[name] = streamId;
  }

  /// Creates the registered subscriptions that don't exist in storage yet,
  /// and returns their names.
  Future<List<String>> ensureAllSubscriptions() async {
    final created = <String>[];
    for (final MapEntry(key: name, value: streamId) in _registered.entries) {
      if (await adapter.getSubscription(name) != null) continue;
      await adapter.subscribe(name, streamId: streamId);
      created.add(name);
    }
    return created;
  }

  /// The stored subscription [name], created first if it is registered but
  /// not stored yet.
  ///
  /// Throws [InvalidConfigurationError] if it is neither stored nor
  /// registered.
  Future<Subscription> ensure(String name) async {
    if (await adapter.getSubscription(name) case final stored?) return stored;
    if (!_registered.containsKey(name)) throw _unknown(name);
    return adapter.subscribe(name, streamId: _registered[name]);
  }

  /// The stored subscription [name], or null.
  Future<Subscription?> get(String name) => adapter.getSubscription(name);

  /// Every stored subscription, ordered by name.
  Future<List<Subscription>> list() => adapter.listSubscriptions();

  /// Moves the cursor of [name] to [lastSeenEventId]. Moving it to the event
  /// it is already on does nothing.
  ///
  /// The cursor can't tell on its own whether an event comes before or after
  /// it, so moving it forward is the caller's job: `CronDispatcher` acks
  /// events in the order it read them.
  ///
  /// Throws [InvalidConfigurationError] if the subscription doesn't exist.
  Future<void> advance(String name, UuidValue lastSeenEventId) async {
    final subscription = await adapter.getSubscription(name);
    if (subscription == null) throw _unknown(name);
    if (subscription.lastSeen == lastSeenEventId) return;
    await adapter.ackSubscription(name, lastSeenEventId);
  }

  /// Deletes the stored subscription [name]. It stays registered.
  Future<void> delete(String name) => adapter.deleteSubscription(name);

  /// Whether no event follows the cursor of [name].
  ///
  /// Throws [InvalidConfigurationError] if the subscription doesn't exist.
  Future<bool> isCaughtUp(String name) async =>
      (await _pending(await _stored(name), 1)).isEmpty;

  /// Whether every stored subscription is caught up.
  Future<bool> areAllCaughtUp() async {
    for (final subscription in await list()) {
      if ((await _pending(subscription, 1)).isNotEmpty) return false;
    }
    return true;
  }

  /// How far behind each stored subscription is. Pending events are counted
  /// up to [countLimit] per subscription.
  Future<LagReport> getLagReport({int countLimit = 1000}) async => LagReport([
    for (final subscription in await list())
      SubscriptionLag._(
        subscription,
        (await _pending(subscription, countLimit + 1)).length,
        countLimit,
      ),
  ]);

  /// Deletes and recreates [name] with no cursor, so that it starts again
  /// from the first event, as a rebuild does.
  ///
  /// Throws [InvalidConfigurationError] if it is neither stored nor
  /// registered.
  Future<Subscription> reset(String name) async {
    final stored = await adapter.getSubscription(name);
    if (stored == null && !_registered.containsKey(name)) throw _unknown(name);
    final streamId = _registered.containsKey(name)
        ? _registered[name]
        : stored!.streamId;
    await adapter.deleteSubscription(name);
    return adapter.subscribe(name, streamId: streamId);
  }

  /// Resets every stored and registered subscription.
  Future<void> resetAll() async {
    final names = {
      for (final subscription in await list()) subscription.name,
      ..._registered.keys,
    };
    for (final name in names) {
      await reset(name);
    }
  }

  Future<Subscription> _stored(String name) async =>
      await adapter.getSubscription(name) ?? (throw _unknown(name));

  Future<List<Object>> _pending(Subscription subscription, int maxCount) =>
      adapter.loadStreamAfterEvent(
        subscription.streamId ?? StreamIds.all,
        afterEventId: subscription.lastSeen,
        maxCount: maxCount,
      );

  static InvalidConfigurationError _unknown(String name) =>
      InvalidConfigurationError(
        'Subscription "$name" does not exist',
        context: {'subscription': name},
      );
}

/// How far one subscription is behind, from
/// [SubscriptionManager.getLagReport].
final class SubscriptionLag {
  SubscriptionLag._(this.subscription, int pending, this.countLimit)
    : pending = pending > countLimit ? countLimit : pending,
      isCapped = pending > countLimit;

  /// The subscription.
  final Subscription subscription;

  /// How many events follow its cursor, at most [countLimit].
  final int pending;

  /// The most pending events counted.
  final int countLimit;

  /// Whether more than [countLimit] events are pending.
  final bool isCapped;

  /// The subscription name.
  String get name => subscription.name;

  /// Whether no event follows the cursor.
  bool get isCaughtUp => pending == 0;

  @override
  String toString() =>
      'SubscriptionLag($name, pending: $pending${isCapped ? '+' : ''})';
}

/// The lag of every subscription, from [SubscriptionManager.getLagReport].
final class LagReport {
  /// Creates the report.
  LagReport(List<SubscriptionLag> subscriptions)
    : subscriptions = List.unmodifiable(subscriptions);

  /// One entry per subscription, ordered by name.
  final List<SubscriptionLag> subscriptions;

  /// Whether every subscription is caught up.
  bool get allCaughtUp => subscriptions.every((s) => s.isCaughtUp);

  /// The pending events across subscriptions, each counted up to its limit.
  int get totalPending => subscriptions.fold(0, (sum, s) => sum + s.pending);
}
