import 'dart:convert';

import 'package:gavel_client/gavel_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Who this browser bids as in one auction.
///
/// `join` returns the key once; the participant ID alone, which the ledger
/// shows, proves nothing.
class Identity {
  const Identity({
    required this.participantId,
    required this.participantKey,
    required this.displayName,
  });

  /// The identity [result] returned by `join`.
  Identity.joined(JoinResult result)
    : participantId = result.participantId,
      participantKey = result.participantKey,
      displayName = result.displayName;

  final UuidValue participantId;
  final String participantKey;
  final String displayName;

  Map<String, Object?> toJson() => {
    'participantId': participantId.uuid,
    'participantKey': participantKey,
    'displayName': displayName,
  };

  static Identity? _fromJson(Object? json) => switch (json) {
    {
      'participantId': final String id,
      'participantKey': final String key,
      'displayName': final String name,
    } =>
      Identity(
        participantId: UuidValue.withValidation(id),
        participantKey: key,
        displayName: name,
      ),
    _ => null,
  };
}

/// The bidder identities this browser holds, one per auction, in
/// localStorage.
abstract final class Identities {
  static String _name(String code) => 'gavel:${code.toUpperCase()}';

  /// The identity kept for the auction with join [code], if any and
  /// readable.
  static Future<Identity?> load(String code) async {
    final stored = (await SharedPreferences.getInstance()).getString(
      _name(code),
    );
    if (stored == null) return null;
    try {
      return Identity._fromJson(jsonDecode(stored));
    } on FormatException {
      return null;
    }
  }

  /// Keeps [identity] for the auction with join [code].
  static Future<void> save(String code, Identity identity) async =>
      (await SharedPreferences.getInstance()).setString(
        _name(code),
        jsonEncode(identity.toJson()),
      );

  /// Forgets the identity for the auction with join [code] only.
  static Future<void> forget(String code) async =>
      (await SharedPreferences.getInstance()).remove(_name(code));
}
