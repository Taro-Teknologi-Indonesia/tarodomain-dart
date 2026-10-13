import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/auction_controller.dart';
import '../core/auction_scope.dart';
import '../core/clock.dart';
import '../core/failures.dart';
import '../core/live.dart';
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

  @override
  void initState() {
    super.initState();
    OrganizerKeys.load(widget.code).then((key) {
      if (mounted) {
        setState(() {
          _organizerKey = key;
          _keyLoaded = true;
        });
      }
    });
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
              Expanded(
                child: LotGrid(
                  lots: _auction.lots,
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
