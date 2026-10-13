import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// [remaining] as `2 h 14 m`, `14 m 05 s` or `42 s`.
String formatRemaining(Duration remaining) {
  final h = remaining.inHours;
  final m = remaining.inMinutes % 60;
  final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
  if (h > 0) return '$h h $m m';
  if (m > 0) return '$m m $s s';
  return '${remaining.inSeconds} s';
}

final _closedAt = DateFormat('HH:mm');

/// The time left until [closeAt] on the server's clock: the local clock
/// plus [offset], so a phone that is off by 30 seconds still agrees with
/// everyone else. Red under a minute, then "Closing…" until the server
/// says the auction is [closed] (UC-08), then "Closed 22:03" (UC-09).
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
        true when widget.closed =>
          'Closed ${_closedAt.format(widget.closeAt.toLocal())}',
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

/// Builds with whether [closeAt] has passed on the server's clock, and
/// again when it does, so a button that can't succeed after the close goes
/// away on time rather than waiting for the server's push (X5).
class DeadlineBuilder extends StatefulWidget {
  const DeadlineBuilder({
    required this.closeAt,
    required this.offset,
    required this.builder,
    super.key,
  });

  /// When the auction closes, in UTC.
  final DateTime closeAt;

  /// Server clock minus local clock.
  final ValueListenable<Duration> offset;

  final Widget Function(BuildContext context, bool timeUp) builder;

  @override
  State<DeadlineBuilder> createState() => _DeadlineBuilderState();
}

class _DeadlineBuilderState extends State<DeadlineBuilder> {
  var _timeUp = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.offset.addListener(_schedule);
    _schedule();
  }

  @override
  void didUpdateWidget(DeadlineBuilder old) {
    super.didUpdateWidget(old);
    if (old.offset != widget.offset) {
      old.offset.removeListener(_schedule);
      widget.offset.addListener(_schedule);
    }
    if (old.closeAt != widget.closeAt) _schedule();
  }

  @override
  void dispose() {
    widget.offset.removeListener(_schedule);
    _timer?.cancel();
    super.dispose();
  }

  /// Checks [DeadlineBuilder.closeAt] against the server's clock now, and
  /// again when it arrives.
  void _schedule() {
    _timer?.cancel();
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
    if (left > Duration.zero) _timer = Timer(left, () => timeUp(true));
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _timeUp);
}
