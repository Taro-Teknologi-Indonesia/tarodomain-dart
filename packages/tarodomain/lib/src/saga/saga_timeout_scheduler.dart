import 'package:uuid/uuid.dart';

import '../adapters/saga_store_adapter.dart';
import '../errors/error_codes.dart';
import '../errors/framework_error.dart';
import 'saga_event_handler.dart';
import 'saga_timeout.dart';

/// What [SagaTimeoutScheduler] did with one timed-out saga.
enum SagaTimeoutOutcome {
  /// The saga's handler for [SagaTimeout] ran.
  handled,

  /// The saga was marked failed: it has no handler for [SagaTimeout], or
  /// the handler threw a non-retryable error.
  failed,

  /// The handler threw a retryable error. The saga is unchanged, so the
  /// next run tries again.
  retryLater,
}

/// Finds sagas of one type that have made no progress for [timeout] and
/// times them out (spec §19.1). Run it periodically, with one scheduler per
/// saga type when the types need different timeouts (spec §19.3).
///
/// A saga times out when it is running or compensating and was last saved
/// more than [timeout] ago. If it has a handler for [SagaTimeout], the
/// event is handed to it through [handler]; otherwise the saga is marked
/// failed with the reason `timeout`.
final class SagaTimeoutScheduler {
  /// Creates the scheduler. [clock] can be injected for tests.
  ///
  /// Throws [InvalidConfigurationError] if [timeout] isn't positive or
  /// [maxCount] is less than 1.
  SagaTimeoutScheduler({
    required this.handler,
    required this.timeout,
    this.maxCount = 100,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.timestamp {
    if (timeout <= Duration.zero || maxCount < 1) {
      throw InvalidConfigurationError(
        'Invalid SagaTimeoutScheduler settings',
        context: {
          'sagaType': handler.sagaType,
          'timeoutMs': timeout.inMilliseconds,
          'maxCount': maxCount,
        },
      );
    }
  }

  /// Runs the sagas, and gives the scheduler their type and store.
  final SagaEventHandler handler;

  /// How long a saga may go without being saved.
  final Duration timeout;

  /// The most sagas one [run] times out.
  final int maxCount;

  final DateTime Function() _clock;

  /// The saga type this scheduler times out.
  String get sagaType => handler.sagaType;

  /// Times out up to [maxCount] sagas, oldest first. Never throws for one
  /// saga's failure; the report shows it.
  ///
  /// A handler that throws a non-retryable error marks the saga failed. One
  /// that throws a retryable error, such as a concurrency conflict, leaves
  /// it as it is for the next run.
  Future<List<SagaTimeoutResult>> run() async {
    final store = handler.sagaStore;
    final timedOut = await store.loadTimedOut(
      _clock().subtract(timeout),
      sagaType: sagaType,
      limit: maxCount,
    );
    final results = <SagaTimeoutResult>[];
    for (final record in timedOut) {
      final event = SagaTimeout.forRecord(record, timeout);
      if (!handler.handles(event)) {
        results.add(await _fail(record, 'timeout'));
        continue;
      }
      try {
        await handler.handle(event);
        results.add(SagaTimeoutResult._(record, SagaTimeoutOutcome.handled));
      } catch (error, stackTrace) {
        results.add(
          shouldRetry(error)
              ? SagaTimeoutResult._(
                  record,
                  SagaTimeoutOutcome.retryLater,
                  error,
                  stackTrace,
                )
              : await _fail(
                  record,
                  'timeout handler failed: $error',
                  error,
                  stackTrace,
                ),
        );
      }
    }
    return results;
  }

  /// Marks the saga in [record] failed. If the store fails, reports
  /// [SagaTimeoutOutcome.retryLater] with the store's error instead.
  Future<SagaTimeoutResult> _fail(
    SagaRecord record,
    String reason, [
    Object? error,
    StackTrace? stackTrace,
  ]) async {
    try {
      await handler.sagaStore.fail(sagaType, record.sagaId, reason);
      return SagaTimeoutResult._(
        record,
        SagaTimeoutOutcome.failed,
        error,
        stackTrace,
      );
    } catch (storeError, storeStackTrace) {
      return SagaTimeoutResult._(
        record,
        SagaTimeoutOutcome.retryLater,
        storeError,
        storeStackTrace,
      );
    }
  }
}

/// What [SagaTimeoutScheduler.run] did with one saga.
final class SagaTimeoutResult {
  SagaTimeoutResult._(this.record, this.outcome, [this.error, this.stackTrace]);

  /// The saga as it was when it timed out.
  final SagaRecord record;

  /// What was done.
  final SagaTimeoutOutcome outcome;

  /// What the timeout handler threw, or null.
  final Object? error;

  /// Where [error] was thrown.
  final StackTrace? stackTrace;

  /// The saga ID.
  UuidValue get sagaId => record.sagaId;

  @override
  String toString() =>
      'SagaTimeoutResult(${record.sagaType}/$sagaId, ${outcome.name})';
}
