import 'dart:convert';

import 'package:crypto/crypto.dart';

/// The SHA-256 of a secret key, hex-encoded. Only this is stored; the key
/// itself never enters a command, event or log.
String hashKey(String key) => sha256.convert(utf8.encode(key)).toString();

/// Whether [key] hashes to [expectedHash], compared in constant time so the
/// response time doesn't leak how much of the hash matched.
bool keyMatches(String key, String expectedHash) {
  final actual = hashKey(key);
  if (actual.length != expectedHash.length) return false;
  var difference = 0;
  for (var i = 0; i < actual.length; i++) {
    difference |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
  }
  return difference == 0;
}

/// Crockford base32: no I, L, O or U, so a code read out loud survives.
const _crockford = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// The code that proves who won the lot [lotId] (UC-09): HMAC-SHA256 over
/// the lot ID keyed with the winner's stored [keyHash], its first 30 bits
/// as 6 Crockford base32 characters, shown as `7KQ-2XM`.
///
/// Only the server can compute it, since [keyHash] never leaves it, and
/// only the winner's key unlocks it. It's computed on request and never
/// stored, put in an event, logged or pushed live.
String winnerCode(String keyHash, String lotId) {
  final mac = Hmac(sha256, utf8.encode(keyHash)).convert(utf8.encode(lotId));
  final bytes = mac.bytes;
  final bits = bytes[0] << 22 | bytes[1] << 14 | bytes[2] << 6 | bytes[3] >> 2;
  final chars = [
    for (var shift = 25; shift >= 0; shift -= 5)
      _crockford[(bits >> shift) & 0x1f],
  ].join();
  return '${chars.substring(0, 3)}-${chars.substring(3)}';
}
