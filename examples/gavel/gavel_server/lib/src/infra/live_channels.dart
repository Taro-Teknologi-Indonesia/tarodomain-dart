import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../generated/protocol.dart';

/// The live channel of the auction with join [code].
String channelFor(String code) => 'auction:${code.trim().toUpperCase()}';

/// Posts [update] to the live channel of the auction with join [code].
///
/// Called from table projections after their row write: under strong
/// consistency the post waits for the command's commit, so a rolled-back
/// command never reaches a client.
Future<void> postLive(Session session, String code, LiveUpdate update) =>
    LiveProjectionNotifier(session).post(channelFor(code), update);
