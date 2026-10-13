# UC-06 — Place bid via kelipatan chips (Bidder, Must — the star)

Depends on: UC-02, UC-03, UC-05, UC-12. Video beats 1:30–2:00 (collision) and 2:00–2:30 (bid vs close).

## Goal

One tap on a chip places `currentPrice + step`. The server validates under strong consistency, and every race resolves into **one clean typed answer**: no retry loop, no lost bid, no double winner.

## Domain (`Lot`)

```dart
class Bid { int sequence; ParticipantId bidder; String bidderName; int amount; DateTime at; bool retracted; }

int get currentPrice => lastValidBid?.amount ?? openBid;
Bid? get lastValidBid => bids.lastWhereOrNull((b) => !b.retracted);

void placeBid({required ParticipantId bidder, required String bidderName,
               required int amount, required int expectedVersion, required DateTime now}) {
  // 1. Closed beats everything (deterministic bid-vs-close, ext. 3c)
  if (status != LotStatus.open || !now.isBefore(closeAt)) throw LotClosedError(closedAt ?? closeAt);
  // 2. Stale view → OutbidError (ext. 3a). Version, not price: any change since the client rendered.
  if (expectedVersion != version) throw OutbidError(currentPrice, lastValidBid?.bidderName, lastValidBid?.bidder, version);
  // 3. Ladder invariant (ext. 3b)
  if (!increments.contains(amount - currentPrice)) throw InvalidIncrementError(increments, currentPrice);
  raise(BidPlaced(id, bidder, bidderName, amount, sequence: bids.length + 1));
}
```

Why it's deterministic:
- Two requests with the same `expectedVersion` both load version *v*. The first appends at *v+1*. The second's append fails with `OptimisticConcurrencyError`, the pipeline **retries the handler**, the reload sees *v+1 ≠ expectedVersion*, and the domain throws `OutbidError`. The framework's retry turns a storage conflict into a business answer, which is the line for the write-up.
- `OutbidError` is a `DomainError` (not retryable), so the retry loop ends right there.
- A double tap by the same bidder gets an `OutbidError` whose `leaderId == me`. The client shows "You're already the high bidder", not "Outbid". Commands also carry a client-generated `commandId`, so a network-level resend is deduplicated by the idempotency store.

Raising your own bid is allowed (a second chip after you lead), as in normal lelang practice.

**Command:** `PlaceBid(lotId, participantId, amount, expectedVersion)`. The handler loads `Participant` (state repo) for `displayName` and to check that `participant.auctionId == lot.auctionId` (else `CommandValidationError`), then loads the `Lot` and calls `placeBid(now: command.timestamp)`. A `PlaceBidHandler extends CommandHandler` holds both repositories.

The endpoint first runs `_verifyParticipant(session, auctionId, participantId, participantKey)` ([00-foundation §4](00-foundation.md)) and dispatches only if it passes. The handler's auction-match check stays as defense in depth.

> `command.timestamp` is set by the server when the endpoint constructs the command. Never accept a timestamp from the client.

## Projection

`BidPlaced` → insert a `LedgerEntry(sequence, participantId, bidderName, amount, placedAt = occurredAt, retracted false)`, update the `LotCard` (currentPrice, leader, bidCount++, version++), and post `LiveUpdate(lotChanged, lot, ledgerEntry)`.

## Endpoint

```dart
// LotEndpoint
Future<LotCard> placeBid(Session s, UuidValue lotId, UuidValue participantId,
                         String participantKey, int amount, int expectedVersion,
                         UuidValue commandId);
```

The endpoint resolves `lotId → auctionId` from `LotCard`, verifies the participant key, then dispatches `PlaceBid` without the key.

It returns the fresh card, so the bidder's UI flips without waiting for the push. The push still arrives, and the version check makes it a no-op.

## Flutter

- `BidChips` (in the UC-05 action bar): one `ActionChip` per step, labelled `+100k` with a second line `Rp 250.000`. Min 48 px tall, `Wrap` with 8 px spacing. On a phone that's 2 rows of 3, reachable by thumb.
- **Single tap, no confirm dialog.** On tap:
  1. Disable all chips and show a spinner on the tapped one. The optimistic UI is limited to that; don't change the price locally.
  2. Call `placeBid(amount = card.currentPrice + step, expectedVersion = card.version, commandId = Uuid.v7())`.
  3. On success, apply the returned card, then show a green banner "You're the high bidder — Rp 250.000" and a light haptic (`HapticFeedback.mediumImpact`, a no-op on most web).
  4. `GavelFailure` handling:
     - `Outbid(currentPrice, leaderName, leaderId)` → amber banner "**Outbid — Sari bid first**" (or "You're already the high bidder" when it's me). Refetch the card if the push hasn't arrived, and re-render the chips from the new price. That's the money shot, so make the banner big and leave it up for 3 s.
     - `InvalidIncrement` → "Price moved — pick again". Chips re-render.
     - `LotClosed(closedAt)` → "Closed at 22:03:00 — your bid didn't count". Chips are hidden.
     - `NotParticipant` → forget the stored identity and open the JoinSheet with "Please join again".
     - Network error → "Couldn't reach the server — try again", with the chips re-enabled. A resend with the **same** `commandId` is safe.
  5. Re-enable the chips.
- Chips also disable themselves locally when `serverClock.now() >= closeAt`.

## Tests (write these first — they're the demo)

Domain (`tarodomain_local`):
- Valid +100k on 150k → `BidPlaced(250k)`, version+1, leader updated.
- Off-ladder +70k → `InvalidIncrementError(increments, currentPrice)`.
- A stale `expectedVersion` → `OutbidError` carrying the current leader's name.
- `now == closeAt` → `LotClosedError`, and `closeAt - 1µs` → accepted.
- Bid after `LotClosed` → `LotClosedError`.
- **Race:** two `dispatch(PlaceBid)` calls with the same expectedVersion, run with `Future.wait`. Exactly one succeeds and the other is `OutbidError`, with stream length +1. Use the shared concurrency suite from `tarodomain_testing` if it fits.

Integration (`serverpod_test`, SQLite):
- `placeBid` with another participant's ID and a wrong key (or a valid key from another auction) → `NOT_PARTICIPANT`, no event appended.
- The same race through the endpoint: one `LotCard`, one ledger row, one `TaroDomainException(code: OUTBID)`.
- Bid vs close: dispatch `CloseLot` and `PlaceBid` concurrently 20 times. Each run ends either as (bid counted, then closed with that bid as the winner) or as (`LOT_CLOSED`, winner = previous leader). Never a bid after `LotClosed` in the stream.

Manual (video rehearsal): two windows side by side, the second in incognito, and tap +100k in both within about 200 ms. Repeat until it's reliable on camera. **No artificial server delay**: if a two-person collision is hard to film, film [X3 `tool/race.dart`](x3-race-proof.md) hitting the deployed server instead.

## Acceptance

- [ ] Collisions always produce exactly one winner and one "Outbid — {name} bid first".
- [ ] No bid is accepted at or after closeAt, even if the close call is late.
- [ ] An off-ladder amount is rejected server-side (test via curl or the integration test, since the UI can't produce it).
- [ ] Bid to all screens in under 1 s.

Estimate: 2.5 h.
