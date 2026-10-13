# UC-11 — Big-screen mode (Viewer, Should)

Depends on: UC-04, UC-12. Cut if behind. It's nearly free on web, and it's the third "camera" in the video.

## Goal

`/a/CODE?screen=board` is a full-screen, read-only, projector-sized live board.

## Server

Nothing. It reuses `board(code)` and `live.watch(code)`.

## Flutter

- In the `BoardRoute` builder, `state.uri.queryParameters['screen'] == 'board'` → `BigScreenBoard` and **skips the join flow** (viewers aren't participants).
- `BigScreenBoard`:
  - Dark theme regardless of system, black background (projector-friendly).
  - Header: auction title (display-medium), a **huge countdown** (`display-large`, monospace digits, red in the final 60 s), and the join URL in large text, so the room can type it. No QR codes (out of scope per use-cases §7).
  - Grid: `crossAxisCount = lots.length <= 3 ? lots.length : 3`. Each card uses the `large` variant of `LotCardWidget`: the visual, name, **price at ~72 px**, and the leader name.
  - On a price change, the card pulses gold for 1 s and the leader name slides in. This is the same animation as UC-04, scaled up.
  - Close: cards flip to "SOLD — Sari — Rp 450.000" with a short 🔨 animation.
  - Hide the cursor after 3 s of no movement, and add a full-screen button (`document.documentElement.requestFullscreen()` via `package:web`).
- Organizer dashboard: an "Open big screen" button that opens the URL in a new tab.

## Tests

- Manual: a 1920×1080 window plus a phone window. A bid from the phone shows up on the big screen in under 1 s and is readable from about 3 m away (zoom check).

## Acceptance

- [ ] No join prompt, and no controls that issue commands.
- [ ] Live updates and close behave the same as on the normal board.
- [ ] Readable at projector distance; the countdown is the dominant element in the final minute.

Estimate: 0.5 h.
