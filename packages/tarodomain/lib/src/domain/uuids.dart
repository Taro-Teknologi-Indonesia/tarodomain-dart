import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A fresh time-ordered UUIDv7.
@internal
UuidValue newUuidV7() => _uuid.v7obj();

/// Namespace for hashing names in [derivedUuidV7].
const _derivedIdNamespace = '9a84a777-ab28-5008-920f-727995f34bdb';

/// A UUIDv7 that is a function of its inputs: [time] in milliseconds as the
/// timestamp, and a SHA-1 hash of [name] as the 74 bits RFC 9562 leaves to
/// the implementation. The same inputs always give the same ID, and IDs
/// still sort by [time].
@internal
UuidValue derivedUuidV7(DateTime time, String name) {
  final hash = _uuid.v5obj(_derivedIdNamespace, name).toBytes();
  final bytes = Uint8List(16);
  var ms = time.millisecondsSinceEpoch;
  for (var i = 5; i >= 0; i--) {
    bytes[i] = ms % 256;
    ms ~/= 256;
  }
  bytes[6] = 0x70 | (hash[6] & 0x0f);
  bytes[7] = hash[7];
  bytes[8] = 0x80 | (hash[8] & 0x3f);
  bytes.setRange(9, 16, hash, 9);
  return UuidValue.fromByteList(bytes);
}

/// Parses [input] as a UUID of any version, or returns null if it isn't one.
@internal
UuidValue? tryParseUuid(String input) {
  final normalized = input.toLowerCase();
  if (!Uuid.isValidUUID(fromString: normalized)) return null;
  return UuidValue.fromString(normalized);
}

/// Whether [uuid] is a version 7 UUID.
///
/// Reads the version digit directly, because `UuidValue.version` throws on
/// the max UUID (`ffffffff-…`).
@internal
bool isUuidV7(UuidValue uuid) => uuid.uuid[14] == '7';
