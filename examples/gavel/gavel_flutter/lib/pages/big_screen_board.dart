import 'dart:async';

import 'package:flutter/material.dart';

import '../core/auction_controller.dart';
import '../core/auction_scope.dart';
import '../core/browser.dart';
import '../core/failures.dart';
import '../core/live.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/lot_card_widget.dart';

/// An auction's board for a projector (UC-11): dark, huge, and read-only.
///
/// Nobody joins from here, and nothing on it issues a command. It shares
/// the board's live subscription, so bids and closes arrive the same way.
class BigScreenBoard extends StatefulWidget {
  const BigScreenBoard({required this.code, super.key});

  /// The auction's join code.
  final String code;

  /// How long the mouse rests before the cursor and controls hide.
  static const idle = Duration(seconds: 3);

  @override
  State<BigScreenBoard> createState() => _BigScreenBoardState();
}

class _BigScreenBoardState extends State<BigScreenBoard> {
  /// Whether the mouse has rested for [BigScreenBoard.idle].
  bool _idle = false;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _wake();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  /// Shows the cursor and controls until the mouse rests again.
  void _wake() {
    _idleTimer?.cancel();
    _idleTimer = Timer(BigScreenBoard.idle, () {
      if (mounted) setState(() => _idle = true);
    });
    if (_idle) setState(() => _idle = false);
  }

  /// Black and gold whatever the system theme, for a dark room.
  static final _theme = gavelBigScreenTheme();

  @override
  Widget build(BuildContext context) {
    final auction = AuctionScope.of(context);
    return Theme(
      data: _theme,
      child: MouseRegion(
        cursor: _idle ? SystemMouseCursors.none : MouseCursor.defer,
        onHover: (_) => _wake(),
        child: Scaffold(
          body: SafeArea(
            child: switch ((auction.failure, auction.auction)) {
              (AuctionNotFound(), _) => _Message(
                'No auction has the code ${widget.code}',
              ),
              (final GavelFailure failure, _) => _Message('$failure'),
              (_, null) => const Center(child: CircularProgressIndicator()),
              (_, final view?) => Column(
                children: [
                  _Header(
                    code: widget.code,
                    title: view.title,
                    closeAt: view.closeAt,
                    closed: view.status == 'CLOSED',
                    auction: auction,
                    showControls: !_idle,
                  ),
                  Expanded(child: _Lots(auction)),
                ],
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// The title and join link beside a countdown big enough to dominate the
/// last minute.
class _Header extends StatelessWidget {
  const _Header({
    required this.code,
    required this.title,
    required this.closeAt,
    required this.closed,
    required this.auction,
    required this.showControls,
  });

  final String code;
  final String title;
  final DateTime closeAt;
  final bool closed;
  final AuctionController auction;

  /// Whether the mouse moved lately, so the full-screen button shows.
  final bool showControls;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: Brand.band,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GavelLogo(size: 40),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.display.copyWith(
                      fontSize: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Typed by the room, so no scheme to get wrong.
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Bid at ',
                          style: TextStyle(color: Brand.mutedOnInk),
                        ),
                        TextSpan(text: '${Uri.base.authority}/a/$code'),
                      ],
                    ),
                    style: text.headlineMedium?.copyWith(
                      color: Brand.goldBright,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountdownPanel(
                  closeAt: closeAt,
                  offset: auction.clockOffset,
                  closed: closed,
                  size: 112,
                  labelSize: 22,
                ),
                const SizedBox(width: 24),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LiveDot(auction.status),
                    AnimatedOpacity(
                      opacity: showControls ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: IconButton(
                        tooltip: 'Full screen',
                        onPressed: showControls ? requestFullscreen : null,
                        icon: const Icon(Icons.fullscreen),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Up to three large cards across, none of them tappable.
class _Lots extends StatelessWidget {
  const _Lots(this.auction);

  final AuctionController auction;

  @override
  Widget build(BuildContext context) {
    final lots = auction.lots;
    final columns = lots.length <= 3 ? lots.length : 3;
    return Center(
      child: ConstrainedBox(
        // A lone lot doesn't stretch its picture past the screen.
        constraints: BoxConstraints(
          maxWidth: columns == 0 ? double.infinity : columns * 720.0,
        ),
        child: LotGrid(
          lots: lots,
          sharedNames: auction.sharedNames,
          size: LotCardSize.large,
          columns: columns == 0 ? null : columns,
          empty: 'No lots yet — the organizer is setting up.',
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.headlineMedium,
    ),
  );
}
