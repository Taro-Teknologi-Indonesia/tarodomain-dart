import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';

import '../core/money.dart';
import '../core/names.dart';
import 'lot_visual.dart';
import 'unpaid.dart';

/// How much room a [LotCardWidget] takes: compact on the organizer
/// dashboard, regular on the board, large on the big screen.
enum LotCardSize { dense, regular, large }

/// One lot: its visual, name, price, leader and status. The board, the
/// organizer dashboard and the big screen all show lots with it.
///
/// When the price changes, the new one slides in over a short pulse, so a
/// bid from anywhere is seen arriving.
class LotCardWidget extends StatefulWidget {
  const LotCardWidget(
    this.lot, {
    this.me,
    this.sharedNames = const {},
    this.size = LotCardSize.regular,
    this.onTap,
    super.key,
  });

  final LotCard lot;

  /// The participant this browser bids as, whose lead is highlighted.
  final UuidValue? me;

  /// The names more than one bidder goes by, which get their tag.
  final Set<String> sharedNames;

  final LotCardSize size;
  final VoidCallback? onTap;

  /// How long the background pulses after a price change.
  static const flash = Duration(milliseconds: 600);

  /// The big screen's pulse, slower so the room sees it.
  static const largeFlash = Duration(seconds: 1);

  @override
  State<LotCardWidget> createState() => _LotCardWidgetState();
}

class _LotCardWidgetState extends State<LotCardWidget>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: _large ? LotCardWidget.largeFlash : LotCardWidget.flash,
  );

  bool get _large => widget.size == LotCardSize.large;

  @override
  void didUpdateWidget(LotCardWidget old) {
    super.didUpdateWidget(old);
    if (old.lot.lotId == widget.lot.lotId &&
        old.lot.currentPrice != widget.lot.currentPrice) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final lot = widget.lot;
    final (title, price, detail, padding) = switch (widget.size) {
      LotCardSize.dense => (
        text.titleSmall,
        text.titleLarge,
        text.bodySmall,
        8.0,
      ),
      LotCardSize.regular => (
        text.titleMedium,
        text.headlineSmall,
        text.bodySmall,
        12.0,
      ),
      // Readable from the back of the room.
      LotCardSize.large => (
        text.headlineMedium,
        text.displayLarge?.copyWith(fontSize: 72),
        text.headlineSmall,
        20.0,
      ),
    };
    final flash = _large ? Colors.amber : theme.colorScheme.primaryContainer;
    final details = Column(
      // Keys the flip on the big screen from the open card to the closed one.
      key: ValueKey(_large && lot.status != 'OPEN'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                lot.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: title,
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(lot.status),
            if (lot.unpaid) ...[const SizedBox(width: 4), const UnpaidTag()],
          ],
        ),
        const SizedBox(height: 4),
        if (_large && lot.status != 'OPEN')
          _Hammered(lot: lot, sharedNames: widget.sharedNames, style: title)
        else ...[
          Row(
            children: [
              Flexible(child: _price(lot, price)),
              if (lot.buyNowPrice case final bn?
                  when lot.status == 'OPEN' && lot.currentPrice < bn) ...[
                const SizedBox(width: 8),
                BuyNowTag(bn),
              ],
            ],
          ),
          _leader(lot, detail),
        ],
      ],
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              // A wider visual leaves the price room on a projector.
              aspectRatio: _large ? 16 / 9 : 4 / 3,
              child: LotVisual(
                imageUrl: lot.imageUrl,
                emoji: lot.tileEmoji,
                color: lot.tileColor,
              ),
            ),
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) => ColoredBox(
                // Up fast, then fade out over the rest of the pulse.
                color: flash.withValues(
                  alpha: _pulse.isAnimating ? (1 - _pulse.value) * flash.a : 0,
                ),
                child: child,
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: _large ? _flip(details) : details,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [lot]'s leader. On the big screen a new one slides in.
  Widget _leader(LotCard lot, TextStyle? style) {
    final leader = _Leader(
      key: ValueKey(lot.leaderId),
      lot: lot,
      me: widget.me,
      sharedNames: widget.sharedNames,
      style: style,
    );
    if (!_large) return leader;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(-0.3, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      child: leader,
    );
  }

  /// [details] turning over like a card when the lot closes: the open face
  /// edges away over the first half, the closed one back over the second.
  Widget _flip(Widget details) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 700),
    switchInCurve: const Interval(0.5, 1, curve: Curves.easeOut),
    switchOutCurve: const Interval(0.5, 1, curve: Curves.easeIn),
    transitionBuilder: (child, animation) => AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX((1 - animation.value) * pi / 2),
        child: child,
      ),
      child: child,
    ),
    layoutBuilder: (current, previous) =>
        Stack(alignment: Alignment.topLeft, children: [...previous, ?current]),
    child: details,
  );

  /// [lot]'s price, the new one sliding in over the old.
  Widget _price(LotCard lot, TextStyle? style) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 300),
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    layoutBuilder: (current, previous) => Stack(
      alignment: Alignment.centerLeft,
      children: [...previous, ?current],
    ),
    child: Text(
      formatRupiah(lot.currentPrice),
      key: ValueKey(lot.currentPrice),
      style: style?.copyWith(
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}

/// The lot's Buy Now price, as `BN Rp 1.500.000`.
class BuyNowTag extends StatelessWidget {
  const BuyNowTag(this.price, {super.key});

  final int price;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: colors.secondary),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'BN ${formatRupiah(price)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: colors.secondary),
      ),
    );
  }
}

