import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../domain/auction.dart';
import '../domain/lot.dart';
import '../domain/lot_commands.dart';
import '../generated/protocol.dart';
import '../infra/participant_guard.dart';

/// Adding lots and, from UC-06 on, bidding on them.
class LotEndpoint extends Endpoint {
  TaroDomainServerpod get _taro => TaroDomainServerpod.instance;

  /// Adds [lot] to the auction with join [code] and returns its card.
  ///
  /// Throws `AUCTION_NOT_FOUND` for an unknown code, `NOT_ORGANIZER` for a
  /// wrong [organizerKey], `LOT_CLOSED` once the auction has closed, and
  /// `COMMAND_VALIDATION` with the offending `field` for a bad lot.
  Future<LotCard> add(
    Session session,
    String code,
    String organizerKey,
    NewLot lot,
  ) => rethrowAsTaroDomainException(() async {
    final auction = await findAuction(session, code);

    final lotId = LotId.generate();
    await _taro.dispatch(
      session,
      AddLot(
        AuctionId.fromExisting(auction.auctionId.uuid),
        lotId,
        organizerKey: organizerKey,
        name: lot.name,
        openBid: lot.openBid,
        increments: lot.increments,
        description: lot.description,
        imageUrl: lot.imageUrl,
        tileEmoji: lot.tileEmoji,
        tileColor: lot.tileColor,
      ),
    );
    return (await LotCard.db.findFirstRow(
      session,
      where: (t) => t.lotId.equals(lotId.value),
    ))!;
  });
}
