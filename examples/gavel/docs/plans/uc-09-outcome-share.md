# UC-09 — View outcome & share result (Participant, Must)

Depends on: UC-05, UC-08. It's the last Must, and **recording starts after this one**.

## Goal

After close, the board shows SOLD + winner + final price (or PASSED). The lot detail ends in the closing event, and late joiners can read everything. The closed lot's URL is a **shareable receipt**: the winner pastes it back into the Facebook thread as proof.

Display names aren't unique (UC-03), so "SOLD to Budi" alone can't settle who won when two bidders are called Budi, and the receipt is public, so either of them can paste it. Two additions close that gap (see [Claiming the win](#claiming-the-win)):

- a **name tag** (`Budi · #3f9c`) that makes the receipt say which Budi, and
- a **winner code** that only the winning browser can show and only the organizer can check, so the seller can tell who actually won.

## Server

Mostly done by earlier UCs (cards and ledger hold the outcome). The extras are:

1. **Link previews for Facebook (Open Graph).** Facebook's crawler doesn't run Flutter JS, so a pasted `/a/CODE/lot/ID` would preview as a blank "Gavel". Add a small Serverpod web route for `/a/:code/lot/:lotId` that returns the Flutter `index.html` **with `<meta property="og:*">` injected**:
   - `og:title`: "SOLD — Natural Pirus Hubei · Rp 450.000" (or "LIVE — … · now Rp 250.000" while open)
   - `og:description`: "Won by Sari · #3f9c at 22:03 WITA · 14 bids, 1 retraction · verified ledger on Gavel"
   - `og:image`: the lot's `imageUrl` if set. Otherwise skip it; generating images is out of scope.
   - `og:url`: the canonical lot URL.

   Do a string replace on a `<!-- OG -->` placeholder in `web/app/index.html` and HTML-escape every value. Budget 30 min. If Serverpod 4's web route API fights back, drop this and accept a generic preview. The link still works.
2. `LotEndpoint.detail` already serves closed lots, and no join is needed (UC-03 ext. 1b).

## Flutter

- **Board, closed state:** cards show the SOLD badge (gold) with "Sari · Rp 450.000", or PASSED (grey) with "No bids". The header reads "Closed 22:03 WITA" in place of the countdown.
- **Lot detail, closed state:**
  - The price block becomes the **result block**: "🔨 SOLD to Sari · #3f9c" (the tag is always there in this block), "Rp 450.000", and "Closed 22:03:00 WITA · by deadline" (or "· Buy Now by Sari").
  - The action bar is replaced by a **Share result** button, which copies the lot URL and shows a "Link copied — paste it in the Facebook thread as proof" snackbar. Use `navigator.share` through `share_plus` on phones if it's quick, otherwise clipboard only.
  - Ledger: the closing row on top, then every bid including retractions. The same view for everyone, forever.
  - Footer note in small text: "This record is append-only. Bids can't be edited or deleted — retractions stay visible."
- **Winner-only touch:** if `winnerId == me`, show a "You won" banner above the result block. It carries the winner code (below).
- Opening a lot URL directly (from Facebook) **without** an identity on a closed auction goes straight to read-only detail, with no join sheet.

## Claiming the win

### Name tag (the partial step)

The tag is `#` plus the **last** 4 hex chars of the participant ID, e.g. `#3f9c`. Not the first ones: participant IDs are UUIDv7, so their leading chars are the join timestamp and would match for everyone who joined that evening. Put one helper, `String nameTag(UuidValue participantId)`, in `gavel_client` so that the server (OG text) and the app produce the same tag.

Where it shows:
- **Always:** the result block, the "You won" banner (so the winner knows their own tag), and the OG description.
- **Only when two people share the name:** board leader/winner lines and ledger rows. "Share the name" means the same trimmed, case-insensitive name with a different `participantId` among the cards and ledgers the app has loaded. Everywhere else the plain name stays, so the common case looks unchanged.

The tag only makes the receipt clear. It isn't proof: it comes from the public ID, so the other Budi can read it from the ledger and copy it.

### Winner code

A short code only the winning browser can get, checked by the organizer before handing the lot over.

- **Formula (server only):** `winnerCode(keyHash, lotId)` = HMAC-SHA256 keyed with the participant's stored `keyHash`, over the lot ID, with the first 30 bits written as 6 Crockford base32 chars (no I, L, O or U) and shown as `7KQ-2XM`. Put it in `domain/keys.dart` next to `hashKey`. It's computed on request and never stored, put in an event, logged or pushed live.
- **Why it can't be faked:** computing it needs `keyHash`, which never leaves the server, and asking for it needs the `participantKey`, which only the winner's browser holds. A code is different for each lot, so one win's code says nothing about another. Guessing doesn't work either: nothing public checks a guess, only the seller does.
- **Endpoints** (reads only, no command, no event):

  ```dart
  // LotEndpoint: the winner's own code, or null if this participant didn't win this lot
  // (lot not SOLD, or SOLD to someone else). Wrong key → NOT_PARTICIPANT.
  Future<String?> winnerCode(Session s, UuidValue lotId, UuidValue participantId,
                             String participantKey);

  // AuctionEndpoint: lotId → code for every SOLD lot. Wrong key → NOT_ORGANIZER.
  Future<Map<String, String>> winnerCodes(Session s, String code, String organizerKey);
  ```

  Both read the winner from the `LotCard` and `keyHash` from `ParticipantRow`. If UC-08 didn't put `winnerId` on the card, add the column.
- **Winner's screen:** the "You won" banner fetches the code and shows "Your winner code: **7KQ-2XM** · send it to the seller to claim", with a copy button.
- **Organizer's screen:** the dashboard lists each SOLD lot as "Budi · #3f9c · code 7KQ-2XM". The organizer's lot detail shows the same line under the result block.
- **Seller's flow:** a buyer DMs "I won the Pirus". The seller asks for the code and compares. Match → hand it over. No match → not the winner, whatever name they use.
- **Lost key** (cleared browser data or another device): no code. That's like losing a ticket, and the seller decides from the ledger and the conversation. If nobody claims, UC-14 marks the lot unpaid.

## Tests

- Widget test: the closed lot renders the result block, no chips and the share button.
- Widget test: two leaders called "Budi" with different IDs → both show their tag. A single "Sari" → no tag on the board or in the ledger, but a tag in the result block.
- Unit: `nameTag` uses the last 4 hex chars. `winnerCode` is stable for the same key and lot, and changes with a different lot or a different key.
- Integration: the winner with their key → the code. A second participant with the **same display name** → null. A wrong key → `NOT_PARTICIPANT`. An open or PASSED lot → null. `winnerCodes` with the organizer key returns the same code, and with a wrong key → `NOT_ORGANIZER`.
- Manual: join twice as "Budi" (normal window and incognito), let one win, and check that only the winner's window shows the code and that it matches the organizer dashboard.
- Manual: copy the closed-lot URL, open it in a fresh incognito window → the full ledger shows without joining.
- Manual: paste the URL into the Facebook post composer (or https://developers.facebook.com/tools/debug/) and check the OG preview if implemented.

## As built

- No schema change: the winner is the card's `leaderId` once it's SOLD (as UC-08 noted), so both endpoints read `LotCard` and `ParticipantRow` only. `winnerCodes` loads the `Auction` aggregate through the runtime's repository to check the organizer key, the same check `AddLot` makes.
- `nameTag` lives in `gavel_client/lib/name_tag.dart`, exported from `gavel_client.dart`. The Flutter helpers (`sharedNames`, `displayName`, `tagged`) are in `core/names.dart`, and `AuctionController.sharedNames` computes the clashes from the cards' leaders and every ledger loaded.
- The "You won" banner fetches its code itself (`loadCode`, once per banner), so the code never enters the controller or the live feed. It shows on the board and the lot page.
- The organizer's dashboard shows a "Winners" card above the grid once a lot is SOLD, and fetches the codes again when another lot sells. The organizer's lot page shows `Budi · #3f9c · code 7KQ-2XM` under the result block.
- A closed lot's bottom bar is "Share result" for everyone, organizer and visitors without an identity included. Clipboard only, no `share_plus`.
- Times are the viewer's local clock with no zone label ("Closed 22:03"), matching the ledger. Browsers don't report a reliable "WITA".
- The OG stretch isn't done.

## Acceptance

- [ ] SOLD/PASSED with winner and final price on every device after close.
- [ ] A direct lot URL works for anyone, any time after close, read-only.
- [ ] The share button copies the canonical lot URL.
- [ ] Two winners can't be confused: the receipt says `SOLD to Budi · #3f9c`, and only the real winner's browser shows a code that matches the organizer's.
- [ ] The winner code never appears in an event, a log line, a live push or a page anyone else can open.
- [ ] (Stretch) The Facebook preview shows "SOLD — {lot} · Rp …".

Estimate: 1.75 h (0.75 h outcome and share, 0.25 h name tag, 0.75 h winner code), +0.5 h OG stretch. The OG stretch is the lowest-priority item in the whole plan; do it only after UC-10.
