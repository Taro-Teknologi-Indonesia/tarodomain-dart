import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../infra/auction_creation.dart';

/// What only a signed-in organizer can do (X6).
///
/// `requireLogin` covers the whole endpoint, so these calls live apart from
/// the public `AuctionEndpoint`. A call without a valid token gets 401
/// before the method runs.
class OrganizerEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Creates an auction called [title] that closes at [closeAt], truncated
  /// to the second, schedules its close, and records the signed-in user
  /// as its creator.
  ///
  /// The returned organizer key is sent only this once.
  Future<CreatedAuction> create(
    Session session,
    String title,
    DateTime closeAt,
  ) => createAuction(
    session,
    title: title,
    closeAt: closeAt,
    organizerUserId: session.authenticated!.userIdentifier,
  );
}
