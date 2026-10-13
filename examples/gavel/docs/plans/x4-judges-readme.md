# X4 — README for judges (last step before submission)

Judging: all four criteria. Judges skim, so the README has to make each criterion verifiable in under 5 minutes.

## File: `examples/gavel/README.md` (link it from the repo root README)

Sections, in this order:

1. **One line + live link:** "Gavel — a live silent auction that closes itself." Then **▶ Try it: `https://<host>/demo`** and the video link.
2. **Try it in 2 minutes:**
   1. Open `/demo`, type a name, and bid with a chip.
   2. Open the same link in an incognito window, type another name, and bid on the same lot.
   3. Tap a chip in both windows at once: one wins, the other shows "Outbid — {name} bid first".
   4. Retract in one window and watch the strike-through appear in the other.
   5. Wait for the close (≤ 15 min) or browse an earlier closed demo auction.
3. **The problem (usefulness):** Akhmad's Facebook lelang. Disputes over who bid first, deleted comments, and winners who don't pay. Include a screenshot of a real `-----# LELANG #-----` post, anonymized, next to the lot form.
4. **How it uses Serverpod:** a table mapping each feature to the Serverpod part behind it:

   | Gavel feature | Serverpod |
   |---|---|
   | Bids, retractions, closes | Endpoints, with typed `SerializableException` errors |
   | Event store, read models, participants | ORM tables + migrations (TaroDomain module) |
   | Live board | Streaming endpoint over WebSocket + `session.messages` |
   | Auction closes at 22:03 with every laptop closed | Future calls (one-off at closeAt, plus a sweep) |
   | Rolling demo auction | Recurring future call |
   | The app itself | Serverpod web server hosting the Flutter web build |
   | Hosting | Serverpod Cloud (if used) |

5. **Craft:** a short architecture diagram (Flutter → endpoint → TaroDomain pipeline → event store → projection → live push), then the three hard parts:
   - Bid races resolve into `OutbidError`, using the optimistic-concurrency retry.
   - The deadline is enforced in the domain, not only by the scheduler.
   - Retraction is a compensating event, so it stays visible forever.
6. **Proof:** `dart test` summary output and the `tool/race.dart` output (X3) with the command to rerun it.
7. **Honest limits:** no accounts (name + per-browser key), single server instance, URL-only images, and what's on the roadmap (relist after non-payment, native builds, web push).
8. **Run locally:** 5 commands at most.

## Checklist before submitting

- [ ] Every link works from a logged-out browser.
- [ ] `/demo` is open at the time of submission.
- [ ] The README test counts match a fresh `dart test` run.
- [ ] The video is ≤ 3 minutes and shows the live URL on screen.

Estimate: 30 min (plus screenshots).
