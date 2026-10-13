import 'dart:io';

import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Endpoints, Protocol;

import 'src/bank.dart';
import 'src/generated/serverpod.dart';

/// Starts the bank server.
///
/// TaroDomain's definition is validated once the database is up, so a
/// broken configuration stops the server instead of failing requests.
Future<void> run(List<String> args) async {
  final pod = Serverpod(args);

  final taro = TaroDomainServerpod(
    bankServerDefinition(),
    scheduleCatchUp: (session, delay) =>
        pod.futureCalls.callWithDelay(delay).taroDomainCalls.catchUp(),
  )..install();

  await pod.start();
  try {
    await taro.validate(pod);
  } catch (e) {
    stderr.writeln('Invalid TaroDomain configuration: $e');
    await pod.shutdown(exitProcess: false);
    exit(1);
  }
  await scheduleTaroDomainJobs(pod);
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
