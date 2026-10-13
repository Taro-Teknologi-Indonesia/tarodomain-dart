# UC-14 — Mark unpaid (Organizer, Could — after the Musts and X1–X3)

Depends on: UC-08 (a SOLD lot), UC-09 (outcome view). Judging: **Usefulness (20%)**. Non-payment is the organizers' biggest pain, and this turns the story from roadmap into a working feature.

## Goal

After close, the organizer can flag a SOLD lot as **unpaid**. The lot page and the board show "Winner did not pay" **permanently**, as an appended event next to the sale. Gavel can't force payment, but it makes non-payment visible on the same public record the winner would have used as proof. Full relisting stays on the roadmap.

## Domain (`Lot`)

```dart
void markUnpaid({required DateTime now, String? note}) {
  if (status != LotStatus.sold) throw CommandValidationError('Only SOLD lots can be marked unpaid', context: {'reason': 'NOT_SOLD'});
  if (unpaid) return;                          // idempotent
  raise(LotMarkedUnpaid(id, winnerId!, winnerName!, markedAt: now, note: note));
}
```

- `note` is optional, max 140 chars (e.g. "no reply after 24 h").
- There's no undo event in the MVP. The organizer confirms in a dialog first. If an undo is needed later, it would be another compensating event (`LotPaymentConfirmed`), never a delete, the same model as UC-07.
- Command `MarkUnpaid(lotId, organizerKey)`. The endpoint verifies the organizer key against the Auction (`NotOrganizerError`), like UC-02.

## Projection

- `LotCard`: add `unpaid: bool` and `unpaidAt: DateTime?`; version++; live push.
- `LedgerEntry`: no change. The client renders the unpaid line from the card as a row above the closing row.

## Endpoint

```dart
Future<LotCard> markUnpaid(Session s, UuidValue lotId, String organizerKey, String? note);
```

## Flutter

- Organizer dashboard, on SOLD lots: a "Mark unpaid" text button opens the confirm dialog: "Mark **Natural Pirus Hubei** as unpaid by **Sari**? This is public and permanent." Then an optional note field.
- Board card: the SOLD badge gets a red "UNPAID" tag.
- Lot detail, at the top of the ledger: "⚠ Winner did not pay — marked by organizer 23 Oct 10:12 · 'no reply after 24 h'". The shared result URL (UC-09) shows it too.

## Tests

- Domain: unpaid on SOLD → event; on PASSED or OPEN → `NOT_SOLD`; twice → one event.
- Integration: the wrong organizer key → `NOT_ORGANIZER`; on success the card shows `unpaid` and a live update is pushed.

## Acceptance

- [ ] Only the organizer browser can mark it.
- [ ] Every viewer sees UNPAID on the board and the lot page, live.
- [ ] The sale and the unpaid mark are both in the event history; nothing is overwritten.

Estimate: 30 min.
