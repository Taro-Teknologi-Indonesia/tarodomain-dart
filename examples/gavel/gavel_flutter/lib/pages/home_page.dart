import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gavel_client/rules.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';
import '../core/input_formatters.dart';
import '../core/money.dart';
import '../theme.dart';
import '../widgets/brand.dart';

/// The front door: what Gavel is, the live demo, creating an auction, and
/// entering a join code (UC-01, UC-03, X2).
class HomePage extends StatefulWidget {
  const HomePage({@visibleForTesting this.session, super.key});

  /// The organizer's session, signed in when its value isn't null (X6);
  /// the app's client unless a test passes one.
  final ValueListenable<Object?>? session;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _join() {
    final code = JoinCodeRules.normalize(_code.text);
    if (JoinCodeRules.isValid(code)) context.go('/a/$code');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final gutter = constraints.maxWidth < 600 ? 16.0 : 32.0;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(
                wide: wide,
                gutter: gutter,
                onDemo: () => context.go('/demo'),
                onCreate: () => context.go('/new'),
                session: widget.session ?? client.auth.authInfoListenable,
              ),
              _Section(
                gutter: gutter,
                // Pulled up over the hero's edge.
                child: Transform.translate(
                  offset: const Offset(0, -40),
                  child: _JoinCard(code: _code, onJoin: _join),
                ),
              ),
              _Section(
                gutter: gutter,
                child: _HowItWorks(wide: wide),
              ),
              const SizedBox(height: 72),
              _Section(
                gutter: gutter,
                child: _TrustGrid(wide: wide),
              ),
              const SizedBox(height: 72),
              _FinalCall(gutter: gutter, onDemo: () => context.go('/demo')),
              _Footer(gutter: gutter),
            ],
          ),
        );
      },
    ),
  );
}

/// [child] centred at most 1080 px wide, with the page's side gutter.
class _Section extends StatelessWidget {
  const _Section({required this.gutter, required this.child});

  final double gutter;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: gutter),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: child,
      ),
    ),
  );
}

