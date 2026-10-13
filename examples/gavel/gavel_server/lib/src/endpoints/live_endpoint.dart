import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../infra/live_channels.dart';

/// Live updates of one auction, pushed to every subscribed browser.
class LiveEndpoint extends Endpoint {
  /// Streams every [LiveUpdate] of the auction with join [code] until the
  /// client disconnects.
  Stream<LiveUpdate> watch(Session session, String code) =>
      session.messages.createStream<LiveUpdate>(channelFor(code));

  /// Posts a `ping` to the auction with join [code], to check that every
  /// watcher gets it. Development mode only.
  Future<void> ping(Session session, String code) async {
    if (session.serverpod.runMode != ServerpodRunMode.development &&
        session.serverpod.runMode != ServerpodRunMode.test) {
      throw StateError('ping is available in development mode only');
    }
    await postLive(
      session,
      code,
      LiveUpdate(kind: LiveUpdateKind.ping, serverNow: DateTime.now().toUtc()),
    );
  }
}
