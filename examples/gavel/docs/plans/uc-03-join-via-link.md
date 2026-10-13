# UC-03 — Join via link (Bidder, Must)

Depends on: UC-01. Feeds into: UC-04, UC-06, UC-07.

## Goal

A bidder taps the link in the Facebook app, the page opens in the phone browser, they type a display name once, and they're on the board. A refresh keeps them as themselves.

## Domain — the deliberately state-based aggregate

`lib/src/domain/participant.dart`, modeled on `AccountHolder` in the bank example:

- `ParticipantId extends AggregateId`.
- `Participant extends AggregateRoot<ParticipantId, ParticipantEvent>`:
  - `factory Participant.join(id, auctionId, displayName, keyHash)`: the trimmed name must be 1–24 chars with no control chars, else `CommandValidationError(field: 'displayName')`. It raises `ParticipantJoined`. `keyHash` goes into state, and so into the row; it's left out of the event payload because the event log is public history.
  - `bool hasKey(String key)` compares `sha256(key)` to `keyHash` in constant time, the same helper the organizer key uses (put it in `domain/secret_key.dart`).
  - `Participant.fromRow(ParticipantRow row)` uses `restoreVersion(row.version)`.
- `ParticipantRepository extends ServerpodStateRepository<Participant, ParticipantId, ParticipantRow>` (in `infra/`, because it imports Serverpod).
- Command `JoinAuction(participantId, auctionId, displayName, keyHash)`, handled by `ParticipantHandler` (`AggregateCommandHandler`) with consistency strong.
- The **domain check that the auction exists** happens in the endpoint (read model lookup), and not in the handler. The participant aggregate doesn't need the auction aggregate.

```yaml
# participant_row.spy.yaml
class: ParticipantRow
serverOnly: true
table: gavel_participants
fields:
  id: UuidValue?, defaultPersist=random_v7
  auctionId: UuidValue
  displayName: String
  keyHash: String           # SHA-256 of participantKey, base64url; the key itself is never stored
  version: int
indexes:
  gavel_participants_auction_idx: { fields: auctionId }
```

Write-up line: *"Bids are event-sourced because we need time travel and an audit trail. Joins are a plain row because we don't. TaroDomain lets you choose per aggregate, and the events are still recorded."* Check that the state repository still publishes `ParticipantJoined` to the bus, as `HolderRegistered` does.

Duplicate names are allowed, and `participantId` tells them apart. The ledger may show "Budi" twice. Add `· #a3f` (the first 3 hex chars of the id) only where two leaders with the same name would be ambiguous. That's optional polish.

## Endpoints

```dart
// AuctionEndpoint
Future<BoardSnapshot> board(Session s, String code);
//   → AuctionView + List<LotCard> + serverNow; throws AUCTION_NOT_FOUND
Future<JoinResult> join(Session s, String code, String displayName);
//   → participantId, participantKey, displayName, auction (AuctionView)
Future<bool> checkParticipant(Session s, String code, UuidValue participantId, String participantKey);
//   → true if the row exists for that auction and the key matches (the localStorage sanity check)
```

- `join` generates `participantKey` with `Random.secure()` (32 bytes, base64url), dispatches `JoinAuction` with its hash, and returns the plain key **once**. The server can't recover it later.
- The shared `_verifyParticipant` helper (see [00-foundation §4](00-foundation.md)) lives in a small mixin used by `AuctionEndpoint` and `LotEndpoint`.

- `join` on a **CLOSED** auction still succeeds (ext. 1b), because the record outlives the event. The client simply renders read-only. A join without a name is also fine for closed auctions: the client can skip the prompt and browse.
- Normalize `code` with `trim().toUpperCase()` everywhere.

## Flutter

- `BoardRoute(/a/:code)` on enter:
  1. `board(code)`. On `AUCTION_NOT_FOUND`, show a full-page "Auction not found — check the link" with the code shown and a field to retype it (ext. 1a).
  2. Read `localStorage['gavel:<CODE>']`. If it's present, call `checkParticipant(participantId, participantKey)` in the background. If that's false (DB reset or a tampered entry), forget the identity and prompt again.
  3. If there's no identity and the auction is OPEN, show a `JoinSheet` (bottom sheet, autofocus, a single field "Your name as shown to others", and a big **Join** button). Bidders can still see the board behind the sheet, which is the hook. Organizers (`:org` key present) skip the prompt entirely: they don't bid, so they never get a participant.
  4. Save `{participantId, participantKey, displayName}` and subscribe to the live channel (UC-12).
- A header chip shows "You: Budi". Tapping it offers "Not you? Switch name", which clears the identity for this auction only.
- Phone-first: the sheet sits above the keyboard (`MediaQuery.viewInsets`), and the text field uses `TextInputAction.done` to submit.
- Facebook in-app browser: test on a real phone. localStorage persists inside FB's webview per session but may be wiped. That's an accepted limitation; mention "Open in browser" in the FAQ, not in the UI.

## Tests

- Domain: an empty name → error; a 25-char name → error; 🙂 in a name is fine.
- Integration: `join` → a row in `gavel_participants` with `version = 1`; a `ParticipantJoined` event exists in the event store; `join` on an unknown code → `AUCTION_NOT_FOUND`.
- Integration: the row stores `keyHash`, the plain key appears nowhere in the DB (search both the event table and the participant table), and `checkParticipant` returns true with the right key and false with a wrong key or another auction's code.
- Manual: join, refresh, and confirm there's no prompt and the name is still shown. Then join in incognito and get a separate identity.

## Acceptance

- [ ] An unknown code shows the friendly not-found page.
- [ ] A closed auction is browsable read-only without being forced to join.
- [ ] A refresh keeps identity; incognito is a different participant.
- [ ] Knowing someone's `participantId` (it's visible in the ledger) isn't enough to act as them.
- [ ] Works at 360 px width; the name field isn't covered by the keyboard.

Estimate: 1 h.
