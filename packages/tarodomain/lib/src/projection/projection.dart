import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';

import '../adapters/idempotency_stores.dart';
import '../bus/event_handler.dart';
import '../domain/domain_event.dart';
import '../errors/error_codes.dart';
import '../errors/framework_error.dart';
import '../event_sourcing/event_registry.dart';

/// Called by [Projection.handle] with an event the projection has no
/// handler for.
typedef UnhandledEventCallback = void Function(DomainEvent event);

/// Handles one event type in a [Projection].
typedef ProjectionHandler<E extends DomainEvent> =
    FutureOr<void> Function(E event);

/// Keeps a read model up to date from events (spec §12).
///
/// Subclasses register a handler per event type in their constructor, and
/// write to their own storage from it:
///
/// ```dart
/// class BalanceProjection extends Projection {
///   BalanceProjection(this.db, {required super.processedEvents}) {
///     on<AccountOpened>((e) => db.insertAccount(e.owner));
///     on<MoneyDeposited>((e) => db.recordDeposit(e.id, e.cents));
///   }
///
///   final BalanceDb db;
///
///   @override
///   String get name => 'balance';
/// }
/// ```
///
/// Each event is handled at most once per projection instance: [handle]
/// skips events recorded in [processedEvents] and records the ones it
/// handles. Events with no handler are recorded too, so they are not
/// delivered again (spec §12.2). Under eventual consistency the record is
/// written after the handler, so a crash in between delivers the event
/// again; handlers should still write idempotently (spec §14.3).
abstract class Projection implements EventHandler {
  /// Creates the projection.
  Projection({required this.processedEvents});

  /// Records which events this projection has handled.
  final ProcessedEventStore processedEvents;

  /// Unique handler name, used on the event bus.
  @override
  String get name;

  /// The handler name recorded in [processedEvents]. The same as [name],
  /// except that every shard of a [ShardProjection] shares it.
  String get projectionName => name;

  final _routes = <_ProjectionRoute>[];

  /// Registers [handler] for events of type [E], including subtypes of [E].
  /// When an event matches several registrations, the one for its exact type
  /// wins, otherwise the first registered.
  ///
  /// Throws [InvalidConfigurationError] if [E] is already registered or is
  /// `DomainEvent` itself.
  @protected
  void on<E extends DomainEvent>(ProjectionHandler<E> handler) {
    if (E == DomainEvent) {
      throw InvalidConfigurationError(
        'Projection "$name" needs a concrete event type for on<E>',
        context: {'projection': name},
      );
    }
    if (_routes.any((route) => route.type == E)) {
      throw InvalidConfigurationError(
        'Projection "$name" already handles $E',
        context: {'projection': name, 'eventType': '$E'},
      );
    }
    _routes.add(_ProjectionRoute<E>(handler));
  }

  /// The event types registered with [on], in registration order.
  List<Type> get handledEventTypes => [for (final r in _routes) r.type];

  /// The event types registered with [on] that no event registered in
  /// [registry] can match.
  List<Type> unregisteredEventTypes(EventRegistry registry) => [
    for (final route in _routes)
      if (!route.isRegisteredIn(registry)) route.type,
  ];

  /// Called with each event that has no handler, before it is recorded as
  /// processed. If it throws, the event isn't recorded and the error
  /// propagates. The framework sets it from its projection validation mode
  /// (see `DispatchGuard`); null skips such events silently (spec §12.2).
  UnhandledEventCallback? onUnhandledEvent;

  /// Whether a handler is registered for [event].
  bool handles(DomainEvent event) => _routeFor(event) != null;

  _ProjectionRoute? _routeFor(DomainEvent event) =>
      _routes.where((r) => r.type == event.runtimeType).firstOrNull ??
      _routes.where((r) => r.matches(event)).firstOrNull;

  /// The instance [event] is recorded under in [processedEvents].
  String instanceIdFor(DomainEvent event) => projectionName;

