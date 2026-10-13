import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'all_errors.dart';

void main() {
  group('FrameworkError', () {
    test('derives retryability and HTTP status from the category', () {
      final conflict = OptimisticConcurrencyError(
        'stream moved',
        context: {'streamId': 'A-1'},
      );
      expect(conflict.retryable, isTrue);
      expect(conflict.httpStatus, 409);
      expect(
        conflict.toHttpResponse().body['error'],
        containsPair('code', 'OPTIMISTIC_CONCURRENCY'),
      );
      expect(conflict.context['streamId'], 'A-1');

      final missing = AggregateNotFoundError('no such account');
      expect(missing.retryable, isFalse);
      expect(missing.httpStatus, 400);
      expect(missing.toJson()['name'], 'AggregateNotFoundError');
    });

    test('only retries framework errors marked retryable', () {
      expect(shouldRetry(OptimisticConcurrencyError('x')), isTrue);
      expect(shouldRetry(AggregateNotFoundError('x')), isFalse);
      expect(shouldRetry(Exception('x')), isFalse);
    });

    test('context is unmodifiable', () {
      final error = EventStoreError('x', context: {'a': 1});
      expect(() => error.context['b'] = 2, throwsUnsupportedError);
    });

    test('log entry includes the cause', () {
      final error = EventAppendFailedError('x', cause: StateError('db down'));
      expect(error.toLogEntry()['cause'], contains('db down'));
    });
  });

  group('error codes (spec §22.2)', () {
    test('has all 51 codes, each once', () {
      expect(allErrors, hasLength(51));
      expect(allErrors.map((row) => row.$2).toSet(), hasLength(51));
    });

    test('category counts match the spec', () {
      int count(ErrorCategory category) =>
          allErrors.where((row) => row.$3 == category).length;
      expect(count(ErrorCategory.domain), 19);
      expect(count(ErrorCategory.concurrency), 3);
      expect(count(ErrorCategory.infrastructure), 18);
      expect(count(ErrorCategory.configuration), 11);
    });

    const expected = {
      ErrorCategory.domain: (retryable: false, status: 400),
      ErrorCategory.concurrency: (retryable: true, status: 409),
      ErrorCategory.infrastructure: (retryable: true, status: 500),
      ErrorCategory.configuration: (retryable: false, status: 500),
    };

    for (final (create, code, category) in allErrors) {
      test('$code is ${category.name}', () {
        final error = create('boom');
        expect(error.code, code);
        expect(error.category, category);
        expect(error.retryable, expected[category]!.retryable);
        expect(error.httpStatus, expected[category]!.status);
        expect(shouldRetry(error), expected[category]!.retryable);
        expect(error.toJson(), containsPair('code', code));
        expect(switch (category) {
          ErrorCategory.domain => error is DomainError,
          ErrorCategory.concurrency => error is ConcurrencyError,
          ErrorCategory.infrastructure => error is InfrastructureError,
          ErrorCategory.configuration => error is ConfigurationError,
        }, isTrue);
      });
    }
  });
}
