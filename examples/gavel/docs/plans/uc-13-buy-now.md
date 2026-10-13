# UC-13 — Buy Now ("BN") (Bidder, Should — only if ahead, not in the video)

Depends on: [UC-02b](uc-02b-buy-now-price.md) (the BN price on lots), UC-06 (same command shape and races), UC-08 (shares the close logic). About 45 min.

## Goal

In a Facebook lelang the seller's template has a `BN:` price, and a collector who comments "BN" instead of a number takes the lot at that price, ending the auction for that item. In Gavel the bidder taps **BUY NOW** instead of a kelipatan chip. The lot closes immediately as SOLD to that bidder at the BN price, with `cause = BUY_NOW`. It's the same strong-consistency path as `PlaceBid`, so a BN and a chip tap that collide get one clean typed answer.

The BN price itself (`Lot.buyNowPrice`, the form field, the `LotCard` column and the board tag) comes from [UC-02b](uc-02b-buy-now-price.md). Null means "no BN on this lot", and BUY NOW is never shown.

## Domain (`Lot`)

```dart
void buyNow({required ParticipantId buyer, required String buyerName,
             required int expectedVersion, required DateTime now}) {
  // 1. Closed beats everything, as in placeBid.
  if (status != LotStatus.open || !now.isBefore(closeAt)) throw LotClosedError(closedAt ?? closeAt);
  // 2. No BN on this lot.
  if (buyNowPrice == null) throw CommandValidationError(..., reason: 'NO_BUY_NOW');
  // 3. Stale view → OutbidError, as in placeBid. The buyer never pays a BN they
  //    didn't see next to the price they saw.
  if (expectedVersion != version) throw OutbidError(currentPrice, lastValidBid?.bidderName, lastValidBid?.bidder, version);
  // 4. Bidding already reached the BN price: BN is gone, keep bidding.
  if (currentPrice >= buyNowPrice!) throw CommandValidationError(..., reason: 'BUY_NOW_PASSED');
  raise(BidPlaced(id, buyer, buyerName, buyNowPrice!, sequence: bids.length + 1, buyNow: true));
  _close(LotCloseCause.buyNow, closedAt: now);
}
```

- Two events in one append: `BidPlaced(buyNow: true)` then `LotClosed(SOLD, winner = buyer, finalPrice = buyNowPrice, cause = BUY_NOW, closedAt = now)`. The BN shows up in the ledger like any bid, so the record reads "Sari — Rp 1.500.000 (BN)" followed by the closing row.
- `_close(cause, closedAt)` is the private helper behind UC-08's `Lot.close`, so SOLD/PASSED and the winner come from one code path with two triggers: the deadline and a buyer.
- `BidPlaced` gains `buyNow: bool` (default false; `fromData` reads a missing key as false). `LedgerEntry` gains `buyNow: bool` for the "(BN)" label.
- A BN bid can't be retracted: the lot is closed, so `RetractBid` already throws `LotClosedError`.
- A chip bid that reaches or passes the BN price is just a bid. It doesn't close the lot; it only removes the BN option (step 4). That matches the lelang norm where BN stops applying once bids reach it.
- `LotCloseCause` is `DEADLINE | BUY_NOW` (replaces the old organizer `SELL_NOW`).

**Command:** `BuyNow(lotId, participantId, expectedVersion)`. `BuyNowHandler` mirrors `PlaceBidHandler`: load the `Participant` for `displayName` and the auction-match check, load the `Lot`, call `buyNow(now: command.timestamp)`. If it fits, give both commands one handler base so the participant check isn't written twice.

## Races

- **BN vs chip, same version:** one commits; the other's append conflicts, the pipeline retries, and the reload throws `OutbidError` (if the chip won) or `LotClosedError` (if BN won). Exactly one outcome, never a bid after `LotClosed`.
- **BN vs BN:** the second gets `LotClosedError` naming the winner's close time. The client shows "Sold — Sari bought it first".
- **BN vs deadline:** serialized on the aggregate like UC-06 3c. Before `closeAt` → bought; at or after → `LotClosedError`.

## Interaction with the deadline saga

The saga's later `CloseLot(DEADLINE)` on a bought lot emits nothing (already closed). The `LotClosed(BUY_NOW)` has a different correlation, so the saga never sees it and must finalize through its timeout path (see the UC-08 note). Add a test here: an auction with one bought lot and one open lot reaches CLOSED at the deadline.

## Projection

- `BidPlaced(buyNow: true)` → ledger row with `buyNow = true`, card updated as for any bid.
- `LotClosed(cause: BUY_NOW)` → card SOLD with winner, final price, `closeCause = 'BUY_NOW'`, `closedAt`. One live push per event, as today.

## Endpoint

```dart
// LotEndpoint
Future<LotCard> buyNow(Session s, UuidValue lotId, UuidValue participantId,
                       String participantKey, int expectedVersion, UuidValue commandId);
```

Same shape as `placeBid` minus `amount`: the price comes from the lot, never from the client. Resolve `lotId → auctionId`, run `_verifyParticipant`, dispatch.

## Flutter

- Lot detail action bar: a **BUY NOW · Rp 1.500.000** button under the chip row, visible only when `card.buyNowPrice != null && status == OPEN && currentPrice < buyNowPrice`. Board card shows a small "BN Rp 1,5jt" tag on the same condition.
- **Confirm dialog** (unlike chips, BN ends the auction and can't be retracted): "Buy **Natural Pirus Hubei** now for **Rp 1.500.000**? This closes the lot and you can't retract it."
- On tap: disable chips and BN, call `buyNow(expectedVersion = card.version, commandId = Uuid.v7())`.
  - Success → apply the card, green banner "🔨 You bought it — Rp 1.500.000".
  - `Outbid` → "Price moved — Sari bid Rp 450.000" and re-render; the user must tap BN again (no silent retry).
  - `LotClosed` → "Sold — {winner} bought it first" or "Closed at 22:03:00".
  - `BUY_NOW_PASSED` → "Bidding passed the BN price — keep bidding". BN hidden.
  - `NotParticipant` / network → as in UC-06.
- Everyone else sees the lot flip to SOLD live, and the ledger closing row reads "🔨 Bought now by Sari 21:47:12".

## Tests

- Domain: BN on an open lot → `BidPlaced(buyNowPrice, buyNow)` + `LotClosed(SOLD, BUY_NOW, buyer)`. No BN price → `NO_BUY_NOW`. `currentPrice >= buyNowPrice` → `BUY_NOW_PASSED`. Stale version → `OutbidError`. `now == closeAt` → `LotClosedError`. BN after BN → `LotClosedError`. Retract after BN → `LotClosedError`.
- Race: `BuyNow` and `PlaceBid` with the same expectedVersion via `Future.wait` → exactly one succeeds; the stream never has a bid after `LotClosed`.
- Integration: wrong participant key → `NOT_PARTICIPANT`, nothing appended. Saga: one bought lot and one open lot → auction CLOSED at the deadline.

## Acceptance

- [ ] BUY NOW appears only on lots with a BN price, while the price is below it.
- [ ] A bought lot shows `cause = BUY_NOW`, the buyer, and the BN price on the record forever, including the shared result URL (UC-09).
- [ ] A BN racing a chip tap always ends with one winner and one clean message.
- [ ] The deadline later finalizes the auction without errors.

Estimate: 0.75 h.
