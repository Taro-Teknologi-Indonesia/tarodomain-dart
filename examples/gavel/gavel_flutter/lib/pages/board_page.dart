import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_client/rules.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';
import '../core/auction_controller.dart';
import '../core/auction_scope.dart';
import '../core/failures.dart';
import '../core/identity.dart';
import '../core/input_formatters.dart';
import '../core/live.dart';
import '../core/organizer_keys.dart';
import '../core/share.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/demo_banner.dart';
import '../widgets/join_sheet.dart';
import '../widgets/lot_card_widget.dart';
import '../widgets/won_banner.dart';

/// An auction's live board (UC-04).
///
/// A bidder without an identity for this auction is asked for a name once
/// (UC-03); the board stays visible behind the prompt.
class BoardPage extends StatefulWidget {
  const BoardPage({required this.code, super.key});

  /// The auction's join code.
  final String code;

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  /// The auction, shared with its other pages through [AuctionScope].
  late final AuctionController _auction;

  /// Who this browser bids as here, once read from localStorage.
  Identity? _identity;
  bool _identityLoaded = false;

  /// Organizers don't bid, so they're never asked to join.
  bool _isOrganizer = false;

  /// Whether the join prompt was shown, so dismissing it sticks.
  bool _prompted = false;

  @override
  void initState() {
    super.initState();
    _auction = AuctionScope.read(context)..addListener(_maybePrompt);
    unawaited(_loadIdentity());
  }

  @override
  void dispose() {
    _auction.removeListener(_maybePrompt);
    super.dispose();
  }

  bool get _isOpen => _auction.auction?.status == 'OPEN';

  Future<void> _loadIdentity() async {
    final identity = await Identities.load(widget.code);
    final organizerKey = await OrganizerKeys.load(widget.code);
    if (!mounted) return;
    setState(() {
      _identity = identity;
      _isOrganizer = organizerKey != null;
      _identityLoaded = true;
    });
    _maybePrompt();
    if (identity != null) unawaited(_checkIdentity(identity));
  }

  /// Drops [identity] if the server doesn't know it, after a database reset
  /// or an edited entry. Network trouble keeps it.
  Future<void> _checkIdentity(Identity identity) async {
    final bool known;
    try {
      known = await client.auction.checkParticipant(
        widget.code,
        identity.participantId,
        identity.participantKey,
      );
    } catch (_) {
      return;
    }
    if (known || !mounted) return;
    await Identities.forget(widget.code);
    if (!mounted) return;
    setState(() {
      _identity = null;
      _prompted = false;
    });
    _maybePrompt();
  }

