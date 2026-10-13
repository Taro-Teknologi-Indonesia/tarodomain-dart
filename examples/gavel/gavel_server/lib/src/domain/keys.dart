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
