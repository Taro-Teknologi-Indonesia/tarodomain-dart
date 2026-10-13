import 'package:tarodomain/tarodomain.dart';

import 'auction.dart';
import 'auction_commands.dart';

/// Registers Gavel's aggregates and commands on [builder], with no provider
/// or read model, so the domain tests run it on `tarodomain_local`.
TaroDomainBuilder registerGavel(TaroDomainBuilder builder) {
  AuctionHandler<C> auction<C extends Command>(CommandContext c) =>
      AuctionHandler<C>(c.repository());

  return builder
      .aggregate<Auction, AuctionId>(
        'Auction',
        (a) => a
            .factory(Auction.new)
            .event<AuctionCreated>('AuctionCreated', AuctionCreated.fromData),
      )
      .command<CreateAuction>('CreateAuction', auction);
}
