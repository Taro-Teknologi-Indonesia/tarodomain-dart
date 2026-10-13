import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_client/rules.dart';
import 'package:intl/intl.dart';

final _when = DateFormat('d MMM HH:mm');

/// The unpaid mark of a SOLD lot whose winner didn't pay (UC-14): "⚠ Winner
/// did not pay — marked by organizer 23 Oct 10:12 · 'no reply after 24 h'",
/// or null for a lot not marked, or not yet as of [asOf].
String? unpaidLine(LotCard lot, {DateTime? asOf}) {
  final at = lot.unpaidAt;
  if (!lot.unpaid || at == null) return null;
  if (asOf != null && asOf.isBefore(at)) return null;
  final note = switch (lot.unpaidNote) {
    final note? => " · '$note'",
    null => '',
  };
  return '⚠ Winner did not pay — marked by organizer '
      '${_when.format(at.toLocal())}$note';
}

/// A red "UNPAID" tag, next to a SOLD lot's badge.
class UnpaidTag extends StatelessWidget {
  const UnpaidTag({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.red.shade700,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      'UNPAID',
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: Colors.white),
    ),
  );
}

/// Asks the organizer to confirm marking [lot] unpaid, with an optional
/// note: whether they confirmed, and the note, trimmed and null when
/// blank.
Future<({bool confirmed, String? note})> confirmMarkUnpaid(
  BuildContext context,
  LotCard lot,
) async =>
    await showDialog<({bool confirmed, String? note})>(
      context: context,
      builder: (context) => _MarkUnpaidDialog(lot),
    ) ??
    (confirmed: false, note: null);

class _MarkUnpaidDialog extends StatefulWidget {
  const _MarkUnpaidDialog(this.lot);

  final LotCard lot;

  @override
  State<_MarkUnpaidDialog> createState() => _MarkUnpaidDialogState();
}

class _MarkUnpaidDialogState extends State<_MarkUnpaidDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bold = const TextStyle(fontWeight: FontWeight.bold);
    return AlertDialog(
      title: const Text('Mark unpaid?'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Mark '),
                  TextSpan(text: widget.lot.name, style: bold),
                  const TextSpan(text: ' as unpaid by '),
                  TextSpan(text: widget.lot.winnerName ?? '', style: bold),
                  const TextSpan(text: '? This is public and permanent.'),
                ],
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLength: LotRules.maxUnpaidNoteLength,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'no reply after 24 h',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () {
            final note = _note.text.trim();
            Navigator.pop(context, (
              confirmed: true,
              note: note.isEmpty ? null : note,
            ));
          },
          child: const Text('Mark unpaid'),
        ),
      ],
    );
  }
}
