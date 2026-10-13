import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../domain/participant.dart';
import '../generated/protocol.dart';

/// Stores [Participant]s in the `gavel_participants` table. Their events
/// still go to the event store and the bus.
class ParticipantRepository
    extends
        ServerpodStateRepository<Participant, ParticipantId, ParticipantRow> {
  /// Creates the repository for a runtime.
  ParticipantRepository(super.context);

  @override
  ParticipantRow toRow(Participant participant) => ParticipantRow(
    id: participant.id.value,
    auctionId: UuidValue.fromString(participant.auctionId),
    displayName: participant.displayName,
    keyHash: participant.keyHash,
    version: participant.version,
  );

  @override
  Participant fromRow(ParticipantRow row) => Participant.restore(
    ParticipantId.fromExisting(row.id!.uuid),
    auctionId: row.auctionId.uuid,
    displayName: row.displayName,
    keyHash: row.keyHash,
    version: row.version,
  );
}
