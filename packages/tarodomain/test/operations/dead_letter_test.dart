import 'dart:math';

import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// A [Random] whose doubles are always [value].
class FixedRandom implements Random {
  FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;
}

void main() {
  late List<Duration> sleeps;

  RetryPolicy policy({int maxRetries = 3, double random = 0.5}) => RetryPolicy(
    maxRetries: maxRetries,
    random: FixedRandom(random),
    sleep: (d) async => sleeps.add(d),
  );

  setUp(() => sleeps = []);

  group('RetryPolicy', () {
    test('defaults to 100, 200 and 400 ms', () {
      final p = policy();
      expect(
        [for (var i = 0; i < 3; i++) p.computeDelay(i)],
        const [
          Duration(milliseconds: 100),
          Duration(milliseconds: 200),
          Duration(milliseconds: 400),
        ],
      );
    });

    test('jitter moves the delay by up to 10%', () {
      expect(policy(random: 0).computeDelay(0), Duration(milliseconds: 90));
      expect(policy(random: 1).computeDelay(0), Duration(milliseconds: 110));
    });

    test('shouldRetry uses the error hierarchy and the attempt', () {
      final p = policy();
      expect(p.shouldRetry(retryableError(), 1), isTrue);
      expect(p.shouldRetry(retryableError(), 3), isTrue);
      expect(p.shouldRetry(retryableError(), 4), isFalse);
      expect(p.shouldRetry(domainError(), 1), isFalse);
      expect(p.shouldRetry(StateError('x'), 1), isFalse);
    });

    test('withRetry retries retryable errors until success', () async {
      var calls = 0;
      final attempts = <int>[];

      final result = await policy().withRetry(() async {
        if (++calls < 3) throw retryableError();
        return 'ok';
      }, onAttempt: (attempt, _) => attempts.add(attempt));

      expect(result, 'ok');
      expect(attempts, [1, 2]);
      expect(sleeps, const [
        Duration(milliseconds: 100),
        Duration(milliseconds: 200),
      ]);
    });

    test('withRetry rethrows after the last retry', () async {
      var calls = 0;

      await expectLater(
        policy(maxRetries: 2).withRetry(() async {
          calls++;
          throw retryableError();
        }),
        throwsA(isA<EventStoreError>()),
      );
      expect(calls, 3);
    });

    test('withRetry does not retry a non-retryable error', () async {
      var calls = 0;

      await expectLater(
        policy().withRetry(() async {
          calls++;
          throw domainError();
        }),
        throwsA(isA<InvalidAggregateStateError>()),
      );
      expect(calls, 1);
      expect(sleeps, isEmpty);
    });
  });

  group('DeadLetterWriter', () {
    late Store s;
    late DeadLetterWriter writer;

    setUp(() {
      s = Store();
      writer = DeadLetterWriter(
        retryPolicy: policy(),
        deadLetters: s.deadLetters,
      );
    });

    test('returns the result without writing on success', () async {
      final result = await writer.executeWithRetry(
        'p',
        MoneyDeposited(1),
        () async => 42,
      );

      expect(result, 42);
      expect(await s.deadLetters.count(), 0);
    });

    test('dead-letters the event after the retries run out', () async {
      final event = MoneyDeposited(1);

      await expectLater(
        writer.executeWithRetry('p', event, () async => throw retryableError()),
        throwsA(isA<EventStoreError>()),
      );

      final entry = (await s.deadLetters.get(event.id, 'p'))!;
      expect(entry.attempts, 4);
      expect(entry.errorCode, 'EVENT_STORE_ERROR');
      expect(entry.event, event.serialize());
      expect(sleeps, hasLength(3));
    });

    test('dead-letters a non-retryable error at once', () async {
      final event = MoneyDeposited(1);

      await expectLater(
        writer.executeWithRetry('p', event, () async => throw StateError('x')),
        throwsStateError,
      );

      final entry = (await s.deadLetters.get(event.id, 'p'))!;
      expect(entry.attempts, 1);
      expect(entry.errorCode, isNull);
      expect(entry.errorMessage, contains('x'));
    });

    test('throws DeadLetterError if the write fails', () async {
      final broken = DeadLetterWriter(
        retryPolicy: policy(maxRetries: 0),
        deadLetters: _BrokenDeadLetterStore(),
      );

      await expectLater(
        broken.executeWithRetry(
          'p',
          MoneyDeposited(1),
          () async => throw domainError(),
        ),
        throwsA(
          isA<DeadLetterError>().having((e) => e.cause, 'cause', isStateError),
        ),
      );
    });
  });
}

class _BrokenDeadLetterStore implements DeadLetterStore {
  @override
  Future<void> write(DeadLetterInput entry) async =>
      throw StateError('dead letters down');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
