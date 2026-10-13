import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gavel_client/gavel_client.dart';

import '../core/money.dart';
import '../core/names.dart';
import '../theme.dart';

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
    const ink = Brand.ink;
    final price = formatRupiah(lot.finalPrice ?? lot.currentPrice);
    final code = _code;
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final share = TextButton.icon(
      onPressed: widget.onShare,
      style: TextButton.styleFrom(foregroundColor: ink),
      icon: const Icon(Icons.share),
      label: const Text('Share result'),
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.goldBright, Brand.gold],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Brand.gold.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🔨 You won ${lot.name} — $price',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (!narrow) share,
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((lot.winnerName, lot.leaderId) case (
                  final name?,
                  final id?,
                ))
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
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  fontFeatures: Brand.tabular,
                                ),
                              ),
                              const TextSpan(
                                text: ' · send it to the seller to claim',
                              ),
                            ],
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: ink,
                          ),
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
                if (narrow) share,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
