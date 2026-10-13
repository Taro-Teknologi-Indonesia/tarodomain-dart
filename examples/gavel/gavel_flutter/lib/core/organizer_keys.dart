import 'package:shared_preferences/shared_preferences.dart';

/// The organizer keys this browser holds, one per auction, in localStorage.
///
/// `create` returns the key once; without it the dashboard is read-only.
abstract final class OrganizerKeys {
  static String _name(String code) => 'gavel:${code.toUpperCase()}:org';

  /// The organizer key of the auction with join [code], if this browser
  /// created it.
  static Future<String?> load(String code) async =>
      (await SharedPreferences.getInstance()).getString(_name(code));

  /// Keeps [key] as the organizer key of the auction with join [code].
  static Future<void> save(String code, String key) async =>
      (await SharedPreferences.getInstance()).setString(_name(code), key);
}
