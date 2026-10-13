import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';
import '../core/auction_controller.dart';
import '../core/auction_scope.dart';
import '../core/clock.dart';
import '../core/failures.dart';
import '../core/identity.dart';
import '../core/live.dart';
import '../core/organizer_keys.dart';
import '../widgets/join_sheet.dart';
import '../widgets/lot_card_widget.dart';

/// An auction's live board (UC-04), or its big-screen mode (UC-11).
///
/// A bidder without an identity for this auction is asked for a name once
/// (UC-03); the board stays visible behind the prompt.
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
        widget.bigScreen ||
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
      return Scaffold(
        appBar: AppBar(
          title: _Title(
            title: auction?.title ?? 'Auction ${widget.code}',
            closeAt: auction?.closeAt,
            offset: _auction.clockOffset,
          ),
          actions: [
            if (!widget.bigScreen && auction != null) ..._identityActions(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LiveDot(_auction.status),
            ),
          ],
        ),
        body: switch ((_auction.failure, auction)) {
          (AuctionNotFound(), _) => _NotFound(code: widget.code),
          (final GavelFailure failure, _) => Center(child: Text('$failure')),
          (_, null) => const Center(child: CircularProgressIndicator()),
          (_, _) => LotGrid(
            lots: _auction.lots,
            me: _identity?.participantId,
            size: widget.bigScreen ? LotCardSize.large : LotCardSize.regular,
            onTap: widget.bigScreen
                ? null
                : (lot) => context.go('/a/${widget.code}/lot/${lot.lotId}'),
            empty: 'No lots yet — the organizer is setting up.',
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
          child: Chip(
            avatar: const Icon(Icons.person, size: 18),
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                'You: ${identity.displayName}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ];
    }
    if (_identityLoaded && !_isOrganizer && _isOpen) {
      return [TextButton(onPressed: _promptJoin, child: const Text('Join'))];
    }
    return const [];
  }
}

/// The auction's title over the countdown to its close.
class _Title extends StatelessWidget {
  const _Title({
    required this.title,
    required this.closeAt,
    required this.offset,
  });

  final String title;
  final DateTime? closeAt;
  final ValueListenable<Duration> offset;

  @override
  Widget build(BuildContext context) {
    final closeAt = this.closeAt;
    final small = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, overflow: TextOverflow.ellipsis),
        if (closeAt != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: small?.color),
              const SizedBox(width: 4),
              CountdownText(closeAt: closeAt, offset: offset, style: small),
            ],
          ),
      ],
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
    final code = _code.text.trim().toUpperCase();
    if (code.isNotEmpty) context.go('/a/$code');
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
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.go,
                decoration: const InputDecoration(
                  labelText: 'Join code',
                  hintText: 'ABC234',
                ),
                onSubmitted: (_) => _open(),
              ),
              FilledButton(onPressed: _open, child: const Text('Open')),
            ],
          ),
        ),
      ),
    );
  }
}
