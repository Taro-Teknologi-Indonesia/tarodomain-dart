import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:intl/intl.dart';

import '../core/time_travel.dart';
import 'ledger_list.dart';

final _minute = DateFormat('HH:mm');

/// Picks a past moment to view a lot at (UC-10): quick picks from the
/// ledger, or a slider that snaps to each bid and retraction.
class AsOfSheet extends StatefulWidget {
  const AsOfSheet({
    required this.ledger,
    required this.end,
    this.closedAt,
    super.key,
  });

  /// Opens the sheet; completes with the moment picked, or null.
  static Future<DateTime?> show(
    BuildContext context, {
    required List<LedgerEntry> ledger,
    required DateTime end,
    DateTime? closedAt,
  }) => showModalBottomSheet<DateTime>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AsOfSheet(ledger: ledger, end: end, closedAt: closedAt),
  );

  /// The lot's ledger, in order.
  final List<LedgerEntry> ledger;

  /// Now on the server's clock, or the close: quick picks stop before it.
  final DateTime end;

  /// When the lot closed, if it has.
  final DateTime? closedAt;

  @override
  State<AsOfSheet> createState() => _AsOfSheetState();
}

class _AsOfSheetState extends State<AsOfSheet> {
  late final _presets = presetsFor(
    widget.ledger,
    end: widget.end,
    closedAt: widget.closedAt,
    clock: (at) => _minute.format(at.toLocal()),
  );
  late final _stops = stopsFor(widget.ledger);
  late var _stop = _stops.length - 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stop = _stops[_stop];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('View the lot as of…', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'The server replays the lot\'s events up to then.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final preset in _presets)
                  ActionChip(
                    label: Text(preset.label),
                    onPressed: () => Navigator.pop(context, preset.at),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_stops.length > 1)
              Slider(
                value: _stop.toDouble(),
                max: (_stops.length - 1).toDouble(),
                divisions: _stops.length - 1,
                label: stop.label,
                onChanged: (v) => setState(() => _stop = v.round()),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${formatClock(stop.at)} · ${stop.label}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, stop.at),
                  child: const Text('Show'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
