# UC-02 — Add lots (Organizer, Must)

Depends on: UC-01, UC-12. Feeds into: UC-04, UC-05, UC-06, UC-08.

## Goal

The organizer fills in the structured version of their `-----# LELANG #-----` template. The lot appears on every connected board live with status OPEN and price = open bid.

## Domain (`lib/src/domain/lot.dart`)

- `LotId extends AggregateId`.
- `Lot extends AggregateRoot<LotId, LotEvent>`:
  - `factory Lot.create(id, {auctionId, name, openBid, increments, description, imageUrl, tileEmoji, tileColor, closeAt, position})`
    - `name.trim()` must be 1–80 chars.
    - `openBid > 0`, else `CommandValidationError(field: 'openBid')`.
    - `increments` must be non-empty, all > 0 and distinct; sort it ascending. Otherwise `CommandValidationError(field: 'increments')`.
    - `imageUrl` is optional; when present it must parse as an `http(s)` `Uri`. Don't fetch it server-side.
    - `description` may be up to 2000 chars, with newlines kept.
    - It raises `LotCreated`.
  - State used later: `bids: List<Bid>`, `status`, `closeAt`, `increments`, `openBid`.
- `Auction.registerLot(lotId, now)` raises `LotRegistered`. It throws `LotClosedError` if the auction isn't open or `now >= closeAt`, and `CommandValidationError` if the auction already has 20 lots (a sanity cap).
- Command `AddLot(auctionId, lotId, organizerKey, …fields)`.
- **`AddLotHandler extends CommandHandler<AddLot>`** (not the single-aggregate base). It takes both repositories:
  1. Load the `Auction`; if `!isOrganizer(key)`, throw `NotOrganizerError`.
  2. `auction.registerLot(lotId, cmd.timestamp)`.
  3. `Lot.create(... closeAt: auction.closeAt, position: auction.lotIds.length)`.
  4. `save(lot)`, then `save(auction)`. Under strong consistency both appends share one unit of work. **Check in the first test** that a conflict on the auction stream rolls back the lot append too. If it doesn't, flip the order (auction first) and accept that an orphan lot stream is harmless because the board reads `lotIds` from the auction.
     - **Decided (step 3):** they share one. A failure after the lot append rolls the lot back, and parallel adds all land after retries, each at its own position.

Ladder value: **rupiah, not ribu**. The default preset is `[25000, 50000, 100000, 150000, 200000, 300000]`, and the UI shows them as `+25k`.

## Read models

```yaml
# lot_card.spy.yaml
class: LotCard
table: gavel_lot_cards
fields:
  lotId: UuidValue
  auctionId: UuidValue
  code: String
  position: int
  name: String
  description: String
  imageUrl: String?
  tileEmoji: String
  tileColor: String          # hex, e.g. "#2E7D6B"
  openBid: int
  increments: List<int>
  currentPrice: int
  leaderId: UuidValue?
  leaderName: String?
  bidCount: int
  status: String             # OPEN | SOLD | PASSED
  version: int               # lot aggregate version → client's expectedVersion
  winnerName: String?
  finalPrice: int?
  closeCause: String?
  closedAt: DateTime?
indexes:
  gavel_lot_cards_lot_idx: { fields: lotId, unique: true }
  gavel_lot_cards_code_idx: { fields: "code, position" }
```

```yaml
# ledger_entry.spy.yaml  (rows written from UC-06 on, defined now)
class: LedgerEntry
table: gavel_ledger_entries
fields:
  lotId: UuidValue
  sequence: int
  participantId: UuidValue
  bidderName: String
  amount: int
  placedAt: DateTime
  retracted: bool
  retractedAt: DateTime?
indexes:
  gavel_ledger_lot_seq_idx: { fields: "lotId, sequence", unique: true }
```

`LotTableProjection`:
- On `LotCreated`, insert a `LotCard` with `currentPrice = openBid`, `version = 1` (or the event's stream version if the envelope exposes it, which is better), and `status = OPEN`. Then post `LiveUpdate(lotChanged, lot: card)`.
- `AuctionTableProjection` on `LotRegistered` increments `lotCount`.

**Decided (step 3):** `LotCreated` also carries the auction's `code`, so the projection can post to `auction:CODE` without reading `gavel_auctions` (which a rebuild may have truncated).

**Version source of truth:** take the lot's aggregate version from the event envelope/stream position if `tarodomain` exposes it to projections. Otherwise keep `version` as `card.version + 1` on every lot event. **Decided (step 3):** projections don't see the stream position, so it's `+ 1`. Both match `Lot.version` as long as every lot event goes through this projection. Add an integration assertion that `card.version == (await repo.load(lotId)).version`.

## Endpoint (`LotEndpoint`)

```dart
Future<LotCard> add(Session s, String code, String organizerKey, NewLot lot);
// NewLot DTO: name, openBid, increments, description, imageUrl?, tileEmoji, tileColor
```

Resolve `code` to `auctionId` via `AuctionView` (`AuctionNotFoundError` if missing), dispatch `AddLot`, and return the fresh `LotCard`.

## Flutter

- `OrganizerDashboard` gets an **Add lot** button, which opens `LotFormSheet` (dialog on desktop, full page under 600 px):
  - Name: "Natural Pirus Hubei"
  - Open bid: numeric with thousands formatting, typed in rupiah. A helper shows "Rp 150.000".
  - **Kelipatan ladder:** six `FilterChip`s pre-selected (+25k … +300k), plus "+ custom step" for one extra integer in thousands. At least one must be selected.
  - Description: multiline, with a placeholder copied from the seller template (`Berat: …\nUkuran: …\nAsal: …\nIkatan: …\nKondisi: …`).
  - Image URL: paste field with a live 64 px preview. On load error, show the tile instead.
  - Tile: a row of 8 emoji (💎 💍 🪨 🔮 🟢 🔵 🔴 ⚪) and 6 color swatches, which act as the fallback visual.
- On submit, call `add`. Map `COMMAND_VALIDATION.field` to inline field errors. `NOT_ORGANIZER` shows a snackbar.
- The dashboard lot list is the same `LotCardWidget` as UC-04, so there's one widget for both.

## Tests

- Domain: open bid 0 → error; empty ladder → error; ladder `[50000, 25000, 25000]` → error (duplicate); unsorted → stored sorted.
- Domain: an `AddLot` with the wrong key → `NotOrganizerError`, and no events.
- Domain: `AddLot` after closeAt → `LotClosedError`.
- Integration: `add` → `LotCard` row plus a `LiveUpdate` on `auction:CODE`.

## Acceptance

- [x] An open bid ≤ 0 or an empty ladder gives an inline typed error.
- [x] A new lot appears on a second (bidder) window without refresh.
- [x] A broken image URL falls back to the emoji/color tile.
- [ ] The write-up quotes the `-----# LELANG #-----` template next to a screenshot of this form.

Estimate: 1.5 h.

> **Follow-up:** the optional BN price (`buyNowPrice`) for UC-13 Buy Now was added after this plan shipped. See [uc-02b-buy-now-price.md](uc-02b-buy-now-price.md).
