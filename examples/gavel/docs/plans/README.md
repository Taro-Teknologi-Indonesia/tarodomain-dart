# Gavel — implementation plans

There's one plan per use case from [../use-cases.md](../use-cases.md), plus a foundation plan for the shared architecture. The MVP is a **Flutter web** app served by the Serverpod server, built on TaroDomain (`tarodomain_serverpod_server`).

Build in this order. The numbers are steps, not UC IDs. Plans prefixed `x` aren't use cases; they come from the judging criteria (works 30%, Serverpod stack 25%, craft 25%, usefulness 20%).

| Step | Plan | Priority | Est. |
|---|---|---|---|
| 0 | [00-foundation.md](00-foundation.md): layout, shared domain model, errors, read models, web serving | — | 1.5h |
| 1 | [uc-12-live-update-push.md](uc-12-live-update-push.md): **hour-2 risk gate** | Must | 1h |
| 1b | [x1-deploy-early.md](x1-deploy-early.md): public HTTPS URL, then redeploy after every step | Must | 1h |
| 2 | [uc-01-create-auction.md](uc-01-create-auction.md) | Must | 1.5h |
| 3 | [uc-02-add-lots.md](uc-02-add-lots.md) | Must | 1.5h |
| 4 | [uc-03-join-via-link.md](uc-03-join-via-link.md) | Must | 1h |
| 4b | [uc-02b-buy-now-price.md](uc-02b-buy-now-price.md): optional BN price on lots, before the board and lot detail render cards | Should | 0.5h |
| 5 | [uc-04-live-board.md](uc-04-live-board.md) | Must | 1.5h |
| 6 | [uc-06-place-bid.md](uc-06-place-bid.md) ⭐ | Must | 2.5h |
| 7 | [uc-05-lot-detail-ledger.md](uc-05-lot-detail-ledger.md) | Must | 1.5h |
| 8 | [uc-07-retract-bid.md](uc-07-retract-bid.md) | Must | 1h |
| 9 | [uc-08-auto-close.md](uc-08-auto-close.md) | Must | 2h |
| 10 | [uc-09-outcome-share.md](uc-09-outcome-share.md) (without the OG stretch): outcome, receipt, name tag, winner code | Must | 1.75h |
| 11 | [x2-rolling-demo-auction.md](x2-rolling-demo-auction.md): `/demo` always open for judges | Must | 0.75h |
| 12 | [x3-race-proof.md](x3-race-proof.md): real parallel bids against production | Must | 0.75h |
| 12b | [x5-client-validation.md](x5-client-validation.md): every server rule on user input also checked in the app before the call | Should | 1.5h |
| — | **Record the video** | | |
| 13 | [uc-11-big-screen.md](uc-11-big-screen.md) | Should | 0.5h |
| 14 | [uc-14-mark-unpaid.md](uc-14-mark-unpaid.md): non-payment made visible | Could | 0.5h |
| 15 | [uc-10-time-travel.md](uc-10-time-travel.md): cut if past hour 12 at step 9 | Should | 1.5h |
| 16 | [uc-13-buy-now.md](uc-13-buy-now.md): bidder BN at a fixed price, only if ahead | Should | 0.75h |
| 17 | UC-09 Open Graph preview stretch | Stretch | 0.5h |
| last | [x4-judges-readme.md](x4-judges-readme.md): live link, 2-minute try-it, Serverpod mapping, proof | Must | 0.5h |

Musts total about 19.5 h, including deploy, the demo auction, the race proof and the README. Add about 1.5 h for recording and the submission form.

**Nothing faked:** no artificial server delays, no bot bidders, and the demo auction is created through the normal commands.

## Decisions made in these plans that the use cases don't spell out

- **The deadline is enforced in the domain** (`Lot.closeAt` checked on every bid and retraction), not only by the scheduler. A late future call can't let a 22:03:01 bid in.
- **The close trigger is a Serverpod future call plus a 5 s sweep.** `AuctionCloseSaga` fans out `CloseLot`. TaroDomain's `SagaTimeout` is an inactivity timer, so it's the saga's safety net and not the deadline.
- **OutbidError comes from `expectedVersion`**: the pipeline's concurrency retry reloads, sees the newer version, and the domain throws `OutbidError`.
- **`BidPlaced` carries `bidderName`**, so `OutbidError.leaderName` and the ledger need no join.
- **`Auction` records `LotRegistered`**, so the close saga knows its lots without reading a projection.
- **Participant key:** `join` returns a random secret next to the public `participantId`. Only its hash is stored, and bidding or retracting requires it, so an ID copied from the ledger can't be used to act as someone else.
- **Claiming a win with a shared name:** the receipt tags the winner (`Budi · #3f9c`, the last 4 hex chars of the participantId), and a winner code, an HMAC of the lot ID keyed with the participant's stored key hash, is shown only to the winner's browser and the organizer. It's computed on request and never stored or published (UC-09).
- **Organizer key:** a random secret returned by `create`, kept in localStorage, with only its hash stored. It guards AddLot and MarkUnpaid. This isn't auth.
- **Every command is strong**, so projections and the live push happen in or after the same transaction.
- **Server clock offset** drives all countdowns.
- **Client validation mirrors the server, never replaces it.** Limits live once in `gavel_client/lib/rules.dart`, a server parity test fails if they drift from the domain, and every server check and `GavelFailure` mapping stays (X5).

## Things to verify early (API details not confirmed while planning)

1. ~~The Serverpod 4.0.4 web server's static route plus SPA fallback for `/a/*` (foundation).~~ Done: `FlutterRoute`.
2. The future call builder for one-off delayed/absolute calls with an identifier (UC-01/08).
3. ~~That two repository saves in one handler share one unit of work (UC-02, UC-06).~~ Done: the strong pipeline runs the whole handler in one unit of work (`test/integration/lot_test.dart` proves the rollback).
4. How the saga builder correlates `LotClosed` back to `AuctionCloseSaga` (UC-08).
5. The public rehydration call on `AggregateRoot` for time travel (UC-10).
