import 'dart:convert';

import 'package:tarodomain_serverpod_client/tarodomain_serverpod_client.dart';

/// A failed server call, typed by the server's error `code`.
///
/// The UI switches on the subtype and never on message strings.
sealed class GavelFailure {
  const GavelFailure();

  /// Turns any error thrown by a [client] call into a failure.
  factory GavelFailure.from(Object error) {
    if (error is ServerpodClientUnauthorized) return const SignedOut();
    if (error is! TaroDomainException) return Unexpected(error.toString());
    final context = _decode(error.context);
    return switch (error.code) {
      'OUTBID' => Outbid(
        currentPrice: context['currentPrice'] as int,
        leaderName: context['leaderName'] as String?,
        leaderId: context['leaderId'] as String?,
        version: context['version'] as int,
      ),
      'LOT_CLOSED' => LotClosed(
        DateTime.parse(context['closedAt'] as String),
        winnerName: context['winnerName'] as String?,
      ),
      'INVALID_INCREMENT' => InvalidIncrement(
        allowedIncrements: [
          for (final step in context['allowedIncrements'] as List) step as int,
        ],
        currentPrice: context['currentPrice'] as int,
      ),
      'RETRACT_NOT_ALLOWED' => RetractNotAllowed(context['reason'] as String),
      'AUCTION_NOT_FOUND' => AuctionNotFound(context['code'] as String),
      'NOT_ORGANIZER' => const NotOrganizer(),
      'NOT_PARTICIPANT' => const NotParticipant(),
      'AGGREGATE_NOT_FOUND' => const NotFound(),
      'COMMAND_VALIDATION' => Invalid(error.message, context),
      _ => Unexpected(error.message),
    };
  }

  static Map<String, Object?> _decode(String? json) =>
      json == null ? const {} : (jsonDecode(json) as Map).cast();
}

/// Someone else bid first.
final class Outbid extends GavelFailure {
  const Outbid({
    required this.currentPrice,
    required this.leaderName,
    required this.leaderId,
    required this.version,
  });

  final int currentPrice;
  final String? leaderName;
  final String? leaderId;

  /// The lot's version now: the next bid's `expectedVersion`.
  final int version;
}

/// The lot closed before the call arrived.
final class LotClosed extends GavelFailure {
  const LotClosed(this.closedAt, {this.winnerName});

  final DateTime closedAt;

  /// Who the lot was SOLD to, if it was.
  final String? winnerName;
}

/// The raise isn't one of the lot's kelipatan steps.
final class InvalidIncrement extends GavelFailure {
  const InvalidIncrement({
    required this.allowedIncrements,
    required this.currentPrice,
  });

  final List<int> allowedIncrements;
  final int currentPrice;
}

/// A retraction was refused: `NOT_LATEST`, `NOT_OWNER` or `NO_BIDS`.
final class RetractNotAllowed extends GavelFailure {
  const RetractNotAllowed(this.reason);

  final String reason;
}

/// No auction has the join code.
final class AuctionNotFound extends GavelFailure {
  const AuctionNotFound(this.code);

  final String code;
}

/// The organizer key didn't match.
final class NotOrganizer extends GavelFailure {
  const NotOrganizer();
}

/// The stored identity isn't a participant of this auction.
final class NotParticipant extends GavelFailure {
  const NotParticipant();
}

/// The call needs a signed-in organizer and the session is gone (X6).
final class SignedOut extends GavelFailure {
  const SignedOut();
}

/// The lot doesn't exist, or didn't yet at the moment asked about (UC-10).
final class NotFound extends GavelFailure {
  const NotFound();
}

/// The server rejected a field of the request.
final class Invalid extends GavelFailure {
  const Invalid(this.message, this.context);

  final String message;
  final Map<String, Object?> context;
}

/// Anything else: network trouble or a server bug.
final class Unexpected extends GavelFailure {
  const Unexpected(this.message);

  final String message;
}
