import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/auction_controller.dart';
import '../core/failures.dart';
import '../core/live.dart';
import '../widgets/lot_card_widget.dart';

/// An auction's live board (UC-04), or its big-screen mode (UC-11).
///
/// For now it lists the lots as they arrive, live.
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
  late final _auction = AuctionController(client, widget.code)..start();

  @override
  void dispose() {
    _auction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _auction,
    builder: (context, _) {
      final theme = Theme.of(context);
      final auction = _auction.auction;
      return Scaffold(
        appBar: AppBar(
          title: Text(auction?.title ?? 'Auction ${widget.code}'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LiveDot(_auction.live.status),
            ),
          ],
        ),
        body: switch ((_auction.failure, auction)) {
          (AuctionNotFound(), _) => Center(
            child: Text(
              'No auction with code ${widget.code}',
              style: theme.textTheme.titleLarge,
            ),
          ),
          (final GavelFailure failure, _) => Center(child: Text('$failure')),
          (_, null) => const Center(child: CircularProgressIndicator()),
          (_, _) => LotGrid(
            lots: _auction.lots,
            empty: 'No lots yet — the organizer is setting up.',
          ),
        },
      );
    },
  );
}