  /// Asks for a name once the auction is known to be open and this browser
  /// has no identity for it.
  void _maybePrompt() {
    if (!mounted ||
        _prompted ||
        !_identityLoaded ||
        _identity != null ||
        _isOrganizer ||
        !_isOpen) {
      return;
    }
    _prompted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptJoin());
  }

  Future<void> _promptJoin() async {
    if (!mounted) return;
    final identity = await JoinSheet.show(context, widget.code);
    if (identity != null && mounted) setState(() => _identity = identity);
  }

  Future<void> _switchName() async {
    await Identities.forget(widget.code);
    if (!mounted) return;
    setState(() => _identity = null);
    await _promptJoin();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _auction,
    builder: (context, _) {
      final auction = _auction.auction;
      final joinable =
          auction != null &&
          _identityLoaded &&
          _identity == null &&
          !_isOrganizer &&
          _isOpen;
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 16,
          title: InkWell(
            onTap: () => context.go('/'),
            child: const GavelLogo(size: 26),
          ),
          actions: [
            if (auction != null) ..._identityActions(),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 16),
              child: LiveDot(_auction.status),
            ),
          ],
        ),
        bottomNavigationBar: joinable ? _JoinBar(onJoin: _promptJoin) : null,
        body: switch ((_auction.failure, auction)) {
          (AuctionNotFound(), _) => _NotFound(code: widget.code),
          (final GavelFailure failure, _) => Center(child: Text('$failure')),
          (_, null) => const Center(child: CircularProgressIndicator()),
          (_, final auction?) => Column(
            children: [
              _Header(
                code: widget.code,
                title: auction.title,
                closeAt: auction.closeAt,
                closed: auction.status == 'CLOSED',
                offset: _auction.clockOffset,
                lots: _auction.lots,
                me: _identity?.participantId,
              ),
              if (auction.isDemo) const DemoBanner(),
              for (final lot in _auction.lots)
                if ((_identity, wonBy(lot, _identity?.participantId)) case (
                  final identity?,
                  true,
                ))
                  WonBanner(
                    key: ValueKey(lot.lotId),
                    lot: lot,
                    onShare: () =>
                        copyLotLink(context, widget.code, lot.lotId.uuid),
                    loadCode: () => client.lot.winnerCode(
                      lot.lotId,
                      identity.participantId,
                      identity.participantKey,
                    ),
                  ),
              Expanded(
                child: LotGrid(
                  lots: _auction.lots,
                  me: _identity?.participantId,
                  sharedNames: _auction.sharedNames,
                  onTap: (lot) =>
                      context.go('/a/${widget.code}/lot/${lot.lotId}'),
                  empty: 'No lots yet — the organizer is setting up.',
                ),
              ),
            ],
          ),
        },
      );
    },
  );

  List<Widget> _identityActions() {
    if (_identity case final identity?) {
      return [
        PopupMenuButton<void>(
          tooltip: 'Your name',
          itemBuilder: (_) => [
            PopupMenuItem(
              onTap: _switchName,
              child: const Text('Not you? Switch name'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BidderAvatar(identity.displayName, size: 26),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    'You: ${identity.displayName}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    if (_identityLoaded && !_isOrganizer && _isOpen) {
      return [
        TextButton(
          onPressed: _promptJoin,
          style: TextButton.styleFrom(foregroundColor: Brand.gold),
          child: const Text('Join'),
        ),
      ];
    }
    return const [];
  }
}

/// The sticky invitation for a visitor who hasn't joined an open auction.
class _JoinBar extends StatelessWidget {
  const _JoinBar({required this.onJoin});

  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Brand.line)),
        boxShadow: [
          BoxShadow(
            color: Brand.ink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Ready to bid?', style: theme.textTheme.titleMedium),
                    Text(
                      'Join with just a name. No sign-up.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Brand.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: onJoin,
                style: Brand.goldButton,
                icon: const Icon(Icons.gavel_rounded, size: 18),
                label: const Text('Join to bid'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The auction's dark header: its title, code and tallies beside the
/// countdown to its close.
class _Header extends StatelessWidget {
  const _Header({
    required this.code,
    required this.title,
    required this.closeAt,
    required this.closed,
    required this.offset,
    required this.lots,
    required this.me,
  });

  final String code;
  final String title;
  final DateTime closeAt;
  final bool closed;
  final ValueListenable<Duration> offset;
  final List<LotCard> lots;

  /// Who this browser bids as, whose leads are counted.
  final UuidValue? me;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final bids = lots.fold(0, (sum, lot) => sum + lot.bidCount);
    final leading = me == null
        ? 0
        : lots.where((l) => l.status == 'OPEN' && l.leaderId == me).length;
    final tallies = [
      lots.length == 1 ? '1 lot' : '${lots.length} lots',
      bids == 1 ? '1 bid' : '$bids bids',
    ].join(' · ');
    return DecoratedBox(
      decoration: Brand.band,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, narrow ? 4 : 12, 16, 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(
                    closed ? 'Auction closed · $code' : 'Live auction · $code',
                    color: Brand.gold,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Brand.display.copyWith(
                      color: Colors.white,
                      fontSize: narrow ? 24 : 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        tallies,
                        style: const TextStyle(
                          color: Brand.mutedOnInk,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (leading > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Brand.lead,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'You lead $leading',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            CountdownPanel(
              closeAt: closeAt,
              offset: offset,
              closed: closed,
              size: narrow ? 28 : 40,
            ),
          ],
        ),
      ),
    );
  }
}

/// The full page for a code that matches no auction, with a field to
/// retype it.
class _NotFound extends StatefulWidget {
  const _NotFound({required this.code});

  final String code;

  @override
  State<_NotFound> createState() => _NotFoundState();
}

class _NotFoundState extends State<_NotFound> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _open() {
    final code = JoinCodeRules.normalize(_code.text);
    if (JoinCodeRules.isValid(code)) context.go('/a/$code');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Brand.goldTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 30,
                    color: Brand.goldDeep,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Auction not found — check the link',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'No auction has the code ${widget.code}.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _code,
                maxLength: JoinCodeRules.length,
                inputFormatters: [JoinCodeFormatter()],
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.go,
                decoration: const InputDecoration(
                  labelText: 'Join code',
                  hintText: 'ABC234',
                ),
                onSubmitted: (_) => _open(),
              ),
              ListenableBuilder(
                listenable: _code,
                builder: (context, _) => FilledButton(
                  onPressed:
                      JoinCodeRules.isValid(JoinCodeRules.normalize(_code.text))
                      ? _open
                      : null,
                  child: const Text('Open'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/demo'),
                child: const Text('Or try the live demo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
