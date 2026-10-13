# X2 — Rolling demo auction (after UC-09)

Judging: **Does it work (30%)**. A judge who opens the link days later must find a live auction they can bid in and watch close.

Depends on: UC-01, UC-02, UC-08.

## Goal

`https://<host>/demo` always redirects to an OPEN auction that closes within 15 minutes. When it closes, a fresh one opens automatically. Closed demo auctions stay browsable, which also shows off UC-09.

## Server

- `DemoCalls extends FutureCall` with `ensureOpen(Session s)`:
  1. Find the newest `AuctionView` with `isDemo = true` (add a `bool isDemo` field, default false, set only by this call).
  2. If none is OPEN, or the open one closes in under 2 min, create a new one through the **normal commands**: `CreateAuction` then 3 × `AddLot`. No shortcuts and no direct table writes, so the demo exercises the real path.
  3. Close time: the next quarter hour that's at least 5 min ahead, e.g. 22:15, 22:30. That satisfies the UC-01 rule unchanged.
  4. Seed lots from `lib/src/demo/seed_lots.dart`: three stones with realistic names, the `-----# LELANG #-----`-style descriptions, open bids of 100k–250k, the default ladder, and emoji tiles (no external image URLs that might break).
  5. The organizer key is generated and thrown away. Nobody can add lots to the demo, which is fine.
- Schedule it as recurring every 60 s in `scheduleGavelJobs` (identifier `gavel-demo`), plus once at start-up.
- `AuctionEndpoint.currentDemo(Session) → String code` returns the open demo code.
- Optional bot bids (**off by default**): no fake bidders, because "nothing critical is faked". The judge brings the second window.

## Flutter

- Route `/demo` calls `currentDemo()` and does `go('/a/<code>')`.
- On demo auctions, show a slim banner: "Public demo — closes every 15 minutes. Open this link in a second (incognito) window to bid against yourself."
- On the home screen, a "Try the live demo" button next to "New auction".

## Tests

- Integration: `ensureOpen` twice gives one open demo auction. Advance the clock past the close and run the sweep plus `ensureOpen`, and you get a new open auction while the old one is CLOSED with its ledger intact.

## Acceptance

- [x] `/demo` always lands on an OPEN auction with 3 lots.
- [ ] After a close, a new demo auction appears within 60 s.
- [x] The demo auction is created only through commands, so it shows up in the event store like any other.

Estimate: 45 min.
