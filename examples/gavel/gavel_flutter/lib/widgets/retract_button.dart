import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';

import '../core/failures.dart';
import '../core/identity.dart';
import '../core/money.dart';
import '../core/retracting.dart';

/// RETRACT for the holder of a lot's latest valid bid (UC-07).
///
/// A tap asks first, naming the exact amount, because the retraction is
/// public and permanent: the bid stays in the ledger, struck through.
/// Every answer ends in a snackbar.
class RetractButton extends StatefulWidget {
  const RetractButton({
    required this.lot,
    required this.bid,
    required this.identity,
    required this.send,
    required this.onRetracted,
    required this.onStale,
    required this.onNotParticipant,
    super.key,
  });

  final LotCard lot;

  /// The bid to take back: [identity]'s, the latest valid one.
  final LedgerEntry bid;

  /// Who this browser bids as.
  final Identity identity;

  final SendRetract send;

  /// Called with the lot as the retraction left it.
  final ValueChanged<LotCard> onRetracted;

  /// Called when a refusal says [lot] is behind the server's.
  final VoidCallback onStale;

  /// Called when the server no longer knows [identity].
  final VoidCallback onNotParticipant;

  @override
  State<RetractButton> createState() => _RetractButtonState();
}

class _RetractButtonState extends State<RetractButton> {
  var _busy = false;

  Future<void> _retract() async {
    final amount = formatRupiah(widget.bid.amount);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Retract your bid of $amount?'),
        content: const Text(
          'Everyone will see it struck through in the history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep bid'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retract'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    String message;
    try {
      final card = await widget.send(
        lotId: widget.lot.lotId,
        identity: widget.identity,
        expectedVersion: widget.lot.version,
        commandId: const Uuid().v7obj(),
      );
      widget.onRetracted(card);
      message = switch (card.leaderName) {
        final leader? =>
          'Bid retracted — $leader leads again at '
              '${formatRupiah(card.currentPrice)}',
        null =>
          'Bid retracted — back to the open bid of '
              '${formatRupiah(card.currentPrice)}',
      };
    } catch (e) {
      final failure = GavelFailure.from(e);
      if (failure is NotParticipant) {
        if (mounted) setState(() => _busy = false);
        widget.onNotParticipant();
        return;
      }
      if (failure is Outbid) widget.onStale();
      message = switch (failure) {
        RetractNotAllowed(reason: 'NOT_LATEST') =>
          "Someone bid after you — you can't retract now.",
        RetractNotAllowed() || Outbid() => 'The lot changed — check again.',
        LotClosed() => 'Lot closed.',
        Unexpected() => "Couldn't reach the server — try again",
        _ => 'Something went wrong — try again',
      };
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: _busy ? null : _retract,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.error,
        minimumSize: const Size.fromHeight(40),
      ),
      icon: _busy
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.undo),
      label: Text('RETRACT ${formatRupiah(widget.bid.amount)}'),
    );
  }
}
