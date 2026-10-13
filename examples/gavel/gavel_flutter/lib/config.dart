/// Where the app finds the Gavel API.
///
/// `--dart-define=GAVEL_API_URL=https://…/` wins. Otherwise a page served from
/// localhost talks to the local server on port 8080, and a page served by
/// Serverpod Cloud from `<project>.serverpod.space` talks to
/// `<project>.api.serverpod.space`, so one build works locally and deployed.
String get apiUrl {
  const override = String.fromEnvironment('GAVEL_API_URL');
  if (override.isNotEmpty) return override;
  final host = Uri.base.host;
  if (host == 'localhost' || host == '127.0.0.1') {
    return 'http://$host:8080/';
  }
  const cloud = '.serverpod.space';
  if (host.endsWith(cloud)) {
    final project = host.substring(0, host.length - cloud.length);
    return 'https://$project.api.serverpod.space/';
  }
  throw UnsupportedError(
    'No API known for $host; build with --dart-define=GAVEL_API_URL=…',
  );
}
