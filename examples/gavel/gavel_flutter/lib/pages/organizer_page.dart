import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gavel_client/gavel_client.dart';

import '../core/api.dart';
import '../core/auction_controller.dart';
import '../core/auction_scope.dart';
import '../core/browser.dart';
import '../core/clock.dart';
import '../core/failures.dart';
import '../core/live.dart';
import '../core/names.dart';
import '../core/organizer_keys.dart';
import '../widgets/lot_card_widget.dart';
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${card.name} is on the board')));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _auction,
    builder: (context, _) {
      final theme = Theme.of(context);
      final auction = _auction.auction;
      final key = _organizerKey;
      final canAdd = key != null && auction?.status == 'OPEN';
      return Scaffold(
        appBar: AppBar(
          title: Text(auction?.title ?? 'Organize ${widget.code}'),
          actions: [
            // The projector's view, in its own tab (UC-11).
            TextButton.icon(
              onPressed: () => openInNewTab(
                '${Uri.base.origin}/a/${widget.code}?screen=board',
              ),
              icon: const Icon(Icons.tv),
              label: const Text('Open big screen'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LiveDot(_auction.status),
            ),
          ],
        ),
        floatingActionButton: canAdd
            ? FloatingActionButton.extended(
                onPressed: () => _addLot(key),
                icon: const Icon(Icons.add),
                label: const Text('Add lot'),
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
              if (_winnerCodes case final codes? when codes.isNotEmpty)
                _Winners(lots: _sold, codes: codes),
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

/// Each SOLD lot's winner with their tag and winner code (UC-09):
/// "Natural Pirus Hubei — Budi · #3f9c · code 7KQ-2XM". The seller asks a
/// buyer for the code and hands the lot over only on a match.
class _Winners extends StatelessWidget {
  const _Winners({required this.lots, required this.codes});

  final List<LotCard> lots;

  /// Winner codes by lot ID.
  final Map<String, String> codes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Card(
        child: ConstrainedBox(
          // Many winners scroll inside the card, leaving room for the grid.
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.3,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Winners', style: theme.textTheme.titleMedium),
                Text(
                  'Ask the buyer for their code and hand the lot over only '
                  'if it matches.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                for (final lot in lots)
                  if ((lot.winnerName, lot.leaderId, codes[lot.lotId.uuid])
                      case (final name?, final id?, final code?))
                    SelectableText(
                      '${lot.name} — ${tagged(name, id)} · code $code',
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The join link with a copy button, and the countdown to the close.
class _ShareHeader extends StatelessWidget {
  const _ShareHeader({
    required this.code,
    required this.closeAt,
    required this.closed,
    required this.offset,
  });

  final String code;
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
    final theme = Theme.of(context);
    final link = Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Join link',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            child: SelectableText(_link, maxLines: 1),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy),
          label: const Text('Copy'),
        ),
      ],
    );
    final countdown = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Closes in', style: theme.textTheme.labelSmall),
        CountdownText(
          closeAt: closeAt,
          offset: offset,
          closed: closed,
          style: theme.textTheme.titleLarge,
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 600
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  link,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: countdown),
                ],
              )
            : Row(
                children: [
                  Expanded(child: link),
                  const SizedBox(width: 24),
                  countdown,
                ],
              ),
      ),
    );
  }
}
