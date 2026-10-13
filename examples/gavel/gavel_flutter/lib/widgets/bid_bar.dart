import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:intl/intl.dart';

import '../core/bidding.dart';
import '../core/failures.dart';
import '../core/identity.dart';
import '../core/money.dart';

/// The kelipatan chips of an open lot (UC-06), over a banner that says what
/// the last tap came to.
///
/// One tap bids `currentPrice + step` at once, with no confirmation. While
/// it's in flight every chip is disabled and the tapped one spins; the
/// price itself only changes when the server answers. Every refusal has its
/// own words, and the outbid one stays up for [bannerTime].
///
/// A lot with a Buy Now price below the current price also gets a BUY NOW
/// button under the chips (UC-13). Unlike a chip it asks first, since it
/// closes the lot and can't be retracted.
class BidBar extends StatefulWidget {
  const BidBar({
    required this.lot,
    required this.identity,
    required this.closeAt,
    required this.offset,
    required this.bidder,
    required this.onAccepted,
    required this.onStale,
    required this.onNotParticipant,
    super.key,
  });

  final LotCard lot;

  /// Who this browser bids as.
  final Identity identity;

  /// When bidding ends, in UTC: the chips disable themselves then, on the
  /// server's clock.
  final DateTime closeAt;

  /// Server clock minus local clock.
  final ValueListenable<Duration> offset;

  final Bidder bidder;

  /// Called with the lot as the accepted bid left it.
  final ValueChanged<LotCard> onAccepted;

  /// Called when a refusal says [lot] is behind the server's, so the page
  /// can fetch the current one if the push hasn't brought it yet.
  final VoidCallback onStale;

  /// Called when the server no longer knows [identity].
  final VoidCallback onNotParticipant;

  /// How long a banner stays up.
  static const bannerTime = Duration(seconds: 3);

  @override
  State<BidBar> createState() => _BidBarState();
}

enum _Tone { good, warning, bad }

class _BidBarState extends State<BidBar> {
  /// The step of the bid in flight, if any.
  int? _pending;

  /// Whether a Buy Now is in flight.
  bool _buying = false;

  bool get _busy => _pending != null || _buying;

  /// Set when the server said bidding passed the BN price, so the button
  /// stays hidden until the next card says so too.
  bool _buyNowPassed = false;

  ({String text, _Tone tone})? _banner;
  Timer? _bannerTimer;

  /// When the server said the lot closed, if it did.
  DateTime? _closedAt;

  /// Whether [BidBar.closeAt] has passed on the server's clock.
  bool _timeUp = false;

