/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// A TaroDomain `FrameworkError` sent to a client (spec §22). Endpoints
/// convert framework errors to this, so Flutter clients get typed errors.
abstract class TaroDomainException
    implements
        _isc.SerializableException,
        _isc.SerializableModel,
        _isc.ProtocolSerialization {
  TaroDomainException._({
    required this.code,
    required this.category,
    required this.retryable,
    required this.httpStatus,
    required this.message,
    this.context,
  });

  factory TaroDomainException({
    required String code,
    required String category,
    required bool retryable,
    required int httpStatus,
    required String message,
    String? context,
  }) = _TaroDomainExceptionImpl;

  factory TaroDomainException.fromJson(Map<String, dynamic> jsonSerialization) {
    return TaroDomainException(
      code: jsonSerialization['code'] as String,
      category: jsonSerialization['category'] as String,
      retryable: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['retryable'],
      ),
      httpStatus: jsonSerialization['httpStatus'] as int,
      message: jsonSerialization['message'] as String,
      context: jsonSerialization['context'] as String?,
    );
  }

  /// The error code, such as `INSUFFICIENT_FUNDS`.
  String code;

  /// The error category: `domain`, `concurrency`, `infrastructure` or
  /// `configuration`.
  String category;

  /// Whether retrying the same request may succeed.
  bool retryable;

  /// The HTTP status the spec assigns to the error.
  int httpStatus;

  /// The error message.
  String message;

  /// The error's context as JSON.
  String? context;

  /// Returns a shallow copy of this [TaroDomainException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  TaroDomainException copyWith({
    String? code,
    String? category,
    bool? retryable,
    int? httpStatus,
    String? message,
    String? context,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'tarodomain_serverpod.TaroDomainException',
      'code': code,
      'category': category,
      'retryable': retryable,
      'httpStatus': httpStatus,
      'message': message,
      if (context != null) 'context': context,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'tarodomain_serverpod.TaroDomainException',
      'code': code,
      'category': category,
      'retryable': retryable,
      'httpStatus': httpStatus,
      'message': message,
      if (context != null) 'context': context,
    };
  }

  @override
  String toString() {
    return 'TaroDomainException(code: $code, category: $category, retryable: $retryable, httpStatus: $httpStatus, message: $message, context: $context)';
  }
}

class _Undefined {}

class _TaroDomainExceptionImpl extends TaroDomainException {
  _TaroDomainExceptionImpl({
    required String code,
    required String category,
    required bool retryable,
    required int httpStatus,
    required String message,
    String? context,
  }) : super._(
         code: code,
         category: category,
         retryable: retryable,
         httpStatus: httpStatus,
         message: message,
         context: context,
       );

  /// Returns a shallow copy of this [TaroDomainException]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  TaroDomainException copyWith({
    String? code,
    String? category,
    bool? retryable,
    int? httpStatus,
    String? message,
    Object? context = _Undefined,
  }) {
    return TaroDomainException(
      code: code ?? this.code,
      category: category ?? this.category,
      retryable: retryable ?? this.retryable,
      httpStatus: httpStatus ?? this.httpStatus,
      message: message ?? this.message,
      context: context is String? ? context : this.context,
    );
  }
}
