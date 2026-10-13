import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';
import '../core/auction_controller.dart';
import '../core/auction_scope.dart';
import '../core/bidding.dart';
import '../core/clock.dart';
import '../core/failures.dart';
import '../core/identity.dart';
import '../core/ledger.dart';
import '../core/live.dart';
import '../core/money.dart';
import '../core/names.dart';
import '../core/organizer_keys.dart';
import '../core/retracting.dart';
import '../core/share.dart';
import '../widgets/as_of_sheet.dart';
import '../widgets/bid_bar.dart';
import '../widgets/join_sheet.dart';
import '../widgets/ledger_list.dart';
import '../widgets/lot_visual.dart';
import '../widgets/retract_button.dart';
import '../widgets/won_banner.dart';

/// One lot (UC-05): its visual, price and status, and the full ledger, with
/// the kelipatan chips in a bottom bar the thumb reaches (UC-06), and
/// RETRACT there for whoever holds the latest valid bid (UC-07). "As of…"
/// replays the lot at a past moment (UC-10).
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
  String? _organizerKey;

  /// The organizer's winner codes by lot ID, once the lot is SOLD (UC-09).
  Map<String, String>? _winnerCodes;

  /// The lot as of the moment the viewer picked, or null for live (UC-10).
  /// Live updates keep arriving underneath.
  LotAsOf? _asOf;

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
      _organizerKey = organizerKey;
      _identityLoaded = true;
    });
  }

  /// Fetches the organizer's winner codes the first time this lot shows
  /// SOLD in a browser holding the organizer key.
  void _maybeLoadWinnerCodes(LotCard lot) {
    final key = _organizerKey;
    if (key == null || lot.status != 'SOLD' || _winnerCodes != null) return;
    _winnerCodes = const {};
    unawaited(
      client.auction
          .winnerCodes(widget.code, key)
          .then((codes) {
            if (mounted) setState(() => _winnerCodes = codes);
          })
          .catchError((Object _) {
            // Asked again the next time the page builds.
            _winnerCodes = null;
          }),
    );
  }

  /// This browser's winner code for the lot, from the server.
  Future<String?> _loadWinnerCode() async {
    final identity = _identity;
    final lotId = _lotId;
    if (identity == null || lotId == null) return null;
    return client.lot.winnerCode(
      lotId,
      identity.participantId,
      identity.participantKey,
    );
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

  /// Picks a past moment and asks the server to replay the lot up to it.
  Future<void> _pickAsOf(AuctionController auction, LotCard lot) async {
    final ledger = auction.ledgerFor(lot.lotId);
    if (ledger == null || ledger.isEmpty) return;
    final closedAt = lot.status == 'OPEN'
        ? null
        : lot.closedAt ?? auction.auction?.closeAt;
    final now = DateTime.now().toUtc().add(auction.clockOffset.value);
    final at = await AsOfSheet.show(
      context,
      ledger: ledger,
      end: closedAt ?? now,
      closedAt: closedAt,
    );
    if (at == null || !mounted) return;
    try {
      final asOf = await client.lot.asOf(lot.lotId, at);
      if (mounted) setState(() => _asOf = asOf);
    } catch (e) {
      if (!mounted) return;
      final message = switch (GavelFailure.from(e)) {
        NotFound() => "Lot didn't exist yet",
        _ => "Couldn't replay that moment — try again",
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  /// Copies the lot's URL, the receipt a winner pastes back (UC-09).
  Future<void> _share() => copyLotLink(context, widget.code, widget.lotId);

  @override
  Widget build(BuildContext context) {
    final auction = AuctionScope.of(context);
    final lotId = _lotId;
    final lot = lotId == null ? null : auction.lot(lotId);
    final loading = auction.auction == null && auction.failure == null;
    final closeAt = auction.auction?.closeAt;
    if (lot != null) _maybeLoadWinnerCodes(lot);
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
                closed: auction.auction?.status == 'CLOSED',
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
              onShare: _share,
              loadWinnerCode: _loadWinnerCode,
              organizerCode: _winnerCodes?[lot.lotId.uuid],
              sharedNames: auction.sharedNames,
              asOf: _asOf,
              onAsOf: () => _pickAsOf(auction, lot),
            )
          : Center(
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text('This lot is not in the auction'),
            ),
      bottomNavigationBar: switch ((lot, _asOf)) {
        (null, _) => null,
        (_, final asOf?) => AsOfBar(
          at: asOf.at,
          onLive: () => setState(() => _asOf = null),
        ),
        (final lot?, null) => _actions(auction, lot),
      },
    );
  }

  Widget? _actions(AuctionController auction, LotCard lot) {
    final closeAt = auction.auction?.closeAt;
    if (lot.status != 'OPEN') return ShareResultBar(onShare: _share);
    if (!_identityLoaded || _isOrganizer || closeAt == null) return null;
    final identity = _identity;
    return SafeArea(
      child: Material(
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: identity == null
              ? FilledButton(
                  onPressed: _join,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Join to bid'),
                )
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

/// A closed lot's action bar: one button that copies the receipt's URL
/// (UC-09), for everyone, joined or not.
class ShareResultBar extends StatelessWidget {
  const ShareResultBar({required this.onShare, super.key});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Material(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: onShare,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          icon: const Icon(Icons.share),
          label: const Text('Share result'),
        ),
      ),
    ),
  );
}

/// The lot's visual, name, description, price block and ledger.
///
/// Given [asOf] (UC-10), the price block shows the server's replay of that
/// moment and the ledger is read as of it.
class LotDetailBody extends StatelessWidget {
  const LotDetailBody({
    required this.lot,
    required this.ledger,
    required this.closeAt,
    this.me,
    this.onShare,
    this.loadWinnerCode,
    this.organizerCode,
    this.sharedNames = const {},
    this.asOf,
    this.onAsOf,
    super.key,
  });

  final LotCard lot;

  /// The lot as of a past moment, if the viewer picked one.
  final LotAsOf? asOf;

  /// Opens the moment picker, from the "As of…" chip.
  final VoidCallback? onAsOf;

  /// Every bid, in ledger order, or null while it loads.
  final List<LedgerEntry>? ledger;

  /// When the auction closes, in UTC.
  final DateTime closeAt;

  /// Who this browser bids as, if it joined.
  final UuidValue? me;

  /// Shares the result, from the banner of a lot [me] won.
  final VoidCallback? onShare;

  /// Fetches [me]'s winner code for the banner of a lot they won.
  final LoadWinnerCode? loadWinnerCode;

  /// The winner code, for the organizer to check a buyer's claim.
  final String? organizerCode;

  /// The names more than one bidder goes by, which get their tag.
  final Set<String> sharedNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final steps = lot.increments;
    final ledger = this.ledger;
    final asOf = this.asOf;
    final leading = me != null && lot.leaderId == me;
    final outbid = !leading && (ledger?.hasValidBidBy(me) ?? false);
    final leader = switch (lot.leaderName) {
      final name? => displayName(name, lot.leaderId, sharedNames),
      null => null,
    };
    final (status, color) = switch (lot) {
      _ when leading => (
        "You're the high bidder — ${formatRupiah(lot.currentPrice)}",
        Colors.green.shade700,
      ),
      _ when leader != null && outbid => (
        'Outbid — $leader leads at ${formatRupiah(lot.currentPrice)}',
        Colors.amber.shade900,
      ),
      _ when leader != null => ('$leader leads', scheme.onSurface),
      _ => ('No bids yet', scheme.onSurfaceVariant),
    };
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            if (onShare case final onShare? when asOf == null && wonBy(lot, me))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: WonBanner(
                  lot: lot,
                  onShare: onShare,
                  loadCode: loadWinnerCode,
                ),
              ),
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
                  if (asOf != null && asOf.status == 'OPEN')
                    _PriceAsOf(asOf, sharedNames)
                  else if (lot.status == 'OPEN') ...[
                    _Price(lot.currentPrice),
                    if (steps.isNotEmpty)
                      Text(
                        'Next bid from '
                        '${formatRupiah(lot.currentPrice + steps.first)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                      ),
                    ),
                  ] else
                    ResultBlock(
                      lot: lot,
                      closeAt: closeAt,
                      organizerCode: organizerCode,
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Bids', style: theme.textTheme.titleMedium),
                      ),
                      if (onAsOf case final onAsOf?
                          when ledger?.isNotEmpty ?? false)
                        ActionChip(
                          avatar: const Icon(Icons.history, size: 18),
                          label: const Text('As of…'),
                          onPressed: onAsOf,
                        ),
                    ],
                  ),
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
              LedgerList(
                lot: lot,
                entries: ledger,
                closeAt: closeAt,
                me: me,
                sharedNames: sharedNames,
                asOf: asOf,
              ),
            if (lot.status != 'OPEN')
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  "This record is append-only. Bids can't be edited or "
                  'deleted — retractions stay visible.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// [price] in big tabular figures, shrunk to fit a phone.
