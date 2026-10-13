import '../catch_up/cron_dispatcher.dart';
import '../errors/error_codes.dart';
import '../projection/projection.dart';

/// Rebuilds projections from the event store (spec §20.1).
///
/// A rebuild:
///
/// 1. calls [Projection.onRebuildStart], where the projection empties its
///    read model;
/// 2. resets the projection's subscription, so it starts again from the
///    first event;
/// 3. forgets which events the projection handled;
/// 4. catches up through the [dispatcher] until no events are left;
/// 5. calls [Projection.onRebuildComplete].
///
/// Pause live delivery to the projection while it is rebuilt. Otherwise an
/// event delivered live between steps 1 and 3 is forgotten and handled
/// again by the replay, which is only safe if the handler writes
/// idempotently (spec §14.3).
final class ProjectionRebuilder {
  /// Creates the rebuilder.
  ProjectionRebuilder(this.dispatcher);

  /// Replays the events. A projection that isn't registered on it yet is
  /// registered when it is rebuilt.
  final CronDispatcher dispatcher;

  /// Rebuilds [projection], following [streamId] (null for every event) if
  /// it isn't registered on the [dispatcher] yet.
  ///
  /// Options:
  ///
  /// - [continueOnError]: skip events whose handler throws a non-retryable
  ///   error, as catch-up does, instead of stopping the rebuild.
  /// - [resetIdempotency]: forget which events the projection handled.
  ///   Without it, only events it hasn't handled are replayed.
  /// - [callHooks]: call [Projection.onRebuildStart] and
  ///   [Projection.onRebuildComplete].
  /// - [batchSize]: events per catch-up pass, by default the dispatcher's.
  /// - [maxPasses]: the most catch-up passes before giving up, unfinished.
  ///
  /// Never throws for a failing event or hook; the result reports it. A
  /// rebuild that stops doesn't call [Projection.onRebuildComplete].
  ///
  /// Throws [InvalidConfigurationError] if the dispatcher has a different
  /// handler with the projection's name.
  Future<RebuildResult> rebuild(
    Projection projection, {
    String? streamId,
    bool continueOnError = false,
    bool resetIdempotency = true,
    bool callHooks = true,
    int? batchSize,
    int maxPasses = 10000,
  }) async {
    final name = projection.name;
    dispatcher.register(projection, streamId: streamId);
    final result = _RebuildBuilder(name);
    try {
      if (callHooks) await projection.onRebuildStart();
      await dispatcher.subscriptions.reset(name);
      if (resetIdempotency) {
        await projection.processedEvents.deleteByHandler(
          projection.projectionName,
          handlerInstance: projection is ShardProjection ? name : null,
        );
      }
      while (result.passes < maxPasses) {
        final pass = await dispatcher.catchUp(
          name,
          batchSize: batchSize,
          stopOnError: !continueOnError,
        );
        result.add(pass);
        if (pass.stopped) return result.build(pass.error, pass.stackTrace);
        if (!pass.hasMore) {
          result.completed = true;
          break;
        }
      }
      if (result.completed && callHooks) await projection.onRebuildComplete();
      return result.build();
    } catch (error, stackTrace) {
      result.completed = false;
      return result.build(error, stackTrace);
    }
  }

  /// Rebuilds each of [projections] in turn, with the options of [rebuild].
  /// A projection that fails doesn't stop the others.
  Future<RebuildAllResult> rebuildAll(
    List<Projection> projections, {
    bool continueOnError = false,
    bool resetIdempotency = true,
    bool callHooks = true,
    int? batchSize,
    int maxPasses = 10000,
  }) async => RebuildAllResult([
    for (final projection in projections)
      await rebuild(
        projection,
        continueOnError: continueOnError,
        resetIdempotency: resetIdempotency,
        callHooks: callHooks,
        batchSize: batchSize,
        maxPasses: maxPasses,
      ),
  ]);

  /// Rebuilds every shard of a sharded projection. Each shard has its own
  /// subscription and idempotency records, and calls its own hooks.
  Future<RebuildAllResult> rebuildShards(
    List<ShardProjection> shards, {
    bool continueOnError = false,
    bool resetIdempotency = true,
    bool callHooks = true,
    int? batchSize,
    int maxPasses = 10000,
  }) => rebuildAll(
    shards,
    continueOnError: continueOnError,
    resetIdempotency: resetIdempotency,
    callHooks: callHooks,
    batchSize: batchSize,
    maxPasses: maxPasses,
  );
}

/// The outcome of rebuilding one projection.
final class RebuildResult {
  RebuildResult._({
    required this.projection,
    required this.completed,
    required this.passes,
    required this.eventsProcessed,
    required List<SkippedEvent> skipped,
    this.error,
    this.stackTrace,
  }) : skipped = List.unmodifiable(skipped);

  /// The projection's handler name.
  final String projection;

  /// Whether every event was replayed.
  final bool completed;

  /// How many catch-up passes ran.
  final int passes;

  /// Events the projection handled.
  final int eventsProcessed;

  /// Events skipped after a non-retryable error, with `continueOnError`.
  final List<SkippedEvent> skipped;

  /// What stopped the rebuild, or null.
  final Object? error;

  /// Where [error] was thrown.
  final StackTrace? stackTrace;

  @override
  String toString() =>
      'RebuildResult($projection, completed: $completed, '
      'events: $eventsProcessed, skipped: ${skipped.length}'
      '${error == null ? '' : ', error: $error'})';
}

final class _RebuildBuilder {
  _RebuildBuilder(this.projection);

  final String projection;
  bool completed = false;
  int passes = 0;
  int eventsProcessed = 0;
  final skipped = <SkippedEvent>[];

  void add(CatchUpResult pass) {
    passes++;
    eventsProcessed += pass.processed;
    skipped.addAll(pass.skipped);
  }

  RebuildResult build([Object? error, StackTrace? stackTrace]) =>
      RebuildResult._(
        projection: projection,
        completed: completed && error == null,
        passes: passes,
        eventsProcessed: eventsProcessed,
        skipped: skipped,
        error: error,
        stackTrace: stackTrace,
      );
}

/// The outcome of rebuilding several projections.
final class RebuildAllResult {
  /// Creates the result.
  RebuildAllResult(List<RebuildResult> results)
    : results = List.unmodifiable(results);

  /// One result per projection, in order.
  final List<RebuildResult> results;

  /// Whether every projection was rebuilt completely.
  bool get allCompleted => results.every((r) => r.completed);

  /// The results of projections that weren't rebuilt completely.
  List<RebuildResult> get failed => [
    for (final r in results)
      if (!r.completed) r,
  ];
}
