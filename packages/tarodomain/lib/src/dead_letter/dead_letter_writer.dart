import '../adapters/dead_letter_store.dart';
import '../domain/domain_event.dart';
import '../errors/error_codes.dart';
import '../errors/framework_error.dart';
import 'retry_policy.dart';

/// Retries an event handler and quarantines the event if it still fails
/// (spec §21.2). Used by queue consumers, which must ack a message they
/// gave up on so that it isn't redelivered forever.
final class DeadLetterWriter {
  /// Creates the writer.
  DeadLetterWriter({required this.retryPolicy, required this.deadLetters});

  /// Decides which failures to retry, and how long to wait.
  final RetryPolicy retryPolicy;

  /// Where failed events go.
  final DeadLetterStore deadLetters;

  /// Runs [operation], which handles [event] for [handlerName], under the
  /// [retryPolicy].
  ///
  /// If it still fails, writes the event to [deadLetters] with the last
  /// error and the number of attempts, then rethrows that error: the caller
  /// can ack the message, since the event is in the dead letter store. If
  /// the write fails too, throws [DeadLetterError] instead, and the caller
  /// should not ack.
  Future<T> executeWithRetry<T>(
    String handlerName,
    DomainEvent event,
    Future<T> Function() operation,
  ) async {
    var attempts = 0;
    try {
      return await retryPolicy.withRetry(
        operation,
        onAttempt: (attempt, _) => attempts = attempt,
      );
    } catch (error, stackTrace) {
      try {
        await deadLetters.write(
          DeadLetterInput(
            handlerName: handlerName,
            event: event.serialize(),
            errorMessage: '$error',
            errorCode: error is FrameworkError ? error.code : null,
            attempts: attempts,
          ),
        );
      } catch (writeError, writeStackTrace) {
        throw DeadLetterError(
          'Could not dead-letter ${event.eventName} ${event.id} for '
          '"$handlerName" after $error: $writeError',
          context: {
            'handler': handlerName,
            'eventType': event.eventName,
            'eventId': event.id.uuid,
            'error': '$error',
          },
          cause: writeError,
          stackTrace: writeStackTrace,
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
