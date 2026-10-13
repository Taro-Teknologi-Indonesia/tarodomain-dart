import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// [remaining] as `2 h 14 m`, `14 m 05 s` or `42 s`.
String formatRemaining(Duration remaining) {
  final h = remaining.inHours;
  final m = remaining.inMinutes % 60;
  final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
  if (h > 0) return '$h h $m m';
  if (m > 0) return '$m m $s s';
  return '${remaining.inSeconds} s';
}

/// The time left until [closeAt] on the server's clock: the local clock
/// plus [offset], so a phone that is off by 30 seconds still agrees with
/// everyone else. Red under a minute, then "Closing…" until the server
/// says the auction is [closed] (UC-08).
class CountdownText extends StatefulWidget {
  const CountdownText({
    required this.closeAt,
    required this.offset,
    this.closed = false,
    this.style,
    super.key,
  });

  /// When the auction closes, in UTC.
  final DateTime closeAt;

  /// Server clock minus local clock.
  final ValueListenable<Duration> offset;

  /// Whether the auction is CLOSED: every lot's outcome is in.
  final bool closed;

  final TextStyle? style;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
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
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    return Text(
      switch (timeUp) {
        false => formatRemaining(remaining),
        true when widget.closed => 'Closed',
        true => 'Closing…',
      },
      style: style.copyWith(
        color: !timeUp && remaining < const Duration(minutes: 1)
            ? Theme.of(context).colorScheme.error
            : null,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
