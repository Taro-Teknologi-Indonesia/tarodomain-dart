import 'package:gavel_client/gavel_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import '../config.dart';

// `client.auth`, wherever the client is used.
export 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    show FlutterAuthSessionManagerExtension;

/// The app's one connection to the server. Only organizers ever sign in
/// (X6); bidders' calls carry no token.
final Client client = Client(apiUrl)
  ..connectivityMonitor = FlutterConnectivityMonitor()
  ..authSessionManager = FlutterAuthSessionManager();