  /// Fires at [BidBar.closeAt] to disable the chips.
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    widget.offset.addListener(_scheduleClose);
    _scheduleClose();
  }

  @override
  void didUpdateWidget(BidBar old) {
    super.didUpdateWidget(old);
    if (old.offset != widget.offset) {
      old.offset.removeListener(_scheduleClose);
      widget.offset.addListener(_scheduleClose);
    }
    if (old.closeAt != widget.closeAt) _scheduleClose();
    if (old.lot.version != widget.lot.version) _buyNowPassed = false;
  }

  @override
  void dispose() {
    widget.offset.removeListener(_scheduleClose);
    _bannerTimer?.cancel();
    _closeTimer?.cancel();
    super.dispose();
  }

  /// Checks [BidBar.closeAt] against the server's clock now, and again
  /// when it arrives.
  void _scheduleClose() {
    _closeTimer?.cancel();
    final serverNow = DateTime.now().toUtc().add(widget.offset.value);
    final left = widget.closeAt.difference(serverNow);
    void timeUp(bool value) {
      if (value == _timeUp) return;
      if (mounted) {
        setState(() => _timeUp = value);
      } else {
        _timeUp = value;
      }
    }

    timeUp(left <= Duration.zero);
    if (left > Duration.zero) _closeTimer = Timer(left, () => timeUp(true));
  }

  void _show(String text, _Tone tone) {
    _bannerTimer?.cancel();
    setState(() => _banner = (text: text, tone: tone));
    _bannerTimer = Timer(BidBar.bannerTime, () {
      if (mounted) setState(() => _banner = null);
    });
  }

  Future<void> _bid(int step) async {
    if (_busy) return;
    setState(() => _pending = step);
    final outcome = await widget.bidder.bid(widget.identity, widget.lot, step);
    if (!mounted) return;
    setState(() => _pending = null);
    switch (outcome) {
      case BidAccepted(:final card):
        widget.onAccepted(card);
        unawaited(HapticFeedback.mediumImpact());
        _show(
          "You're the high bidder — ${formatRupiah(card.currentPrice)}",
          _Tone.good,
        );
      case BidRefused(:final failure):
        _refused(failure);
    }
  }

  Future<void> _buyNow() async {
    if (_busy) return;
    final lot = widget.lot;
    final price = lot.buyNowPrice!;
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => BuyNowDialog(name: lot.name, price: price),
    );
    if (sure != true || !mounted || _busy) return;
    setState(() => _buying = true);
    final outcome = await widget.bidder.buyNow(widget.identity, lot);
    if (!mounted) return;
    setState(() => _buying = false);
    switch (outcome) {
      case BidAccepted(:final card):
        widget.onAccepted(card);
        unawaited(HapticFeedback.heavyImpact());
        _show(
          '🔨 You bought it — ${formatRupiah(card.finalPrice ?? price)}',
          _Tone.good,
        );
      case BidRefused(failure: Outbid(:final leaderName, :final currentPrice)):
        widget.onStale();
        _show(
          'Price moved — ${leaderName ?? 'someone'} bid '
          '${formatRupiah(currentPrice)}',
          _Tone.warning,
        );
      case BidRefused(failure: LotClosed(:final winnerName?)):
        widget.onStale();
        _show('Sold — $winnerName bought it first', _Tone.bad);
      case BidRefused(:final failure):
        _refused(failure);
    }
  }

  void _refused(GavelFailure failure) {
    switch (failure) {
      case Outbid(:final leaderId, :final leaderName):
        widget.onStale();
        if (leaderId == widget.identity.participantId.uuid) {
          _show("You're already the high bidder", _Tone.good);
        } else {
          _show('Outbid — ${leaderName ?? 'someone'} bid first', _Tone.warning);
        }
      case InvalidIncrement():
        widget.onStale();
        _show('Price moved — pick again', _Tone.warning);
      case LotClosed(:final closedAt):
        setState(() => _closedAt = closedAt);
        final time = DateFormat.Hms().format(closedAt.toLocal());
        _show("Closed at $time — your bid didn't count", _Tone.bad);
      case NotParticipant():
        widget.onNotParticipant();
      case Unexpected():
        _show("Couldn't reach the server — try again", _Tone.bad);
      case Invalid(context: {'reason': 'BUY_NOW_PASSED'}):
        widget.onStale();
        setState(() => _buyNowPassed = true);
        _show('Bidding passed the BN price — keep bidding', _Tone.warning);
      case Invalid(context: {'reason': 'NO_BUY_NOW'}):
        widget.onStale();
        _show('This lot has no Buy Now', _Tone.bad);
      case Invalid(:final message):
        _show(message, _Tone.bad);
      case RetractNotAllowed() ||
          AuctionNotFound() ||
          NotOrganizer() ||
          NotFound():
        _show('Something went wrong — try again', _Tone.bad);
    }
  }

  @override
  Widget build(BuildContext context) {
    final closed = _closedAt != null || widget.lot.status != 'OPEN' || _timeUp;
    final banner = _banner;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: banner == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _Banner(banner.text, banner.tone),
                ),
        ),
        if (closed)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Bidding closed', textAlign: TextAlign.center),
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final step in widget.lot.increments)
                _BidChip(
                  step: step,
                  amount: widget.lot.currentPrice + step,
                  busy: _pending == step,
                  onPressed: _busy ? null : () => _bid(step),
                ),
            ],
          ),
          if (widget.bidder.canBuyNow &&
              !_buyNowPassed &&
              canBuyNow(widget.lot))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _BuyNowButton(
                price: widget.lot.buyNowPrice!,
                busy: _buying,
                onPressed: _busy ? null : _buyNow,
              ),
            ),
        ],
      ],
    );
  }
}

/// BUY NOW · Rp 1.500.000: takes the lot at its BN price, after
/// [BuyNowDialog].
class _BuyNowButton extends StatelessWidget {
  const _BuyNowButton({
    required this.price,
    required this.busy,
    required this.onPressed,
  });

  final int price;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: busy
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.gavel),
      label: Text('BUY NOW · ${formatRupiah(price)}'),
    ),
  );
}

/// Asks before a Buy Now, which closes the lot and can't be retracted.
/// Pops true to buy.
class BuyNowDialog extends StatelessWidget {
  const BuyNowDialog({required this.name, required this.price, super.key});

  final String name;
  final int price;

  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(fontWeight: FontWeight.bold);
    return AlertDialog(
      title: const Text('Buy now?'),
      content: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Buy '),
            TextSpan(text: name, style: bold),
            const TextSpan(text: ' now for '),
            TextSpan(text: formatRupiah(price), style: bold),
            const TextSpan(
              text: "? This closes the lot and you can't retract it.",
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Buy for ${formatRupiah(price)}'),
        ),
      ],
    );
  }
}

/// One kelipatan chip: the step over the price it bids.
class _BidChip extends StatelessWidget {
  const _BidChip({
    required this.step,
    required this.amount,
    required this.busy,
    required this.onPressed,
  });

  final int step;
  final int amount;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 96),
      child: ActionChip(
        onPressed: onPressed,
        tooltip: 'Bid ${formatRupiah(amount)}',
        avatar: busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(formatStep(step), style: text.titleMedium),
            Text(formatRupiah(amount), style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// A big, colored line saying what the last tap came to.
class _Banner extends StatelessWidget {
  const _Banner(this.text, this.tone);

  final String text;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      _Tone.good => (Colors.green.shade700, Colors.white),
      _Tone.warning => (Colors.amber.shade600, Colors.black),
      _Tone.bad => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Semantics(
      liveRegion: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
