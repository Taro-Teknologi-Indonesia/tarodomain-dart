import 'dart:math';

import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

void main() {
  late List<Duration> sleeps;

  setUp(() => sleeps = []);

  ConcurrencyChecker checker({Random? random, int maxRetries = 3}) =>
      ConcurrencyChecker(
        random: random ?? _FixedRandom(0.5),
        sleep: (d) async => sleeps.add(d),
        maxRetries: maxRetries,
      );

  group('computeDelay', () {
    test('defaults to 10, 20 and 40 ms without jitter', () {
      final c = checker();
      expect(
        [for (var i = 0; i < 3; i++) c.computeDelay(i)],
        const [
          Duration(milliseconds: 10),
          Duration(milliseconds: 20),
          Duration(milliseconds: 40),
        ],
      );
    });

    test('jitter stays within ±10%', () {
      expect(
        checker(random: _FixedRandom(0)).computeDelay(0),
        const Duration(microseconds: 9000),
      );
      expect(
        checker(random: _FixedRandom(1)).computeDelay(1),
        const Duration(microseconds: 22000),
      );
      final real = ConcurrencyChecker();
      for (var i = 0; i < 100; i++) {
        final delay = real.computeDelay(2).inMicroseconds;
        expect(delay, inInclusiveRange(36000, 44000));
      }
    });

    test('is capped at maxDelay', () {
      final c = ConcurrencyChecker(
        random: _FixedRandom(0.5),
        maxDelay: const Duration(milliseconds: 30),
      );
      expect(c.computeDelay(5), const Duration(milliseconds: 30));
    });
  });

  group('withRetry', () {
    test('retries conflicts, then returns the result', () async {
      var calls = 0;
      final retries = <int>[];
      final result = await checker().withRetry(() async {
        if (++calls < 3) throw OptimisticConcurrencyError('conflict');
        return 'done';
      }, onRetry: (retry, _) => retries.add(retry));

      expect(result, 'done');
      expect(calls, 3);
      expect(retries, [0, 1]);
      expect(sleeps, const [
        Duration(milliseconds: 10),
        Duration(milliseconds: 20),
      ]);
    });

    test('rethrows the conflict after the last retry', () async {
      var calls = 0;
      await expectLater(
        checker().withRetry<void>(() async {
          calls++;
          throw OptimisticConcurrencyError('conflict');
        }),
        throwsA(isA<OptimisticConcurrencyError>()),
      );
      expect(calls, 4);
      expect(sleeps, hasLength(3));
    });

    test('does not retry other errors', () async {
      var calls = 0;
      await expectLater(
        checker().withRetry<void>(() async {
          calls++;
          throw AggregateNotFoundError('missing');
        }),
        throwsA(isA<AggregateNotFoundError>()),
      );
      expect(calls, 1);
      expect(sleeps, isEmpty);
    });

    test('maxRetries 0 runs once', () async {
      var calls = 0;
      await expectLater(
        checker(maxRetries: 0).withRetry<void>(() async {
          calls++;
          throw OptimisticConcurrencyError('conflict');
        }),
        throwsA(isA<OptimisticConcurrencyError>()),
      );
      expect(calls, 1);
    });
  });

  test('check throws on a version mismatch', () {
    final c = checker();
    c.check(3, 3, 's');
    expect(
      () => c.check(3, 4, 's'),
      throwsA(
        isA<OptimisticConcurrencyError>().having((e) => e.context, 'context', {
          'streamId': 's',
          'expectedVersion': 3,
          'actualVersion': 4,
        }),
      ),
    );
  });

  test('rejects invalid settings', () {
    expect(
      () => ConcurrencyChecker(maxRetries: -1),
      throwsA(isA<InvalidConfigurationError>()),
    );
    expect(
      () => ConcurrencyChecker(jitter: 1),
      throwsA(isA<InvalidConfigurationError>()),
    );
  });
}

class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
