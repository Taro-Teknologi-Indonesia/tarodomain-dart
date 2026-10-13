import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';

import '../core/money.dart';

/// Whether [me] won [lot]: it is SOLD and its last leader is [me].
bool wonBy(LotCard lot, UuidValue? me) =>
    me != null && lot.status == 'SOLD' && lot.leaderId == me;

/// The full-width celebration for a lot this browser won (UC-08):
/// "🔨 You won Natural Pirus Hubei — Rp 450.000", with a share button.
class WonBanner extends StatelessWidget {
  const WonBanner({required this.lot, required this.onShare, super.key});

  /// The lot won.
  final LotCard lot;

  /// Shares the result (UC-09).
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final price = formatRupiah(lot.finalPrice ?? lot.currentPrice);
    return Material(
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '🔨 You won ${lot.name} — $price',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.brown.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share),
              label: const Text('Share result'),
            ),
          ],
        ),
      ),
    );
  }
}
