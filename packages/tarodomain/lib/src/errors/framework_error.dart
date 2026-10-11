/// Error categories from spec §22.1. The category decides retryability and
/// HTTP status.
enum ErrorCategory {
  /// Business rule violation. Retrying won't help.
  domain(retryable: false, httpStatus: 400),

  /// Transient conflict. A retry might succeed.
  concurrency(retryable: true, httpStatus: 409),

  /// Transient failure. A retry might succeed.
  infrastructure(retryable: true, httpStatus: 500),

  /// Framework misconfiguration. Retrying won't help.
  configuration(retryable: false, httpStatus: 500);

  const ErrorCategory({required this.retryable, required this.httpStatus});

  /// Whether an operation that failed with this category may succeed on retry.
  final bool retryable;

  /// HTTP status code reported for this category.
  final int httpStatus;
}

/// Base class for every error the framework throws (spec §22.3).
abstract class FrameworkError implements Exception {
  /// Creates an error with a human-readable [message].
  FrameworkError(
    this.message, {
    Map<String, Object?> context = const {},
    this.cause,
    this.stackTrace,
  }) : context = Map.unmodifiable(context);

  /// Stable machine-readable code, such as `OPTIMISTIC_CONCURRENCY`.
  String get code;

  /// Category that decides [retryable] and [httpStatus].
  ErrorCategory get category;

  /// Human-readable description.
  final String message;

  /// Extra details, such as the stream ID or the expected version.
  final Map<String, Object?> context;

  /// The underlying error, if this one wraps another.
  final Object? cause;

  /// Stack trace of [cause], if known.
  final StackTrace? stackTrace;

  /// Whether the failed operation may succeed on retry.
  bool get retryable => category.retryable;

  /// HTTP status code to report to API callers.
  int get httpStatus => category.httpStatus;

  /// JSON-safe representation for API responses.
  Map<String, Object?> toJson() => {
    'name': runtimeType.toString(),
    'code': code,
    'category': category.name,
    'message': message,
    'retryable': retryable,
    'context': context,
  };

  /// Status and body for an HTTP error response.
  ({int status, Map<String, Object?> body}) toHttpResponse() =>
      (status: httpStatus, body: {'error': toJson()});

  /// Structured entry for logging, including the cause.
  Map<String, Object?> toLogEntry() => {
    ...toJson(),
    if (cause != null) 'cause': cause.toString(),
    if (stackTrace != null) 'stackTrace': stackTrace.toString(),
  };

  @override
  String toString() => '$runtimeType($code): $message';
}

/// True when an operation that threw [error] may succeed on retry. Errors from
/// outside the framework are not retried.
bool shouldRetry(Object error) => error is FrameworkError && error.retryable;
