import 'package:tarodomain/tarodomain.dart';

import 'auction.dart';
import 'errors.dart';
import 'lot.dart';

/// Adds a lot to an auction. Its [timestamp] is "now" for the close-time
/// check, so tests can pin it.
class AddLot extends Command {
  /// Creates the command.
  AddLot(
    this.auctionId,
    this.lotId, {
    required this.organizerKey,
    required this.name,
    required this.openBid,
    required this.increments,
    required this.buyNowPrice,
    required this.description,
    required this.imageUrl,
    required this.tileEmoji,
    required this.tileColor,
    super.timestamp,
  });

  /// The auction to add the lot to.
  final AuctionId auctionId;

  /// The new lot's ID.
  final LotId lotId;

  /// The organizer's secret, checked against the auction's hash. Commands
  /// aren't stored, so it never reaches the event store.
  final String organizerKey;

  /// The lot's name.
  final String name;

  /// The first bid's minimum, in rupiah.
  final int openBid;

  /// The allowed raises, in rupiah, in any order.
  final List<int> increments;

  /// The Buy Now (BN) price, in rupiah, or null for no BN.
  final int? buyNowPrice;

  /// The seller's description.
  final String description;

  /// A photo of the lot, or null.
  final String? imageUrl;

  /// The tile's emoji.
  final String tileEmoji;

  /// The tile's background, as `#RRGGBB`.
  final String tileColor;
}

/// Handles [AddLot], which changes two aggregates: the [Auction] records
/// the lot and the new [Lot] is created.
///
/// Under strong consistency the whole handler runs in one unit of work, so
/// both appends commit together or not at all, and a conflict on the
/// auction stream retries the handler from a clean slate.
class AddLotHandler extends CommandHandler<AddLot> {
  /// Creates the handler.
  AddLotHandler(this.auctions, this.lots);

  /// Loads and saves auctions.
  final Repository<Auction, AuctionId> auctions;

  /// Loads and saves lots.
  final Repository<Lot, LotId> lots;

  @override
  Future<void> handle(AddLot command) async {
    final auction = await auctions.load(command.auctionId);
    if (!auction.isOrganizer(command.organizerKey)) {
      throw NotOrganizerError();
    }
    if (await lots.exists(command.lotId)) {
      throw AggregateAlreadyExistsError(
        'Lot ${command.lotId} already exists',
        context: {'lotId': command.lotId.uuid},
      );
    }
    final position = auction.lotIds.length;
    auction.registerLot(command.lotId.uuid, command.timestamp);
    final lot = Lot.create(
      command.lotId,
      auctionId: auction.id.uuid,
      code: auction.code,
      name: command.name,
      openBid: command.openBid,
      increments: command.increments,
      buyNowPrice: command.buyNowPrice,
      description: command.description,
      imageUrl: command.imageUrl,
      tileEmoji: command.tileEmoji,
      tileColor: command.tileColor,
      closeAt: auction.closeAt,
      position: position,
    );
    await lots.save(lot);
    await auctions.save(auction);
  }
}
