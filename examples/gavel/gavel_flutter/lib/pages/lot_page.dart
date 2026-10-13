import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';
import '../core/auction_controller.dart';
import '../core/auction_scope.dart';
import '../core/bidding.dart';
import '../core/clock.dart';
import '../core/identity.dart';
import '../core/ledger.dart';
import '../core/live.dart';
import '../core/money.dart';
import '../core/organizer_keys.dart';
import '../core/retracting.dart';
import '../widgets/bid_bar.dart';
import '../widgets/join_sheet.dart';
import '../widgets/ledger_list.dart';
import '../widgets/lot_visual.dart';
import '../widgets/retract_button.dart';

/// One lot (UC-05): its visual, price and status, and the full ledger, with
/// the kelipatan chips in a bottom bar the thumb reaches (UC-06), and
/// RETRACT there for whoever holds the latest valid bid (UC-07).
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
  final _sendRetract = sendRetractWith(client);

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

  /// Copies the lot's URL, the receipt a winner pastes back (UC-09).
  Future<void> _share() async {
    final url = Uri.base.resolve('/a/${widget.code}/lot/${widget.lotId}');
    await Clipboard.setData(ClipboardData(text: url.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context) {
    final auction = AuctionScope.of(context);
    final lotId = _lotId;
    final lot = lotId == null ? null : auction.lot(lotId);
    final loading = auction.auction == null && auction.failure == null;
    final closeAt = auction.auction?.closeAt;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/a/${widget.code}')),
        title: Text(lot?.name ?? 'Lot', overflow: TextOverflow.ellipsis),
        actions: [
          if (closeAt != null)
            Center(
              child: CountdownText(
                closeAt: closeAt,
                offset: auction.clockOffset,
              ),
            ),
          IconButton(
            tooltip: 'Copy link',
            icon: const Icon(Icons.share),
            onPressed: _share,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: LiveDot(auction.status),
          ),
        ],
      ),
      body: lot != null && closeAt != null
          ? LotDetailBody(
              lot: lot,
              ledger: auction.ledgerFor(lot.lotId),
              closeAt: closeAt,
              me: _identity?.participantId,
            )
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
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_retractable(auction, lot, identity) case final bid?)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: RetractButton(
                          lot: lot,
                          bid: bid,
                          identity: identity,
                          send: _sendRetract,
                          onRetracted: auction.merge,
                          onStale: _refresh,
                          onNotParticipant: _rejoin,
                        ),
                      ),
                    BidBar(
                      lot: lot,
                      identity: identity,
                      closeAt: closeAt,
                      offset: auction.clockOffset,
                      bidder: _bidder,
                      onAccepted: auction.merge,
                      onStale: _refresh,
                      onNotParticipant: _rejoin,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// [identity]'s bid on [lot] if they may take it back now, else null.
  LedgerEntry? _retractable(
    AuctionController auction,
    LotCard lot,
    Identity identity,
  ) {
    final ledger = auction.ledgerFor(lot.lotId);
    if (ledger == null || !ledger.canRetract(lot, identity.participantId)) {
      return null;
    }
    return ledger.lastValid;
  }
}

/// The lot's visual, name, description, price block and ledger.
class LotDetailBody extends StatelessWidget {
  const LotDetailBody({
    required this.lot,
    required this.ledger,
    required this.closeAt,
    this.me,
    super.key,
  });

  final LotCard lot;

  /// Every bid, in ledger order, or null while it loads.
  final List<LedgerEntry>? ledger;

  /// When the auction closes, in UTC.
  final DateTime closeAt;

  /// Who this browser bids as, if it joined.
  final UuidValue? me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final steps = lot.increments;
    final ledger = this.ledger;
    final leading = me != null && lot.leaderId == me;
    final outbid = !leading && (ledger?.hasValidBidBy(me) ?? false);
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
      LotCard(:final leaderName?) when outbid => (
        'Outbid — $leaderName leads at ${formatRupiah(lot.currentPrice)}',
        Colors.amber.shade900,
      ),
      LotCard(:final leaderName?) => ('$leaderName leads', scheme.onSurface),
      _ => ('No bids yet', scheme.onSurfaceVariant),
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  if (lot.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _Description(lot.description),
                  ],
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatRupiah(lot.currentPrice),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (lot.status == 'OPEN' && steps.isNotEmpty)
                    Text(
                      'Next bid from '
                      '${formatRupiah(lot.currentPrice + steps.first)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: theme.textTheme.titleMedium?.copyWith(color: color),
                  ),
                  const SizedBox(height: 24),
                  Text('Bids', style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (ledger == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              LedgerList(lot: lot, entries: ledger, closeAt: closeAt, me: me),
          ],
        ),
      ),
    );
  }
}

/// The seller's description, newlines kept, cut to 4 lines with "more".
class _Description extends StatefulWidget {
  const _Description(this.text);

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  static const _lines = 4;
  var _expanded = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final style = DefaultTextStyle.of(context).style;
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: _lines,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final long = painter.didExceedMaxLines;
      painter.dispose();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            widget.text,
            maxLines: _expanded || !long ? null : _lines,
          ),
          if (long)
            TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(_expanded ? 'less' : 'more'),
            ),
        ],
      );
    },
  );
}
