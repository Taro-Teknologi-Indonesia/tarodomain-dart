/// Where the app finds the Gavel API.
///
/// `--dart-define=GAVEL_API_URL=https://…/` wins. Otherwise a page served from
/// localhost talks to the local server on port 8080, and a deployed page to
/// `/api/` on its own origin.
String get apiUrl {
  const override = String.fromEnvironment('GAVEL_API_URL');
  if (override.isNotEmpty) return override;
  final base = Uri.base;
  if (base.host == 'localhost' || base.host == '127.0.0.1') {
    return 'http://${base.host}:8080/';
  }
  return '${base.origin}/api/';
}
