import 'dart:math';

import '../errors/error_codes.dart';

/// Waits for [duration]. Tests inject one that returns at once.
typedef Sleep = Future<void> Function(Duration duration);

/// Checks stream versions and retries work that hit an optimistic
/// concurrency conflict (spec §11.5, §16).
///
/// The delay before retry `n` (counting from 0) is
/// `initialDelay * multiplier^n`, capped at [maxDelay], then moved by a
/// random offset of up to ±[jitter]. The defaults give 3 retries after
/// 10, 20 and 40 ms.
final class ConcurrencyChecker {
  /// Creates a checker. [random] and [sleep] can be injected for tests.
  ///
  /// Throws [InvalidConfigurationError] if a setting is out of range.
  ConcurrencyChecker({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 10),
    this.multiplier = 2,
    this.maxDelay = const Duration(seconds: 1),
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
        'Invalid ConcurrencyChecker settings',
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

  /// Throws [OptimisticConcurrencyError] unless [actual] equals [expected].
  ///
  /// The spec calls this `assert`, which is reserved in Dart.
  void check(int expected, int actual, String streamId) {
    if (expected == actual) return;
    throw OptimisticConcurrencyError(
      'Stream $streamId is at version $actual, expected $expected',
      context: {
        'streamId': streamId,
        'expectedVersion': expected,
        'actualVersion': actual,
      },
    );
  }

  /// Runs [operation], and runs it again after a delay each time it throws
  /// [OptimisticConcurrencyError], at most [maxRetries] times. Other errors,
  /// and the conflict after the last retry, are rethrown.
  ///
  /// [onRetry] is called before each delay with the retry number (from 0)
  /// and the conflict.
  Future<T> withRetry<T>(
    Future<T> Function() operation, {
    void Function(int retry, OptimisticConcurrencyError error)? onRetry,
  }) async {
    for (var retry = 0; ; retry++) {
      try {
        return await operation();
      } on OptimisticConcurrencyError catch (error) {
        if (retry >= maxRetries) rethrow;
        onRetry?.call(retry, error);
        await _sleep(computeDelay(retry));
      }
    }
  }

  /// The delay before retry number [retry], counting from 0, with jitter.
  Duration computeDelay(int retry) {
    final base = min(
      initialDelay.inMicroseconds * pow(multiplier, retry),
      maxDelay.inMicroseconds,
    );
    final offset = jitter * (2 * _random.nextDouble() - 1);
    return Duration(microseconds: (base * (1 + offset)).round());
  }
}
