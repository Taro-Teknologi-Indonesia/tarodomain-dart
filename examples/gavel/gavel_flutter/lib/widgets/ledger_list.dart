import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:intl/intl.dart';

import '../core/money.dart';

final _clock = DateFormat('HH:mm:ss');

/// [at] on the viewer's clock, as `22:01:47`.
String formatClock(DateTime at) => _clock.format(at.toLocal());

/// A lot's whole ledger, newest on top (UC-05): every bid with who, how
/// much and when. Retracted bids stay, struck through: the event log is
/// the product. A closed lot's closing line sits above them all.
///
/// Lives inside the page's scroll view, so it doesn't scroll itself. New
/// bids slide in at the top.
class LedgerList extends StatefulWidget {
  const LedgerList({
    required this.lot,
    required this.entries,
    required this.closeAt,
    this.me,
    super.key,
  });

  final LotCard lot;

  /// Every bid, in ledger order.
  final List<LedgerEntry> entries;

  /// When the auction closes, in UTC: the closing line's time until the lot
  /// knows its own.
  final DateTime closeAt;

  /// Who this browser bids as, whose rows are highlighted.
  final UuidValue? me;

  @override
  State<LedgerList> createState() => _LedgerListState();
}

class _LedgerListState extends State<LedgerList> {
  final _list = GlobalKey<SliverAnimatedListState>();
  late int _count = widget.entries.length;

  @override
  void didUpdateWidget(LedgerList old) {
    super.didUpdateWidget(old);
    // Rows are never removed, so the ledger only grows. The newest is on
    // top, so new rows go in at 0; the builder reads the current list, so
    // a gap a refetch filled still shows in order.
    final added = widget.entries.length - _count;
    for (var i = 0; i < added; i++) {
      _list.currentState?.insertItem(0);
    }
    _count = widget.entries.length;
  }

  @override
  Widget build(BuildContext context) {
    final closing = _closingLine(widget.lot);
    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        if (closing != null)
          SliverToBoxAdapter(
            child: ListTile(
              dense: true,
              title: Text(
                closing,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        if (widget.entries.isEmpty && closing == null)
          const SliverToBoxAdapter(
            child: ListTile(dense: true, title: Text('No bids yet')),
          ),
        SliverAnimatedList(
          key: _list,
          initialItemCount: _count,
          itemBuilder: (context, index, animation) {
            final entries = widget.entries;
            final entry = entries[entries.length - 1 - index];
            return SizeTransition(
              sizeFactor: animation,
              child: FadeTransition(
                opacity: animation,
                child: LedgerRow(
                  entry,
                  mine: widget.me != null && entry.participantId == widget.me,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// "🔨 Closed 22:03:00 — SOLD to Sari", or null while the lot is open.
  String? _closingLine(LotCard lot) {
    if (lot.status == 'OPEN') return null;
    final at = formatClock(lot.closedAt ?? widget.closeAt);
    final outcome = switch (lot) {
      LotCard(status: 'SOLD', closeCause: 'BUY_NOW', :final winnerName) =>
        'Bought now by $winnerName',
      LotCard(status: 'SOLD', :final winnerName) => 'SOLD to $winnerName',
      _ => 'PASSED — no bids',
    };
    return '🔨 Closed $at — $outcome';
  }
}

/// One bid: `#12 · Budi · Rp 250.000 · 22:01:47`. Struck through and muted
/// once retracted, with when, fading into it as the retraction arrives;
/// highlighted when it's [mine].
class LedgerRow extends StatelessWidget {
  const LedgerRow(this.entry, {this.mine = false, super.key});

  final LedgerEntry entry;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final retracted = entry.retracted;
    final retractedAt = entry.retractedAt;
    return ListTile(
      dense: true,
      tileColor: mine ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
      title: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 300),
        style: DefaultTextStyle.of(context).style.merge(
          TextStyle(
            decoration: retracted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: retracted ? scheme.onSurfaceVariant : scheme.onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        child: Text(
          '#${entry.sequence} · ${entry.bidderName} · '
          '${formatRupiah(entry.amount)} · ${formatClock(entry.placedAt)}',
        ),
      ),
      subtitle: retracted
          ? Text(
              retractedAt == null
                  ? 'retracted'
                  : 'retracted ${formatClock(retractedAt)}',
            )
          : null,
    );
  }
}
