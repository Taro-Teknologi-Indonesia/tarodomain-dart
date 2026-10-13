import 'dart:io';

import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Endpoints, Protocol;

import 'src/demo/demo_auctions.dart';
import 'src/gavel.dart';
import 'src/generated/serverpod.dart';
import 'src/infra/timer_jobs.dart';

/// Starts the Gavel server: the API, plus the Flutter web app from `web/app`.
///
/// TaroDomain's definition is validated once the database is up, so a
/// broken configuration stops the server instead of failing requests. The
/// scheduled jobs run as future calls, or from timers where the plan
/// disables future calls (Serverpod Cloud's).
Future<void> run(List<String> args) async {
  final pod = Serverpod(args);
  final futureCalls = pod.config.futureCall.enabled;

  final taro = TaroDomainServerpod(
    gavelServerDefinition(),
    scheduleCatchUp: futureCalls
        ? (session, delay) =>
              pod.futureCalls.callWithDelay(delay).taroDomainCalls.catchUp()
        : null,
  )..install();

  // Static files with a fallback to index.html, so deep links such as
  // `/a/<CODE>` load the app. The build is plain JS, not WASM.
  pod.webServer.addRoute(
    FlutterRoute(Directory('web/app'), enableWasmHeaders: false),
  );

  await pod.start();
  try {
    await taro.validate(pod);
  } catch (e) {
    stderr.writeln('Invalid TaroDomain configuration: $e');
    await pod.shutdown(exitProcess: false);
    exit(1);
  }
  if (futureCalls) {
    await scheduleJobs(pod);
  } else {
    startTimerJobs(pod);
  }
  await _openDemo(pod);
}

/// Opens the public demo auction at start-up, so `/demo` works before the
/// demo job's first run. A failure is logged, not fatal: the job retries.
Future<void> _openDemo(Serverpod pod) async {
  final session = await pod.createSession(enableLogging: false);
  try {
    await ensureDemoOpen(session);
  } catch (e, stackTrace) {
    stderr.writeln('Opening the demo auction failed: $e\n$stackTrace');
  } finally {
    await session.close();
  }
}

/// Schedules the recurring jobs, TaroDomain's, the auction-close sweep and
/// the demo auction's, replacing any scheduled by an earlier start.
Future<void> scheduleJobs(Serverpod pod) async {
  final calls = pod.futureCalls;
  for (final job in ['catch-up', 'saga-timeouts', 'cleanup']) {
    await calls.cancel('tarodomain-$job');
  }
  await calls.cancel('gavel-auction-close-sweep');
  await calls.cancel('gavel-demo');
  await calls
      .callRecurring(identifier: 'gavel-auction-close-sweep')
      .every(const Duration(seconds: 5))
      .auctionCloseCalls
      .sweep();
  await calls
      .callRecurring(identifier: 'gavel-demo')
      .every(const Duration(seconds: 60))
      .demoCalls
      .ensureOpen();
  await calls
      .callRecurring(identifier: 'tarodomain-catch-up')
      .every(const Duration(seconds: 5))
      .taroDomainCalls
      .catchUp();
  await calls
      .callRecurring(identifier: 'tarodomain-saga-timeouts')
      .every(const Duration(seconds: 5))
      .taroDomainCalls
      .sagaTimeouts();
  await calls
      .callRecurring(identifier: 'tarodomain-cleanup')
      .cron('0 3 * * *')
      .taroDomainCalls
      .cleanup();
}
