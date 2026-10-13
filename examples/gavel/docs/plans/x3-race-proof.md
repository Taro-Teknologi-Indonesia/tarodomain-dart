# X3 — Race proof tool (after UC-06; polish after UC-08)

Judging: **Does it work (30%)** ("nothing critical is faked") and **Craft (25%)**.

Depends on: UC-03, UC-06, X2 (demo auction to aim at).

## Goal

Prove the concurrency claims against the **deployed** server with real parallel requests, with no artificial server delay anywhere. This replaces the removed `--dev-delay-bid-ms` idea.

## `gavel_server/tool/race.dart`

A Dart CLI that uses the generated `gavel_client` package directly:

```
dart run tool/race.dart --host https://<host> --code ABC123 --lot <lotId> --bidders 20
```

1. Joins N participants (`join`), each with its own key.
2. Reads the lot card once, so every bidder shares the same `expectedVersion` and price.
3. Fires N `placeBid(+smallest step)` calls at once (`Future.wait`, separate clients so they're separate connections).
4. Prints:

```
20 bids at version 7, price Rp 250.000
  accepted : 1   (Bidder-13 → Rp 275.000)
  OUTBID   : 19  (all named Bidder-13 as leader)
  other    : 0
ledger rows added: 1   ✓ exactly one winner
```

5. Exits non-zero if accepted ≠ 1 or anything other than `OUTBID` came back, so it doubles as a smoke test after deploys.

`--mode close-race`: start N bids spread across ±300 ms around `closeAt` and report how many were accepted before close and how many got `LOT_CLOSED`. Then verify from `detail(lotId)` that no ledger row is timestamped at or after `closeAt`, and that the winner is the last valid bid.

## Uses

- **Video:** a 10-second terminal shot of `race.dart` hitting production next to the board in the browser, which flips once while the terminal reports 19 OUTBIDs.
- **README:** paste the output and the command so judges can rerun it against `/demo`.
- **CI-ish check:** run it after every deploy (X1 step 5).

## Notes

- Bidders created by the tool are real participants named `race-1…race-N` in the ledger. On the demo auction that's honest and visible, not hidden.
- Keep N ≤ 50 so it doesn't look like load-testing someone's server.

Estimate: 40 min.
