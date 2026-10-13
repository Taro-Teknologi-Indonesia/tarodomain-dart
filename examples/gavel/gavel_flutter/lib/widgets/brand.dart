import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme.dart';

/// The gavel in a gold tile beside the wordmark.
class GavelLogo extends StatelessWidget {
  const GavelLogo({this.size = 32, this.onDark = true, super.key});

  /// The tile's side; the wordmark scales with it.
  final double size;

  /// Whether it sits on [Brand.ink], so the wordmark goes white.
  final bool onDark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Brand.goldBright, Brand.gold, Color(0xFFB9821F)],
          ),
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [
            BoxShadow(
              color: Brand.gold.withValues(alpha: 0.35),
              blurRadius: size * 0.5,
              offset: Offset(0, size * 0.12),
            ),
          ],
        ),
        child: Icon(Icons.gavel_rounded, size: size * 0.6, color: Brand.ink),
      ),
      SizedBox(width: size * 0.32),
      Text(
        'Gavel',
        style: Brand.display.copyWith(
          fontSize: size * 0.8,
          color: onDark ? Colors.white : Brand.ink,
          letterSpacing: 0,
        ),
      ),
    ],
  );
}

/// A small capitalised label, as over a price or a countdown.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {this.color, this.size, super.key});

  final String text;
  final Color? color;

  /// The font size, 11 unless given.
  final double? size;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: Brand.eyebrow.copyWith(
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      fontSize: size,
    ),
  );
}

/// A round initial for a bidder, colored from their name so the same
/// bidder keeps the same color.
class BidderAvatar extends StatelessWidget {
  const BidderAvatar(this.name, {this.size = 24, this.highlight, super.key});

  final String name;
  final double size;

  /// Overrides the name's color, as for "you".
  final Color? highlight;

  static const _palette = [
    Color(0xFF1E5AA8),
    Color(0xFF2E7D6B),
    Color(0xFF8D5524),
    Color(0xFFB23A48),
    Color(0xFF6B4FA0),
    Color(0xFF0E7490),
    Color(0xFFA16207),
  ];

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.characters.first.toUpperCase();
    final color =
        highlight ??
        _palette[trimmed.codeUnits.fold(0, (a, b) => a + b) % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.48,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

/// [remaining] as a clock: `1:02:45`, `04:12`.
String formatClockRemaining(Duration remaining) {
  final h = remaining.inHours;
  final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
  final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// The countdown to the close as a clock under CLOSES IN, for dark bands:
/// gold, red in the last minute, then CLOSING… and CLOSED 22:03. Runs on
/// the server's clock, the local one plus [offset].
class CountdownPanel extends StatefulWidget {
  const CountdownPanel({
    required this.closeAt,
    required this.offset,
    this.closed = false,
    this.size = 40,
    this.labelSize,
    this.align = CrossAxisAlignment.end,
    super.key,
  });

  /// When the auction closes, in UTC.
  final DateTime closeAt;

  /// Server clock minus local clock.
  final ValueListenable<Duration> offset;

  /// Whether the auction is CLOSED: every lot's outcome is in.
  final bool closed;

  /// The digits' font size.
  final double size;

  /// CLOSES IN's font size, 11 unless given.
  final double? labelSize;

  final CrossAxisAlignment align;

  @override
  State<CountdownPanel> createState() => _CountdownPanelState();
}

class _CountdownPanelState extends State<CountdownPanel> {
  static final _hm = DateFormat('HH:mm');
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc().add(widget.offset.value);
    final remaining = widget.closeAt.difference(now);
    final timeUp = widget.closed || remaining <= Duration.zero;
    final urgent = !timeUp && remaining < const Duration(minutes: 1);
    final (label, value, color) = switch (timeUp) {
      false => (
        'Closes in',
        formatClockRemaining(remaining),
        urgent ? const Color(0xFFFF5A5F) : Brand.goldBright,
      ),
      true when widget.closed => (
        'Closed',
        _hm.format(widget.closeAt.toLocal()),
        Colors.white,
      ),
      true => ('Hammer falling', 'CLOSING…', const Color(0xFFFF5A5F)),
    };
    return Column(
      crossAxisAlignment: widget.align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Eyebrow(label, color: Brand.mutedOnInk, size: widget.labelSize),
        const SizedBox(height: 2),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontFamily: Brand.sans,
            fontSize: widget.size,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.5,
            color: color,
            fontFeatures: Brand.tabular,
          ),
          child: Text(value, maxLines: 1),
        ),
      ],
    );
  }
}
