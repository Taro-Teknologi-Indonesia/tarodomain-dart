# UC-02b — BN price on lots (Organizer, follow-up to UC-02)

Depends on: UC-02 (done). Feeds into: UC-04, UC-05, UC-13. About 30 min.

## Why this exists

UC-02 shipped before UC-13 became a bidder's **Buy Now**. Buy Now needs a fixed BN price per lot, the `BN:` line of the seller's `-----# LELANG #-----` template. This plan adds that optional field to the code UC-02 already built. Doing it now, before UC-04 and UC-05, means the board card and lot detail render the BN tag from the start instead of being reworked later. The BUY NOW button and command stay in [UC-13](uc-13-buy-now.md).

## Domain (`lib/src/domain/lot.dart`, `lot_commands.dart`)

- `LotCreated` gets `final int? buyNowPrice`.
  - `toData` writes `'buyNowPrice': buyNowPrice`.
  - `fromData` reads `data['buyNowPrice'] as int?`, so `LotCreated` events stored before this change still load, as lots with no BN.
- `Lot.create(..., required int? buyNowPrice)`:
  - Null means no BN.
  - When present it must be `> openBid`, else `_invalid('buyNowPrice', 'NOT_ABOVE_OPEN_BID', 'The BN price must be above the open bid')`. Check it after `openBid`.
- `Lot` state: `int? buyNowPrice`, set in `apply(LotCreated)`, and included in `toSnapshot` / `restoreSnapshotState` (read as `int?`, so older snapshots restore as no BN).
- `AddLot` gets `final int? buyNowPrice`, and `AddLotHandler` passes it to `Lot.create`.

## Models and projection

- `new_lot.spy.yaml`: `buyNowPrice: int?` ("The Buy Now (BN) price, in rupiah, or null for no BN.").
- `lot_card.spy.yaml`: `buyNowPrice: int?` after `increments`.
- `LotTableProjection` on `LotCreated`: copy `e.buyNowPrice` into the card.
- `LotEndpoint.add`: pass `lot.buyNowPrice` into `AddLot`.
- Run `serverpod generate`, then `serverpod create-migration` (CLI at `~/.pub-cache/bin/serverpod`). The column is nullable, so existing rows need no backfill and read as no BN.

## Flutter

- `LotFormSheet`: an optional **Buy now (BN)** rupiah field right under the open bid, same thousands formatting and "Rp 1.500.000" helper. Empty means null. Map `COMMAND_VALIDATION.field == 'buyNowPrice'` to its inline error, like the other fields.
- `LotCardWidget`: when `card.buyNowPrice != null && card.status == 'OPEN' && card.currentPrice < card.buyNowPrice`, show a small "BN Rp 1.500.000" tag next to the price. The board (UC-04) and organizer dashboard share this widget, so both get it.

## Tests

- Domain (`test/domain/lot_test.dart`, next to the open-bid group):
  - No BN → `LotCreated.buyNowPrice == null`.
  - BN above the open bid → stored.
  - BN equal to the open bid, and below it → `COMMAND_VALIDATION` on `buyNowPrice`.
  - `LotCreated.fromData` without a `buyNowPrice` key → null.
- Integration (`test/integration/lot_test.dart`): `add` with a BN price → the `LotCard` carries it, and the pushed `LiveUpdate` card does too.
- Flutter widget test: the card shows the BN tag only while it applies.

## Acceptance

- [ ] An organizer can add a lot with or without a BN price, and a BN at or below the open bid gives an inline error.
- [ ] Lots created before this change still load and show no BN.
- [ ] The BN price shows on every board card live.

Estimate: 0.5 h.
