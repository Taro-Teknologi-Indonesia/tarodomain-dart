# UC-04 — View live board (Participant, Must)

Depends on: UC-02, UC-03, UC-12. **The whole video is this screen breathing.**

## Goal

All lots appear as cards (tile/image, name, current price, leader, status) with one auction countdown. Every committed change lands live in under 1 s.

## Server

No new commands. It reuses `AuctionEndpoint.board(code) → BoardSnapshot { auction, lots (ordered by position), serverNow }` from UC-03.

`LotTableProjection` already writes `LotCard`. From this UC on, every lot event must update the card **and** post `LiveUpdate(lotChanged, lot: card, ledgerEntry: …)`:

| Event | Card change |
|---|---|
| `LotCreated` | insert |
| `BidPlaced` | currentPrice, leaderId/Name, bidCount++, version++ (UC-06) |
| `BidRetracted` | recompute from ledger rows: last non-retracted entry or openBid, version++ (UC-07) |
| `LotClosed` | status, winnerName, finalPrice, closeCause, closedAt, version++ (UC-08) |

`AuctionTableProjection` posts `LiveUpdate(auctionChanged, auction: view)` on `AuctionClosed`/`AuctionFinalized`.

## Flutter

### `AuctionController extends ChangeNotifier`

- Fields: `AuctionView auction`, `Map<UuidValue, LotCard> lots`, `Map<UuidValue, List<LedgerEntry>> ledgers` (lazy, UC-05), `Duration clockOffset`, `LiveStatus status`.
- `start()`: subscribe → fetch snapshot → merge buffered (UC-12 rules).
- `_apply(LiveUpdate u)`: replace the card when `u.lot.version > existing.version`, append or update the ledger entry, and `notifyListeners()`.
- One controller per auction code, provided above the board and detail routes so the lot detail reuses it (no second subscription).

### `BoardScreen`

- **Header:** auction title, `CountdownText(closeAt, offset)` (red under 60 s; shows "Closed" after), live dot, and "You: Budi".
- **Layout:** `LayoutBuilder`: under 600 px use a `ListView` with a full-width card per lot; above that use a `GridView` with `maxCrossAxisExtent: 360`.
- **`LotCardWidget`** (shared with the organizer dashboard and the big screen through a `dense`/`large` variant):
  - Visual: `Image.network(imageUrl, errorBuilder: → TileVisual)`, else `TileVisual(emoji, color)`, at a 4:3 aspect ratio.
  - Name, two lines max.
  - `Rp 250.000` big, `formatRupiah` from `core/money.dart`.
  - Leader line: "Budi leads" / "No bids — opens at Rp 150.000" / "**You** lead" (highlighted when `leaderId == me`).
  - Status badge: OPEN (green), SOLD (gold), PASSED (grey).
  - **Change flash:** when a card's `currentPrice` changes, animate the price (`AnimatedSwitcher` plus a 600 ms background pulse). This is what makes the video "breathe".
- Tapping a card goes to `/a/:code/lot/:lotId`.
- Empty state: "No lots yet — the organizer is setting up."

### Shared helpers (`core/`)

- `money.dart`: `formatRupiah(int) → 'Rp 250.000'` and `formatStep(int) → '+25k'`.
- `clock.dart`: `ServerClock(offset).now()` plus a `Ticker` stream every 250 ms for countdowns.

## Tests

- Widget test: `LotCardWidget` with and without an image, leader = me versus another person, SOLD/PASSED.
- Unit test: `AuctionController._apply` ignores an older version and accepts a newer one.
- Manual: three windows (desktop grid, a phone-sized devtools window and incognito). A bid in one shows up in the others within 1 s.

## As built

- No server change in this step: `LotCreated` already posts its card. `BidPlaced`, `BidRetracted`, `LotClosed` and `AuctionClosed` post from the projections as UC-06/07/08 add those events.
- One `AuctionController` per code lives in `AuctionScope` (`core/auction_scope.dart`), which a `ShellRoute` puts above `/a/:code`, its lot route and its organizer route. The board, the lot detail and the dashboard share one subscription. `AuctionController.apply` is the merge that `_apply` describes, `@visibleForTesting`.
- The countdown sits under the title in the app bar. The board passes its identity's `participantId` as `me`, and the big screen gets `LotCardSize.large` with no taps. The dashboard uses `dense`.
- A closed lot's line reads "Siti won" (or "**You** won") and "No bids — passed".
- The wide layout is rows of equal-height cards at most 360 px wide, not a `GridView`, so a card is never clipped by a fixed aspect ratio.
- There's no `Ticker` stream: `CountdownText` keeps its own 250 ms timer, and it's the only timer.
- Flutter tests run with `melos run test:flutter` (also in CI). `flutter_test` pins `test_api`, so the workspace's `test` constraint is now `^1.31.1`.

## Acceptance

- [ ] Single column on phones, grid on desktop, and no horizontal scroll at 360 px.
- [ ] Bid, retract and close all update every window without a refresh.
- [ ] The countdown matches across devices to within 1 s, even with the phone clock skewed (test by changing the laptop clock by 30 s).

Estimate: 1.5 h.
