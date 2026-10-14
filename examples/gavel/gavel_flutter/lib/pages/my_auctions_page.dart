import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/clock.dart';
import '../core/failures.dart';
import '../core/money.dart';
import '../core/organizer_keys.dart';
import '../theme.dart';

/// The signed-in organizer's auctions, running and past, from any browser
/// they sign into (UC-15). Each opens its organizer dashboard.
class MyAuctionsPage extends StatefulWidget {
  const MyAuctionsPage({
    @visibleForTesting this.myAuctions,
    @visibleForTesting this.hasKey,
    super.key,
  });

  /// Sends `organizer.myAuctions`; the app's client unless a test passes
  /// one.
  final Future<MyAuctions> Function()? myAuctions;

  /// Whether this browser holds the organizer key of the auction with a
  /// join code; [OrganizerKeys] unless a test passes one.
  final Future<bool> Function(String code)? hasKey;

  @override
  State<MyAuctionsPage> createState() => _MyAuctionsPageState();
}

class _MyAuctionsPageState extends State<MyAuctionsPage> {
  MyAuctions? _mine;

  /// The join codes whose organizer key this browser holds.
  var _keys = <String>{};

  bool _failed = false;

  /// Server clock minus local clock, for the countdowns.
  final _offset = ValueNotifier(Duration.zero);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final mine = await (widget.myAuctions ?? client.organizer.myAuctions)();
      final hasKey =
          widget.hasKey ??
          (code) async => await OrganizerKeys.load(code) != null;
      final keys = <String>{
        for (final a in mine.auctions)
          if (await hasKey(a.auction.code)) a.auction.code,
      };
      if (!mounted) return;
      _offset.value = mine.serverNow.difference(DateTime.now().toUtc());
      setState(() {
        _mine = mine;
        _keys = keys;
      });
    } on Object catch (e) {
      if (!mounted) return;
      if (GavelFailure.from(e) is SignedOut) {
        // The router then sends the organizer to sign in, and back here.
        await client.auth.signOutDevice();
        return;
      }
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = _mine;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: const Text('My auctions'),
      ),
      body: switch ((_failed, mine)) {
        (true, _) => _Problem(onRetry: _load),
        (_, null) => const Center(child: CircularProgressIndicator()),
        (_, MyAuctions(:final auctions)) when auctions.isEmpty =>
          const _Empty(),
        (_, final mine?) => RefreshIndicator(
          onRefresh: _load,
          child: _List(auctions: mine.auctions, keys: _keys, offset: _offset),
        ),
      },
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.auctions,
    required this.keys,
    required this.offset,
  });

  final List<MyAuction> auctions;
  final Set<String> keys;
  final ValueListenable<Duration> offset;

  @override
  Widget build(BuildContext context) {
    final running = [
      for (final a in auctions)
        if (a.auction.status != 'CLOSED') a,
    ];
    final history = [
      for (final a in auctions)
        if (a.auction.status == 'CLOSED') a,
    ];
    Widget row(MyAuction a) =>
        _Row(mine: a, hasKey: keys.contains(a.auction.code), offset: offset);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          // Pull to refresh even when the list is short.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (running.isNotEmpty) ...[
              _Heading('Running', running.length),
              ...running.map(row),
            ],
            if (history.isNotEmpty) ...[
              _Heading('History', history.length),
              ...history.map(row),
            ],
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.label, this.count);

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text('${label.toUpperCase()} · $count', style: Brand.eyebrow),
  );
}

final _closeTime = DateFormat('EEE d MMM, HH:mm');
final _closeDate = DateFormat('d MMM yyyy');

class _Row extends StatelessWidget {
  const _Row({required this.mine, required this.hasKey, required this.offset});

  final MyAuction mine;
  final bool hasKey;
  final ValueListenable<Duration> offset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auction = mine.auction;
    final closed = auction.status == 'CLOSED';
    final muted = theme.textTheme.bodyMedium?.copyWith(color: Brand.muted);
    final lots =
        '${auction.lotCount} ${auction.lotCount == 1 ? 'lot' : 'lots'}';
    return ListTile(
      onTap: () => context.go('/a/${auction.code}/organizer'),
      title: Text(auction.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasKey)
            Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: Brand.muted),
                const SizedBox(width: 4),
                Text('View only on this device', style: muted),
              ],
            ),
          Text(
            closed
                ? '${auction.code} · Closed '
                      '${_closeDate.format(auction.closeAt.toLocal())}'
                : '${auction.code} · Closes '
                      '${_closeTime.format(auction.closeAt.toLocal())} · '
                      '$lots',
            style: muted,
          ),
          if (closed) _Sales(mine: mine, style: muted),
        ],
      ),
      trailing: closed
          ? const Icon(Icons.chevron_right)
          : CountdownText(
              closeAt: auction.closeAt,
              offset: offset,
              style: theme.textTheme.titleMedium,
            ),
    );
  }
}

/// "2 of 3 sold · Rp 500.000 · 1 unpaid", or "No lots sold".
class _Sales extends StatelessWidget {
  const _Sales({required this.mine, this.style});

  final MyAuction mine;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (mine.soldCount == 0) return Text('No lots sold', style: style);
    return Text.rich(
      TextSpan(
        text:
            '${mine.soldCount} of ${mine.auction.lotCount} sold · '
            '${formatRupiah(mine.soldTotal)}',
        children: [
          if (mine.unpaidCount > 0)
            TextSpan(
              text: ' · ${mine.unpaidCount} unpaid',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      style: style,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('No auctions yet', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.go('/new'),
          child: const Text('Create an auction'),
        ),
      ],
    ),
  );
}

class _Problem extends StatelessWidget {
  const _Problem({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Could not load your auctions. Check your connection.'),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
