import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';

import 'adapters/event_sequencer.dart';
import 'db/taro_db.dart';
import 'exceptions.dart';
import 'generated/protocol.dart';
import 'serverpod_provider.dart';

/// TaroDomain on a Serverpod server: a [FrameworkDefinition] plus the
/// settings of its [ServerpodProvider]s, with entry points that take the
/// request's [Session] (spec §26).
///
/// Create one when the server starts, call [validate], and [install] it so
/// the app's `TaroDomainFutureCall` subclass can find it:
///
/// ```dart
/// final taro = TaroDomainServerpod(
///   definition,
///   scheduleCatchUp: (session, delay) => session.serverpod.futureCalls
///       .callWithDelay(delay)
///       .taroDomainCalls
///       .catchUp(),
/// )..install();
/// await taro.validate(pod);
/// ```
///
/// Endpoints then call [dispatch], and queries use [runtime].
final class TaroDomainServerpod {
  /// Creates the integration for [definition].
  ///
  /// [scheduleCatchUp] configures every [ServerpodProvider] (see there). [catchUpPasses] bounds the passes of
  /// one [runCatchUp]. The TTLs are how long [cleanup] keeps processed
  /// commands (spec §14.1), processed events and dead letters (spec §21.1);
  /// null keeps them forever.
  TaroDomainServerpod(
    this.definition, {
    this.scheduleCatchUp,
    this.catchUpPasses = 10,
    this.leaseDuration = const Duration(minutes: 5),
    this.processedCommandsTtl = const Duration(days: 7),
    this.processedEventsTtl = const Duration(days: 7),
    this.deadLettersTtl = const Duration(days: 30),
    this.clock,
  });

  static TaroDomainServerpod? _instance;

  /// The integration [install] made current.
  ///
  /// Throws [StateError] if none was installed.
  static TaroDomainServerpod get instance =>
      _instance ??
      (throw StateError(
        'No TaroDomainServerpod installed: call install() at startup',
      ));

  /// What the app configured with `TaroDomain.builder()`.
  final FrameworkDefinition definition;

  /// Schedules catch-up after an eventual command, or null to rely on the
  /// recurring catch-up.
  final CatchUpScheduler? scheduleCatchUp;

  /// The most catch-up passes one [runCatchUp] makes.
  final int catchUpPasses;

  /// How long a server holds the lease of a scheduled job before another
  /// may take over, if it never releases it.
  final Duration leaseDuration;

  /// How long processed command records are kept.
  final Duration? processedCommandsTtl;

  /// How long processed event records are kept.
  final Duration? processedEventsTtl;

  /// How long dead letters are kept.
  final Duration? deadLettersTtl;

  /// The clock of the stores' timestamps, or null for the system clock.
  final DateTime Function()? clock;

  /// Makes this the [instance] the module's future calls use.
  void install() => _instance = this;

  /// A provider on [session].
  ServerpodProvider provider(Session session) => ServerpodProvider(
    session,
    scheduleCatchUp: scheduleCatchUp,
    clock: clock,
  );

  /// A runtime on [session]. Runtimes are cheap; create one per request.
  TaroDomain runtime(Session session) =>
      definition.createRuntime(provider: provider(session));

  /// Creates a runtime once on a new session of [pod] and discards it, so
  /// an invalid configuration, such as a projection handling an
  /// unregistered event, stops the server at startup instead of failing the
  /// first request.
  ///
  /// Throws [InvalidConfigurationError] if the configuration is invalid.
  Future<void> validate(Serverpod pod) => pod.withSession(
    (session) async => runtime(session),
    enableLogging: false,
  );

  /// Runs [command] on a runtime for [session].
  ///
  /// A [FrameworkError] is rethrown as a [TaroDomainException], which
  /// Serverpod sends to the client as a typed exception.
  Future<CommandDispatchResult> dispatch(Session session, Command command) =>
      rethrowAsTaroDomainException(() => runtime(session).dispatch(command));

  /// Positions newly committed events (see [EventSequencer]), then catches
  /// every projection and saga up from the event store, in passes until
  /// none has more or [catchUpPasses] is reached. Returns null if another
  /// server holds the catch-up lease.
  Future<List<CatchUpResult>?> runCatchUp(Session session) =>
      _withLease(session, 'catch-up', () async {
        await EventSequencer(session).run();
        final cron = runtime(session).cron;
        final results = <CatchUpResult>[];
        for (var pass = 0; pass < catchUpPasses; pass++) {
          final run = await cron.runAll();
          results.addAll(run);
          if (!run.any((r) => r.hasMore && r.error == null)) break;
        }
        return results;
      });

  /// Times out stuck sagas (spec §19). Returns null if another server holds
  /// the lease.
  Future<Map<String, List<SagaTimeoutResult>>?> runSagaTimeouts(
    Session session,
  ) => _withLease(session, 'saga-timeouts', () async {
    return {
      for (final scheduler in runtime(session).timeoutSchedulers)
        scheduler.handler.sagaType: await scheduler.run(),
    };
  });

  /// Deletes processed commands, processed events and dead letters older
  /// than their TTLs. Returns how many of each were deleted, or null if
  /// another server holds the lease.
  Future<Map<String, int>?> cleanup(Session session) =>
      _withLease(session, 'cleanup', () async {
        final taro = runtime(session);
        final now = (clock ?? DateTime.timestamp)().toUtc();
        return {
          if (processedCommandsTtl case final ttl?)
            'processedCommands': await taro.commandIdempotency.deleteOld(
              now.subtract(ttl),
            ),
          if (processedEventsTtl case final ttl?)
            'processedEvents': await taro.processedEvents.deleteOld(
              now.subtract(ttl),
            ),
          if (deadLettersTtl case final ttl?)
            'deadLetters': await taro.deadLetters.deleteOld(now.subtract(ttl)),
        };
      });

  /// Runs [work] if this server gets the lease [job], so one server at a
  /// time runs each scheduled job. Returns null otherwise.
  ///
  /// Correctness doesn't depend on it (the sequencer, idempotency records
  /// and forward-only cursors already make concurrent runs safe); it avoids
  /// doing the same work twice.
  Future<T?> _withLease<T>(
    Session session,
    String job,
    Future<T> Function() work,
  ) async {
    final db = TaroDb(session, clock: clock);
    final locks = TaroLockRow.t;
    final name = 'tarodomain-$job';
    final owner = const Uuid().v4();
    final now = db.now();
    final lockedUntil = now.add(leaseDuration);
    final acquired =
        (await db.insert<TaroLockRow>([
          TaroLockRow(name: name, owner: owner, lockedUntil: lockedUntil),
        ], ignoreConflicts: true)).isNotEmpty ||
        (await db.updateWhere<TaroLockRow>(
          columnValues: [
            ColumnValue(locks.owner, owner),
            ColumnValue(locks.lockedUntil, lockedUntil),
          ],
          where: locks.name.equals(name) & (locks.lockedUntil < now),
        )).isNotEmpty;
    if (!acquired) return null;
    try {
      return await work();
    } finally {
      await db.deleteWhere<TaroLockRow>(
        where: locks.name.equals(name) & locks.owner.equals(owner),
      );
    }
  }
}
