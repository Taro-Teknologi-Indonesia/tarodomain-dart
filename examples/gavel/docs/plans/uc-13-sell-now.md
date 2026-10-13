# UC-13 — Sell Now ("BN") (Organizer, Should — only if ahead, not in the video)

Depends on: UC-08 (reuses `CloseLot`). About 45 min.

## Goal

The organizer taps SELL NOW on a lot with at least one valid bid. The lot closes immediately as SOLD to the current leader at the current price, with `cause = SELL_NOW`. It's **the same close command** the deadline saga uses, so it's idempotent and races safely with in-flight bids.

## Domain

- No new aggregate method. `Lot.close(cause: SELL_NOW, now)` from UC-08 already:
  - is a no-op if the lot is already closed,
  - picks `lastValidBid` as the winner, and
  - sets `closedAt = now` (for DEADLINE it's `closeAt`; for SELL_NOW it's the actual time).
- One extra guard, for SELL_NOW only: `lastValidBid == null` → `CommandValidationError(reason: 'NO_BIDS')`. Selling with no bids is meaningless; PASSED is reserved for the deadline.
- **Organizer check:** `SellNowHandler extends CommandHandler<SellNow>` loads `Auction` → `isOrganizer(key)` or throws `NotOrganizerError`, then dispatches the same logic as `CloseLot`. Simplest: share a private `closeLot(lot, cause, now)` function used by both handlers. That's one code path with two triggers.
  - Alternative: the endpoint verifies the key against the Auction and then dispatches `CloseLot(lotId, SELL_NOW)` directly. That's fewer classes. Prefer it if the endpoint can load the aggregate cheaply via `runtime(session)` and a repository; otherwise use the handler.
- `expectedVersion`: SELL NOW sends the version the organizer saw. On a mismatch, throw `OutbidError` with the new leader, so the organizer never sells to someone they didn't see. The organizer confirms again.

## Interaction with the deadline saga

The saga's later `CloseLot(DEADLINE)` on this lot emits nothing (already closed). See the UC-08 note: the saga must still finalize the auction, so verify its timeout path handles "lot already terminal". Add a test for it here.

## Endpoint

```dart
// LotEndpoint
Future<LotCard> sellNow(Session s, UuidValue lotId, String organizerKey, int expectedVersion);
```

## Flutter

- Organizer dashboard lot row (and lot detail, when the `:org` key is present): a **SELL NOW** button, enabled only when `bidCount > 0 && status == OPEN && card.leaderId != null`.
- Confirm dialog: "Sell **Natural Pirus Hubei** to **Sari** for **Rp 450.000** now? This closes the lot for everyone."
- `Outbid` → refresh the dialog with the new leader and price and ask again.
- Bidders see the lot flip to SOLD live, and the ledger closing row reads "🔨 Sold now by organizer 21:47:12".

## Tests

- Domain: sell now with bids → SOLD/SELL_NOW with the leader. With no bids → `NO_BIDS`. A second sell now → no-op. The wrong key → `NotOrganizerError`.
- Race: `SellNow` and `PlaceBid` concurrently → either (bid counted and SellNow gets `OUTBID`, so the organizer re-confirms) or (sold, and the bid gets `LOT_CLOSED`).
- Saga: an auction with one sold-now lot and one open lot reaches CLOSED at the deadline.

## Acceptance

- [ ] Only the organizer browser sees and can use SELL NOW.
- [ ] A sell-now lot shows `cause = SELL_NOW` on the record forever.
- [ ] The deadline later finalizes the auction without errors.

Estimate: 0.75 h.
