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

/// A small dot: green while live, amber while connecting or reconnecting.
class LiveDot extends StatelessWidget {
  const LiveDot(this.status, {super.key});

  final ValueListenable<LiveStatus> status;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: status,
    builder: (context, value, _) {
      final live = value == LiveStatus.live;
      return Tooltip(
        message: live ? 'Live' : 'Reconnecting…',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: live ? Colors.green : Colors.amber,
          ),
        ),
      );
    },
  );
}
