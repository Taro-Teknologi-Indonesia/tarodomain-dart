// The generator only accepts FutureCall without type arguments.
// ignore_for_file: strict_raw_type

import 'package:serverpod/serverpod.dart';

import 'taro_domain_serverpod.dart';

/// The scheduled jobs of TaroDomain as Serverpod future calls (spec §18.3,
/// §19, §14.1), run on the installed [TaroDomainServerpod.instance].
///
/// Serverpod generates future calls only from an app's own code, so the app
/// extends this class once and runs `serverpod generate`:
///
/// ```dart
/// class TaroDomainCalls extends TaroDomainFutureCall {}
/// ```
///
/// and schedules the recurring runs at startup, for example:
///
/// ```dart
/// await pod.futureCalls
///     .callRecurring(identifier: 'tarodomain-catch-up')
///     .every(const Duration(seconds: 10))
///     .taroDomainCalls
///     .catchUp();
/// ```
abstract class TaroDomainFutureCall extends FutureCall {
  /// Catches projections and sagas up from the event store.
  Future<void> catchUp(Session session) async {
    await TaroDomainServerpod.instance.runCatchUp(session);
  }

  /// Times out stuck sagas.
  Future<void> sagaTimeouts(Session session) async {
    await TaroDomainServerpod.instance.runSagaTimeouts(session);
  }

  /// Deletes expired idempotency records and dead letters.
  Future<void> cleanup(Session session) async {
    await TaroDomainServerpod.instance.cleanup(session);
  }
}
