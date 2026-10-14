import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';

import '../core/clock.dart';
import '../core/money.dart';
import '../core/names.dart';
import '../theme.dart';
import 'brand.dart';
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
    this.closeAt,
    this.offset,
    this.onTap,
    super.key,
  });

  final LotCard lot;

  /// When the auction closes, in UTC: the board's card counts down to it
  /// while the lot is open.
  final DateTime? closeAt;

  /// Server clock minus local clock, for the countdown.
  final ValueListenable<Duration>? offset;

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

  /// The board's card, styled like the example lot on the home page.
  bool get _regular => widget.size == LotCardSize.regular;

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
        12.0,
      ),
      LotCardSize.regular => (
        text.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Brand.ink,
        ),
        text.headlineMedium?.copyWith(
          fontSize: 34,
          letterSpacing: -0.5,
          color: Brand.ink,
        ),
        text.bodyMedium,
        16.0,
      ),
      // Readable from the back of the room.
      LotCardSize.large => (
        text.headlineMedium,
        text.displayLarge?.copyWith(fontSize: 72),
        text.headlineSmall,
        24.0,
      ),
    };
    final flash = _large ? Brand.gold : Brand.goldTint;
    final mine = widget.me != null && lot.leaderId == widget.me;
    // A lead of yours glows green, a lot you won gold.
    final accent = switch (lot.status) {
      'OPEN' when mine => Brand.lead,
      'SOLD' when mine => Brand.gold,
      _ => null,
    };
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
            // On the board and the big screen it sits on the picture instead.
            if (widget.size == LotCardSize.dense) ...[
              const SizedBox(width: 8),
              StatusBadge(lot.status),
            ],
            if (lot.unpaid) ...[const SizedBox(width: 4), const UnpaidTag()],
          ],
        ),
        SizedBox(height: _large || _regular ? 12 : 8),
        if (_large && lot.status != 'OPEN')
          _Hammered(lot: lot, sharedNames: widget.sharedNames, style: title)
        else ...[
          Eyebrow(switch (lot) {
            LotCard(status: 'OPEN', leaderId: null) => 'Opening bid',
            LotCard(status: 'OPEN') => 'Current bid',
            LotCard(status: 'SOLD') => 'Sold for',
            _ => 'Opened at',
          }, size: _large ? 18 : null),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _price(lot, price),
              if (lot.buyNowPrice case final bn?
                  when lot.status == 'OPEN' && lot.currentPrice < bn)
                BuyNowTag(bn, large: _large),
            ],
          ),
          const SizedBox(height: 6),
          _leader(lot, detail),
        ],
      ],
    );
    final themeShape = theme.cardTheme.shape as RoundedRectangleBorder?;
    final cardShape = _regular
        ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
        : themeShape;
    final card = Card(
      clipBehavior: Clip.antiAlias,
      color: _regular ? Colors.white : null,
      shape: accent == null
          ? cardShape
          : cardShape?.copyWith(side: BorderSide(color: accent, width: 2)),
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              // A wider visual leaves the price room on a projector.
              aspectRatio: widget.size == LotCardSize.dense ? 4 / 3 : 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LotVisual(
                    imageUrl: lot.imageUrl,
                    emoji: lot.tileEmoji,
                    color: lot.tileColor,
                  ),
                  if (_regular || (_large && lot.bidCount > 0))
                    Positioned(
                      right: padding * 0.75,
                      top: padding * 0.75,
                      child: _Overlay(
                        large: _large,
                        child: Text(
                          lot.bidCount == 1 ? '1 bid' : '${lot.bidCount} bids',
                        ),
                      ),
                    ),
                  if (widget.size != LotCardSize.dense)
                    Positioned(
                      left: padding * 0.75,
                      top: padding * 0.75,
                      child: StatusBadge(
                        lot.status,
                        large: _large,
                        solid: true,
                      ),
                    ),
                  if ((widget.closeAt, widget.offset) case (
                    final closeAt?,
                    final offset?,
                  ) when _regular && lot.status == 'OPEN')
                    Positioned(
                      right: padding * 0.75,
                      bottom: padding * 0.75,
                      child: _Overlay(
                        large: false,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('⏱ '),
                            CountdownText(closeAt: closeAt, offset: offset),
                          ],
                        ),
                      ),
                    ),
                  if (accent != null)
                    Positioned(
                      left: padding * 0.75,
                      // Under the status badge, where there is one.
                      top: widget.size == LotCardSize.dense
                          ? padding * 0.75
                          : null,
                      bottom: widget.size == LotCardSize.dense
                          ? null
                          : padding * 0.75,
                      child: _Overlay(
                        large: _large,
                        color: accent,
                        foreground: lot.status == 'SOLD'
                            ? Brand.ink
                            : Colors.white,
                        child: Text(
                          lot.status == 'SOLD' ? '🏆 YOU WON' : '★ YOU LEAD',
                        ),
                      ),
                    ),
                ],
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
                padding: _regular
                    ? const EdgeInsets.fromLTRB(20, 16, 20, 20)
                    : EdgeInsets.all(padding),
                child: _large ? _flip(details) : details,
              ),
            ),
          ],
        ),
      ),
    );
    if (!_regular) return card;
    // Lifted off the page, like the example lot.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Brand.gold.withValues(alpha: 0.12),
            blurRadius: 40,
            spreadRadius: -10,
          ),
        ],
      ),
      child: card,
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
  Widget _price(LotCard lot, TextStyle? style) => FittedBox(
    // Shrinks rather than breaking a big price across two lines.
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: _priceSwitcher(lot, style),
  );

  Widget _priceSwitcher(LotCard lot, TextStyle? style) => AnimatedSwitcher(
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
        fontWeight: FontWeight.w800,
        fontFeatures: Brand.tabular,
        height: 1.15,
      ),
    ),
  );
}

