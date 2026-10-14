# UC-15 — My auctions: running & history (Organizer, Should)

Depends on: X6 (done), which records the creator on `AuctionCreated`, and UC-14 (done) for the unpaid count. About 2 h. Judging: **usefulness (20%)**, since a seller runs more than one auction, and **Serverpod stack (25%)**, for a `requireLogin` read over the ORM with a server-only field.

## Goal

A signed-in organizer opens **My auctions** and sees every auction they created, split into **Running** (open or closing) and **History** (closed), in any browser they sign into. Tapping one opens its organizer dashboard.

## Scope

- **Auctions with a creator only.** Auctions created before X6 and the demo auctions have no `organizerUserId` and never show up. That's accepted: there's no way to tell who made them.
- **Read only.** Nothing is dispatched, and no event changes.
- **Rights don't change.** The organizer key still guards AddLot, MarkUnpaid and the winner codes. Opened from a browser without the key, the dashboard is read-only, as today. The list says so up front ("View only on this device").
- **No live updates on the list.** It loads on open and on pull-to-refresh. The countdowns run on the client from the server clock offset; an auction that closes while the list is open moves to History on the next load.
- **Not in this plan:** organizer rights by account, renaming or deleting auctions, paging. See Later.

## Server

### Read model: `organizerUserId` on `AuctionView`

`AuctionView` goes to every bidder (`BoardSnapshot`, the live push), so the creator's ID must not travel with it. Serverpod's `scope=serverOnly` keeps the column in the table and out of the client model:

```yaml
  ### The signed-in organizer who created the auction (X6), or null for
  ### the demo and auctions created before X6. Never sent to clients.
  organizerUserId: String?, scope=serverOnly
indexes:
  # …existing indexes
  gavel_auctions_organizer_close_idx:
    fields: organizerUserId, closeAt
```

In `AuctionTableProjection`, the `AuctionCreated` handler sets `organizerUserId: e.organizerUserId`. Nothing else in the projection changes.

### Models: `MyAuction` and `MyAuctions`

```yaml
### One of the signed-in organizer's auctions, as My auctions lists it.
class: MyAuction
fields:
  ### The auction.
  auction: AuctionView

  ### How many of its lots are SOLD.
  soldCount: int

  ### The sum of the SOLD lots' final prices, in rupiah.
  soldTotal: int

  ### How many SOLD lots were marked unpaid (UC-14).
  unpaidCount: int
```

```yaml
### The signed-in organizer's auctions, with the server's clock.
class: MyAuctions
fields:
  ### Running ones first, then closed ones (see `myAuctions`).
  auctions: List<MyAuction>

  ### The server's clock when it answered, for the countdowns.
  serverNow: DateTime
```

### Endpoint: `OrganizerEndpoint.myAuctions`

`OrganizerEndpoint` already has `requireLogin`, so the call is signed-in only with no extra check.

```dart
/// The signed-in organizer's auctions with their sales so far: running
/// ones (OPEN or CLOSING) first, soonest close first, then closed ones,
/// most recent close first.
Future<MyAuctions> myAuctions(Session session) =>
    listMyAuctions(session, session.authenticated!.userIdentifier);
```

`listMyAuctions` lives in `infra/my_auctions.dart`, so tests can call it with any user:

1. `AuctionView.db.find(where: organizerUserId.equals(userId))`.
2. One `LotCard.db.find(where: code.inSet(codes) & status.equals('SOLD'))` for all of them. Sum `finalPrice` and count `unpaid` per code in Dart. An organizer has tens of auctions, not thousands; a SQL `GROUP BY` isn't worth it.
3. Sort as the doc comment says and return them with `serverNow`.

### Migration and backfill

- Run `~/.pub-cache/bin/serverpod generate`, then `~/.pub-cache/bin/serverpod create-migration`. It adds the nullable column and the index.
- Auctions created since X6 already have the creator in their `AuctionCreated` event, but the existing rows don't have it yet. Append a backfill to the generated `migration.sql`:

  ```sql
  -- UC-15: fill the creator from the auction's own AuctionCreated event.
  UPDATE "gavel_auctions" a
  SET "organizerUserId" = e."payload"::jsonb -> 'data' ->> 'organizerUserId'
  FROM "tarodomain_events" e
  WHERE e."eventType" = 'AuctionCreated'
    AND (e."payload"::jsonb -> 'data' ->> 'auctionId')::uuid = a."auctionId"
    AND e."payload"::jsonb -> 'data' ->> 'organizerUserId' IS NOT NULL;
  ```

  `tool/deploy.sh` applies it like the earlier migrations. It's idempotent, so a rerun is harmless.

## Flutter

### Route

```dart
GoRoute(
  path: '/mine',
  redirect: (_, state) =>
      requireSignIn(client.auth.isAuthenticated, state.uri),
  builder: (_, _) => const MyAuctionsPage(),
),
```

`requireSignIn` already remembers `from=/mine`, and `returnPath` already accepts it, so after signing in the organizer lands back on the list.

### Home page

In the header row, next to **Sign out**, the same `ValueListenableBuilder` shows a **My auctions** text button while signed in (`context.go('/mine')`). Signed out, there's no button; **For sellers** stays as is.

### `pages/my_auctions_page.dart`

