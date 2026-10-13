import 'dart:math';

import '../command/concurrency_checker.dart';
import '../errors/error_codes.dart';
import 'cron_dispatcher.dart';

/// Why a [BackpressureController.run] ended.
enum BackpressureStopReason {
  /// Every subscription caught up, stopped at an error, or used up its
  /// passes.
  completed,

  /// The time budget ran out.
  timeBudget,

  /// The event budget ran out.
  eventBudget,
}

/// Runs a [CronDispatcher] within limits (spec §18.4), for hosts that give
/// each run a fixed time, such as a scheduled job.
///
/// A run takes one batch from each subscription in turn, so a subscription
/// that is far behind doesn't starve the others, until each one is caught up,
/// has stopped at an error or has had [maxPassesPerSubscription] batches, or
/// the run reaches [maxDuration] or [maxEventsPerRun]. A batch already
/// started always finishes, so a run can overshoot [maxDuration] by one
/// batch.
final class BackpressureController {
  /// Creates the controller. [clock] and [sleep] can be injected for tests.
  ///
  /// Throws [InvalidConfigurationError] if a limit is out of range.
  BackpressureController(
    this.dispatcher, {
    this.maxDuration = const Duration(seconds: 25),
    this.maxEventsPerRun = 10000,
    this.maxPassesPerSubscription = 100,
    this.throttle = Duration.zero,
    this.batchSize,
    this.onProgress,
    DateTime Function()? clock,
    Sleep? sleep,
  }) : _clock = clock ?? DateTime.timestamp,
       _sleep = sleep ?? Future<void>.delayed {
    if (maxDuration <= Duration.zero ||
        maxEventsPerRun < 1 ||
        maxPassesPerSubscription < 1 ||
        throttle.isNegative ||
        (batchSize ?? 1) < 1) {
      throw InvalidConfigurationError(
        'Invalid BackpressureController settings',
        context: {
          'maxDurationMs': maxDuration.inMilliseconds,
          'maxEventsPerRun': maxEventsPerRun,
          'maxPassesPerSubscription': maxPassesPerSubscription,
          'throttleMs': throttle.inMilliseconds,
          'batchSize': batchSize,
        },
      );
    }
  }

  /// The dispatcher that does the work.
  final CronDispatcher dispatcher;

  /// The time budget of one run.
  final Duration maxDuration;

  /// The most events one run moves cursors past, across subscriptions.
  final int maxEventsPerRun;

  /// The most batches one run takes from a subscription.
  final int maxPassesPerSubscription;

  /// The pause between batches.
  final Duration throttle;

  /// Events per batch, or null for the dispatcher's batch size.
  final int? batchSize;

  /// Called after every batch.
  final void Function(BackpressureProgress progress)? onProgress;

  final DateTime Function() _clock;
  final Sleep _sleep;

  /// Catches up the subscriptions named in [only], or every handler
  /// registered on the dispatcher, within the limits. Never throws for a
  /// failing event; the report shows it.
  Future<BackpressureReport> run({List<String>? only}) async {
    final start = _clock();
    await dispatcher.subscriptions.ensureAllSubscriptions();
    final names = only ?? [for (final h in dispatcher.handlers) h.name];
    final runs = {for (final name in names) name: _SubscriptionRunBuilder()};
    final active = List.of(names);
    var total = 0;
    var reason = BackpressureStopReason.completed;

    outer:
    while (active.isNotEmpty) {
      for (final name in List.of(active)) {
        if (_clock().difference(start) >= maxDuration) {
          reason = BackpressureStopReason.timeBudget;
          break outer;
        }
        if (total >= maxEventsPerRun) {
          reason = BackpressureStopReason.eventBudget;
          break outer;
        }
        final size = min(
          batchSize ?? dispatcher.batchSize,
          maxEventsPerRun - total,
        );
        final result = await dispatcher.catchUp(name, batchSize: size);
        final stats = runs[name]!..add(result);
        total += result.advanced;
        if (!result.hasMore ||
            result.stopped ||
            stats.passes >= maxPassesPerSubscription) {
          active.remove(name);
        }
        onProgress?.call(
          BackpressureProgress._(result, total, _clock().difference(start)),
        );
        if (active.isNotEmpty && throttle > Duration.zero) {
          await _sleep(throttle);
        }
      }
    }

    return BackpressureReport._(
      reason: reason,
      elapsed: _clock().difference(start),
      subscriptions: [
        for (final MapEntry(:key, :value) in runs.entries) value.build(key),
      ],
    );
  }
}

/// Progress after one batch of a [BackpressureController.run].
final class BackpressureProgress {
  BackpressureProgress._(this.batch, this.eventsSoFar, this.elapsed);

  /// The batch that just finished.
  final CatchUpResult batch;

  /// Events the run has moved cursors past so far.
  final int eventsSoFar;

  /// Time since the run started.
  final Duration elapsed;
}

/// What one run did for one subscription.
final class SubscriptionRun {
  SubscriptionRun._({
    required this.subscription,
    required this.passes,
    required this.processed,
    required this.skipped,
    required this.hasMore,
    this.error,
  });

  /// The subscription name.
  final String subscription;

  /// How many batches it took.
  final int passes;

  /// Events the handler completed.
  final int processed;

  /// Events skipped after a non-retryable error.
  final int skipped;

  /// Whether events may remain after the run.
  final bool hasMore;

  /// The error its last batch stopped at, or null.
  final Object? error;

  @override
  String toString() =>
      'SubscriptionRun($subscription, passes: $passes, '
      'processed: $processed, skipped: $skipped, hasMore: $hasMore)';
}

final class _SubscriptionRunBuilder {
  int passes = 0;
  int processed = 0;
  int skipped = 0;
  bool hasMore = true;
  Object? error;

  void add(CatchUpResult result) {
    passes++;
    processed += result.processed;
    skipped += result.skipped.length;
    hasMore = result.hasMore;
    error = result.error;
  }

  SubscriptionRun build(String name) => SubscriptionRun._(
    subscription: name,
    passes: passes,
    processed: processed,
    skipped: skipped,
    hasMore: hasMore,
    error: error,
  );
}

/// The outcome of a [BackpressureController.run].
final class BackpressureReport {
  BackpressureReport._({
    required this.reason,
    required this.elapsed,
    required List<SubscriptionRun> subscriptions,
  }) : subscriptions = List.unmodifiable(subscriptions);

  /// Why the run ended.
  final BackpressureStopReason reason;

  /// How long the run took.
  final Duration elapsed;

  /// One entry per subscription, in the order they were run.
  final List<SubscriptionRun> subscriptions;

  /// Events the run moved cursors past.
  int get eventsProcessed =>
      subscriptions.fold(0, (sum, s) => sum + s.processed + s.skipped);

  /// [eventsProcessed] per second of [elapsed].
  double get eventsPerSecond => elapsed == Duration.zero
      ? 0
      : eventsProcessed *
            Duration.microsecondsPerSecond /
            elapsed.inMicroseconds;

  /// Whether any subscription may still have events to handle.
  bool get hasMore => subscriptions.any((s) => s.hasMore);

  @override
  String toString() =>
      'BackpressureReport(${reason.name}, events: $eventsProcessed, '
      'elapsed: $elapsed)';
}