/// A small pill over a lot's picture: its bid count, or YOU LEAD.
class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.child,
    required this.large,
    this.color,
    this.foreground = Colors.white,
  });

  final Widget child;
  final bool large;
  final Color? color;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: large ? 16 : 10,
      vertical: large ? 8 : 5,
    ),
    decoration: BoxDecoration(
      color: color ?? Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(999),
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(
        color: foreground,
        fontSize: large ? 22 : 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        fontFeatures: Brand.tabular,
      ),
      child: child,
    ),
  );
}

/// The lot's Buy Now price, as `BN Rp 1.500.000`.
class BuyNowTag extends StatelessWidget {
  const BuyNowTag(this.price, {this.large = false, super.key});

  final int price;

  /// Sized for the back of the room.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 8,
        vertical: large ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'BN ${formatRupiah(price)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSecondaryContainer,
          fontWeight: FontWeight.w800,
          fontSize: large ? 22 : null,
        ),
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
    final colors = Theme.of(context).colorScheme;
    final muted = style?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    if (name == null) {
      return Text(
        open ? 'No bids yet — be the first' : 'No bids — passed',
        style: muted,
      );
    }
    final avatar = BidderAvatar(
      name,
      size: (style?.fontSize ?? 14) * 1.5,
      highlight: isMe ? Brand.lead : null,
    );
    final label = !isMe
        ? Text(
            open ? '$name leads' : '$name won',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: muted,
          )
        : Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'You',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Brand.lead,
                  ),
                ),
                TextSpan(text: open ? ' lead' : ' won'),
              ],
            ),
            style: muted,
          );
    return Row(
      children: [
        avatar,
        const SizedBox(width: 8),
        Flexible(child: label),
      ],
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
            style: bold?.copyWith(color: Brand.goldBright),
          ),
        ),
      ],
    );
  }
}

/// An open lot as a red LIVE pill, SOLD in gold, PASSED in grey.
class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.status, {
    this.large = false,
    this.solid = false,
    super.key,
  });

  final String status;

  /// Sized for the back of the room.
  final bool large;

  /// Filled in, to stand out on a lot's picture.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      // Solid where it sits on the picture.
      'OPEN' when solid => (Brand.live, Colors.white),
      'OPEN' => (Brand.live.withValues(alpha: 0.1), Brand.live),
      'SOLD' => (Brand.gold, Brand.ink),
      _ => (Colors.grey.shade200, Colors.grey.shade700),
    };
    final scale = large ? 2.0 : 1.0;
    return Container(
      padding: solid && !large
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
          : EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'OPEN') ...[
            Container(
              width: 6 * scale,
              height: 6 * scale,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 5 * scale),
          ],
          Text(
            status == 'OPEN' ? 'LIVE' : status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              fontSize: solid && !large ? 12 : 11 * scale,
            ),
          ),
        ],
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
    this.closeAt,
    this.offset,
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

  /// When the auction closes, in UTC, for the board's countdowns.
  final DateTime? closeAt;

  /// Server clock minus local clock, for the countdowns.
  final ValueListenable<Duration>? offset;

  final void Function(LotCard lot)? onTap;

  Widget _card(LotCard lot) => LotCardWidget(
    lot,
    // Keeps each card's flash state with its lot as the list changes.
    key: ValueKey(lot.lotId),
    me: me,
    sharedNames: sharedNames,
    size: size,
    closeAt: closeAt,
    offset: offset,
    onTap: onTap == null ? null : () => onTap!(lot),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final large = size == LotCardSize.large;
      // The projector's wider margins, only once there's room for them.
      final roomy = large && constraints.maxWidth >= 900;
      final side = roomy ? 32.0 : 16.0;
      final spacing = roomy ? 24.0 : 16.0;
      final List<Widget> body;
      if (lots.isEmpty) {
        body = [_Empty(empty)];
      } else if (columns == null && constraints.maxWidth < 600) {
        body = [
          for (final (i, lot) in lots.indexed) ...[
            if (i > 0) SizedBox(height: spacing),
            _card(lot),
          ],
        ];
      } else {
        // A grid of cards at most 360 px wide. Rows rather than a GridView,
        // so a card is as tall as its content needs at any width.
        final width = constraints.maxWidth - 2 * side;
        final columns =
            this.columns ?? ((width + spacing) / (360 + spacing)).ceil();
        final rows = (lots.length / columns).ceil();
        body = [
          for (var row = 0; row < rows; row++) ...[
            if (row > 0) SizedBox(height: spacing),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) SizedBox(width: spacing),
                    Expanded(
                      child: row * columns + col < lots.length
                          ? _card(lots[row * columns + col])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ];
      }
      return ListView(
        padding: EdgeInsets.fromLTRB(side, large ? 8 : 20, side, 96),
        children: body,
      );
    },
  );
}

/// What shows where the lots will be.
class _Empty extends StatelessWidget {
  const _Empty(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.gavel_rounded,
              size: 30,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
