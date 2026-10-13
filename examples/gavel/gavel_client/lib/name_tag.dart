import 'package:serverpod_client/serverpod_client.dart';

/// The tag that tells two bidders with the same name apart (UC-09):
/// `#` and the last 4 hex characters of [participantId], as `#3f9c`.
///
/// The last ones, because participant IDs are UUIDv7 and lead with the
/// join time, which everyone joining the same evening shares. It makes a
/// receipt clear but proves nothing: the ID is public.
String nameTag(UuidValue participantId) {
  final hex = participantId.uuid.replaceAll('-', '').toLowerCase();
  return '#${hex.substring(hex.length - 4)}';
}
