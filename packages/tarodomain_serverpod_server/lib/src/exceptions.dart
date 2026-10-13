import 'dart:convert';

import 'package:tarodomain/tarodomain.dart';

import 'generated/protocol.dart';

/// Converts a [FrameworkError] to the serializable [TaroDomainException],
/// which Serverpod sends to clients as a typed exception.
extension FrameworkErrorToException on FrameworkError {
  /// This error as a [TaroDomainException]. Context values that aren't JSON
  /// are sent as their `toString()`.
  TaroDomainException toException() => TaroDomainException(
    code: code,
    category: category.name,
    retryable: retryable,
    httpStatus: httpStatus,
    message: message,
    context: context.isEmpty
        ? null
        : jsonEncode(context, toEncodable: (value) => value.toString()),
  );
}

/// Runs [action], converting a [FrameworkError] it throws to a
/// [TaroDomainException]. Other errors pass through, and Serverpod reports
/// them as internal server errors.
Future<T> rethrowAsTaroDomainException<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on FrameworkError catch (e, stackTrace) {
    Error.throwWithStackTrace(e.toException(), stackTrace);
  }
}
