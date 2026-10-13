import 'dart:async';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../future_calls/auction_close_calls.dart';

/// Runs the scheduled jobs from in-process timers, for a server whose plan
/// disables future calls (Serverpod Cloud's).
///
/// Every few seconds: TaroDomain's catch-up and saga timeouts, and the close
/// of auctions past their deadline. Once a day: TaroDomain's cleanup. Each
/// server runs its own timers; the jobs are idempotent, so several servers
/// running them is safe.
void startTimerJobs(Serverpod pod) {
  final taro = TaroDomainServerpod.instance;
  _every(pod, const Duration(seconds: 5), 'catch-up', taro.runCatchUp);
  _every(
    pod,
    const Duration(seconds: 5),
    'saga-timeouts',
    taro.runSagaTimeouts,
  );
  _every(pod, const Duration(seconds: 5), 'auction-close', closeDueAuctions);
  _every(pod, const Duration(days: 1), 'cleanup', taro.cleanup);
}

/// Runs [job] every [interval] in a fresh session, skipping a tick while the
/// previous run is still going.
void _every(
  Serverpod pod,
  Duration interval,
  String name,
  Future<void> Function(Session session) job,
) {
  var running = false;
  Timer.periodic(interval, (_) async {
    if (running) return;
    running = true;
    final session = await pod.createSession(enableLogging: false);
    try {
      await job(session);
    } catch (e, stackTrace) {
      stderr.writeln('Timer job $name failed: $e\n$stackTrace');
    } finally {
      await session.close();
      running = false;
    }
  });
}
