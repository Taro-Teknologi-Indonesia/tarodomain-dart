import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/pages/my_auctions_page.dart';

final _now = DateTime.now().toUtc();

MyAuction _auction(
  String code,
  String status, {
  int lotCount = 3,
  int soldCount = 0,
  int soldTotal = 0,
  int unpaidCount = 0,
}) => MyAuction(
  auction: AuctionView(
    auctionId: UuidValue.fromString('00000000-0000-4000-8000-0000000000a1'),
    code: code,
    title: 'Auction $code',
    closeAt: status == 'CLOSED'
        ? _now.subtract(const Duration(days: 1))
        : _now.add(const Duration(hours: 1)),
    status: status,
    lotCount: lotCount,
  ),
  soldCount: soldCount,
  soldTotal: soldTotal,
  unpaidCount: unpaidCount,
);

Future<void> _show(
  WidgetTester tester,
  List<MyAuction> auctions, {
  Set<String> keys = const {'RUN234', 'OLD345', 'NIL456'},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MyAuctionsPage(
        myAuctions: () async =>
            MyAuctions(auctions: auctions, serverNow: DateTime.now().toUtc()),
        hasKey: (code) async => keys.contains(code),
      ),
    ),
  );
  await tester.pump();
}

/// Removes the page, so the countdowns' timers stop.
Future<void> _close(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

void main() {
  final running = _auction('RUN234', 'OPEN');
  final sold = _auction(
    'OLD345',
    'CLOSED',
    soldCount: 2,
    soldTotal: 500000,
    unpaidCount: 1,
  );
  final unsold = _auction('NIL456', 'CLOSED');

  testWidgets('splits the auctions into Running and History', (tester) async {
    await _show(tester, [running, sold, unsold]);

    expect(find.text('RUNNING · 1'), findsOneWidget);
    expect(find.text('HISTORY · 2'), findsOneWidget);
    final runningY = tester.getTopLeft(find.text('Auction RUN234')).dy;
    final historyY = tester.getTopLeft(find.text('HISTORY · 2')).dy;
    expect(runningY, lessThan(historyY));
    expect(
      tester.getTopLeft(find.text('Auction OLD345')).dy,
      greaterThan(historyY),
    );
    await _close(tester);
  });

  testWidgets('leaves out a section with nothing in it', (tester) async {
    await _show(tester, [sold]);

    expect(find.text('HISTORY · 1'), findsOneWidget);
    expect(find.textContaining('RUNNING'), findsNothing);
    await _close(tester);
  });

  testWidgets('a past auction shows its sales and unpaid marks', (
    tester,
  ) async {
    await _show(tester, [sold, unsold]);

    expect(
      find.text('2 of 3 sold · Rp 500.000 · 1 unpaid', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('No lots sold'), findsOneWidget);
    await _close(tester);
  });

  testWidgets('with no auctions, offers to create one', (tester) async {
    await _show(tester, []);

    expect(find.text('No auctions yet'), findsOneWidget);
    expect(find.text('Create an auction'), findsOneWidget);
  });

  testWidgets('a row without the organizer key here is view only', (
    tester,
  ) async {
    await _show(tester, [running, sold], keys: {'OLD345'});

    expect(find.text('View only on this device'), findsOneWidget);
    final lockY = tester.getTopLeft(find.text('View only on this device')).dy;
    expect(lockY, lessThan(tester.getTopLeft(find.text('HISTORY · 1')).dy));
    await _close(tester);
  });

  testWidgets('a failed load offers to try again', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MyAuctionsPage(
          myAuctions: () async {
            calls++;
            if (calls == 1) throw Exception('offline');
            return MyAuctions(auctions: const [], serverNow: _now);
          },
          hasKey: (_) async => true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();

    expect(find.text('No auctions yet'), findsOneWidget);
  });
}
