import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/widgets/lot_card_widget.dart';
import 'package:gavel_flutter/widgets/lot_visual.dart';

import '../support.dart';

Widget _app(
  LotCard lot, {
  UuidValue? me,
  Set<String> sharedNames = const {},
  LotCardSize size = LotCardSize.regular,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: SizedBox(
        width: size == LotCardSize.large ? 640 : 360,
        child: LotCardWidget(lot, me: me, sharedNames: sharedNames, size: size),
      ),
    ),
  ),
);

/// The visible text, including that of rich text such as "**You** lead".
String _texts(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .map((t) => t.text.toPlainText())
    .join('\n');

void main() {
  testWidgets('shows the tile when there is no photo', (tester) async {
    await tester.pumpWidget(_app(lotCard()));

    expect(find.byType(TileVisual), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text('🧵'), findsOneWidget);
  });

  testWidgets('falls back to the tile when the photo fails', (tester) async {
    await tester.pumpWidget(
      _app(lotCard(imageUrl: 'https://example.com/batik.jpg')),
    );
    expect(find.byType(Image), findsOneWidget);

    // The test HTTP client answers every request with 400.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.byType(TileVisual), findsOneWidget);
  });

  testWidgets('shows the open bid while nobody has bid', (tester) async {
    await tester.pumpWidget(_app(lotCard()));

    expect(find.text('Rp 150.000'), findsOneWidget);
    expect(find.text('No bids yet — be the first'), findsOneWidget);
    expect(find.text('LIVE'), findsOneWidget);
  });

  testWidgets('names someone else who leads', (tester) async {
    final lot = lotCard(
      version: 2,
      currentPrice: 175000,
      leaderId: siti,
      leaderName: 'Siti',
    );
    await tester.pumpWidget(_app(lot, me: budi));

    expect(find.text('Rp 175.000'), findsOneWidget);
    expect(find.text('Siti leads'), findsOneWidget);
    expect(_texts(tester), isNot(contains('You lead')));
  });

  testWidgets('highlights my lead', (tester) async {
    final lot = lotCard(
      version: 2,
      currentPrice: 175000,
      leaderId: budi,
      leaderName: 'Budi',
    );
    await tester.pumpWidget(_app(lot, me: budi));

    expect(_texts(tester), contains('You lead'));
    expect(find.text('Budi leads'), findsNothing);
  });

  testWidgets('shows a sold lot with its winner', (tester) async {
    final lot = lotCard(
      version: 3,
      currentPrice: 200000,
      status: 'SOLD',
      leaderId: siti,
      leaderName: 'Siti',
      winnerName: 'Siti',
    );
    await tester.pumpWidget(_app(lot, me: budi));

    expect(find.text('SOLD'), findsOneWidget);
    expect(find.text('Siti won'), findsOneWidget);
  });

  testWidgets('tags the winner only when another bidder shares the '
      'name', (tester) async {
    final lot = lotCard(
      version: 3,
      currentPrice: 200000,
      status: 'SOLD',
      leaderId: budi,
      leaderName: 'Budi',
      winnerName: 'Budi',
    );
    await tester.pumpWidget(_app(lot, me: siti, sharedNames: {'budi'}));
    expect(find.text('Budi · #00b1 won'), findsOneWidget);

    await tester.pumpWidget(_app(lot, me: siti));
    expect(find.text('Budi won'), findsOneWidget);
  });

  testWidgets('shows a passed lot', (tester) async {
    await tester.pumpWidget(_app(lotCard(version: 2, status: 'PASSED')));

    expect(find.text('PASSED'), findsOneWidget);
    expect(find.text('No bids — passed'), findsOneWidget);
  });

  group('the BN tag', () {
    testWidgets('shows while the price is below BN', (tester) async {
      await tester.pumpWidget(_app(lotCard(buyNowPrice: 1500000)));

      expect(find.text('BN Rp 1.500.000'), findsOneWidget);
    });

    testWidgets('is absent without a BN price', (tester) async {
      await tester.pumpWidget(_app(lotCard()));

      expect(find.byType(BuyNowTag), findsNothing);
    });

    testWidgets('goes once the price reaches BN', (tester) async {
      final lot = lotCard(
        version: 2,
        currentPrice: 1500000,
        leaderId: siti,
        leaderName: 'Siti',
        buyNowPrice: 1500000,
      );
      await tester.pumpWidget(_app(lot));

      expect(find.byType(BuyNowTag), findsNothing);
    });

    testWidgets('goes once the lot closes', (tester) async {
      await tester.pumpWidget(
        _app(lotCard(version: 2, status: 'PASSED', buyNowPrice: 1500000)),
      );

      expect(find.byType(BuyNowTag), findsNothing);
    });
  });

  testWidgets('slides a new price in', (tester) async {
    await tester.pumpWidget(_app(lotCard()));
    await tester.pumpWidget(
      _app(
        lotCard(
          version: 2,
          currentPrice: 175000,
          leaderId: siti,
          leaderName: 'Siti',
        ),
      ),
    );

    // Both prices show while the new one slides in, then only the new one.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Rp 150.000'), findsOneWidget);
    expect(find.text('Rp 175.000'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Rp 150.000'), findsNothing);
    expect(find.text('Rp 175.000'), findsOneWidget);
  });

  testWidgets('a phone-width list does not overflow', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 740)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LotGrid(
            lots: [lotCard(buyNowPrice: 1500000000)],
            empty: 'No lots yet.',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a desktop grid does not overflow at any width', (tester) async {
    final lots = [
      for (var i = 0; i < 5; i++)
        lotCard(buyNowPrice: 1500000000).copyWith(
          lotId: UuidValue.fromString('00000000-0000-4000-8000-00000000000$i'),
          position: i,
        ),
    ];
    addTearDown(tester.view.reset);
    for (final width in [600.0, 760.0, 1024.0, 1440.0]) {
      tester.view
        ..physicalSize = Size(width, 900)
        ..devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LotGrid(lots: lots, empty: 'No lots yet.'),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'at $width px');
    }
  });

  group('on the big screen', () {
    const large = LotCardSize.large;
    final leading = lotCard(
      version: 2,
      currentPrice: 175000,
      leaderId: siti,
      leaderName: 'Siti',
    );

    testWidgets('slides a new leader in', (tester) async {
      await tester.pumpWidget(_app(leading, size: large));
      await tester.pumpWidget(
        _app(
          lotCard(
            version: 3,
            currentPrice: 200000,
            leaderId: budi,
            leaderName: 'Budi',
          ),
          size: large,
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Siti leads'), findsOneWidget);
      expect(find.text('Budi leads'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Siti leads'), findsNothing);
      expect(find.text('Budi leads'), findsOneWidget);
    });

    testWidgets('flips to the hammer when the lot sells', (tester) async {
      await tester.pumpWidget(_app(leading, size: large));
      await tester.pumpWidget(
        _app(
          lotCard(
            version: 3,
            currentPrice: 175000,
            status: 'SOLD',
            leaderId: siti,
            leaderName: 'Siti',
            winnerName: 'Siti',
            finalPrice: 175000,
          ),
          size: large,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SOLD — Siti — Rp 175.000'), findsOneWidget);
      expect(find.text('🔨'), findsOneWidget);
      expect(find.text('Siti leads'), findsNothing);
    });

    testWidgets('says a passed lot had no bids', (tester) async {
      await tester.pumpWidget(
        _app(lotCard(version: 2, status: 'PASSED'), size: large),
      );

      expect(find.text('PASSED — no bids'), findsOneWidget);
    });

    testWidgets('keeps a fixed number of columns', (tester) async {
      addTearDown(tester.view.reset);
      tester.view
        ..physicalSize = const Size(400, 900)
        ..devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LotGrid(
              lots: [
                for (var i = 1; i <= 2; i++)
                  lotCard().copyWith(
                    lotId: UuidValue.fromString(
                      '00000000-0000-4000-8000-00000000000$i',
                    ),
                    position: i,
                  ),
              ],
              size: large,
              columns: 2,
              empty: 'No lots yet.',
            ),
          ),
        ),
      );

      // Side by side, even under 600 px.
      final cards = find.byType(LotCardWidget);
      expect(
        tester.getTopLeft(cards.at(0)).dy,
        tester.getTopLeft(cards.at(1)).dy,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
