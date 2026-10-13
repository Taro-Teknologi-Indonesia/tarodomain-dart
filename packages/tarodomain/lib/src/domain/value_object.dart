import 'package:collection/collection.dart';

import '../errors/error_codes.dart';
import '../errors/framework_error.dart';

/// An object defined by its value rather than its identity (spec §2.3).
///
/// Subclasses check their invariants by overriding [validate], which runs on
/// construction. Two value objects are equal when they have the same runtime
/// type and structurally equal values, so `AccountId` and `TransferId` holding
/// the same UUID are not equal.
///
/// Dart reserves `with`, and a base class can't construct an instance of its
/// subclass, so there is no generic functional update. Subclasses that need
/// one write their own `copyWith`:
///
/// ```dart
/// class Money extends ValueObject<({int cents, String currency})> {
///   Money(super.value);
///
///   Money copyWith({int? cents}) =>
///       Money((cents: cents ?? value.cents, currency: value.currency));
/// }
/// ```
abstract class ValueObject<T extends Object> {
  /// Creates the value object and runs [validate] on [value].
  ///
  /// A [FrameworkError] thrown by [validate] propagates unchanged; anything
  /// else is wrapped in [ValueObjectConstructionFailedError].
  ValueObject(this.value) {
    try {
      validate(value);
    } on FrameworkError {
      rethrow;
    } catch (error, stackTrace) {
      throw ValueObjectConstructionFailedError(
        'Validation of $runtimeType threw: $error',
        context: {'type': '$runtimeType'},
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// The wrapped value. Collections are compared structurally, but are not
  /// copied, so pass unmodifiable ones.
  final T value;

  /// Checks the invariants of [value]. Throw [ValueObjectInvalidError] when
  /// one is violated. The default accepts every value.
  void validate(T value) {}

  static const _equality = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueObject<T> &&
          other.runtimeType == runtimeType &&
          _equality.equals(value, other.value);

  @override
  int get hashCode => Object.hash(runtimeType, _equality.hash(value));

  @override
  String toString() => '$runtimeType($value)';
}

/// Adds ordering to a [ValueObject] whose value is [Comparable].
///
/// Comparing value objects of different runtime types throws
/// [IncomparableValueError].
mixin OrderedValueObject<T extends Comparable<Object?>> on ValueObject<T>
    implements Comparable<ValueObject<T>> {
  @override
  int compareTo(ValueObject<T> other) {
    if (other.runtimeType != runtimeType) {
      throw IncomparableValueError(
        'Cannot compare $runtimeType with ${other.runtimeType}',
        context: {'left': '$runtimeType', 'right': '${other.runtimeType}'},
      );
    }
    return value.compareTo(other.value);
  }
}
