import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gavel_client/gavel_client.dart';

import '../core/money.dart';
import '../core/names.dart';

/// Whether [me] won [lot]: it is SOLD and its last leader is [me].
bool wonBy(LotCard lot, UuidValue? me) =>
    me != null && lot.status == 'SOLD' && lot.leaderId == me;

/// Fetches this browser's winner code for a lot: `LotEndpoint.winnerCode`,
/// or a fake in tests.
typedef LoadWinnerCode = Future<String?> Function();

/// The full-width celebration for a lot this browser won (UC-08):
/// "🔨 You won Natural Pirus Hubei — Rp 450.000", with a share button,
/// the winner's own tag, and the winner code to send the seller (UC-09).
class WonBanner extends StatefulWidget {
  const WonBanner({
    required this.lot,
    required this.onShare,
    this.loadCode,
    super.key,
  });

  /// The lot won.
  final LotCard lot;

  /// Shares the result (UC-09).
  final VoidCallback onShare;

  /// Fetches the winner code, once, when the banner first shows.
  final LoadWinnerCode? loadCode;

  @override
  State<WonBanner> createState() => _WonBannerState();
}

class _WonBannerState extends State<WonBanner> {
  String? _code;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final load = widget.loadCode;
    if (load == null) return;
    try {
      final code = await load();
      if (mounted) setState(() => _code = code);
    } catch (_) {
      // No code then; the receipt and the ledger still stand.
    }
  }

  Future<void> _copy(String code) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: code));
    messenger.showSnackBar(
      const SnackBar(content: Text('Code copied — send it to the seller')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lot = widget.lot;
    final ink = Colors.brown.shade900;
    final price = formatRupiah(lot.finalPrice ?? lot.currentPrice);
    final code = _code;
    return Material(
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '🔨 You won ${lot.name} — $price',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onShare,
                  icon: const Icon(Icons.share),
                  label: const Text('Share result'),
                ),
              ],
            ),
            if ((lot.winnerName, lot.leaderId) case (final name?, final id?))
              Text(
                "You're ${tagged(name, id)} on the receipt",
                style: theme.textTheme.bodyMedium?.copyWith(color: ink),
              ),
            if (code != null)
              Row(
                children: [
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Your winner code: '),
                          TextSpan(
                            text: code,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const TextSpan(
                            text: ' · send it to the seller to claim',
                          ),
                        ],
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(color: ink),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy code',
                    icon: const Icon(Icons.copy, size: 18),
                    color: ink,
                    onPressed: () => _copy(code),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
