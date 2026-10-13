# UC-10 — Time-travel view (Participant, Should)

Depends on: UC-05, UC-07. Demo beat 2:30–2:50. **Cut rule:** if the build is past hour 12 when UC-08 is done, skip this one and say "time travel" in the roadmap instead.

## Goal

From the lot screen, pick a past moment (a preset like 22:00 or 22:02, or a slider). The server replays that lot's events up to T and shows price + leader with an **"AS OF 22:02"** badge. LIVE returns to now. It's read-only, and a judge can verify it against the visible ledger.

## Server

There's no "load as of" in `tarodomain` today, so fold the stream directly. It's about 20 lines:

```dart
// LotEndpoint
Future<LotAsOf> lotAsOf(Session s, UuidValue lotId, DateTime at) async {
  final rt = TaroDomainServerpod.instance.runtime(s);
  final id = LotId.fromExisting(lotId.uuid);
  final events = await rt.eventStore.loadStream(StreamIds.forAggregate('Lot', id));
  final lot = Lot(id);
  for (final e in events.where((e) => !e.occurredAt.isAfter(at.toUtc()))) {
    lot.applyHistoric(e as LotEvent);   // whatever AggregateRoot exposes for rehydration: check
  }                                      // EventSourcedRepository.load for the exact call
  return LotAsOf(at: at, price: lot.currentPrice, leaderName: lot.lastValidBid?.bidderName,
                 status: lot.statusName, bidCount: lot.bids.length,
                 retractedCount: lot.bids.where((b) => b.retracted).length,
                 lastSequence: lot.bids.lastOrNull?.sequence ?? 0);
}
```

- Use the **aggregate itself** to rebuild the state and not the projection: it's "replay the events", which is what judges are told.
- Skip snapshots on purpose: always replay from version 0. A lot has a few dozen events.
- `at` earlier than `LotCreated` → `AggregateNotFoundError`, and the client shows "Lot didn't exist yet".
- `LotAsOf` is a DTO, `.spy.yaml` with no table.
- Check: `StreamIds.forAggregate` naming and the public rehydration method on `AggregateRoot` (look at `EventSourcedRepository.load`). If rehydration is `@protected`, add a static `Lot.replay(id, events)` inside the domain that uses `apply` directly.

## Flutter

- A chip in the lot detail app bar or the top of the ledger: `⏱ As of…`.
- A bottom sheet to pick the time:
  - Presets generated from the ledger: "Before first bid", every distinct minute with activity (e.g. 22:00, 22:01, 22:02), and "Just before close".
  - A slider from `LotCreated.at` to `closedAt ?? now`, snapping to ledger timestamps.
- Result mode on the detail screen:
  - An amber **"AS OF 22:02:00"** badge plus a **LIVE** button.
  - The price block shows `asOf.price` and `asOf.leaderName`.
  - Chips and RETRACT are hidden (no commands against past state).
  - **Ledger rows after T are dimmed to 30% opacity** and rows at or before T stay normal. A retraction that happened after T shows *un*-struck as of T, which visibly proves the replay. Do this client-side from `placedAt`/`retractedAt` versus T, and use the server's answer for the price/leader so the server stays the source of truth.
- LIVE clears the as-of state. Live updates keep arriving in the background.

## Tests

- Domain/integration: bids at t1 < t2 < t3, retraction at t4.
  - asOf(t2) → price of bid 2, leader 2.
  - asOf(t4 − 1 ms) → the price of the bid that was later retracted.
  - asOf(t4) → the restored price.
  - asOf(before create) → not found.
- Manual: during the rehearsal, pick 22:02 and compare against the ledger visually.

## Acceptance

- [ ] As-of shows the correct price and leader at any T, matching the ledger by eye. Covered by `test/domain/as_of_test.dart` and `lot_detail_test.dart`; the by-eye rehearsal check is still to do.
- [x] A retraction after T shows as an active bid at T.
- [x] No command is possible in as-of mode; LIVE restores the live view.

## As built

The code shipped inside `0c3d818` (the X2 commit) because both sessions shared one index.

- `rehydrate` wasn't needed: `AggregateRoot.loadFromHistory` is public, so `Lot.asOf(id, events, at)` in the domain replays from version 0 and throws `AggregateNotFoundError` before `LotCreated`.
- `at` counts to the end of its millisecond, because a web client's `DateTime` has no finer grain and a snapped ledger time would otherwise miss its own bid.
- `LotAsOf` also carries `leaderId` (for the name tag) and `version`.
- The quick picks are the start of each minute after one with activity, so "22:02" includes everything in 22:01.
- The AS OF badge and LIVE take the place of the bottom bar, so the chips and RETRACT can't render in as-of mode.

Estimate: 1.5 h.
