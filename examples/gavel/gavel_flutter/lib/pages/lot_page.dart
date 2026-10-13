import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';
import '../core/auction_controller.dart';
import '../core/auction_scope.dart';
import '../core/bidding.dart';
import '../core/identity.dart';
import '../core/live.dart';
import '../core/money.dart';
import '../core/organizer_keys.dart';
import '../widgets/bid_bar.dart';
import '../widgets/join_sheet.dart';
import '../widgets/lot_visual.dart';

/// One lot: its visual, price and status, with the kelipatan chips in a
/// bottom bar the thumb reaches (UC-06). The ledger comes with UC-05.
class LotPage extends StatefulWidget {
  const LotPage({required this.code, required this.lotId, super.key});

  /// The auction's join code.
  final String code;

  /// The lot, as it appears in the URL.
  final String lotId;

  @override
  State<LotPage> createState() => _LotPageState();
}

class _LotPageState extends State<LotPage> {
  late final AuctionController _auction = AuctionScope.read(context);
  late final UuidValue? _lotId = _parse(widget.lotId);
  final _bidder = Bidder(sendBidWith(client));

  /// Who this browser bids as here, once read from localStorage.
  Identity? _identity;
  bool _identityLoaded = false;

  /// Organizers don't bid, so they get no chips.
  bool _isOrganizer = false;

  static UuidValue? _parse(String id) {
    try {
      return UuidValue.withValidation(id);
    } on FormatException {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadIdentity());
  }

  Future<void> _loadIdentity() async {
    final identity = await Identities.load(widget.code);
    final organizerKey = await OrganizerKeys.load(widget.code);
    if (!mounted) return;
    setState(() {
      _identity = identity;
      _isOrganizer = organizerKey != null;
      _identityLoaded = true;
    });
  }

  Future<void> _join({String? message}) async {
    final identity = await JoinSheet.show(
      context,
      widget.code,
      message: message,
    );
    if (identity != null && mounted) setState(() => _identity = identity);
  }

  Future<void> _rejoin() async {
    await Identities.forget(widget.code);
    if (!mounted) return;
    setState(() => _identity = null);
    await _join(message: 'Please join again');
  }

  Future<void> _refresh() async {
    try {
      await _auction.refresh();
    } catch (_) {
      // The live feed brings the lot anyway once it reconnects.
    }
  }

  @override
  Widget build(BuildContext context) {
    final auction = AuctionScope.of(context);
    final lotId = _lotId;
    final lot = lotId == null ? null : auction.lot(lotId);
    final loading = auction.auction == null && auction.failure == null;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/a/${widget.code}')),
        title: Text(lot?.name ?? 'Lot', overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LiveDot(auction.status),
          ),
        ],
      ),
      body: lot != null
          ? _LotBody(lot: lot, me: _identity?.participantId)
          : Center(
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('This lot is not in the auction'),
            ),
      bottomNavigationBar: lot == null ? null : _actions(auction, lot),
    );
  }

  Widget? _actions(AuctionController auction, LotCard lot) {
    final closeAt = auction.auction?.closeAt;
    if (!_identityLoaded || _isOrganizer || closeAt == null) return null;
    final identity = _identity;
    return SafeArea(
      child: Material(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: identity == null
              ? lot.status == 'OPEN'
                    ? FilledButton(
                        onPressed: _join,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Join to bid'),
                      )
                    : null
              : BidBar(
                  lot: lot,
                  identity: identity,
                  closeAt: closeAt,
                  offset: auction.clockOffset,
                  bidder: _bidder,
                  onAccepted: auction.merge,
                  onStale: _refresh,
                  onNotParticipant: _rejoin,
                ),
        ),
      ),
    );
  }
}

/// The lot's visual, name, price block and description.
class _LotBody extends StatelessWidget {
  const _LotBody({required this.lot, required this.me});

  final LotCard lot;
  final UuidValue? me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final steps = lot.increments;
    final leading = me != null && lot.leaderId == me;
    final (status, color) = switch (lot) {
      LotCard(status: 'SOLD', :final winnerName, :final finalPrice) => (
        'SOLD to $winnerName — ${formatRupiah(finalPrice ?? lot.currentPrice)}',
        null,
      ),
      LotCard(status: 'PASSED') => ('PASSED — no bids', null),
      _ when leading => (
        "You're the high bidder — ${formatRupiah(lot.currentPrice)}",
        Colors.green.shade700,
      ),
      LotCard(:final leaderName?) => ('$leaderName leads', scheme.onSurface),
      _ => ('No bids yet', scheme.onSurfaceVariant),
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LotVisual(
                    imageUrl: lot.imageUrl,
                    emoji: lot.tileEmoji,
                    color: lot.tileColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(lot.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              formatRupiah(lot.currentPrice),
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (lot.status == 'OPEN' && steps.isNotEmpty)
              Text(
                'Next bid from ${formatRupiah(lot.currentPrice + steps.first)}',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 4),
            Text(
              status,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
            if (lot.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              SelectableText(lot.description),
            ],
          ],
        ),
      ),
    );
  }
}
