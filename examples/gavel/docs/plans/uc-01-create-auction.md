# UC-01 — Create auction & share link (Organizer, Must)

Depends on: [00-foundation](00-foundation.md). Feeds into: UC-02, UC-03, UC-08.

## Goal

The organizer enters a title and a close time, and gets a dashboard with a copyable join link and a countdown. The server has scheduled the close independently of any client.

## Domain (`lib/src/domain/auction.dart`)

- `AuctionId extends AggregateId`.
- `Auction extends AggregateRoot<AuctionId, AuctionEvent>`:
  - `factory Auction.create(id, {title, closeAt, code, organizerKeyHash, now})`
    - `title.trim()` must be 1–80 chars, or it throws `CommandValidationError(field: 'title')`.
    - `closeAt` must be at least `now + 5 min`, or it throws `CommandValidationError(field: 'closeAt', reason: 'TOO_SOON')`. This is ext. 2a.
    - It raises `AuctionCreated`.
  - State: `title, code, closeAt, organizerKeyHash, lotIds = [], status = open`.
  - `bool isOrganizer(String key)` compares `sha256(key)` to `organizerKeyHash` in constant time.
- Command `CreateAuction(auctionId, title, closeAt, code, organizerKeyHash)`. Validation uses `command.timestamp` as `now`, so tests are deterministic.
- `AuctionHandler` (`AggregateCommandHandler`) also handles `CloseAuction`/`FinalizeAuction` later (UC-08).

### Join code

- 6 characters from `ABCDEFGHJKMNPQRSTUVWXYZ23456789` (no 0/O/1/I/L), generated in the endpoint with `Random.secure()`.
- Uniqueness: the `gavel_auctions.code` index is unique. On a unique-violation insert in the projection (strong, so the same transaction), the whole command rolls back. The endpoint catches that and retries with a new code, up to 3 times. With 31⁶ ≈ 887 M codes it will never actually loop.

## Read model

```yaml
# auction_view.spy.yaml
class: AuctionView
table: gavel_auctions
fields:
  auctionId: UuidValue
  code: String
  title: String
  closeAt: DateTime
  status: String          # OPEN | CLOSING | CLOSED
  lotCount: int
indexes:
  gavel_auctions_code_idx: { fields: code, unique: true }
  gavel_auctions_auction_id_idx: { fields: auctionId, unique: true }
  gavel_auctions_status_close_idx: { fields: "status, closeAt" }   # sweep query in UC-08
```

`AuctionTableProjection` handles `AuctionCreated` with an insert. Later UCs extend it.

## Endpoint (`AuctionEndpoint`)

```dart
Future<CreatedAuction> create(Session s, String title, DateTime closeAt);
// CreatedAuction { code, auctionId, organizerKey, closeAt, serverNow }
```

1. Generate `auctionId`, `code`, `organizerKey` (32 random bytes, base64url), and `hash`.
2. `_taro.dispatch(s, CreateAuction(...))`.
3. **Schedule the close:** `Serverpod.instance.futureCalls.callWithDelay(closeAt.difference(now), identifier: 'close-$auctionId').auctionCloseCalls.close(auctionId)`. Check the exact Serverpod 4 future-call builder; the bank example uses `callWithDelay(...).taroDomainCalls.catchUp()`. Scheduling happens after the dispatch commits, so the deadline sweep in UC-08 covers a crash between the two.
4. Return the `CreatedAuction`.

## Flutter

- `HomeScreen` (`/`) has two cards: **New auction** (organizer, desktop-first) and **Have a code?** (a 6-char text field → `/a/CODE`).
- `CreateAuctionScreen`:
  - Title field.
  - Date picker plus time picker, defaulting to today and now + 1 h rounded. Odd minutes are allowed: use `showTimePicker` with minute input, not 5-minute steps.
  - Show "Closes at 22:03 WITA (in 2 h 14 m)" under the picker, with the zone name from `DateTime.now().timeZoneName`.
  - Submit: convert local → UTC and call `create`. On `COMMAND_VALIDATION` with `field: closeAt`, show an inline error and stay on the form.
  - On success, save `localStorage['gavel:<CODE>:org'] = organizerKey` and go to `/a/CODE/organizer`.
- `OrganizerDashboard` (shell only here; lots come in UC-02):
  - Big share link `https://<host>/a/CODE` in a read-only field with a **Copy** button (`Clipboard.setData`) that shows a "Link copied — paste it in your Facebook post" snackbar.
  - Countdown widget (shared with UC-04) driven by `serverNow` offset.
  - If the organizer key is missing from localStorage (another browser), show "Read-only — open from the browser that created this auction".

## Tests

- Domain: a closeAt 4 min ahead fails, 5 min passes, 22:03 is accepted, and an empty title fails.
- Domain: `AuctionCreated` stores the hash and never the key.
- Integration: `create` → an `AuctionView` row exists with `status = OPEN`, and a future call is registered (query `serverpod_future_call` or use the test tools' future-call inspection if 4.0.4 has it).

## Acceptance

- [ ] A close time in the past or < 5 min ahead shows a typed validation error and keeps the form state.
- [ ] The dashboard shows a link, a working copy button and a live countdown.
- [x] Refreshing the dashboard keeps organizer rights (key in localStorage).
- [ ] Closing the organizer tab doesn't affect the scheduled close (verified in UC-08).

Estimate: 1.5 h.
