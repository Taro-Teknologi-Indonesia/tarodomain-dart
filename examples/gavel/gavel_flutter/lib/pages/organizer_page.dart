import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_client/rules.dart';

import '../core/api.dart';
import '../core/auction_controller.dart';
import '../core/auction_scope.dart';
import '../core/browser.dart';
import '../core/clock.dart';
import '../core/failures.dart';
import '../core/live.dart';
import '../core/names.dart';
import '../core/organizer_keys.dart';
import '../theme.dart';
import '../widgets/brand.dart';
import '../widgets/lot_card_widget.dart';
import '../widgets/unpaid.dart';
import 'lot_form_sheet.dart';

/// The organizer's dashboard: the auction's lots, live, and adding more
/// (UC-02). Read-only in a browser that doesn't hold the organizer key.
class OrganizerPage extends StatefulWidget {
  const OrganizerPage({required this.code, super.key});

  /// The auction's join code.
  final String code;

  @override
  State<OrganizerPage> createState() => _OrganizerPageState();
}

class _OrganizerPageState extends State<OrganizerPage> {
  /// The auction, shared with its other pages through [AuctionScope].
  late final AuctionController _auction = AuctionScope.read(context);
  String? _organizerKey;
  var _keyLoaded = false;

  /// The winner code of each SOLD lot by lot ID, once fetched (UC-09).
  Map<String, String>? _winnerCodes;

  /// The SOLD lots the codes were fetched for, so a newly sold lot fetches
  /// them again.
  var _codesFor = 0;

  @override
  void initState() {
    super.initState();
    _auction.addListener(_maybeLoadWinnerCodes);
    OrganizerKeys.load(widget.code).then((key) {
      if (mounted) {
        setState(() {
          _organizerKey = key;
          _keyLoaded = true;
        });
        _maybeLoadWinnerCodes();
      }
    });
  }

  @override
  void dispose() {
    _auction.removeListener(_maybeLoadWinnerCodes);
    super.dispose();
  }

  List<LotCard> get _sold => [
    for (final lot in _auction.lots)
      if (lot.status == 'SOLD') lot,
  ];

  /// Fetches the winner codes whenever more lots are SOLD than they were
  /// fetched for.
  void _maybeLoadWinnerCodes() {
    final key = _organizerKey;
    final sold = _sold.length;
    if (key == null || sold == 0 || sold <= _codesFor) return;
    _codesFor = sold;
    client.auction
        .winnerCodes(widget.code, key)
        .then(
          (codes) {
            if (mounted) setState(() => _winnerCodes = codes);
          },
          onError: (Object _) {
            // Fetched again with the next update.
            _codesFor = 0;
          },
        );
  }

  Future<void> _addLot(String organizerKey) async {
    final card = await showLotForm(
      context,
      code: widget.code,
      organizerKey: organizerKey,
    );
    if (card == null || !mounted) return;
    _auction.merge(card);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${card.name} is on the board')));
  }

  /// Marks [lot]'s winner as not having paid, once the organizer confirms
  /// (UC-14).
  Future<void> _markUnpaid(String organizerKey, LotCard lot) async {
    final (:confirmed, :note) = await confirmMarkUnpaid(context, lot);
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final card = await client.lot.markUnpaid(lot.lotId, organizerKey, note);
      _auction.merge(card);
      messenger.showSnackBar(
        SnackBar(content: Text('${card.name} is marked unpaid')),
      );
    } on Object catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(switch (GavelFailure.from(e)) {
            NotOrganizer() => 'Only the organizer can mark a lot unpaid',
            Invalid(:final message) => message,
            Unexpected() => "Couldn't reach the server — try again",
            _ => 'Something went wrong — try again',
          }),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _auction,
    builder: (context, _) {
      final theme = Theme.of(context);
      final auction = _auction.auction;
      final key = _organizerKey;
      final canAdd = key != null && auction?.status == 'OPEN';
      final full = AuctionRules.lotCount(_auction.lots.length);
      return Scaffold(
        appBar: AppBar(
          title: Text(auction?.title ?? 'Organize ${widget.code}'),
          actions: [
            // The projector's view, in its own tab (UC-11).
            TextButton.icon(
              onPressed: () => openInNewTab(
                '${Uri.base.origin}/a/${widget.code}?screen=board',
              ),
              style: TextButton.styleFrom(foregroundColor: Brand.gold),
              icon: const Icon(Icons.tv),
              label: const Text('Open big screen'),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 16),
              child: LiveDot(_auction.status),
            ),
          ],
        ),
        // Gone at the close on the server's clock, not only once its push
        // arrives; disabled at the lot cap. The server checks both again.
        floatingActionButton: canAdd
            ? DeadlineBuilder(
                closeAt: auction!.closeAt,
                offset: _auction.clockOffset,
                builder: (context, timeUp) => timeUp
                    ? const SizedBox.shrink()
                    : AddLotButton(
                        lotCount: _auction.lots.length,
                        onAdd: () => _addLot(key),
                      ),
              )
            : null,
        body: switch ((_auction.failure, auction)) {
          (AuctionNotFound(), _) => Center(
            child: Text(
              'No auction with code ${widget.code}',
              style: theme.textTheme.titleLarge,
            ),
          ),
          (final GavelFailure failure, _) => Center(child: Text('$failure')),
          (_, null) => const Center(child: CircularProgressIndicator()),
          (_, final auction?) => Column(
            children: [
              _ShareHeader(
                code: widget.code,
                title: auction.title,
                closeAt: auction.closeAt,
                closed: auction.status == 'CLOSED',
                offset: _auction.clockOffset,
              ),
              if (_keyLoaded && key == null)
                MaterialBanner(
                  leading: const Icon(Icons.lock_outline),
                  content: const Text(
                    'Read-only — open from the browser that created this '
                    'auction',
                  ),
                  actions: [const SizedBox.shrink()],
                ),
              if (canAdd && full != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(full.message, style: theme.textTheme.bodySmall),
                ),
              if ((_winnerCodes, key) case (
                final codes?,
                final key?,
              ) when codes.isNotEmpty)
                _Winners(
                  lots: _sold,
                  codes: codes,
                  onMarkUnpaid: (lot) => _markUnpaid(key, lot),
                ),
              Expanded(
                child: LotGrid(
                  lots: _auction.lots,
                  sharedNames: _auction.sharedNames,
                  size: LotCardSize.dense,
                  empty: key == null
                      ? 'No lots yet.'
                      : 'No lots yet — add the first one.',
                ),
              ),
            ],
          ),
        },
      );
    },
  );
}