/// Who leads [lot], or who won it, or its opening bid while nobody has bid.
/// "You" stands out when [me] is the one, and a name in [sharedNames] gets
/// its tag.
class _Leader extends StatelessWidget {
  const _Leader({
    required this.lot,
    required this.me,
    required this.sharedNames,
    required this.style,
    super.key,
  });

  final LotCard lot;
  final UuidValue? me;
  final Set<String> sharedNames;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final open = lot.status == 'OPEN';
    final name = switch (open ? lot.leaderName : lot.winnerName) {
      final name? => displayName(name, lot.leaderId, sharedNames),
      null => null,
    };
    final isMe = me != null && lot.leaderId == me;
    if (name == null) {
      return Text(
        open
            ? 'No bids — opens at ${formatRupiah(lot.openBid)}'
            : 'No bids — passed',
        style: style,
      );
    }
    if (!isMe) {
      return Text(
        open ? '$name leads' : '$name won',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    final colors = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'You',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors.onTertiaryContainer,
              backgroundColor: colors.tertiaryContainer,
            ),
          ),
          TextSpan(text: open ? ' lead' : ' won'),
        ],
      ),
      style: style,
    );
  }
}

/// A closed lot on the big screen: "🔨 SOLD — Sari — Rp 450.000", the
/// gavel striking once, or "PASSED — no bids".
class _Hammered extends StatelessWidget {
  const _Hammered({
    required this.lot,
    required this.sharedNames,
    required this.style,
  });

  final LotCard lot;
  final Set<String> sharedNames;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final bold = style?.copyWith(fontWeight: FontWeight.bold);
    final winner = lot.winnerName;
    if (lot.status != 'SOLD' || winner == null) {
      return Text('PASSED — no bids', style: bold);
    }
    final name = displayName(winner, lot.leaderId, sharedNames);
    final price = formatRupiah(lot.finalPrice ?? lot.currentPrice);
    return Row(
      children: [
        TweenAnimationBuilder<double>(
          // Raised, then brought down onto the block.
          tween: Tween(begin: -0.8, end: 0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.bounceOut,
          builder: (context, angle, child) => Transform.rotate(
            angle: angle,
            alignment: Alignment.bottomRight,
            child: child,
          ),
          child: Text('🔨', style: bold),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            'SOLD — $name — $price',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: bold?.copyWith(color: Colors.amber),
          ),
        ),
      ],
    );
  }
}

/// OPEN in green, SOLD in gold, PASSED in grey.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'OPEN' => Colors.green.shade700,
      'SOLD' => Colors.amber.shade800,
      _ => Colors.grey.shade600,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

/// [lots] in one column under 600 px and a grid above, or [empty] when
/// there are none. A fixed number of [columns] holds at any width.
class LotGrid extends StatelessWidget {
  const LotGrid({
    required this.lots,
    required this.empty,
    this.me,
    this.sharedNames = const {},
    this.size = LotCardSize.regular,
    this.columns,
    this.onTap,
    super.key,
  });

  final List<LotCard> lots;
  final String empty;
  final int? columns;

  /// The participant this browser bids as, whose leads are highlighted.
  final UuidValue? me;

  /// The names more than one bidder goes by, which get their tag.
  final Set<String> sharedNames;

  final LotCardSize size;
  final void Function(LotCard lot)? onTap;

  Widget _card(LotCard lot) => LotCardWidget(
    lot,
    // Keeps each card's flash state with its lot as the list changes.
    key: ValueKey(lot.lotId),
    me: me,
    sharedNames: sharedNames,
    size: size,
    onTap: onTap == null ? null : () => onTap!(lot),
  );

  @override
  Widget build(BuildContext context) {
    if (lots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(empty, textAlign: TextAlign.center),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.fromLTRB(16, 8, 16, 96);
        if (this.columns == null && constraints.maxWidth < 600) {
          return ListView.separated(
            padding: padding,
            itemCount: lots.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _card(lots[i]),
          );
        }
        // A grid of cards at most 360 px wide. Rows rather than a GridView,
        // so a card is as tall as its content needs at any width.
        const spacing = 8.0;
        final width = constraints.maxWidth - padding.horizontal;
        final columns =
            this.columns ?? ((width + spacing) / (360 + spacing)).ceil();
        final rows = (lots.length / columns).ceil();
        return ListView.separated(
          padding: padding,
          itemCount: rows,
          separatorBuilder: (_, _) => const SizedBox(height: spacing),
          itemBuilder: (_, row) => IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < columns; col++) ...[
                  if (col > 0) const SizedBox(width: spacing),
                  Expanded(
                    child: row * columns + col < lots.length
                        ? _card(lots[row * columns + col])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