class _Price extends StatelessWidget {
  const _Price(this.price);

  final int price;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      formatRupiah(price),
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}

/// The price and leader the server's replay gives as of a past moment
/// (UC-10).
class _PriceAsOf extends StatelessWidget {
  const _PriceAsOf(this.asOf, this.sharedNames);

  final LotAsOf asOf;
  final Set<String> sharedNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leader = switch (asOf.leaderName) {
      final name? => displayName(name, asOf.leaderId, sharedNames),
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Price(asOf.price),
        Text(
          leader == null ? 'No bids yet' : '$leader led',
          style: theme.textTheme.titleMedium,
        ),
      ],
    );
  }
}

/// The bottom bar while viewing a past moment (UC-10): an amber
/// "AS OF 22:02:00" badge and LIVE. It takes the place of the chips and
/// RETRACT, so no command can run against past state.
class AsOfBar extends StatelessWidget {
  const AsOfBar({required this.at, required this.onLive, super.key});

  /// The moment shown, in UTC.
  final DateTime at;

  final VoidCallback onLive;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Material(
      elevation: 8,
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  'AS OF ${formatClock(at)}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onLive,
              icon: const Icon(Icons.fiber_manual_record, size: 14),
              label: const Text('LIVE'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A closed lot's outcome, the receipt a winner shares (UC-09):
/// "🔨 SOLD to Sari · #3f9c", the final price, and when and how it closed.
/// The winner's tag is always there, so two Saris can't be confused.
class ResultBlock extends StatelessWidget {
  const ResultBlock({
    required this.lot,
    required this.closeAt,
    this.organizerCode,
    super.key,
  });

  final LotCard lot;

  /// When the auction closes, in UTC: the close time until the lot knows
  /// its own.
  final DateTime closeAt;

  /// The winner code, shown to the organizer only.
  final String? organizerCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winner = switch ((lot.winnerName, lot.leaderId)) {
      (final name?, final id?) when lot.status == 'SOLD' => tagged(name, id),
      _ => null,
    };
    final closed = 'Closed ${formatClock(lot.closedAt ?? closeAt)}';
    final how = lot.closeCause == 'BUY_NOW'
        ? 'Buy Now by ${lot.winnerName}'
        : 'by deadline';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          winner == null ? '🔨 PASSED — no bids' : '🔨 SOLD to $winner',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: winner == null ? Colors.grey.shade600 : null,
          ),
        ),
        if (winner != null) _Price(lot.finalPrice ?? lot.currentPrice),
        Text(
          winner == null ? closed : '$closed · $how',
          style: theme.textTheme.bodyMedium,
        ),
        if ((winner, organizerCode) case (final winner?, final code?)) ...[
          const SizedBox(height: 8),
          SelectableText(
            '$winner · code $code',
            style: theme.textTheme.titleMedium?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
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
