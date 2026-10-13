import 'dart:io';

import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Endpoints, Protocol;

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
    await scheduleTaroDomainJobs(pod);
  } else {
    startTimerJobs(pod);
  }
}

/// Schedules TaroDomain's recurring jobs, replacing any scheduled by an
/// earlier start.
Future<void> scheduleTaroDomainJobs(Serverpod pod) async {
  final calls = pod.futureCalls;
  for (final job in ['catch-up', 'saga-timeouts', 'cleanup']) {
    await calls.cancel('tarodomain-$job');
  }
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
