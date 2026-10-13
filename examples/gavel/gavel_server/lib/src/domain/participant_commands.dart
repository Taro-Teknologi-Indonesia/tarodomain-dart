import 'package:tarodomain/tarodomain.dart';

import 'participant.dart';

/// Joins an auction as a new participant.
///
/// Whether the auction exists is checked by the caller against the read
/// model: the participant doesn't need the auction aggregate.
class JoinAuction extends Command {
  /// Creates the command.
  JoinAuction(
    this.participantId, {
    required this.auctionId,
    required this.displayName,
    required this.keyHash,
  });

  /// The new participant's ID.
  final ParticipantId participantId;

  /// The auction joined.
  final String auctionId;

  /// The name shown to the other bidders.
  final String displayName;

  /// The hash of the participant's secret key, never the key itself.
  final String keyHash;
}

/// Handles [JoinAuction].
class ParticipantHandler<C extends Command>
    extends AggregateCommandHandler<C, Participant, ParticipantId> {
  /// Creates the handler.
  ParticipantHandler(super.repository);

  @override
  Future<void> handle(C command) async {
    switch (command) {
      case JoinAuction(:final participantId):
        if (await exists(participantId)) {
          throw AggregateAlreadyExistsError(
            'Participant $participantId already exists',
            context: {'participantId': participantId.uuid},
          );
        }
        await save(
          Participant.join(
            participantId,
            auctionId: command.auctionId,
            displayName: command.displayName,
            keyHash: command.keyHash,
          ),
        );
    }
  }
}
