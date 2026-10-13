# UC-09 — View outcome & share result (Participant, Must)

Depends on: UC-05, UC-08. It's the last Must, and **recording starts after this one**.

## Goal

After close, the board shows SOLD + winner + final price (or PASSED). The lot detail ends in the closing event, and late joiners can read everything. The closed lot's URL is a **shareable receipt**: the winner pastes it back into the Facebook thread as proof.

## Server

Mostly done by earlier UCs (cards and ledger hold the outcome). The extras are:

1. **Link previews for Facebook (Open Graph).** Facebook's crawler doesn't run Flutter JS, so a pasted `/a/CODE/lot/ID` would preview as a blank "Gavel". Add a small Serverpod web route for `/a/:code/lot/:lotId` that returns the Flutter `index.html` **with `<meta property="og:*">` injected**:
   - `og:title`: "SOLD — Natural Pirus Hubei · Rp 450.000" (or "LIVE — … · now Rp 250.000" while open)
   - `og:description`: "Won by Sari at 22:03 WITA · 14 bids, 1 retraction · verified ledger on Gavel"
   - `og:image`: the lot's `imageUrl` if set. Otherwise skip it; generating images is out of scope.
   - `og:url`: the canonical lot URL.

   Do a string replace on a `<!-- OG -->` placeholder in `web/app/index.html` and HTML-escape every value. Budget 30 min. If Serverpod 4's web route API fights back, drop this and accept a generic preview. The link still works.
2. `LotEndpoint.detail` already serves closed lots, and no join is needed (UC-03 ext. 1b).

## Flutter

- **Board, closed state:** cards show the SOLD badge (gold) with "Sari · Rp 450.000", or PASSED (grey) with "No bids". The header reads "Closed 22:03 WITA" in place of the countdown.
- **Lot detail, closed state:**
  - The price block becomes the **result block**: "🔨 SOLD to Sari", "Rp 450.000", and "Closed 22:03:00 WITA · by deadline" (or "· Sell Now by organizer").
  - The action bar is replaced by a **Share result** button, which copies the lot URL and shows a "Link copied — paste it in the Facebook thread as proof" snackbar. Use `navigator.share` through `share_plus` on phones if it's quick, otherwise clipboard only.
  - Ledger: the closing row on top, then every bid including retractions. The same view for everyone, forever.
  - Footer note in small text: "This record is append-only. Bids can't be edited or deleted — retractions stay visible."
- **Winner-only touch:** if `winnerId == me`, show a "You won" banner above the result block.
- Opening a lot URL directly (from Facebook) **without** an identity on a closed auction goes straight to read-only detail, with no join sheet.

## Tests

- Widget test: the closed lot renders the result block, no chips and the share button.
- Manual: copy the closed-lot URL, open it in a fresh incognito window → the full ledger shows without joining.
- Manual: paste the URL into the Facebook post composer (or https://developers.facebook.com/tools/debug/) and check the OG preview if implemented.

## Acceptance

- [ ] SOLD/PASSED with winner and final price on every device after close.
- [ ] A direct lot URL works for anyone, any time after close, read-only.
- [ ] The share button copies the canonical lot URL.
- [ ] (Stretch) The Facebook preview shows "SOLD — {lot} · Rp …".

Estimate: 0.75 h (+0.5 h OG stretch).
