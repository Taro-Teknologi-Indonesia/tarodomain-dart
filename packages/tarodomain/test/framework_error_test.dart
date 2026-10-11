import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

class OptimisticConcurrencyError extends FrameworkError {
  OptimisticConcurrencyError(super.message, {super.context});

  @override
  String get code => 'OPTIMISTIC_CONCURRENCY';

  @override
  ErrorCategory get category => ErrorCategory.concurrency;
}

class AggregateNotFoundError extends FrameworkError {
  AggregateNotFoundError(super.message);

  @override
  String get code => 'AGGREGATE_NOT_FOUND';

  @override
  ErrorCategory get category => ErrorCategory.domain;
}

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
  });
}