- A `Scaffold` titled "My auctions" with a back button to `/`, in the same 620 px column as the dashboard. A `RefreshIndicator` reloads.
- `myAuctions` is a test seam defaulting to `client.organizer.myAuctions`, like `CreateAuctionPage.create`.
- Splits the list on `auction.status == 'CLOSED'` into two sections, **Running** and **History**, each with its count. A section with nothing in it is left out.
- **Running row:** title, `CODE`, local close time and a countdown (`core/clock.dart`, offset from `serverNow`), lot count, `LiveDot(status)`.
- **History row:** title, `CODE`, close date, "2 of 3 sold · Rp 1.250.000", plus "· 1 unpaid" in the error colour when `unpaidCount > 0`. "No lots sold" when `soldCount == 0`. Amounts go through `core/money.dart`.
- Every row opens `/a/<CODE>/organizer`. If `OrganizerKeys.load(code)` is null in this browser, the row shows "View only on this device" under the title.
- **Empty:** "No auctions yet" and a **Create an auction** button to `/new`.
- **Failures:** `SignedOut` → `client.auth.signOutDevice()`, and the router sends the organizer to `/sign-in?from=%2Fmine`. Anything else → an inline error with **Try again**.

### Create page

After a successful create, the page still opens the new dashboard. Nothing to change: the list reads the server, so the new auction is there next time.

## Tests

Server integration (`test/integration/my_auctions_test.dart`, with `signedIn` from `organizer_session.dart`):

- Signed out, `organizer.myAuctions` throws `ServerpodUnauthenticatedException`.
- `organizer-1` creates two auctions and `organizer-2` one: each sees only their own.
- The demo auction never appears, for any user.
- Ordering: two open auctions come soonest close first; after closing both (the close helper from `close_test.dart`), they come most recent close first, after any open one.
- Sales: a closed auction with one SOLD lot at Rp 300.000, one SOLD and marked unpaid at Rp 200.000, and one PASSED gives `soldCount 2`, `soldTotal 500000`, `unpaidCount 1`.
- Privacy: `endpoints.auction.board(code)`'s `auction`, serialized with `toJson()`, has no `organizerUserId` key.
- Backfill: insert an `AuctionView` row with a null `organizerUserId` for an auction whose event has one, run the migration's `UPDATE`, and the row gets it. (Or test it once by hand on a local DB; see Verify first.)

Flutter (`test/pages/my_auctions_page_test.dart`, with the `myAuctions` seam):

- Running and History sections, with the right rows in each.
- The history line: "2 of 3 sold · Rp 500.000 · 1 unpaid", and "No lots sold".
- The empty state shows **Create an auction**.
- A row without a stored organizer key shows "View only on this device".
- `test/core/auth_redirects_test.dart`: signed out on `/mine` → `/sign-in?from=%2Fmine`; signed in on `/sign-in?from=%2Fmine` → `/mine`.

Manual, before deploying:

- Sign in, create two auctions, open **My auctions**: both under Running.
- Sign in from another browser: same list, rows marked "View only on this device", dashboards read-only.
- Let one close: it moves to History with its sold count and total.

## Docs

- **Judges' README (X4):** one line in the try-it: "Signed in, **My auctions** lists your running and past auctions."
- **X6 plan:** in Later, mark "My auctions" as done in UC-15.
- **Plans README:** add the step.

## Acceptance

- [x] Signed in, **My auctions** on the home page lists the organizer's own auctions under Running and History, and nobody else's.
- [x] History rows show sold count, total and unpaid count.
- [x] The same list appears in any browser the organizer signs into; rows without the key say "View only on this device".
- [x] Signed out, `/mine` goes to sign-in and comes back to the list.
- [x] `organizer.myAuctions` without a token gets 401.
- [x] The board and the live push never carry `organizerUserId`.
- [x] Auctions created after X6 but before this migration show up (backfill).

## Verify first (about 15 min, before writing code)

1. `scope=serverOnly` works on a field of a **table** class in Serverpod 4.0.4: the column is generated and the client's `AuctionView` has no such field. If it doesn't, move the creator into its own server-only table (`gavel_auction_creators`: `auctionId`, `organizerUserId`) written by the same projection, and join in `listMyAuctions`.
2. `tarodomain_events.payload` for an `AuctionCreated` is exactly `toData()` as JSON (no envelope), and `eventType` is `'AuctionCreated'`. Run the backfill's `SELECT` part on a local DB with one signed-in auction. Adjust the JSON path if it's wrapped.
3. `inSet` on a `String` column exists in the 4.0.4 ORM (it does for `UuidValue` and `int`).

## What the build found

- `scope=serverOnly` works on a table field in 4.0.4: the column is generated, the client's `AuctionView` has no such field, and the server's `toJsonForProtocol()` leaves it out. The privacy test checks `toJsonForProtocol()`, which is what goes on the wire; the server's `toJson()` still has it.
- The event payload is the whole serialized event (`eventType`, `eventVersion`, the envelope, and `data`), so the backfill reads `payload -> 'data'`. The integration test runs the `UPDATE` straight from `migration.sql`.
- `inSet` is on every column type, `String` included.
- `LiveDot` shows the live connection, which this list doesn't have. A running row shows the countdown instead, which turns into "Closing…" past the close.

## Later (not this plan)

- **Organizer rights by account:** AddLot, MarkUnpaid and the winner codes accept the signed-in creator as well as the key, which removes "View only on this device".
- **Live list:** subscribe to each running auction's topic, or one `organizer:{userId}` topic, so rows move to History on close without a reload.
- **Claim an old auction:** let the organizer attach a pre-X6 auction to their account by proving the organizer key.
- **Paging and search** once anyone has more than a screenful.

Estimate: 2 h (0.25 h verify, 0.75 h server and tests, 0.75 h Flutter and tests, 0.25 h migration and deploy).
