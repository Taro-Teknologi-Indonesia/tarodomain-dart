import 'package:gavel_client/gavel_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

import '../config.dart';

/// The app's one connection to the server.
final client = Client(apiUrl)
  ..connectivityMonitor = FlutterConnectivityMonitor();
