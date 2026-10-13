# UC-08 — Auto-close auction at deadline (System, Must)

Depends on: UC-01, UC-02, UC-06. Video beat 2:00–2:30, the "wait, how?" moment: the organizer's laptop is closed and the hammer still falls.

## Goal

At `closeAt` the server, independent of any client, closes every open lot: SOLD to the highest valid bid, or PASSED. Retries and double fires are idempotent no-ops, and final-second bids serialize against the close on the lot aggregate.

## Design

```
Serverpod future call @closeAt ──► CloseAuction(auctionId)        [Auction: AuctionClosed(lotIds)]
recurring sweep (every 5 s)   ──┘                                       │
                                                                        ▼
                                        AuctionCloseSaga.startsWhen<AuctionClosed>
                                          → [CloseLot(lotId, DEADLINE) for each lotId]
                                        continueWhen<LotClosed>  (remaining.remove(lotId))
                                          → remaining.isEmpty ? [FinalizeAuction] : []
                                        completedWhen<AuctionFinalized>
                                        compensateWhen<SagaTimeout>
                                          → re-issue CloseLot for remaining (idempotent)
```

Why the deadline isn't a `SagaTimeout`: TaroDomain's `SagaTimeout` fires after a saga has made **no progress** for a duration (`updatedAt + timeout`). It's an inactivity timer, not a wall-clock alarm. The wall-clock trigger is a Serverpod **future call**, and the saga orchestrates the fan-out and uses its timeout as a safety net. The write-up should state this split plainly, because it shows the right primitive for each job.

### Domain

- `Auction.close(now)`:
  - Already `closing` or `closed` → **no-op, no event** (ext. 2a). The handler then saves nothing.
  - `now < closeAt` → `CommandValidationError('TOO_EARLY')`. That guards against a sweep bug, and `BuyNow` doesn't go through here.
  - Otherwise raises `AuctionClosed(lotIds, cause: DEADLINE)` → status `closing`.
- `Auction.finalize()` raises `AuctionFinalized` once → `closed`, and is a no-op after that.
- `Lot.close(cause, now)`:
  - Already SOLD or PASSED → **no-op** (idempotent: the saga retry, a double fire, or a lot already bought via Buy Now).
  - `lastValidBid != null` → `LotClosed(SOLD, winnerId, winnerName, finalPrice = amount, cause, closedAt = now)`.
  - Else → `LotClosed(PASSED, cause, closedAt = now)`.
  - **closedAt for DEADLINE is `closeAt`, not `now`**, so the record reads "closed 22:03:00" even if the call fired at 22:03:02.
- Commands `CloseAuction(auctionId)`, `CloseLot(lotId, cause)` and `FinalizeAuction(auctionId)`, all strong.
- `AuctionCloseSaga extends ProcessManager<AuctionCloseState>` with state `{auctionId, remaining: Set<String>}`. Register it in the builder like `TransferSaga`, with a saga timeout of 30 s.
  - Check how the builder correlates `LotClosed` to this saga instance (correlation ID = the causing command's correlation). Commands issued by the saga carry the saga's correlation ID, so `LotClosed` from a saga-issued `CloseLot` routes back to it. A **BuyNow** `LotClosed` (UC-13) has a different correlation, so the saga won't see it. That's fine, because its `CloseLot` for that lot is then a no-op that emits nothing. In that case `remaining` would never shrink for that lot, so `continueWhen` won't fire and the timeout path must handle "already closed". Fix: in the timeout handler, after re-issuing, also issue `FinalizeAuction` when every remaining lot is terminal, checked by reading `LotCard` statuses via an injected query. If that gets fiddly, make `CloseLot` on an already-closed lot raise nothing and have the saga treat a `SagaTimeout` as "finalize". Keep it simple, and don't let this eat more than 20 min.

### Trigger: future calls (`lib/src/future_calls/auction_close_calls.dart`)

```dart
class AuctionCloseCalls extends FutureCall {
  Future<void> close(Session s, UuidValue auctionId) =>
      TaroDomainServerpod.instance.dispatch(s, CloseAuction(AuctionId.fromExisting(auctionId.uuid)));

  /// Belt and braces: closes every OPEN auction past its closeAt.
  Future<void> sweep(Session s) async {
    final due = await AuctionView.db.find(s, where: (t) => t.status.equals('OPEN') & (t.closeAt <= DateTime.now().toUtc()));
    for (final a in due) { await close(s, a.auctionId); }
  }
}
```

- `close` is scheduled per auction in UC-01 (`identifier: 'close-<id>'`).
- `sweep` is recurring every 5 s, registered in `scheduleGavelJobs(pod)` next to `scheduleTaroDomainJobs`. It covers a server restart over the deadline and a crash between create and schedule.
- Wrap each `close` in try/catch with logging, so one bad auction doesn't stop the sweep.
- Check Serverpod 4.0.4's API for scheduling at an absolute time (`callAtTime`) versus `callWithDelay`, and use whichever exists.

### Projection & live

- `LotClosed` → card status, winnerName, finalPrice, closeCause, closedAt, version++, plus a live push.
- `AuctionClosed` → `AuctionView.status = CLOSING`; `AuctionFinalized` → `CLOSED`, plus a live push. Clients show "Closing…" for the fraction of a second in between.

### Race with final-second bids (ext. 2b)

Both `PlaceBid` and `CloseLot` append to the same lot stream with optimistic concurrency:
- Bid commits first → `CloseLot` conflicts, retries, reloads, and sees the bid. The winner is that bidder.
- Close commits first → the bid's retry reloads, sees `status != open`, and gets `LotClosedError`.
- Plus the domain deadline check (`now >= closeAt` rejects bids), so a bid that *arrives* after 22:03:00 is rejected even when the close fires late.

## Flutter

- Countdown hits 0 → the client disables the chips locally and shows "Closing…". The board then flips per lot as `LotClosed` pushes arrive.
- **Winner's screen:** when a `LotClosed` arrives with `winnerId == me`, show a full-width celebration banner "🔨 You won Natural Pirus Hubei — Rp 450.000" with a "Share result" button (UC-09).
- **Loser's screen:** "SOLD to Sari — Rp 450.000".

## Tests

Domain:
- `Lot.close` with bids → SOLD with the highest valid bid. With all bids retracted → PASSED. A second close → no events.
- `Auction.close` twice → one `AuctionClosed`.
- Saga: given `AuctionClosed([l1, l2])`, it emits 2 `CloseLot`. After both `LotClosed`, it emits `FinalizeAuction`, then completes.
- Saga timeout path re-issues for the remaining lots, and nothing breaks if they're already closed.

Integration:
- Create an auction with `closeAt = now + 2 s` (inject the clock or relax the 5-min rule in test via a `minLead` parameter), add 2 lots, bid on one, and wait for the sweep → one SOLD and one PASSED, auction CLOSED.
- Double fire: call `close` twice concurrently → one `AuctionClosed`, one `LotClosed` per lot.

Manual (video): set closeAt to about 3 minutes ahead, **close the organizer laptop lid** (or kill the organizer tab) on camera, and watch the phone flip to SOLD.

## Acceptance

- [ ] All lots are terminal within about 5 s after closeAt with no client involved.
- [ ] Retries or a double fire produce no duplicate events.
- [ ] A final-second bid is either counted and wins, or gets `LOT_CLOSED`. It's never silently lost.
- [ ] A server restarted after closeAt closes the overdue auctions within 5 s of boot.

Estimate: 2 h.