  /// Runs the handler registered for [event], unless it was already handled.
  ///
  /// A [FrameworkError] from the handler is rethrown as it is; anything
  /// else is wrapped in [ProjectionHandlerFailedError]. Either way the event
  /// is not recorded, so it can be delivered again.
  @override
  Future<void> handle(DomainEvent event) async {
    if (await alreadyProcessed(event)) return;
    if (_routeFor(event) case final route?) {
      try {
        await route.call(event);
      } on FrameworkError {
        rethrow;
      } catch (error, stackTrace) {
        throw ProjectionHandlerFailedError(
          'Projection "$name" failed on ${event.eventName} ${event.id}: '
          '$error',
          context: {
            'projection': name,
            'eventType': event.eventName,
            'eventId': event.id.uuid,
          },
          cause: error,
          stackTrace: stackTrace,
        );
      }
    } else {
      onUnhandledEvent?.call(event);
    }
    await markProcessed(event);
  }

  /// Whether [event] is recorded as handled.
  @protected
  Future<bool> alreadyProcessed(DomainEvent event) =>
      processedEvents.exists(projectionName, instanceIdFor(event), event.id);

  /// Records [event] as handled.
  @protected
  Future<void> markProcessed(DomainEvent event) => processedEvents
      .markProcessed(projectionName, instanceIdFor(event), event.id);

  /// Called before a rebuild replays events, for example to truncate the
  /// read model tables. Does nothing by default.
  Future<void> onRebuildStart() async {}

  /// Called after a rebuild has replayed every event, for example to create
  /// indexes. Does nothing by default.
  Future<void> onRebuildComplete() async {}
}

final class _ProjectionRoute<E extends DomainEvent> {
  _ProjectionRoute(this.handler);

  final ProjectionHandler<E> handler;

  Type get type => E;

  bool matches(DomainEvent event) => event is E;

  bool isRegisteredIn(EventRegistry registry) => registry.mayProduce<E>();

  FutureOr<void> call(DomainEvent event) => handler(event as E);
}

/// One shard of a projection whose events are split across [shardCount]
/// instances by [shardKey] (spec §12.1).
///
/// Each shard is a separate handler named `<projectionName>-shard-<index>`.
/// It handles only events whose key hashes to its [shardIndex], and records
/// them under its own name as the instance, so one shard can be rebuilt
/// without the others.
abstract class ShardProjection extends Projection {
  /// Creates shard [shardIndex] of [shardCount].
  ///
  /// Throws [InvalidConfigurationError] unless
  /// `0 <= shardIndex < shardCount`.
  ShardProjection({
    required super.processedEvents,
    required this.shardIndex,
    required this.shardCount,
  }) {
    if (shardCount < 1 || shardIndex < 0 || shardIndex >= shardCount) {
      throw InvalidConfigurationError(
        'Invalid shard $shardIndex of $shardCount',
        context: {'shardIndex': shardIndex, 'shardCount': shardCount},
      );
    }
  }

  /// This shard's position, from 0.
  final int shardIndex;

  /// How many shards the projection is split into.
  final int shardCount;

  /// The name shared by every shard, recorded as the handler name in
  /// [processedEvents].
  @override
  String get projectionName;

  /// This shard's handler name.
  @override
  String get name => '$projectionName-shard-$shardIndex';

  /// The key that decides which shard handles [event], such as an account
  /// ID, or null if no shard handles it.
  String? shardKey(DomainEvent event);

  /// Whether this shard handles [event].
  bool ownsEvent(DomainEvent event) => switch (shardKey(event)) {
    final key? => shardFor(key, shardCount) == shardIndex,
    null => false,
  };

  @override
  String instanceIdFor(DomainEvent event) => name;

  /// Handles [event] if this shard owns it. Events owned by other shards are
  /// neither handled nor recorded.
  @override
  Future<void> handle(DomainEvent event) async {
    if (ownsEvent(event)) await super.handle(event);
  }

  /// The shard, out of [shardCount], that [key] belongs to.
  ///
  /// Uses 32-bit FNV-1a over the key's UTF-8 bytes, which, unlike
  /// [String.hashCode], is the same in every process.
  static int shardFor(String key, int shardCount) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(key)) {
      hash ^= byte;
      // hash * 0x01000193 mod 2^32, split so that no intermediate exceeds
      // 2^53 and the result is exact on the web too.
      hash = ((hash & 0xff) * 0x1000000 + hash * 0x193) & 0xffffffff;
    }
    return hash % shardCount;
  }
}
