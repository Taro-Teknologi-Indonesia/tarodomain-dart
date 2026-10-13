# X5 — Client-side validation (cross-cutting, Should)

Depends on: UC-01, UC-02, UC-02b, UC-03, UC-06, UC-07 (done). Extend it to UC-13 and UC-14 as they land. About 1.5 h.

## Goal

Every rule the server enforces on what a user types or taps is also checked in the app **before** the call, so a bad form never costs a round trip and a button that can't succeed is disabled, not tapped and refused. Today the domain is the only place these rules live. The client has a few ad-hoc checks (`maxLength` on text fields, an empty-name check in `JoinSheet`, the empty-steps hint in `LotFormSheet`, `Ledger.canRetract`), and everything else shows up only after the server answers `COMMAND_VALIDATION`.

## Rules for this plan

- **The server stays the authority.** Nothing in the domain or the endpoints is removed or relaxed. Client checks are a UX layer, and every existing `GavelFailure` mapping stays, because the client can be stale (another tab, a slow clock, an old build) and the server rejects anyway.
- **Same rule, same words.** A client check uses the server's limit, `field` and `reason`, and shows the server's message. A user sees the same text whether the app or the server caught it.
- **Races aren't validated.** `OUTBID`, `RETRACT_NOT_ALLOWED(NOT_LATEST)` after someone else bids, and a close that lands mid-call depend on state the client can't know yet. They stay server errors with their current handling.
- **No drift.** Limits are written once on the client side, and a server test fails if they ever differ from the domain constants (see Tests).

## Shared rules: `gavel_client/lib/rules.dart`

A hand-written, pure-Dart library in the client package, outside `lib/src/protocol/` so `serverpod generate` never touches it. It isn't exported from `gavel_client.dart`; it's imported as `package:gavel_client/rules.dart`. It lives in `gavel_client` and not `gavel_flutter` so that `gavel_server`'s tests can import it (Flutter packages can't be imported from the server).

```dart
/// What's wrong with one field: the same `field`/`reason` the server puts in
/// `CommandValidationError.context`, and the server's message.
final class FieldError {
  const FieldError(this.field, this.reason, this.message);
  final String field, reason, message;
}

abstract final class AuctionRules {
  static const maxTitleLength = 80;              // Auction.maxTitleLength
  static const minimumLeadTime = Duration(minutes: 5);
  static const maxLots = 20;
  static FieldError? title(String title);
  static FieldError? closeAt(DateTime closeAt, {required DateTime now});
}

abstract final class LotRules {
  static const maxNameLength = 80, maxDescriptionLength = 2000, maxEmojiLength = 16;
  /// Every field error of a new lot, in the server's check order.
  static List<FieldError> newLot({required String name, required int openBid,
      required int? buyNowPrice, required List<int> increments,
      required String description, required String? imageUrl,
      required String tileEmoji, required String tileColor});
}

abstract final class ParticipantRules {
  static const maxNameLength = 24;               // counted in runes, like the server
  static FieldError? displayName(String name);
}

abstract final class JoinCodeRules {
  static const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; // no 0/O, 1/I/L
  static const length = 6;
  static String normalize(String input);          // trim + uppercase
  static bool isValid(String code);
}
```

`LotRules.newLot` returns **all** field errors, not the first one, so the form can mark every bad field at once. The server stops at the first. The table test below compares the server's error with the first one in the client's list.

`gavel_server` gets `gavel_client: {path: ../gavel_client}` under `dev_dependencies` for the parity tests. The domain doesn't import it: the domain keeps its own constants, and the test holds the two together.

## Per use case

### UC-01 — Create auction (`create_auction_page.dart`)

| Field | Rule (server) | Client |
|---|---|---|
| title | trimmed, 1–80 (`EMPTY`, `TOO_LONG`) | `AuctionRules.title` as the field's `validator`; keep `maxLength: 80`, which now reads the constant |
| closeAt | at least 5 min after now (`TOO_SOON`) | `AuctionRules.closeAt` against the device clock; the "Closes at …" line turns red and says "at least 5 minutes from now" instead of only "(in the past)" |

- Wrap the fields in a `Form`. Validate on submit, then `AutovalidateMode.onUserInteraction` after the first failed submit, so errors don't appear while the user is still typing for the first time.
- `_submit` returns early if `formKey.currentState!.validate()` is false or `closeAt` fails. No call is sent.
- Re-check `closeAt` at submit time, not only when picked: a form left open for 5 minutes goes stale.
- The device clock can be off. The server's `TOO_SOON` mapping onto `_errors['closeAt']` stays.

### UC-02 / UC-02b — Add lot (`lot_form_sheet.dart`, `organizer_page.dart`)

| Field | Rule (server) | Client |
|---|---|---|
| name | trimmed, 1–80 | validator |
| openBid | > 0 (`NOT_POSITIVE`) | validator; an empty field counts as 0 |
| buyNowPrice | null, or > openBid (`NOT_ABOVE_OPEN_BID`) | validator, re-run when openBid changes |
| increments | non-empty, each > 0, no duplicates | the steps row's error line (replaces today's `_steps.isEmpty` hint); the custom step input rejects 0 and a step already selected, with "Each step must be different" |
| description | ≤ 2000 | validator (keep `maxLength`) |
| imageUrl | empty, or http(s) with a host (`NOT_A_URL`) | validator, using the same `Uri.tryParse` check as `Lot._isWebUrl` |
| tileEmoji | trimmed, 1–16 UTF-16 units | the emoji picker can only produce valid values; validate anyway so a pasted value can't slip through |
| tileColor | `#RRGGBB` | picker-only today; validate anyway |

