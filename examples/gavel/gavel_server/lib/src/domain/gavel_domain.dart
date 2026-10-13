import 'package:tarodomain/tarodomain.dart';

import 'auction.dart';
import 'auction_close_saga.dart';
import 'auction_commands.dart';
import 'lot.dart';
import 'lot_commands.dart';
import 'participant.dart';
import 'participant_commands.dart';

/// Registers Gavel's aggregates and commands on [builder], with no provider
/// or read model, so the domain tests run it on `tarodomain_local`.
///
/// [participants] stores the state-based [Participant]; it defaults to an
/// [InMemoryParticipantRepository] shared by the runtime's repositories.
TaroDomainBuilder registerGavel(
  TaroDomainBuilder builder, {
  StateRepositoryFactory<Participant, ParticipantId>? participants,
}) {
  AuctionHandler<C> auction<C extends Command>(CommandContext c) =>
      AuctionHandler<C>(c.repository());
  final rows = <String, (Map<String, Object?>, int)>{};

  return builder
      .aggregate<Auction, AuctionId>(
        'Auction',
        (a) => a
            .factory(Auction.new)
            .event<AuctionCreated>('AuctionCreated', AuctionCreated.fromData)
            .event<LotRegistered>('LotRegistered', LotRegistered.fromData)
            .event<AuctionClosed>('AuctionClosed', AuctionClosed.fromData)
            .event<AuctionFinalized>(
              'AuctionFinalized',
              AuctionFinalized.fromData,
            ),
      )
      .aggregate<Lot, LotId>(
        'Lot',
        (a) => a
            .factory(Lot.new)
            .event<LotCreated>('LotCreated', LotCreated.fromData)
            .event<BidPlaced>('BidPlaced', BidPlaced.fromData)
            .event<BidRetracted>('BidRetracted', BidRetracted.fromData)
            .event<LotClosed>('LotClosed', LotClosed.fromData),
      )
      .aggregate<Participant, ParticipantId>(
        'Participant',
        (a) => a
            .stateRepository(
              participants ??
                  (c) => InMemoryParticipantRepository(c.eventBus, rows),
            )
            .event<ParticipantJoined>(
              'ParticipantJoined',
              ParticipantJoined.fromData,
            ),
      )
      .command<CreateAuction>('CreateAuction', auction)
      .command<CloseAuction>('CloseAuction', auction)
      .command<FinalizeAuction>('FinalizeAuction', auction)
      .command<AddLot>(
        'AddLot',
        (c) => AddLotHandler(c.repository(), c.repository()),
      )
      .command<PlaceBid>(
        'PlaceBid',
        (c) => PlaceBidHandler(c.repository(), c.repository()),
      )
      .command<RetractBid>(
        'RetractBid',
        (c) => RetractBidHandler(c.repository()),
      )
      .command<CloseLot>('CloseLot', (c) => CloseLotHandler(c.repository()))
      .command<JoinAuction>(
        'JoinAuction',
        (c) => ParticipantHandler<JoinAuction>(c.repository()),
      )
      // Closing normally completes within the close's own dispatch; the
      // timeout only catches a lot that never reports back.
      .saga(AuctionCloseSaga.new, timeout: const Duration(seconds: 30));
}
