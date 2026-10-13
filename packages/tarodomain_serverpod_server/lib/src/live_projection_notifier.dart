import 'package:serverpod/serverpod.dart';

import 'serverpod_unit_of_work.dart';

/// Posts live updates from projections to Serverpod message channels, which
/// endpoint streams forward to clients.
///
/// A message posted while a unit of work is active is sent only after it
/// commits, so clients never see a change that was rolled back.
final class LiveProjectionNotifier {
  /// Creates a notifier on [session].
  LiveProjectionNotifier(this.session, {this.scope = MessageScope.auto});

  /// The request's session.
  final Session session;

  /// Where messages go: this server, or every server through Redis.
  final MessageScope scope;

  /// Posts [message] to [channel] once the active unit of work commits, or
  /// at once if none is active.
  Future<void> post(String channel, SerializableModel message) =>
      ServerpodUnitOfWork.afterCommit(session, () async {
        await session.messages.postMessage(channel, message, scope: scope);
      });
}