/// The dashboard's Add lot button, greyed out with a tooltip saying why
/// once the auction has [AuctionRules.maxLots] lots.
class AddLotButton extends StatelessWidget {
  const AddLotButton({required this.lotCount, required this.onAdd, super.key});

  /// How many lots the auction has.
  final int lotCount;

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final full = AuctionRules.lotCount(lotCount);
    final enabled = full == null;
    return FloatingActionButton.extended(
      onPressed: enabled ? onAdd : null,
      tooltip: full?.message,
      backgroundColor: enabled ? null : scheme.surfaceContainerHighest,
      foregroundColor: enabled
          ? null
          : scheme.onSurface.withValues(alpha: 0.38),
      icon: const Icon(Icons.add),
      label: const Text('Add lot'),
    );
  }
}

/// Each SOLD lot's winner with their tag and winner code (UC-09):
/// "Natural Pirus Hubei — Budi · #3f9c · code 7KQ-2XM". The seller asks a
/// buyer for the code and hands the lot over only on a match. A winner who
/// didn't pay can be marked unpaid (UC-14); a marked lot shows its tag.
class _Winners extends StatelessWidget {
  const _Winners({
    required this.lots,
    required this.codes,
    required this.onMarkUnpaid,
  });

  final List<LotCard> lots;

  /// Winner codes by lot ID.
  final Map<String, String> codes;

  final void Function(LotCard lot) onMarkUnpaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        child: ConstrainedBox(
          // Many winners scroll inside the card, leaving room for the grid.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.3,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      color: Brand.goldDeep,
                    ),
                    const SizedBox(width: 8),
                    Text('Winners', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Ask the buyer for their code and hand the lot over only '
                  'if it matches.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                for (final lot in lots)
                  if ((lot.winnerName, lot.leaderId, codes[lot.lotId.uuid])
                      case (final name?, final id?, final code?))
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            '${lot.name} — ${tagged(name, id)} · code $code',
                            style: const TextStyle(
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        if (lot.unpaid)
                          const UnpaidTag()
                        else
                          TextButton(
                            onPressed: () => onMarkUnpaid(lot),
                            child: const Text('Mark unpaid'),
                          ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The auction's dark header: its title, the join link with a copy
/// button, and the countdown to the close.
class _ShareHeader extends StatelessWidget {
  const _ShareHeader({
    required this.code,
    required this.title,
    required this.closeAt,
    required this.closed,
    required this.offset,
  });

  final String code;
  final String title;
  final DateTime closeAt;
  final bool closed;
  final ValueListenable<Duration> offset;

  String get _link => '${Uri.base.origin}/a/$code';

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: _link));
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Link copied — paste it in your Facebook post'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final link = Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.link_rounded, color: Brand.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              _link,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => _copy(context),
            style: Brand.goldButton,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
          ),
        ],
      ),
    );
    final countdown = CountdownPanel(
      closeAt: closeAt,
      offset: offset,
      closed: closed,
      size: 32,
    );
    return DecoratedBox(
      decoration: Brand.band,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 600;
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Organizer dashboard · $code', color: Brand.gold),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Brand.display.copyWith(
                    color: Colors.white,
                    fontSize: narrow ? 24 : 30,
                  ),
                ),
              ],
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: heading),
                      const SizedBox(width: 12),
                      countdown,
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Eyebrow(
                    'Share this link in your post',
                    color: Brand.mutedOnInk,
                  ),
                  const SizedBox(height: 6),
                  link,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading,
                      const SizedBox(height: 14),
                      const Eyebrow(
                        'Share this link in your post',
                        color: Brand.mutedOnInk,
                      ),
                      const SizedBox(height: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: link,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                countdown,
              ],
            );
          },
        ),
      ),
    );
  }
}
