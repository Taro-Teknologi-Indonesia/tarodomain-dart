import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:tarodomain_serverpod_client/tarodomain_serverpod_client.dart';

/// Whether an auction's live stream is connected.
enum LiveStatus { connecting, live, reconnecting }

/// What a [LiveConnection] delivers, in order.
sealed class LiveEvent {
  const LiveEvent();
}

/// The board as it is now. Comes first, and again after every reconnect,
/// because updates missed while disconnected are not replayed.
final class SnapshotArrived extends LiveEvent {
  const SnapshotArrived(this.snapshot);

  final BoardSnapshot snapshot;
}

/// One change pushed by the server.
///
/// Can be older than the last snapshot (subscribe/fetch race): merges must
/// ignore a lot whose version is not newer than the one held.
final class UpdateArrived extends LiveEvent {
  const UpdateArrived(this.update);

  final LiveUpdate update;
}

/// The live feed of the auction with join [code]: a board snapshot, then
/// every update, reconnecting with backoff when the stream drops.
///
/// It subscribes before fetching the snapshot and holds updates back until
/// the snapshot arrives, so nothing committed in between is lost. There is
/// no polling: the server pushes every change.
class LiveConnection {
  LiveConnection(this.client, this.code);

  final Client client;

  /// The auction's join code.
  final String code;

  /// Whether the stream is connected.
  final status = ValueNotifier(LiveStatus.connecting);

  /// Server clock minus local clock, from the last `serverNow` received.
  final clockOffset = ValueNotifier(Duration.zero);

  static const _maxBackoff = Duration(seconds: 10);

  final _events = StreamController<LiveEvent>();
  StreamSubscription<LiveUpdate>? _subscription;
  Timer? _retry;
  var _attempt = 0;
  var _started = false;
  var _closed = false;

  /// The events, from the first snapshot on. Listen once.
  Stream<LiveEvent> events() {
    if (!_started) {
      _started = true;
      _connect();
    }
    return _events.stream;
  }

  /// Stops the stream and any pending reconnect.
  Future<void> close() async {
    _closed = true;
    _retry?.cancel();
    await _subscription?.cancel();
    await _events.close();
    status.dispose();
    clockOffset.dispose();
  }

  Future<void> _connect() async {
    if (_closed) return;
    final buffered = <LiveUpdate>[];
    var hasSnapshot = false;

    await _subscription?.cancel();
    _subscription = client.live
        .watch(code)
        .listen(
          (update) {
            _syncClock(update.serverNow);
            if (hasSnapshot) {
              _emit(UpdateArrived(update));
            } else {
              buffered.add(update);
            }
          },
          onError: (Object _) => _reconnect(),
          onDone: _reconnect,
          cancelOnError: true,
        );

    final BoardSnapshot snapshot;
    try {
      snapshot = await client.auction.board(code);
    } on Object catch (e) {
      // An unknown auction won't appear by retrying; anything else might be
      // the connection.
      if (e is TaroDomainException && e.code == 'AUCTION_NOT_FOUND') {
        await _subscription?.cancel();
        if (!_closed) _events.addError(e);
        return;
      }
      _reconnect();
      return;
    }
    if (_closed) return;

    _syncClock(snapshot.serverNow);
    _emit(SnapshotArrived(snapshot));
    hasSnapshot = true;
    for (final update in buffered) {
      _emit(UpdateArrived(update));
    }
    _attempt = 0;
    status.value = LiveStatus.live;
  }

  /// Tries again after 1, 2, 4, 8, then 10 seconds.
  void _reconnect() {
    if (_closed || (_retry?.isActive ?? false)) return;
    status.value = LiveStatus.reconnecting;
    final delay = Duration(seconds: min(1 << _attempt, _maxBackoff.inSeconds));
    _attempt = min(_attempt + 1, 4);
    _retry = Timer(delay, _connect);
  }

  void _syncClock(DateTime serverNow) {
    if (_closed) return;
    clockOffset.value = serverNow.difference(DateTime.now().toUtc());
  }

  void _emit(LiveEvent event) {
    if (!_closed) _events.add(event);
  }
}

/// A broadcast-style pill for dark backgrounds: a pulsing red dot and LIVE
/// while connected, amber while connecting or reconnecting.
class LiveDot extends StatefulWidget {
  const LiveDot(this.status, {this.compact = false, super.key});

  final ValueListenable<LiveStatus> status;

  /// Only the dot, where a phone's app bar has no room for the word.
  final bool compact;

  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    widget.status.addListener(_sync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(LiveDot old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status) {
      old.status.removeListener(_sync);
      widget.status.addListener(_sync);
      _sync();
    }
  }

  @override
  void dispose() {
    widget.status.removeListener(_sync);
    _pulse.dispose();
    super.dispose();
  }

  /// Pulses only while live, and never when the system asks for less motion.
  void _sync() {
    final live = widget.status.value == LiveStatus.live;
    if (live && !MediaQuery.disableAnimationsOf(context)) {
      if (!_pulse.isAnimating) unawaited(_pulse.repeat());
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: widget.status,
    builder: (context, value, _) {
      final live = value == LiveStatus.live;
      final color = live ? const Color(0xFFFF4D4F) : Colors.amber;
      return Tooltip(
        message: live
            ? 'Live — bids appear the moment they land'
            : 'Reconnecting…',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: widget.compact
              ? const EdgeInsets.all(6)
              : const EdgeInsets.fromLTRB(8, 4, 10, 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 14,
                child: AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) =>
                      CustomPaint(painter: _PulsePainter(color, _pulse.value)),
                ),
              ),
              if (!widget.compact) ...[
                const SizedBox(width: 6),
                Text(
                  switch (value) {
                    LiveStatus.live => 'LIVE',
                    LiveStatus.connecting => 'CONNECTING',
                    LiveStatus.reconnecting => 'RECONNECTING',
                  },
                  style: TextStyle(
                    color: live ? Colors.white : Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// A dot with a ring spreading out from it as [t] goes from 0 to 1.
class _PulsePainter extends CustomPainter {
  _PulsePainter(this.color, this.t);

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    if (t > 0) {
      canvas.drawCircle(
        center,
        r * (0.4 + 0.6 * t),
        Paint()..color = color.withValues(alpha: 0.5 * (1 - t)),
      );
    }
    canvas.drawCircle(center, r * 0.4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t || old.color != color;
}
