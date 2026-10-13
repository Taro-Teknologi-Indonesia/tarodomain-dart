import 'package:uuid/uuid.dart';

import '../errors/error_codes.dart';
import 'uuids.dart';
import 'value_object.dart';

/// Typed UUID that identifies an aggregate (spec §2.4).
///
/// UUID generation and parsing come from the `uuid` package. Create a
/// subclass per aggregate so IDs can't be mixed up at compile time. Dart
/// doesn't inherit constructors, so each subclass forwards the ones it needs:
///
/// ```dart
/// class AccountId extends AggregateId {
///   AccountId.generate() : super.generate();
///   AccountId.fromExisting(super.uuid) : super.fromExisting();
///   AccountId.fromUuidv7(super.uuid) : super.fromUuidv7();
/// }
/// ```
class AggregateId extends ValueObject<UuidValue> {
  /// A fresh UUIDv7.
  AggregateId.generate() : super(newUuidV7());

  /// Parses [uuid], accepting any UUID version.
  ///
  /// Throws [ValueObjectInvalidError] if [uuid] is not a valid UUID.
  AggregateId.fromExisting(String uuid) : super(_parse(uuid, v7Only: false));

  /// Parses [uuid], accepting only version 7.
  ///
  /// Throws [ValueObjectInvalidError] if [uuid] is not a valid UUIDv7.
  AggregateId.fromUuidv7(String uuid) : super(_parse(uuid, v7Only: true));

  static UuidValue _parse(String input, {required bool v7Only}) {
    final uuid = tryParseUuid(input);
    if (uuid == null || (v7Only && !isUuidV7(uuid))) {
      throw ValueObjectInvalidError(
        v7Only ? 'Not a valid UUIDv7: "$input"' : 'Not a valid UUID: "$input"',
        context: {'value': input},
      );
    }
    return uuid;
  }

  /// The canonical lowercase string form of the UUID.
  String get uuid => value.uuid;

  @override
  String toString() => value.uuid;
}
