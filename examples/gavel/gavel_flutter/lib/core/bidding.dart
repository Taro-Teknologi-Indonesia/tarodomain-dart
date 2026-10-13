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

/// Buys a lot at its Buy Now price: `LotEndpoint.buyNow`, or a fake in
/// tests.
typedef SendBuyNow =
    Future<LotCard> Function({
      required UuidValue lotId,
      required Identity identity,
      required int expectedVersion,
      required UuidValue commandId,
    });

/// [SendBuyNow] through [client].
SendBuyNow sendBuyNowWith(Client client) =>
    ({
      required lotId,
      required identity,
      required expectedVersion,
      required commandId,
    }) => client.lot.buyNow(
      lotId,
      identity.participantId,
      identity.participantKey,
      expectedVersion,
      commandId,
    );

/// Whether [lot] offers Buy Now: it has a BN price, is open, and bidding
/// hasn't reached the price (UC-13).
bool canBuyNow(LotCard lot) => switch (lot.buyNowPrice) {
  final bn? => lot.status == 'OPEN' && lot.currentPrice < bn,
  null => false,
};

/// What one tap on a chip, or on BUY NOW, came to.
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
/// A Buy Now (UC-13), sent through [_sendBuyNow], works the same way.
class Bidder {
  Bidder(this._send, [this._sendBuyNow]);

  final SendBid _send;
  final SendBuyNow? _sendBuyNow;

  /// Whether this bidder can send Buy Now.
  bool get canBuyNow => _sendBuyNow != null;

  /// The last Buy Now sent whose answer never arrived.
  ({UuidValue lotId, int version, UuidValue commandId})? _lostBuy;

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

  /// Buys [lot] at its Buy Now price as [identity], as seen at its
  /// version. The price comes from the server's lot, never from here.
  ///
  /// Never throws: every answer, a lost one included, is a [BidOutcome].
  Future<BidOutcome> buyNow(Identity identity, LotCard lot) async {
    final send = _sendBuyNow;
    if (send == null) throw StateError('This bidder has no Buy Now');
    final lost = _lostBuy;
    final commandId =
        lost != null && lost.lotId == lot.lotId && lost.version == lot.version
        ? lost.commandId
        : const Uuid().v7obj();
    _lostBuy = null;
    try {
      return BidAccepted(
        await send(
          lotId: lot.lotId,
          identity: identity,
          expectedVersion: lot.version,
          commandId: commandId,
        ),
      );
    } catch (e) {
      final failure = GavelFailure.from(e);
      if (failure is Unexpected) {
        _lostBuy = (
          lotId: lot.lotId,
          version: lot.version,
          commandId: commandId,
        );
      }
      return BidRefused(failure);
    }
  }
}
