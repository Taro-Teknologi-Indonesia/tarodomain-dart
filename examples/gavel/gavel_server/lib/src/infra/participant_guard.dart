import 'package:serverpod/serverpod.dart';

import '../domain/errors.dart';
import '../domain/keys.dart';
import '../generated/protocol.dart';

/// The auction with join [code], trimmed and upper-cased.
///
/// Throws [AuctionNotFoundError] if no auction has the code.
Future<AuctionView> findAuction(Session session, String code) async {
  final normalized = code.trim().toUpperCase();
  return await AuctionView.db.findFirstRow(
        session,
        where: (t) => t.code.equals(normalized),
      ) ??
      (throw AuctionNotFoundError(normalized));
}

/// The participant [participantId] of the auction [auctionId], if [key] is
/// their participant key.
///
/// Throws [NotParticipantError] for an unknown participant, one of another
/// auction, or a wrong key, all alike, so callers dispatch nothing.
Future<ParticipantRow> verifyParticipant(
  Session session,
  UuidValue auctionId,
  UuidValue participantId,
  String key,
) async {
  final row = await ParticipantRow.db.findById(session, participantId);
  // Hash the key even for an unknown participant, so timing doesn't tell
  // the cases apart.
  final matches = keyMatches(key, row?.keyHash ?? '');
  if (row == null || row.auctionId != auctionId || !matches) {
    throw NotParticipantError();
  }
  return row;
}
