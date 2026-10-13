import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:intl/intl.dart';

import '../core/money.dart';
import '../core/names.dart';
import '../core/time_travel.dart';

final _clock = DateFormat('HH:mm:ss');

/// [at] on the viewer's clock, as `22:01:47`.
String formatClock(DateTime at) => _clock.format(at.toLocal());

/// A lot's whole ledger, newest on top (UC-05): every bid with who, how
/// much and when. Retracted bids stay, struck through: the event log is
/// the product. A closed lot's closing line sits above them all.
///
/// As of a past moment (UC-10), rows placed after it are dimmed and a
/// bid retracted after it stands un-struck: the replay, visible.
///
/// Lives inside the page's scroll view, so it doesn't scroll itself. New
/// bids slide in at the top.
class LedgerList extends StatefulWidget {
  const LedgerList({
    required this.lot,
    required this.entries,
    required this.closeAt,
    this.me,
    this.sharedNames = const {},
    this.asOf,
    super.key,
  });

  final LotCard lot;

  /// The lot as of a past moment, if the viewer picked one.
  final LotAsOf? asOf;

  /// Every bid, in ledger order.
  final List<LedgerEntry> entries;

  /// When the auction closes, in UTC: the closing line's time until the lot
  /// knows its own.
  final DateTime closeAt;

  /// Who this browser bids as, whose rows are highlighted.
  final UuidValue? me;

  /// The names more than one bidder goes by, which get their tag.
  final Set<String> sharedNames;

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
                  sharedNames: widget.sharedNames,
                  asOf: widget.asOf?.at,
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
    if (lot.status == 'OPEN' || widget.asOf?.status == 'OPEN') return null;
    final at = formatClock(lot.closedAt ?? widget.closeAt);
    final winner = switch (lot.winnerName) {
      final name? => displayName(name, lot.leaderId, widget.sharedNames),
      null => null,
    };
    final outcome = switch (lot) {
      LotCard(status: 'SOLD', closeCause: 'BUY_NOW') => 'Bought now by $winner',
      LotCard(status: 'SOLD') => 'SOLD to $winner',
      _ => 'PASSED — no bids',
    };
    return '🔨 Closed $at — $outcome';
  }
}

/// One bid: `#12 · Budi · Rp 250.000 · 22:01:47`. Struck through and muted
/// once retracted, with when, fading into it as the retraction arrives;
/// highlighted when it's [mine]. A name in [sharedNames] gets its tag.
/// As of [asOf], a bid placed later is dimmed and one retracted later
/// isn't struck.
class LedgerRow extends StatelessWidget {
  const LedgerRow(
    this.entry, {
    this.mine = false,
    this.sharedNames = const {},
    this.asOf,
    super.key,
  });

  final LedgerEntry entry;
  final bool mine;
  final Set<String> sharedNames;

  /// The past moment the ledger is viewed at, or null for live.
  final DateTime? asOf;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final asOf = this.asOf;
    final retracted = asOf == null ? entry.retracted : entry.retractedBy(asOf);
    final retractedAt = entry.retractedAt;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: asOf != null && entry.placedAfter(asOf) ? 0.3 : 1,
      child: ListTile(
        dense: true,
        tileColor: mine
            ? scheme.primaryContainer.withValues(alpha: 0.35)
            : null,
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
            '#${entry.sequence} · '
            '${displayName(entry.bidderName, entry.participantId, sharedNames)} · '
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
      ),
    );
  }
}
