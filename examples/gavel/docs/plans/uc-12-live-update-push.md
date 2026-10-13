# UC-12 — Live update push (System, Must)

**Build first, right after the foundation step.** Every demo beat depends on it, and use-cases.md asks for it to be proven by hour 2.

Depends on: [00-foundation](00-foundation.md). Used by: UC-02, 04, 05, 06, 07, 08, 09, 11, 13.

## Goal

Every committed event (lot created, bid, retraction, close) reaches every browser subscribed to `auction:<CODE>` in under 1 s, with no polling and no refresh.

## Server

### Models (`lib/src/models/`)

```yaml
# live_update.spy.yaml
class: LiveUpdate
fields:
  kind: LiveUpdateKind          # enum: lotChanged, auctionChanged, ping
  lot: LotCard?
  ledgerEntry: LedgerEntry?
  auction: AuctionView?
  serverNow: DateTime
```

`live_update_kind.spy.yaml` holds the enum.

### Endpoint

```dart
class LiveEndpoint extends Endpoint {
  /// Streams every LiveUpdate for [code] until the client disconnects.
  Stream<LiveUpdate> watch(Session session, String code) =>
      session.messages.createStream<LiveUpdate>(channelFor(code));
}

String channelFor(String code) => 'auction:${code.toUpperCase()}';
```

- Spike version: add `ping(Session, String code)`, which posts `LiveUpdate(kind: ping)` through `LiveProjectionNotifier`. Delete it after the gate passes, or keep it behind `--mode development`.

### Posting

- `LiveProjectionNotifier(session).post(channelFor(code), update)` is called **from inside the table projections** (UC-02/04/06/07/08), after the row write. Because commands run strong, the projection is inside the unit of work, and `post` runs after commit, so a rolled-back bid never reaches a client.
- The projection needs the auction `code` in order to name the channel. `LotCard` stores `code`, so the lot projection reads it from the row it just wrote.
- Use `MessageScope.auto`. One server instance needs no Redis.

## Client (`gavel_flutter/lib/core/live.dart`)

```dart
class LiveConnection {
  LiveConnection(this.client, this.code);
  Stream<LiveUpdate> updates();      // wraps client.live.watch(code), with reconnect
}
```

- **Subscribe first, then fetch the snapshot** (`getBoard`), and buffer updates until the snapshot arrives. When a buffered update is merged, ignore any `LotCard` whose `version` is ≤ the snapshot's version. That makes merges monotonic (use-cases §5) and safe against the subscribe/fetch race.
- **Reconnect:** on stream error or done, use exponential backoff (1 s, 2 s, 4 s, capped at 10 s). After each reconnect, refetch the board snapshot, because events during the gap are not replayed.
- Show a small connection dot (green = live, amber = reconnecting) in the app bar. That's cheap, and it's useful in the video.
- Update the clock offset from `serverNow` on every message.

## Tests

- Integration: open `watch('ABC123')` in `serverpod_test` with a stream listener, dispatch a command that touches a lot in `ABC123`, and expect one `LiveUpdate` with the new `LotCard`.
- Integration: a command that throws inside the projection produces no message.
- Manual (**the hour-2 gate**): run the server, open two browser windows (one incognito) on `/a/TEST`, call `ping`, and see both windows flash within 1 s.

## Acceptance

- [ ] Two separate browser windows receive the same update in under 1 s.
- [ ] Killing and restarting the server leaves clients reconnected and showing current state within about 10 s.
- [ ] No polling timers anywhere in the client. The countdown is a local ticker, not a fetch.

## Risks

- Serverpod web streaming uses a WebSocket to the API port. Behind a reverse proxy, make sure `Upgrade` headers are passed. Test it on the deploy target early, not on the last evening.
- If `createStream` turns out to be per-server-only, that's fine: the MVP runs a single instance.
