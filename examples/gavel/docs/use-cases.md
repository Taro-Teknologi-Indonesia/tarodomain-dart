Gavel — Use Case Document (v2, web-first)
Product: Gavel — a live silent auction that closes itself.
One-liner: The crowd stays on Facebook; the gavel — a provably fair, self-closing bid ledger — lives in Gavel.
Delivery: Flutter web app served by Serverpod. No install, no app store — the join link pasted into a Facebook post is the entire funnel.
Context scenario: Akhmad sells gemstones through lelang posts on Facebook. Tonight he creates a Gavel auction for three stones, sets close at 22:03 WITA, and pastes the link under his photos. Forty collectors tap it from the Facebook mobile app; the page opens in their phone browser, they type a display name, and bid by tapping kelipatan chips. A fat-fingered +300k is visibly retracted. Two bids collide in the final second and one gets a clean answer. At 22:03:00 the auction closes on the server while Akhmad's laptop is closed. Nobody can dispute who bid first — and the winner pastes the lot's URL back into the thread as proof.

Status: MVP for the Serverpod "Build Something Real" hackathon. Scope frozen to use cases marked Must.

Changed in this revision (v2):

Web-first delivery — join-by-link replaces app install; big-screen mode becomes trivial; native mobile and PWA are roadmap.
Kelipatan ladder replaces fixed increment (UC-02, UC-06) — matches the community-standard +25 +50 +100 +150 +200 +300 practice; InvalidIncrementError becomes reachable and meaningful.
Lot fields extended — description + optional image URL (parity with the seller's Facebook template); emoji/color tile as fallback.
UC-13 Buy Now (BN) added — a bidder takes the lot at the seller's fixed BN price; reuses the close logic; Should-have, not in the video.
UC-09 strengthened — the closed lot's URL is a shareable receipt (the "certificate of result," nearly free on web).
UC-03 persists identity in browser localStorage — refresh-safe, no accounts.
Demo plan re-blocked for browser recording.
1. Actors

```
| Actor | Description |
|---|---|
| **Organizer** | Creates the auction, defines lots, owns nothing else — cannot edit or delete bids. Desktop browser. |
| **Bidder** | Joins via link, types a display name, bids and retracts via kelipatan chips. Phone browser (arrives from the Facebook app) or desktop. |
| **Participant** | Organizer or bidder, once joined — views boards and history. |
| **Viewer** | Read-only big-screen display — same web app on a projector (UC-11). |
| **System** | Serverpod scheduler + TaroDomain sagas. Acts autonomously at deadlines. |


```

No authentication. Identity = join code + display name + server-issued participantId, persisted in localStorage. Known limitation, accepted for MVP.

2. Glossary
Auction — one event with a single close time and a 6-character join code embedded in the share URL.
Lot — one item; event-sourced aggregate. Status: OPEN → SOLD / PASSED.
Kelipatan ladder — the set of allowed raise steps (default +25 +50 +100 +150 +200 +300 ribu), set per lot by the organizer.
Bid — an immutable event, never edited or deleted.
Leader — holder of the current highest bid (or the open bid if none).
Retraction — a compensating event that voids a bid; remains visible, struck through, forever.
Close time — server-side deadline (stored UTC, displayed local); lots close via saga, not by any client.
Join link — URL containing the auction code; the only distribution mechanism.
3. Use case overview

```
| ID | Use case | Actor | Priority | Changed in v2 |
|---|---|---|---|---|
| UC-01 | Create auction & share link | Organizer | Must | Share is a URL, not a code |
| UC-02 | Add lots | Organizer | Must | Ladder, description, image URL |
| UC-03 | Join via link | Bidder | Must | Web link; localStorage identity |
| UC-04 | View live board | Participant | Must | Responsive web layout |
| UC-05 | View lot detail & ledger | Participant | Must | Image display with tile fallback |
| UC-06 | Place bid via kelipatan chips | Bidder | Must — the star | Chips replace fixed button |
| UC-07 | Retract bid | Bidder | Must | — |
| UC-08 | Auto-close at deadline | System | Must | — |
| UC-09 | View outcome & share result | Participant | Must | URL = shareable receipt; winner code to claim |
| UC-10 | Time-travel view | Participant | Should | — |
| UC-11 | Big-screen mode | Viewer | Should | Trivial on web |
| UC-12 | Live update push | System | Must | WebSocket on web |
| UC-13 | Buy Now ("BN") | Bidder | Should | New |
| UC-14 | Mark unpaid | Organizer | Could | New — non-payment made visible |
| UC-15 | My auctions: running & history | Organizer (signed in) | Should | New — builds on X6 sign-in |


```

Capability matrix (TaroDomain features, load-bearing per use case):

```
| Capability | 01 | 02 | 03 | 06 | 07 | 08 | 09 | 10 | 12 |
|---|---|---|---|---|---|---|---|---|---|
| Event sourcing (immutable audit) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| Optimistic concurrency + typed errors | ✅ | ✅ | ✅ | ✅✅ | ✅ | ✅ | — | — | — |
| Sagas / server-side deadlines | ✅ | — | — | — | — | ✅ | — | — | — |
| Live client sync (websocket) | — | ✅ | — | ✅ | ✅ | ✅ | — | — | ✅ |
| Projections (eventual reads) | — | ✅ | — | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Compensating events (undo) | — | — | — | — | ✅ | — | — | — | — |
| Time travel | — | — | — | — | — | — | — | ✅ | — |
| State-based aggregate (per-aggregate choice) | — | — | ✅ | — | — | — | — | — | — |


```

4. Detailed use cases
UC-01 Create auction & share link — Organizer (Must)
Trigger: Organizer opens Gavel in a desktop browser, taps "New auction."
Main flow:

Enter title and close time (date + time picker, minimum 5 minutes ahead; odd-minute closes like 22:03 are normal, not special).
Server creates the Auction aggregate → AuctionCreated(title, closeAt, code); 6-character code generated.
Close saga registered: a Serverpod future call scheduled at closeAt.
Dashboard shows the share link (URL containing the code), a countdown, and a copy button.
Extensions: 2a. Close time in the past → typed validation error, stay on form.
Postconditions: Auction exists, open, close scheduled server-side.
TaroDomain: event-sourced aggregate; saga registration at creation.
Web note: "Sharing" is copying a URL. The organizer pastes it into their Facebook post or comment — this is the entire distribution model: no store, no install, no onboarding.

UC-02 Add lots — Organizer (Must)
Trigger: Organizer taps "Add lot" on the dashboard.
Main flow:

Form fields: title ("Natural Pirus Hubei"), open bid (int rupiah), kelipatan ladder (preset +25 +50 +100 +150 +200 +300 ribu, editable), description (multi-line: weight, dimensions, origin, setting, condition), optional image URL (paste a link to the existing Facebook photo), optional BN price (the template's `BN:` line, added in UC-02b), emoji + color tile (fallback visual).
Server emits LotCreated(name, openBid, increments, description, imageUrl?, buyNowPrice?, tile). buyNowPrice is the optional BN price from the template (UC-13).
Lot appears on the board with status OPEN, current price = open bid.
Extensions: 1a. Open bid ≤ 0 or empty ladder → typed validation error. 1b. BN price at or below the open bid → typed validation error (UC-02b).
TaroDomain: event-sourced Lot aggregate; board projection updates live.
Design note: this form is the seller's existing -----# LELANG #----- template, structured. Quote that in the write-up.

UC-03 Join via link — Bidder (Must)
Trigger: Bidder taps the link in the Facebook post/comment (or types the code manually at the URL-less home screen).
Main flow:

URL carries the code. If no stored identity for this auction, prompt for a display name.
Server creates participant (state-based aggregate — a normal Serverpod row, events still recorded) → ParticipantJoined.
Board loads; client subscribes to the auction's live topic over websocket.
Extensions: 1a. Unknown code → AuctionNotFoundError → "Auction not found — check the link." 1b. Auction already closed → join read-only; the history is browsable — the record outlives the event.
Web notes: participantId + display name persisted in localStorage per auction — refresh keeps you logged in as you; duplicate names allowed, participantId disambiguates (shown as a short tag like "Budi · #3f9c" where names collide; UC-09). Phone browser is the primary target (bidders arrive from the Facebook mobile app): single-column responsive layout, thumb-reachable chips.
TaroDomain: deliberately state-based — demonstrates the per-aggregate choice: joins don't need time travel, bids do.

UC-04 View live board — Participant (Must)
Main flow: Board shows all lots as cards: tile or image, name, current price, leader name, status, one auction countdown. Every committed change (bid, retraction, close) arrives via live push — no polling, no refresh.
Web notes: responsive — single column on phones, grid on desktop. Propagation target < 1s across devices.
TaroDomain: projection read model + live sync after commit.
Demo beat: the whole video is this use case breathing.

UC-05 View lot detail & ledger — Participant (Must)
Main flow: Tap a card → detail screen: image (if URL provided; falls back to tile on load error), big current price, minimum next bid, my-bid status, kelipatan chips, RETRACT (if I hold the latest bid), and below: the full ledger — every bid in order, who/when/amount, retractions struck through and never removed.
TaroDomain: event sourcing as the product — the ledger is the audit trail.
Demo beat: 2:30–2:50.

UC-06 Place bid via kelipatan chips — Bidder (Must — the star)
Preconditions: Joined; lot OPEN.
Trigger: Bidder taps a kelipatan chip. Single tap — no confirm dialog (RETRACT is the recovery path, UC-07).
Main flow:

Lot detail shows current price + chip row: +25k +50k +100k +150k +200k +300k, each previewing the resulting bid (+100k → Rp 250.000).
Tap sends PlaceBid(lotId, participantId, expectedVersion, amount = currentPrice + increment).
Server validates: lot open, amount − currentPrice ∈ ladder. Commits under strong consistency.
BidPlaced; projections update; live push to the auction topic; UI flips to "You're the high bidder — Rp 250.000."
Extensions (each a typed error with payload, each a demo beat):

3a. Concurrent bid: another BidPlaced committed first; version conflict → OutbidError(currentPrice, leaderName) → "Outbid — {name} bid first," chips re-render from the new price. No retry loop, no lost bid, no double winner. (Video 1:30–2:00 — the money shot.)
3b. Off-ladder amount (stale client after being outbid): InvalidIncrementError(allowedIncrements, currentPrice) → chips re-render. Server-side invariant; the chip UI normally prevents it.
3c. Bid vs. close race: a bid at 22:02:58 and the close saga serialize on the aggregate. Bid first → it counts and the close sees it. Close first → LotClosedError(closedAt). Both orders deterministic and safe. (Video 2:00–2:30.)
TaroDomain: optimistic concurrency with typed errors — with money on it.
Web note: the collision demo is two browser windows (one incognito for the second participant).

UC-07 Retract bid — Bidder (Must)
Preconditions: Bidder holds the lot's latest bid; lot OPEN.
Main flow:

Tap RETRACT → confirmation dialog ("Retract your bid of Rp 450.000?") — the fat-finger recovery path.
RetractBid(lotId, participantId, expectedVersion).
Server validates: own latest bid, lot open.
Appends BidRetracted — a compensating event, not a delete.
Previous bid becomes leader again (or price returns to open bid). All screens update live. Ledger shows the entry struck through, permanently.
Extensions: 3a. Not own latest / not theirs → RetractNotAllowedError(reason). 3b. Closed → LotClosedError. 3c. Outbid between view and tap → concurrency conflict → typed error, no partial state.
TaroDomain: compensating events. In a comment thread a retracted bid is a deleted comment or a public scandal; here it's a first-class, visible correction.
Demo beat: 0:50–1:30.

UC-08 Auto-close auction at deadline — System (Must)
Preconditions: Auction open; close saga scheduled at closeAt (UC-01).
Main flow:

Serverpod future call fires at closeAt — server-side, independent of any client.
Saga loads each open Lot, emits LotClosed: SOLD with winner = highest bid, or PASSED if no bids.
Projections flip; live push to all devices; winner's screen shows confirmation.
Extensions:

2a. Lot already closed (retry, double-fire) → idempotent no-op.
2b. Final-second bid in flight → serialized by the aggregate (UC-06, ext. 3c).
2c. Organizer's device offline / laptop closed → close still fires. (Video 2:00–2:30 — the "wait, how?" beat for dev judges.)
Postconditions: All lots terminal; ledger final; auction read-only but fully browsable.
TaroDomain: saga with timeout driven by Serverpod future calls; idempotency; strong consistency on close.

UC-09 View outcome & share result — Participant (Must)
Main flow: After close, board shows SOLD + winner + final price (or PASSED). Lot detail ends in the closing event. Late joiners can still enter and read everything.
Web note (new): the closed lot's URL is a shareable receipt — the winner pastes it back into the Facebook thread as proof of result. This is the "certificate of result" from the roadmap, essentially free on web; it closes the loop with the venue the crowd never left.
Claiming the win: display names aren't unique (UC-03), and the receipt is public, so two bidders called "Budi" could both paste it. The receipt names the winner with a short tag from their participantId ("SOLD to Budi · #3f9c"); the tag also appears on the board and in the ledger wherever two people share a name. The tag is public, so it is not proof. Proof is a winner code: the winner's browser shows it in the "You won" banner (only the holder of the participant key can request it), and the organizer's dashboard shows the same code for each SOLD lot. The seller asks the buyer for the code before handing over the lot.
Extensions: 1a. Two bidders with the same name both claim the lot → seller asks for the winner code; only the real winner's matches. 1b. Winner lost their browser identity (cleared data, other device) → no code; seller decides, or marks the lot unpaid (UC-14).
TaroDomain: event sourcing as permanent, publicly verifiable record. The winner code is derived from the participant's stored key hash on request; it is never an event, so the public history can't leak it.

UC-10 Time-travel view — Participant (Should — cut if behind hour 12)
Main flow: In lot history, tap the "as of" chip → pick a past time (presets, e.g., 22:00 / 22:02, or slider) → server replays the lot's events up to T → UI shows price + leader with an "AS OF 22:02" badge. Tap LIVE to return. Read-only; no commands against past state.
TaroDomain: time travel; directly verifiable by a judge against the visible ledger.
Demo beat: 2:30–2:50.

UC-11 Big-screen mode — Viewer (Should)
Main flow: Same web app at a board URL (e.g., ?screen=board): full-screen, read-only, large prices, live. Projector at the gala; in the hackathon video it's your third "camera." Nearly free now that delivery is web.
Cut if behind.

UC-12 Live update push — System (Must)
Every committed event (bid, retraction, close) pushes to topic auction:{code}; all subscribed web clients update. No polling anywhere.
TaroDomain: post-commit live sync over websocket.
Web risk note: verify websocket sync works in two separate browser windows by hour 2 — the entire demo depends on it.

UC-13 Buy Now ("BN") — Bidder (Should — only if ahead; not in the video)
Preconditions: Joined; lot OPEN; the lot has a BN price (optional field in UC-02, above the open bid) and the current price is still below it.
Trigger: Instead of a kelipatan chip, the bidder taps BUY NOW and confirms — the Gavel version of commenting "BN" under the seller's post.
Main flow: BuyNow(lotId, participantId, expectedVersion) under strong consistency appends BidPlaced(amount = BN price, buyNow) and LotClosed(SOLD, winner = buyer, finalPrice = BN price, cause = BUY_NOW) in one commit. Everyone sees the lot flip to SOLD live; the ledger shows the BN row and the closing row.
Extensions: 2a. A chip bid committed first → OutbidError, the buyer re-confirms at the new state. 2b. Another BN or the deadline first → LotClosedError. 2c. Bidding already reached the BN price → validation error (BUY_NOW_PASSED); BN disappears and bidding continues. 2d. Lot has no BN price → validation error (NO_BUY_NOW).
TaroDomain: one close path, two triggers (deadline saga and a buyer) — and a two-event atomic append that races cleanly with PlaceBid. ~1 h.

UC-14 Mark unpaid — Organizer (Could — after the Musts; ~30 min)
Trigger: The winner of a SOLD lot doesn't pay. The organizer taps "Mark unpaid" on the lot, with an optional short note.
Main flow: Emits LotMarkedUnpaid(winnerId, winnerName, markedAt, note?) on the Lot. Board and lot page show "UNPAID" / "Winner did not pay" permanently, live, including on the shared result URL (UC-09).
Extensions: 1a. Lot not SOLD → typed validation error (NOT_SOLD). 1b. Already marked → idempotent no-op. 1c. Not the organizer → NotOrganizerError.
Why: winners who don't pay are the community's biggest pain, even with real Facebook accounts. Gavel can't force payment, but it puts non-payment on the same public, append-only record the winner would have used as proof. Relisting stays on the roadmap.
TaroDomain: another appended event — the sale is never overwritten.

UC-15 My auctions: running & history — Organizer (Should — after X6; ~2 h)
Preconditions: The organizer is signed in (X6). Only auctions created while signed in belong to an account; older auctions and the demo have no creator and never show up.
Trigger: On the home page, the signed-in organizer taps "My auctions" (shown next to "Sign out"). Signed out, the link isn't shown, and opening /mine directly asks for sign-in first, then returns to the list.
Main flow:

The server reads the organizer's auctions from the auctions read model by the signed-in user, never from the browser. Any browser the organizer signs into shows the same list.
Running: every auction that is OPEN or CLOSING, soonest close first. Each row shows title, join code, close time (local) with a countdown, and lot count.
History: every CLOSED auction, most recent close first. Each row shows title, join code, close date, lot count, and the outcome in one line: "2 of 3 sold · Rp 1.250.000", with "1 unpaid" when any SOLD lot was marked unpaid (UC-14).
Tapping a row opens that auction's organizer dashboard (/a/<CODE>/organizer).
Extensions: 1a. No auctions yet → empty state with a "Create an auction" button. 1b. Session expired or revoked → SignedOut → back to sign-in, then back to /mine. 4a. The browser doesn't hold that auction's organizer key (another device, cleared data) → the row says "View only on this device" and the dashboard opens read-only, as today; the share link and outcomes are still there, but adding lots, marking unpaid and winner codes need the creating browser (organizer rights by account stay on the roadmap).
Postconditions: Nothing changes; this is a read.
Privacy: the creator's user ID is never sent to bidders. It stays on the server; the board and the live push carry the same auction data as before.
TaroDomain: projections — the creator was already on AuctionCreated (X6), so the list is one more column on the existing read model, filled by the projection and backfilled from the event store for auctions created since X6.

5. Consistency model

```
| Command | Consistency | On conflict |
|---|---|---|
| `PlaceBid` | **Strong** | `OutbidError` (currentPrice, leaderName) |
| `RetractBid` | **Strong** | Typed errors, no partial state |
| `BuyNow` | **Strong** | `OutbidError` / `LotClosedError` |
| `CloseAuction` (saga) | **Strong** | Idempotent no-op |
| `JoinAuction` | Strong (state-based) | — |
| Reads (board, ledger, time travel) | Eventual (projections) | Monotonic; race window invisible in practice |


```

6. Domain events & typed errors
Event
Aggregate
Key payload
AuctionCreated	Auction	code, title, closeAt
LotCreated	Lot	name, openBid, increments[], description, imageUrl?, buyNowPrice?, tile
ParticipantJoined	Participant (state-based)	displayName
BidPlaced	Lot	participantId, amount, sequence, buyNow
BidRetracted	Lot	participantId, reference to voided bid
LotClosed	Lot	outcome, winnerId?, finalPrice?, cause (DEADLINE | BUY_NOW)
LotMarkedUnpaid	Lot	winnerId, winnerName, markedAt, note?

Error
Raised when
Payload
OutbidError	Concurrent bid committed first	currentPrice, leaderName
LotClosedError	Lot/auction closed	closedAt
InvalidIncrementError	Off-ladder amount	allowedIncrements, currentPrice
RetractNotAllowedError	Not own latest bid, or closed	reason
AuctionNotFoundError	Unknown code in link	—

All amounts are int rupiah (IDR has no subunit); format Rp 250.000.

7. Out of scope (frozen)
Cut for MVP: payments/escrow; accounts & auth; proxy/max bidding; anti-sniping soft close; photo/video upload (URL paste only); chat or comments of any kind; multiple concurrent auctions; FCM/web push notifications; QR codes (the link replaces them); custom bid amounts outside the ladder; staggered per-lot closes; PWA install.

Roadmap (write-up): native mobile builds (same codebase — the pitch: "the web app is the MVP; iOS/Android are one flutter build away"), PWA + web push, FCM, escrow, relist after non-payment (the organizer marks a SOLD lot UNPAID and relists it into a new auction with one tap, copying name, ladder, description and image; the original record keeps the unpaid outcome, so a winner who doesn't pay stays visible on the public ledger; community practice is to restart the auction, not offer the lot to the runner-up), exportable certificate of result. Note that "shareable web link" — roadmap in v1 — is the MVP now; that's the story of this revision.