import 'package:tarodomain/tarodomain.dart';

import 'auction.dart';

/// Creates an auction. Its [timestamp] is "now" for the close-time check,
/// so tests can pin it.
class CreateAuction extends Command {
  /// Creates the command.
  CreateAuction(
    this.auctionId, {
    required this.title,
    required this.closeAt,
    required this.code,
    required this.organizerKeyHash,
    super.timestamp,
  });

  /// The new auction's ID.
  final AuctionId auctionId;

  /// The auction's title.
  final String title;

  /// When the auction closes.
  final DateTime closeAt;

  /// The join code.
  final String code;

  /// The SHA-256 of the organizer key.
  final String organizerKeyHash;
}

/// Handles the [Auction] commands.
class AuctionHandler<C extends Command>
    extends AggregateCommandHandler<C, Auction, AuctionId> {
  /// Creates the handler.
  AuctionHandler(super.repository);

  @override
  Future<void> handle(C command) async {
    switch (command) {
      case CreateAuction(:final auctionId):
        if (await exists(auctionId)) {
          throw AggregateAlreadyExistsError(
            'Auction $auctionId already exists',
            context: {'auctionId': auctionId.uuid},
          );
        }
        await save(
          Auction.create(
            auctionId,
            title: command.title,
            closeAt: command.closeAt,
            code: command.code,
            organizerKeyHash: command.organizerKeyHash,
            now: command.timestamp,
          ),
        );
    }
  }
}
