import 'dart:math';

import '../command/concurrency_checker.dart';
import '../errors/error_codes.dart';
import '../errors/framework_error.dart' as errors show shouldRetry;

/// Retries work that failed with a retryable error (spec §21.3), such as an
/// event handler run by a queue consumer.
///
/// Whether an error is retryable comes from the error hierarchy
/// ([errors.shouldRetry]): concurrency and infrastructure errors are, domain
/// and configuration errors and anything that isn't a `FrameworkError` are
/// not.
///
/// The delay before retry `n` (counting from 0) is
/// `initialDelay * multiplier^n`, capped at [maxDelay], then moved by a
/// random offset of up to ±[jitter]. The defaults give 3 retries after
/// 100, 200 and 400 ms.
final class RetryPolicy {
  /// Creates a policy. [random] and [sleep] can be injected for tests.
  ///
  /// Throws [InvalidConfigurationError] if a setting is out of range.
  RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 100),
    this.multiplier = 2,
    this.maxDelay = const Duration(seconds: 30),
    this.jitter = 0.1,
    Random? random,
    Sleep? sleep,
  }) : _random = random ?? Random(),
       _sleep = sleep ?? Future<void>.delayed {
    if (maxRetries < 0 ||
        initialDelay.isNegative ||
        multiplier < 1 ||
        maxDelay < initialDelay ||
        jitter < 0 ||
        jitter >= 1) {
      throw InvalidConfigurationError(
        'Invalid RetryPolicy settings',
        context: {
          'maxRetries': maxRetries,
          'initialDelayMs': initialDelay.inMilliseconds,
          'multiplier': multiplier,
          'maxDelayMs': maxDelay.inMilliseconds,
          'jitter': jitter,
        },
      );
    }
  }

  /// How many times to retry after the first attempt.
  final int maxRetries;

  /// The delay before the first retry, before jitter.
  final Duration initialDelay;

  /// How much the delay grows with each retry.
  final num multiplier;

  /// The longest delay, before jitter.
  final Duration maxDelay;

  /// The largest random offset, as a fraction of the delay.
  final double jitter;

  final Random _random;
  final Sleep _sleep;

  /// Whether to retry after [error] ended attempt number [attempt],
  /// counting from 1.
  bool shouldRetry(Object error, int attempt) =>
      attempt <= maxRetries && errors.shouldRetry(error);

  /// The delay before retry number [retry], counting from 0, with jitter.
  Duration computeDelay(int retry) {
    final base = min(
      initialDelay.inMicroseconds * pow(multiplier, retry),
      maxDelay.inMicroseconds,
    );
    final offset = jitter * (2 * _random.nextDouble() - 1);
    return Duration(microseconds: (base * (1 + offset)).round());
  }

  /// Runs [operation], and runs it again after a delay each time it throws
  /// an error [shouldRetry] accepts. The last error is rethrown.
  ///
  /// [onAttempt] is called after every failed attempt with its number
  /// (from 1) and error, before deciding whether to retry.
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    void Function(int attempt, Object error)? onAttempt,
  }) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await operation();
      } catch (error) {
        onAttempt?.call(attempt, error);
        if (!shouldRetry(error, attempt)) rethrow;
        await _sleep(computeDelay(attempt - 1));
      }
    }
  }
}
