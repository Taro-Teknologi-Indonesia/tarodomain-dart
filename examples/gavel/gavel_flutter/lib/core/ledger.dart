import 'package:gavel_client/gavel_client.dart';

/// What a lot's ledger says about who leads and who may retract.
extension LedgerRules on List<LedgerEntry> {
  /// The latest bid not taken back: the one that leads, and the only one
  /// its bidder may retract (UC-07).
  LedgerEntry? get lastValid {
    for (final entry in reversed) {
      if (!entry.retracted) return entry;
    }
    return null;
  }

  /// Whether [me] has a bid here that wasn't taken back.
  bool hasValidBidBy(UuidValue? me) =>
      me != null && any((e) => !e.retracted && e.participantId == me);

  /// Whether [me] may retract on [lot]: it's open and [me] holds the latest
  /// valid bid.
  bool canRetract(LotCard lot, UuidValue? me) =>
      me != null && lot.status == 'OPEN' && lastValid?.participantId == me;
}
