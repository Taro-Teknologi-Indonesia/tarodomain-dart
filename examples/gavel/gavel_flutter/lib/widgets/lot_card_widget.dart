import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';

import '../core/money.dart';
import 'lot_visual.dart';

/// One lot: its visual, name, price, leader and status. The board, the
/// organizer dashboard and the big screen all show lots with it.
class LotCardWidget extends StatelessWidget {
  const LotCardWidget(this.lot, {this.onTap, super.key});

  final LotCard lot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: LotVisual(
                imageUrl: lot.imageUrl,
                emoji: lot.tileEmoji,
                color: lot.tileColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          lot.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(lot.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(lot.currentPrice),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    lot.leaderName == null
                        ? 'No bids — opens at ${formatRupiah(lot.openBid)}'
                        : '${lot.leaderName} leads',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// OPEN in green, SOLD in gold, PASSED in grey.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'OPEN' => Colors.green.shade700,
      'SOLD' => Colors.amber.shade800,
      _ => Colors.grey.shade600,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

/// [lots] in one column under 600 px and a grid above, or [empty] when
/// there are none.
class LotGrid extends StatelessWidget {
  const LotGrid({required this.lots, required this.empty, super.key});

  final List<LotCard> lots;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (lots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(empty, textAlign: TextAlign.center),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.fromLTRB(16, 8, 16, 96);
        if (constraints.maxWidth < 600) {
          return ListView.separated(
            padding: padding,
            itemCount: lots.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => LotCardWidget(lots[i]),
          );
        }
        return GridView.builder(
          padding: padding,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 360,
            childAspectRatio: 0.92,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: lots.length,
          itemBuilder: (_, i) => LotCardWidget(lots[i]),
        );
      },
    );
  }
}
