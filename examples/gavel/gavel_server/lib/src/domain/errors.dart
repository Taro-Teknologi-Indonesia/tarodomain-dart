import 'package:tarodomain/tarodomain.dart';

/// A bid lost the race: someone else bid first.
///
/// [context] carries what the client needs to offer the next chip without
/// another fetch.
final class OutbidError extends DomainError {
  /// Creates the error for a lot whose price is now [currentPrice].
  OutbidError({
    required int currentPrice,
    required String? leaderName,
    required String? leaderId,
    required int version,
  }) : super(
         'Outbid: the price is now $currentPrice',
         context: {
           'currentPrice': currentPrice,
           'leaderName': leaderName,
           'leaderId': leaderId,
           'version': version,
         },
       );

  @override
  String get code => 'OUTBID';
}

/// The lot closed before the bid, retraction or Buy Now arrived.
final class LotClosedError extends DomainError {
  /// Creates the error for a lot that closed at [closedAt], SOLD to
  /// [winnerName] if it was, so a losing buyer reads who got it first.
  LotClosedError({required DateTime closedAt, String? winnerName})
    : super(
        'The lot closed at ${closedAt.toUtc().toIso8601String()}',
        context: {
          'closedAt': closedAt.toUtc().toIso8601String(),
          'winnerName': ?winnerName,
        },
      );

  @override
  String get code => 'LOT_CLOSED';
}

/// The raise is not one of the lot's kelipatan steps.
final class InvalidIncrementError extends DomainError {
  /// Creates the error for a lot at [currentPrice] that allows
  /// [allowedIncrements].
  InvalidIncrementError({
    required List<int> allowedIncrements,
    required int currentPrice,
  }) : super(
         'Raise must be one of $allowedIncrements',
         context: {
           'allowedIncrements': allowedIncrements,
           'currentPrice': currentPrice,
         },
       );

  @override
  String get code => 'INVALID_INCREMENT';
}

/// Why a retraction was refused.
enum RetractRefusal {
  /// The bid is no longer the latest one.
  notLatest('NOT_LATEST'),

  /// The bid belongs to someone else.
  notOwner('NOT_OWNER'),

  /// The lot has no bid to retract.
  noBids('NO_BIDS');

  const RetractRefusal(this.code);

  /// The value sent to the client.
  final String code;
}

/// A bid can't be retracted.
final class RetractNotAllowedError extends DomainError {
  /// Creates the error for [reason].
  RetractNotAllowedError(RetractRefusal reason)
    : super(
        'Retraction refused: ${reason.code}',
        context: {'reason': reason.code},
      );

  @override
  String get code => 'RETRACT_NOT_ALLOWED';
}

/// No auction has the join code.
final class AuctionNotFoundError extends DomainError {
  /// Creates the error for [code].
  AuctionNotFoundError(String code)
    : super('No auction with code $code', context: {'code': code});

  @override
  String get code => 'AUCTION_NOT_FOUND';
}

/// The organizer key does not match the auction's.
final class NotOrganizerError extends DomainError {
  /// Creates the error.
  NotOrganizerError() : super('Only the organizer can do this');

  @override
  String get code => 'NOT_ORGANIZER';
}

/// The participant is unknown, belongs to another auction, or presented the
/// wrong key.
final class NotParticipantError extends DomainError {
  /// Creates the error.
  NotParticipantError() : super('Not a participant of this auction');

  @override
  String get code => 'NOT_PARTICIPANT';
}
