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
/// everyone else. Red under a minute, "Closed" after.
class CountdownText extends StatefulWidget {
  const CountdownText({
    required this.closeAt,
    required this.offset,
    this.style,
    super.key,
  });

  /// When the auction closes, in UTC.
  final DateTime closeAt;

  /// Server clock minus local clock.
  final ValueListenable<Duration> offset;

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
    final closed = remaining <= Duration.zero;
    final style = widget.style ?? DefaultTextStyle.of(context).style;
    return Text(
      closed ? 'Closed' : formatRemaining(remaining),
      style: style.copyWith(
        color: !closed && remaining < const Duration(minutes: 1)
            ? Theme.of(context).colorScheme.error
            : null,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
