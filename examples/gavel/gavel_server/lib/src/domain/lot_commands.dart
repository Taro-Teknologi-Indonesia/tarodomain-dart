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

/// A handler that acts on a [Lot] as one of its auction's participants.
abstract class BidderHandler<C extends Command> extends CommandHandler<C> {
  /// Creates the handler.
  BidderHandler(this.participants, this.lots);

  /// Loads participants, for the bidder's name and auction.
  final Repository<Participant, ParticipantId> participants;

  /// Loads and saves lots.
  final Repository<Lot, LotId> lots;

  /// The participant [id], who must belong to [lot]'s auction.
  ///
  /// Throws [NotParticipantError] otherwise. The endpoint checked the key
  /// against the lot's auction already; this keeps a direct dispatch
  /// honest too.
  Future<Participant> bidder(ParticipantId id, Lot lot) async {
    final Participant participant;
    try {
      participant = await participants.load(id);
    } on AggregateNotFoundError {
      throw NotParticipantError();
    }
    if (participant.auctionId != lot.auctionId) throw NotParticipantError();
    return participant;
  }
}

/// Handles [PlaceBid]: reads the bidder's name from their [Participant] and
/// places the bid on the [Lot].
class PlaceBidHandler extends BidderHandler<PlaceBid> {
  /// Creates the handler.
  PlaceBidHandler(super.participants, super.lots);

  @override
  Future<void> handle(PlaceBid command) async {
    final lot = await lots.load(command.lotId);
    final participant = await bidder(command.participantId, lot);
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

/// Buys a lot at its Buy Now price as [participantId], who saw the lot at
/// [expectedVersion] (UC-13). The price comes from the lot, never from the
/// client. Its [timestamp] is "now" for the close-time check and the
/// close, set by the server.
///
/// The caller has already checked the participant's key; the command
/// carries only the verified ID.
class BuyNow extends Command {
  /// Creates the command. Pass the client's command ID as [id], so a
  /// resend is recognized as already processed.
  BuyNow(
    this.lotId,
    this.participantId, {
    required this.expectedVersion,
    super.id,
    super.timestamp,
  });

  /// The lot bought.
  final LotId lotId;

  /// Who buys.
  final ParticipantId participantId;

  /// The lot's version the buyer saw: any change since is an outbid.
  final int expectedVersion;
}

/// Handles [BuyNow]: reads the buyer's name from their [Participant] and
/// buys the [Lot], which closes it.
class BuyNowHandler extends BidderHandler<BuyNow> {
  /// Creates the handler.
  BuyNowHandler(super.participants, super.lots);

  @override
  Future<void> handle(BuyNow command) async {
    final lot = await lots.load(command.lotId);
    final participant = await bidder(command.participantId, lot);
    lot.buyNow(
      buyer: participant.id.uuid,
      buyerName: participant.displayName,
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

/// Closes a lot for [cause] (UC-08). Its [timestamp] is "now", the close
/// time of a cause other than the deadline.
class CloseLot extends Command {
  /// Creates the command.
  CloseLot(this.lotId, this.cause, {super.timestamp});

  /// The lot to close.
  final LotId lotId;

  /// Why it closes.
  final LotCloseCause cause;
}

/// Handles [CloseLot] on the [Lot]. A lot already closed saves nothing.
class CloseLotHandler extends CommandHandler<CloseLot> {
  /// Creates the handler.
  CloseLotHandler(this.lots);

  /// Loads and saves lots.
  final Repository<Lot, LotId> lots;

  @override
  Future<void> handle(CloseLot command) async {
    final lot = await lots.load(command.lotId)
      ..close(command.cause, command.timestamp);
    if (lot.hasUncommittedChanges) await lots.save(lot);
  }
}

/// Marks a SOLD lot's winner as not having paid (UC-14). Its [timestamp]
/// is when, set by the server.
class MarkUnpaid extends Command {
  /// Creates the command.
  MarkUnpaid(
    this.lotId, {
    required this.organizerKey,
    this.note,
    super.timestamp,
  });

  /// The SOLD lot.
  final LotId lotId;

  /// The organizer's secret, checked against the lot's auction. Commands
  /// aren't stored, so it never reaches the event store.
  final String organizerKey;

  /// A short public note, or null.
  final String? note;
}

/// Handles [MarkUnpaid]: checks the organizer on the lot's [Auction], then
/// marks the [Lot]. A lot already marked saves nothing.
class MarkUnpaidHandler extends CommandHandler<MarkUnpaid> {
  /// Creates the handler.
  MarkUnpaidHandler(this.auctions, this.lots);

  /// Loads auctions, for the organizer check.
  final Repository<Auction, AuctionId> auctions;

  /// Loads and saves lots.
  final Repository<Lot, LotId> lots;

  @override
  Future<void> handle(MarkUnpaid command) async {
    final lot = await lots.load(command.lotId);
    final auction = await auctions.load(AuctionId.fromExisting(lot.auctionId));
    if (!auction.isOrganizer(command.organizerKey)) {
      throw NotOrganizerError();
    }
    lot.markUnpaid(now: command.timestamp, note: command.note);
    if (lot.hasUncommittedChanges) await lots.save(lot);
  }
}