/// The dark band: the promise, the two ways in, and a lot taking bids.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.wide,
    required this.gutter,
    required this.onDemo,
    required this.onCreate,
    required this.session,
  });

  final bool wide;
  final double gutter;
  final VoidCallback onDemo;
  final VoidCallback onCreate;
  final ValueListenable<Object?> session;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final pitch = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LiveTag('Live silent auctions for collectors'),
        const SizedBox(height: 20),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(text: 'Every bid live.\nEvery close '),
              TextSpan(
                text: 'on time.',
                style: TextStyle(color: Brand.gold),
              ),
            ],
          ),
          style: Brand.display.copyWith(
            fontSize: narrow ? 40 : 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Gavel turns your lelang post into a live auction room. Bidders '
            'join from one link, tap to raise, and watch every bid land in '
            'real time. Then the hammer falls exactly at the deadline: no '
            'comment scrolling, no "who was first?"',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: narrow ? 16 : 18,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onDemo,
              style: Brand.goldButton.copyWith(
                minimumSize: const WidgetStatePropertyAll(Size(64, 56)),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 28),
                ),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(
                    fontFamily: Brand.sans,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Try the live demo'),
            ),
            OutlinedButton.icon(
              onPressed: onCreate,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(64, 56),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
              ),
              icon: const Icon(Icons.gavel_rounded, size: 20),
              label: const Text('Create an auction'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Wrap(
          spacing: 20,
          runSpacing: 8,
          children: [
            _Assurance('No sign-up, just a name'),
            _Assurance('Nothing to install'),
            _Assurance('Every bid on the record'),
          ],
        ),
      ],
    );
    return DecoratedBox(
      decoration: Brand.band,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 104),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const GavelLogo(),
                      const Spacer(),
                      // Only a signed-in organizer has auctions to list
                      // (UC-15) or anything to sign out of (X6). From here
                      // no redirect follows.
                      ValueListenableBuilder(
                        valueListenable: session,
                        builder: (context, signedIn, _) {
                          final white = TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          );
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (signedIn != null)
                                TextButton(
                                  onPressed: () => context.go('/mine'),
                                  style: white,
                                  child: const Text('My auctions'),
                                ),
                              TextButton(
                                onPressed: onCreate,
                                style: white,
                                child: const Text('For sellers'),
                              ),
                              if (signedIn != null)
                                TextButton(
                                  onPressed: client.auth.signOutDevice,
                                  style: white,
                                  child: const Text('Sign out'),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: wide ? 72 : 40),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 6, child: pitch),
                        const SizedBox(width: 56),
                        const Expanded(flex: 5, child: _ExampleLot()),
                      ],
                    )
                  else ...[
                    pitch,
                    const SizedBox(height: 48),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: const _ExampleLot(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A red dot and a capitalised line, as a broadcast's LIVE tag.
class _LiveTag extends StatelessWidget {
  const _LiveTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Brand.live,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: Brand.eyebrow.copyWith(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}

class _Assurance extends StatelessWidget {
  const _Assurance(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.check_circle_rounded, size: 18, color: Brand.gold),
      const SizedBox(width: 6),
      Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ],
  );
}

/// An illustrative lot taking bids on a loop, labelled as an example: what
/// a bidder sees, before they've opened anything.
class _ExampleLot extends StatefulWidget {
  const _ExampleLot();

  @override
  State<_ExampleLot> createState() => _ExampleLotState();
}

class _ExampleLotState extends State<_ExampleLot> {
  static const _script = [
    ('Sari', 25000),
    ('Budi', 50000),
    ('Rina', 25000),
    ('Andi', 100000),
    ('Sari', 25000),
    ('Dewi', 50000),
  ];
  static const _open = 150000;

  late final Timer _timer;
  var _step = 0;
  var _price = _open;
  var _bids = 0;
  String? _leader;
  int? _tapped;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2400), (_) => _next());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _next() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    setState(() {
      if (_step == _script.length) {
        _step = 0;
        _price = _open;
        _bids = 0;
        _leader = null;
        _tapped = null;
        return;
      }
      final (name, raise) = _script[_step++];
      _price += raise;
      _bids++;
      _leader = name;
      _tapped = raise;
    });
  }

  @override
  Widget build(BuildContext context) {
    final leader = _leader;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 60,
                offset: const Offset(0, 30),
              ),
              BoxShadow(
                color: Brand.gold.withValues(alpha: 0.18),
                blurRadius: 80,
                spreadRadius: -10,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [Color(0xFF2F6F62), Color(0xFF173A33)],
                          radius: 0.9,
                        ),
                      ),
                      child: Center(child: _Cabochon()),
                    ),
                    // The demo's turquoise, served beside the app; the drawn
                    // stone shows while it loads, or if it doesn't.
                    Image.network(
                      'lots/pirus-hubei.jpg',
                      fit: BoxFit.cover,
                      frameBuilder: (_, child, frame, synchronous) =>
                          AnimatedOpacity(
                            opacity: synchronous || frame != null ? 1 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: child,
                          ),
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _Pill(
                        color: Brand.live,
                        child: const Text('● LIVE'),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: _Pill(
                        color: Colors.black.withValues(alpha: 0.55),
                        child: Text('$_bids bids'),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _Pill(
                        color: Colors.black.withValues(alpha: 0.55),
                        child: const Text('⏱ 04:12'),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Natural Pirus Hubei',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Brand.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Eyebrow(leader == null ? 'Opening bid' : 'Current bid'),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      child: Text(
                        formatRupiah(_price),
                        key: ValueKey(_price),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Brand.ink,
                          fontFeatures: Brand.tabular,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        key: ValueKey(leader),
                        children: [
                          if (leader != null) ...[
                            BidderAvatar(leader, size: 22),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            leader == null ? 'No bids yet' : '$leader leads',
                            style: const TextStyle(
                              color: Brand.muted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final step in const [25000, 50000, 100000]) ...[
                          if (step != 25000) const SizedBox(width: 8),
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _tapped == step
                                    ? Brand.gold
                                    : Brand.goldTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    formatStep(step),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Brand.ink,
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(_price + step),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Brand.muted,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: Brand.tabular,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Example lot: what bidders see, one tap per raise',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// A polished green stone, drawn so it never depends on an emoji font: the
/// example lot's visual until its photo loads.
class _Cabochon extends StatelessWidget {
  const _Cabochon();

  @override
  Widget build(BuildContext context) => Container(
    width: 128,
    height: 96,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.elliptical(64, 48)),
      gradient: const RadialGradient(
        center: Alignment(-0.35, -0.45),
        radius: 0.95,
        colors: [Color(0xFF9BE7C4), Color(0xFF2FA374), Color(0xFF0B4A33)],
        stops: [0, 0.45, 1],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: const Align(
      alignment: Alignment(-0.45, -0.55),
      child: SizedBox(
        width: 34,
        height: 16,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.elliptical(17, 8)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCCFFFFFF), Color(0x00FFFFFF)],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        fontFeatures: Brand.tabular,
      ),
      child: child,
    ),
  );
}

/// Entering a code from a seller's post.
class _JoinCard extends StatelessWidget {
  const _JoinCard({required this.code, required this.onJoin});

  final TextEditingController code;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = TextField(
      controller: code,
      maxLength: JoinCodeRules.length,
      inputFormatters: [JoinCodeFormatter()],
      textCapitalization: TextCapitalization.characters,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 4,
      ),
      decoration: const InputDecoration(
        labelText: 'Join code',
        hintText: 'ABC234',
        counterText: '',
        prefixIcon: Icon(Icons.tag_rounded),
      ),
      onSubmitted: (_) => onJoin(),
    );
    final button = ListenableBuilder(
      listenable: code,
      builder: (context, _) => FilledButton(
        onPressed: JoinCodeRules.isValid(JoinCodeRules.normalize(code.text))
            ? onJoin
            : null,
        style: FilledButton.styleFrom(minimumSize: const Size(160, 56)),
        child: const Text('Open the board'),
      ),
    );
    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Brand.line),
          boxShadow: [
            BoxShadow(
              color: Brand.ink.withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final heading = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Got a join code?', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  "It's the six letters in the seller's post. Bidding starts "
                  'the moment you pick a name.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Brand.muted,
                  ),
                ),
              ],
            );
            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading,
                  const SizedBox(height: 16),
                  field,
                  const SizedBox(height: 12),
                  button,
                ],
              );
            }
            return Row(
              children: [
                Expanded(flex: 5, child: heading),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: field),
                const SizedBox(width: 12),
                button,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Three steps from a seller's post to a paid winner.
class _HowItWorks extends StatelessWidget {
  const _HowItWorks({required this.wide});

  final bool wide;

  static const _steps = [
    (
      Icons.inventory_2_outlined,
      'Create and add lots',
      'Pick one close time, then add each lot with its photo, open bid and '
          'kelipatan, just like your usual post.',
    ),
    (
      Icons.share_outlined,
      'Share one link',
      'Paste it in your Facebook group. Bidders join with only a name and '
          'raise with one tap.',
    ),
    (
      Icons.gavel_rounded,
      'The hammer falls',
      'Every lot closes on the server clock, to the second. Winners get a '
          'code that you check before you hand the lot over.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = [
      for (final (i, (icon, title, body)) in _steps.indexed)
        _StepCard(number: i + 1, icon: icon, title: title, body: body),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('How it works', color: Brand.goldDeep),
        const SizedBox(height: 8),
        Text(
          'From lelang post to live room in two minutes',
          style: Brand.display.copyWith(
            fontSize: wide ? 40 : 30,
            color: Brand.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Everything a Facebook auction does, minus the comment chaos.',
          style: theme.textTheme.bodyLarge?.copyWith(color: Brand.muted),
        ),
        const SizedBox(height: 32),
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, card) in cards.indexed) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(child: card),
                ],
              ],
            ),
          )
        else
          for (final (i, card) in cards.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            card,
          ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.body,
  });

  final int number;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Brand.goldTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Brand.goldDeep),
                ),
                const Spacer(),
                Text(
                  '0$number',
                  style: Brand.display.copyWith(
                    fontSize: 28,
                    color: Brand.line,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Brand.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Why a buyer and a seller can trust the result.
class _TrustGrid extends StatelessWidget {
  const _TrustGrid({required this.wide});

  final bool wide;

  static const _points = [
    (
      Icons.receipt_long_outlined,
      'Every bid on the record',
      'The ledger is append-only. A retracted bid stays visible, struck '
          'through, so nobody can quietly rewrite history.',
    ),
    (
      Icons.timer_outlined,
      'Closes on the second',
      "The server's clock decides, not the last comment. Every phone counts "
          'down to the same moment.',
    ),
    (
      Icons.verified_user_outlined,
      'Winner codes',
      'Each winner gets a private code. Sellers hand a lot over only when '
          'the code matches.',
    ),
    (
      Icons.bolt_outlined,
      'Live everywhere',
      'Phones, laptops and the projector update the instant a bid lands. '
          'No refreshing.',
    ),
    (
      Icons.history_rounded,
      'Replay any moment',
      'Scrub back to see exactly who led a lot at any second, rebuilt from '
          'its events.',
    ),
    (
      Icons.tv_outlined,
      'Big-screen mode',
      'Running a live event? Put the board on a projector and let the room '
          'watch the hammer fall.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final columns = wide
        ? 3
        : (MediaQuery.sizeOf(context).width >= 600 ? 2 : 1);
    final rows = <Widget>[];
    for (var i = 0; i < _points.length; i += columns) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = i; j < i + columns; j++) ...[
                if (j > i) const SizedBox(width: 16),
                Expanded(
                  child: j < _points.length
                      ? _TrustPoint(_points[j])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Built for trust', color: Brand.goldDeep),
        const SizedBox(height: 8),
        Text(
          'Fair for bidders. Safe for sellers.',
          style: Brand.display.copyWith(
            fontSize: wide ? 40 : 30,
            color: Brand.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No more disputes over who bid first or whether a winner is real.',
          style: theme.textTheme.bodyLarge?.copyWith(color: Brand.muted),
        ),
        const SizedBox(height: 32),
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: 16),
          row,
        ],
      ],
    );
  }
}

class _TrustPoint extends StatelessWidget {
  const _TrustPoint(this.point);

  final (IconData, String, String) point;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, title, body) = point;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Brand.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Brand.goldDeep, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Brand.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The closing invitation into the always-open demo (X2).
class _FinalCall extends StatelessWidget {
  const _FinalCall({required this.gutter, required this.onDemo});

  final double gutter;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    return _Section(
      gutter: gutter,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(narrow ? 28 : 48),
        decoration: Brand.band.copyWith(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            const _LiveTag('Open right now'),
            const SizedBox(height: 16),
            Text(
              'A demo auction is taking bids now',
              textAlign: TextAlign.center,
              style: Brand.display.copyWith(
                fontSize: narrow ? 28 : 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                'It closes and reopens every 15 minutes. Open it in two '
                'windows and try to outbid yourself before the hammer falls.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onDemo,
              style: Brand.goldButton.copyWith(
                minimumSize: const WidgetStatePropertyAll(Size(220, 56)),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Join the live demo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.gutter});

  final double gutter;

  @override
  Widget build(BuildContext context) => _Section(
    gutter: gutter,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 12,
        children: [
          const GavelLogo(size: 24, onDark: false),
          Text(
            'Built with Flutter and Serverpod · every bid an event',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Brand.muted),
          ),
        ],
      ),
    ),
  );
}
