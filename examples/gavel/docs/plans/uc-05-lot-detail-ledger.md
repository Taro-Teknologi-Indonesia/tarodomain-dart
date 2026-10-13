# UC-05 — View lot detail & ledger (Participant, Must)

Depends on: UC-04. Hosts the controls of UC-06 (chips), UC-07 (retract) and UC-10 (as-of). Demo beat 2:30–2:50.

## Goal

A tap on a card opens the lot screen: image or tile, big price, minimum next bid, my status, kelipatan chips, RETRACT when I hold the latest bid, and the **full ledger** where retractions are struck through and never removed. The event log *is* the product.

## Server

```dart
// LotEndpoint
Future<LotDetail> detail(Session s, UuidValue lotId);
// LotDetail { lot: LotCard, ledger: List<LedgerEntry> (ordered by sequence), closeAt, serverNow }
```

- Reads come from `gavel_lot_cards` + `gavel_ledger_entries` (projections). Throw `AggregateNotFoundError` → 404 if the lot is missing.
- The ledger has no pagination; the lot cap is about 200 bids in practice.
- The ledger for closed lots also includes a synthetic closing line, which the client derives from `lot.status/closedAt/closeCause`. No extra table.

## Flutter — `LotDetailScreen(/a/:code/lot/:lotId)`

The data comes from the shared `AuctionController` card plus `controller.ledgerFor(lotId)`, which fetches `detail` once and is then kept current by `LiveUpdate.ledgerEntry`.

The layout is one scroll view on phones, with chips in a pinned bottom bar:

1. **Visual:** image (`errorBuilder` → tile) at max 50 vh on phones.
2. **Name** and **description** (`SelectableText`, newlines kept, collapsed to 4 lines with "more").
3. **Price block:**
   - `Rp 250.000` (display-large).
   - "Next bid from Rp 275.000" (= currentPrice + min(increments)).
   - Status line, one of:
     - "You're the high bidder — Rp 250.000" (green)
     - "Outbid — Sari leads at Rp 300.000" (amber, when I have any non-retracted bid and I'm not the leader)
     - "No bids yet"
     - "SOLD to Sari — Rp 300.000" / "PASSED — no bids" (UC-09)
4. **Action bar** (bottom, sticky) — see UC-06 and UC-07:
   - A `Wrap` of chips: `+25k → Rp 275.000` …
   - RETRACT (outlined, red) only when `ledger.lastValid.participantId == me && status == OPEN`.
   - Hidden when the lot is closed or I haven't joined (then show "Join to bid", which opens the JoinSheet).
5. **Ledger** (`ListView` inside the scroll view, newest at the top):
   - Each row: `#12 · Budi · Rp 250.000 · 22:01:47`.
   - My rows get a subtle highlight.
   - **Retracted rows:** `TextDecoration.lineThrough`, muted color, plus a "retracted 22:01:52" caption. Never removed.
   - The top row is the closing event when closed: "🔨 Closed 22:03:00 — SOLD to Sari" (or "SELL NOW by organizer").
   - New rows slide in (`AnimatedList`).
6. **App bar:** back to the board, auction countdown, and a share icon (UC-09) that copies the lot URL.

## Tests

- Widget test: a ledger with one retracted entry renders strike-through, and the entry count is unchanged.
- Widget test: RETRACT is visible only for the latest valid bid owner.
- Manual: open the detail in two windows, bid in one, and watch the ledger row appear in the other.

## Acceptance

- [ ] A broken image URL falls back to the tile without a broken-image icon.
- [ ] Every bid appears in order with who, when and how much. Retractions stay visible and struck through.
- [ ] A late joiner sees the identical ledger (the projection rebuilt from events would give the same rows, so add one `ProjectionRebuilder` integration test).

Estimate: 1.5 h.
