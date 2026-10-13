import 'package:gavel_client/gavel_client.dart';

import 'failures.dart';
import 'identity.dart';

/// Sends one bid: `LotEndpoint.placeBid`, or a fake in tests.
typedef SendBid =
    Future<LotCard> Function({
      required UuidValue lotId,
      required Identity identity,
      required int amount,
      required int expectedVersion,
      required UuidValue commandId,
    });

/// [SendBid] through [client].
SendBid sendBidWith(Client client) =>
    ({
      required lotId,
      required identity,
      required amount,
      required expectedVersion,
      required commandId,
    }) => client.lot.placeBid(
      lotId,
      identity.participantId,
      identity.participantKey,
      amount,
      expectedVersion,
      commandId,
    );

/// What one tap on a chip came to.
sealed class BidOutcome {
  const BidOutcome();
}

/// The bid stands; [card] is the lot with it.
final class BidAccepted extends BidOutcome {
  const BidAccepted(this.card);

  final LotCard card;
}

/// The bid was refused, or its answer never arrived.
final class BidRefused extends BidOutcome {
  const BidRefused(this.failure);

  final GavelFailure failure;
}

/// Places bids, one at a time, each with a client-made command ID.
///
/// When a bid's answer is lost, the same bid sent again reuses its command
/// ID, so the server counts it once whether or not the first one landed.
class Bidder {
  Bidder(this._send);

  final SendBid _send;

  /// The last bid sent whose answer never arrived.
  ({UuidValue lotId, int amount, int version, UuidValue commandId})? _lost;

  /// Bids one [step] over [lot]'s current price as [identity].
  ///
  /// Never throws: every answer, a lost one included, is a [BidOutcome].
  Future<BidOutcome> bid(Identity identity, LotCard lot, int step) async {
    final amount = lot.currentPrice + step;
    final lost = _lost;
    final commandId =
        lost != null &&
            lost.lotId == lot.lotId &&
            lost.amount == amount &&
            lost.version == lot.version
        ? lost.commandId
        : const Uuid().v7obj();
    _lost = null;
    try {
      return BidAccepted(
        await _send(
          lotId: lot.lotId,
          identity: identity,
          amount: amount,
          expectedVersion: lot.version,
          commandId: commandId,
        ),
      );
    } catch (e) {
      final failure = GavelFailure.from(e);
      if (failure is Unexpected) {
        _lost = (
          lotId: lot.lotId,
          amount: amount,
          version: lot.version,
          commandId: commandId,
        );
      }
      return BidRefused(failure);
    }
  }
}
