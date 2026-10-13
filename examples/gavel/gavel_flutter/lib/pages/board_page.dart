import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';

import '../core/api.dart';
import '../core/failures.dart';
import '../core/live.dart';

/// An auction's live board (UC-04), or its big-screen mode (UC-11).
///
/// For now it shows the auction and flashes on every live update, which is
/// the UC-12 gate: two windows on one code flash together.
class BoardPage extends StatefulWidget {
  const BoardPage({required this.code, this.bigScreen = false, super.key});

  /// The auction's join code.
  final String code;

  /// Whether to show the read-only projector layout.
  final bool bigScreen;

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  late final LiveConnection _live = LiveConnection(client, widget.code);
  late final StreamSubscription<LiveEvent> _events;

  AuctionView? _auction;
  GavelFailure? _failure;
  LiveUpdateKind? _lastKind;
  var _flash = false;
  Timer? _flashOff;

  @override
  void initState() {
    super.initState();
    _events = _live.events().listen(
      _onEvent,
      onError: (Object e) => setState(() => _failure = GavelFailure.from(e)),
    );
  }

  @override
  void dispose() {
    _flashOff?.cancel();
    unawaited(_events.cancel());
    unawaited(_live.close());
    super.dispose();
  }

  void _onEvent(LiveEvent event) {
    setState(() {
      switch (event) {
        case SnapshotArrived(:final snapshot):
          _auction = snapshot.auction;
        case UpdateArrived(:final update):
          _auction = update.auction ?? _auction;
          _lastKind = update.kind;
          _flash = true;
      }
    });
    _flashOff?.cancel();
    _flashOff = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _flash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auction = _auction;
    return Scaffold(
      appBar: AppBar(
        title: Text(auction?.title ?? 'Auction ${widget.code}'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LiveDot(_live.status),
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: _flash
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        alignment: Alignment.center,
        child: switch ((_failure, auction)) {
          (AuctionNotFound(), _) => Text(
            'No auction with code ${widget.code}',
            style: theme.textTheme.titleLarge,
          ),
          (final GavelFailure failure, _) => Text('$failure'),
          (_, null) => const CircularProgressIndicator(),
          (_, final AuctionView auction) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(auction.code, style: theme.textTheme.displayMedium),
              Text('${auction.status} · ${auction.lotCount} lots'),
              if (_lastKind != null) Text('Last update: ${_lastKind!.name}'),
            ],
          ),
        },
      ),
    );
  }
}