- Same `Form` and autovalidate pattern as UC-01. `_submit` calls `LotRules.newLot` and, if the list isn't empty, sets `_errors` from it and doesn't call the server. That reuses the existing inline-error plumbing, so server and client errors render the same way.
- Organizer dashboard: disable **Add lot** when the auction already has `AuctionRules.maxLots` lots ("An auction takes at most 20 lots" as the button's tooltip and a helper line), or when the auction is closed by the server clock. The `lots` / `LOT_CLOSED` snackbars stay for the race.

### UC-03 — Join (`home_page.dart`, `board_page.dart`, `join_sheet.dart`, `router.dart`)

- **Join code** (home page and the board's "open another code" field): an input formatter that uppercases and drops characters outside `JoinCodeRules.alphabet`, so `0`, `O`, `1`, `I`, `L` can't be typed. The Join/Open button is disabled until `JoinCodeRules.isValid`. Today `_join` silently does nothing for a short code.
- **URL code**: `/a/:code` with a malformed code renders the existing "auction not found" state directly, without calling `board`. A valid-looking code that doesn't exist is still the server's `AUCTION_NOT_FOUND`.
- **Display name** (`JoinSheet`): `ParticipantRules.displayName` replaces the `name.isEmpty` check. Two gaps it closes:
  - The server counts **runes**, but `TextField.maxLength` counts grapheme clusters, so a name with ZWJ emoji fits the field and is refused by the server. The validator counts runes like the server and shows "Use 1 to 24 characters" before the call.
  - Control characters (`CONTROL_CHARACTER`): a formatter strips them on paste, and the validator catches anything left.

### UC-06 — Place bid (`bid_bar.dart`)

The chips already only offer `currentPrice + step` for the lot's own steps and disable on close and while a bid is in flight, so `INVALID_INCREMENT` can't come from the UI. Add:
- Chips aren't tappable without a stored identity: show the Join prompt instead of sending a call that ends in `NOT_PARTICIPANT`. Check that `LotPage` already does this; if it does, only add a test.
- The close check uses the **server clock offset** (`clock.dart`), not `DateTime.now()`, so a device that's a minute fast doesn't disable early and one that's slow doesn't send a doomed bid. Verify `_timeUp` does this.

`OUTBID` and the close race stay as they are.

### UC-07 — Retract (`ledger.dart`, `retract_button.dart`)

- `Ledger.canRetract` checks `lot.status == 'OPEN'` but not `closeAt`. Between `closeAt` and the `LotClosed` push the RETRACT button is still shown and the server answers `LOT_CLOSED`. Pass the server-clock `now` in and require `now.isBefore(lot.closeAt)`, and hide the button on a timer at `closeAt`, like the bid chips.
- `NO_BIDS` and `NOT_OWNER` are already unreachable because the button only shows on the user's own latest valid bid.

### UC-13 — Buy now (when built)

Show BUY NOW only when all of these hold, mirroring `Lot.buyNow`'s checks: the lot is open by the server clock, `buyNowPrice != null` (`NO_BUY_NOW`), `currentPrice < buyNowPrice` (`BUY_NOW_PASSED`), and the user has joined. A bid that pushes the price to the BN hides the button on the next live update. `OUTBID` from a stale version stays server-side.

### UC-14 — Mark unpaid (when built)

"Mark unpaid" only on `SOLD` lots that aren't already unpaid (`NOT_SOLD`), only with a stored organizer key. The note field: `maxLength: 140` plus a validator, with the limit added to `rules.dart` as `LotRules.maxUnpaidNoteLength`.

### Read-only use cases

UC-04, UC-05, UC-08, UC-09, UC-10, UC-11 and UC-12 take no user input beyond the join code in the URL (covered under UC-03), so they need nothing here.

## Tests

`gavel_client` (`test/rules_test.dart`, plain `dart test`):
- Each rule at its boundary: title of 80 vs 81 characters after trimming, a 24-rune name with a ZWJ emoji vs 25, BN equal to openBid vs one above, `ftp://x` and `https://` (no host) as image URLs, duplicate steps, a code with `O` in it.

`gavel_server` (`test/domain/client_rules_parity_test.dart`):
- **Constants:** `AuctionRules.maxTitleLength == Auction.maxTitleLength`, and so on for every limit, the lead time, `maxLots` and the join-code alphabet and length (make the endpoint's `_codeAlphabet` and `_codeLength` public, or move them to the domain, so the test can see them).
- **Behaviour, one table, two runners:** a list of bad inputs for `Auction.create`, `Lot.create` and `Participant.join`. For each one, the domain throws `CommandValidationError` with a `field`/`reason`, and the client rule returns the same pair (for `LotRules.newLot`, as its first error). Add a few valid inputs where both must accept. This is what keeps the two in step, not the constants alone.

`gavel_flutter` (widget tests):
- Create auction: an empty title shows the error and `client.auction.create` is never called (fake client).
- Add lot: BN at or below the open bid shows the inline error without a call; Add lot is disabled at 20 lots.
- Join sheet: a 25-rune name shows "Use 1 to 24 characters" without a call; the code field drops `O` and the button stays disabled at 5 characters.
- Retract button: hidden once the server clock passes `closeAt` while the lot is still `OPEN`.

## Acceptance

- [ ] No form sends a call that the domain would reject with `COMMAND_VALIDATION`, for any input the parity table covers.
- [ ] The inline error text is the same whether the client or the server caught it.
- [ ] Buttons that can't succeed (Add lot at 20 lots or after close, Join with a short code, RETRACT after `closeAt`) are disabled or hidden, not refused after the tap.
- [ ] Every server-side check and every `GavelFailure` mapping is still in place.
- [ ] The parity test fails if any limit in `rules.dart` and the domain differs.

Estimate: 1.5 h (rules + parity test 0.5 h, forms 0.5 h, buttons and widget tests 0.5 h).
