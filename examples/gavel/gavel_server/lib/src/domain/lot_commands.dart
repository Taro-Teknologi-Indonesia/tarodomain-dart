import 'package:tarodomain/tarodomain.dart';

import 'auction.dart';
import 'errors.dart';
import 'lot.dart';
import 'participant.dart';

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

/// Bids [amount] on a lot as [participantId], who saw the lot at
/// [expectedVersion]. Its [timestamp] is "now" for the close-time check,
/// set by the server and never taken from the client.
///
/// The caller has already checked the participant's key; the command
/// carries only the verified ID.
class PlaceBid extends Command {
  /// Creates the command. Pass the client's command ID as [id], so a
  /// resend is recognized as already processed.
  PlaceBid(
    this.lotId,
    this.participantId, {
    required this.amount,
    required this.expectedVersion,
    super.id,
    super.timestamp,
  });

  /// The lot bid on.
  final LotId lotId;

  /// Who bids.
  final ParticipantId participantId;

  /// The bid, in rupiah.
  final int amount;

  /// The lot's version the bidder saw: any change since is an outbid.
  final int expectedVersion;
}

/// Handles [PlaceBid]: reads the bidder's name from their [Participant] and
/// places the bid on the [Lot].
class PlaceBidHandler extends CommandHandler<PlaceBid> {
  /// Creates the handler.
  PlaceBidHandler(this.participants, this.lots);

  /// Loads participants, for the bidder's name and auction.
  final Repository<Participant, ParticipantId> participants;

  /// Loads and saves lots.
  final Repository<Lot, LotId> lots;

  @override
  Future<void> handle(PlaceBid command) async {
    final lot = await lots.load(command.lotId);
    final Participant participant;
    try {
      participant = await participants.load(command.participantId);
    } on AggregateNotFoundError {
      throw NotParticipantError();
    }
    // The endpoint checked the key against the lot's auction already; this
    // keeps a direct dispatch honest too.
    if (participant.auctionId != lot.auctionId) throw NotParticipantError();
    lot.placeBid(
      bidder: participant.id.uuid,
      bidderName: participant.displayName,
      amount: command.amount,
      expectedVersion: command.expectedVersion,
      now: command.timestamp,
    );
    await lots.save(lot);
  }
}

/// Takes back [participantId]'s bid on a lot, the latest valid one, seen at
/// [expectedVersion]. Its [timestamp] is "now" for the close-time check,
/// set by the server.
///
/// The caller has already checked the participant's key; the command
/// carries only the verified ID.
class RetractBid extends Command {
  /// Creates the command. Pass the client's command ID as [id], so a
  /// resend is recognized as already processed.
  RetractBid(
    this.lotId,
    this.participantId, {
    required this.expectedVersion,
    super.id,
    super.timestamp,
  });

  /// The lot whose bid is taken back.
  final LotId lotId;

  /// Who retracts.
  final ParticipantId participantId;

  /// The lot's version the bidder saw.
  final int expectedVersion;
}

/// Handles [RetractBid] on the [Lot].
class RetractBidHandler extends CommandHandler<RetractBid> {
  /// Creates the handler.
  RetractBidHandler(this.lots);

  /// Loads and saves lots.
  final Repository<Lot, LotId> lots;

  @override
  Future<void> handle(RetractBid command) async {
    final lot = await lots.load(command.lotId);
    lot.retractBid(
      by: command.participantId.uuid,
      expectedVersion: command.expectedVersion,
      now: command.timestamp,
    );
    await lots.save(lot);
  }
}
