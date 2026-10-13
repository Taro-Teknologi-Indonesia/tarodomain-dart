# UC-07 — Retract bid (Bidder, Must)

Depends on: UC-06. Demo beat 0:50–1:30 (the fat-fingered +300k).

## Goal

The holder of a lot's latest bid can void it after a confirm dialog. The bid stays in the ledger struck through **forever**, and the previous valid bid becomes leader again (or the price returns to the open bid). It's a compensating event, not a delete.

## Domain (`Lot`)

```dart
void retractBid({required ParticipantId by, required int expectedVersion, required DateTime now}) {
  if (status != LotStatus.open || !now.isBefore(closeAt)) throw LotClosedError(closedAt ?? closeAt); // 3b
  final last = lastValidBid;
  if (last == null) throw RetractNotAllowedError('NO_BIDS');
  if (last.bidder != by) throw RetractNotAllowedError('NOT_LATEST');                                   // 3a
  if (expectedVersion != version) throw OutbidError(currentPrice, last.bidderName, last.bidder, version); // 3c
  raise(BidRetracted(id, by, retractedSequence: last.sequence));
}
// apply(BidRetracted): bids.firstWhere((b) => b.sequence == e.retractedSequence).retracted = true;
```

Rule decisions:
- Only the **latest valid** bid can be retracted. After B retracts, A becomes the latest again and can retract too. That's fine and matches "previous bid becomes leader again".
- There's no retract limit for the MVP. Every retraction is public and permanent, and that is the deterrent. Write that sentence in the write-up.
- Ordering of checks: closed → no bids → not mine → stale version. A stale version after someone outbid me fails "not mine" first, which carries the more useful reason. That's still a typed error with no partial state (3c).

Command `RetractBid(lotId, participantId, expectedVersion)`, handled by `LotHandler` (single aggregate).

## Projection

`BidRetracted`:
1. Update the `LedgerEntry` at `(lotId, retractedSequence)`: `retracted = true, retractedAt = occurredAt`.
2. Recompute the card from the ledger rows: the last non-retracted entry → currentPrice/leader, else openBid with no leader. Then version++.
3. Post `LiveUpdate(lotChanged, lot, ledgerEntry: updatedEntry)`. The client replaces the entry by `sequence`.

## Endpoint

```dart
Future<LotCard> retractBid(Session s, UuidValue lotId, UuidValue participantId,
                           String participantKey, int expectedVersion,
                           UuidValue commandId);
```

The endpoint verifies the participant key first ([00-foundation §4](00-foundation.md)). This matters most here, because without it anyone reading the public ledger could retract the leader's bid by sending the leader's `participantId`.

## Flutter

- A RETRACT button in the lot action bar, visible only when `ledger.lastValid?.participantId == me && open`.
- Tap opens an `AlertDialog`: "**Retract your bid of Rp 450.000?** Everyone will see it struck through in the history." with buttons [Keep bid] [Retract]. The destructive style goes on Retract.
- On success, show a snackbar "Bid retracted — Budi leads again at Rp 150.000".
- Failures:
  - `RetractNotAllowed(NOT_LATEST)` → "Someone bid after you — you can't retract now."
  - `LotClosed` → "Lot closed."
  - `Outbid` → refetch, then "The lot changed — check again."
  - `NotParticipant` → forget the stored identity and prompt to join again.
- The ledger row animates to strike-through (a 300 ms `AnimatedDefaultTextStyle`), and it's never removed.

## Tests

Domain:
- A bids 150k, B bids 450k (fat finger), B retracts → current 150k, leader A, B's bid `retracted`, and the stream has 3 events.
- C tries to retract B's bid → `RetractNotAllowedError('NOT_LATEST')`.
- Retract with no bids → `NO_BIDS`.
- Retract after closeAt → `LotClosedError`.
- Retract-all → price = openBid, leader null.
- Bid after retraction uses the restored price (A at 150k, B can now bid +25k → 175k).

Integration: retract with the leader's `participantId` (copied from the ledger) but no valid key → `NOT_PARTICIPANT`, and the bid stays valid.

Integration: retract → the ledger row has `retracted = true`, the card is recomputed, and a live message is posted.

## Acceptance

- [ ] The confirm dialog shows the exact amount.
- [ ] All screens show the strike-through and the restored leader in under 1 s.
- [ ] The retracted entry stays in the ledger forever, after close and in time travel (UC-10).
- [ ] Every rejection is a typed error, with no half-applied state.

Estimate: 1 h.
