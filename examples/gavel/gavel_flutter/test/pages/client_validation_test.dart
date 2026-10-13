import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_flutter/pages/create_auction_page.dart';
import 'package:gavel_flutter/pages/home_page.dart';
import 'package:gavel_flutter/pages/lot_form_sheet.dart';
import 'package:gavel_flutter/pages/organizer_page.dart';
import 'package:gavel_flutter/widgets/join_sheet.dart';

/// X5: what the server would refuse is caught before the call.
void main() {
  Future<void> pumpPage(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
  }

  group('create auction', () {
    testWidgets('an empty title shows the error and sends nothing', (
      tester,
    ) async {
      var calls = 0;
      await pumpPage(
        tester,
        CreateAuctionPage(
          create: (_, _) async {
            calls++;
            throw StateError('unreachable');
          },
        ),
      );

      await tester.tap(find.text('Create auction'));
      await tester.pump();

      expect(find.text('The title must be 1 to 80 characters'), findsOneWidget);
      expect(calls, 0);
    });
  });

  group('add lot', () {
    late int calls;

    Future<void> pumpForm(WidgetTester tester) {
      calls = 0;
      return pumpPage(
        tester,
        LotFormSheet(
          code: 'ABC234',
          organizerKey: 'key',
          add: (_, _, _) async {
            calls++;
            throw StateError('unreachable');
          },
        ),
      );
    }

    Future<void> fill(WidgetTester tester, String label, String text) =>
        tester.enterText(find.widgetWithText(TextField, label), text);

    testWidgets('a BN at the open bid shows the inline error and sends '
        'nothing', (tester) async {
      await pumpForm(tester);
      await fill(tester, 'Name', 'Natural Pirus Hubei');
      await fill(tester, 'Open bid', '150000');
      await fill(tester, 'Buy now (BN, optional)', '150000');

      await tester.tap(find.widgetWithText(FilledButton, 'Add lot'));
      await tester.pump();

      expect(
        find.text('The BN price must be above the open bid'),
        findsOneWidget,
      );
      expect(calls, 0);

      // Checked again on every change after a refused submit.
      await fill(tester, 'Buy now (BN, optional)', '150001');
      await tester.pump();
      expect(
        find.text('The BN price must be above the open bid'),
        findsNothing,
      );
    });

    testWidgets('marks every bad field at once', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Add lot'));
      await tester.pump();

      expect(find.text('The name must be 1 to 80 characters'), findsOneWidget);
      expect(find.text('The open bid must be above 0'), findsOneWidget);
      expect(calls, 0);
    });

    testWidgets('a custom step already selected is refused', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.text('custom step'));
      await tester.pump();

      await tester.enterText(find.widgetWithText(TextField, '+'), '25');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.text('Each step must be different'), findsOneWidget);
    });
  });

  group('add lot button', () {
    testWidgets('is disabled at 20 lots', (tester) async {
      var taps = 0;
      Future<void> pumpButton(int lots) => pumpPage(
        tester,
        Scaffold(
          floatingActionButton: AddLotButton(
            lotCount: lots,
            onAdd: () => taps++,
          ),
        ),
      );

      await pumpButton(19);
      await tester.tap(find.text('Add lot'));
      expect(taps, 1);

      await pumpButton(20);
      await tester.tap(find.text('Add lot'));
      expect(taps, 1);
      expect(
        find.byTooltip('An auction takes at most 20 lots'),
        findsOneWidget,
      );
    });
  });

  group('join', () {
    testWidgets('a 25-rune name is refused before the call', (tester) async {
      var calls = 0;
      await pumpPage(
        tester,
        Scaffold(
          body: JoinSheet(
            code: 'ABC234',
            join: (_, _) async {
              calls++;
              throw StateError('unreachable');
            },
          ),
        ),
      );

      // 18 letters and a seven-rune family: 19 graphemes, 25 runes.
      await tester.enterText(find.byType(TextField), '${'a' * 18}👨‍👩‍👧‍👦');
      await tester.tap(find.text('Join and start bidding'));
      await tester.pump();

      expect(find.text('Use 1 to 24 characters'), findsOneWidget);
      expect(calls, 0);
    });

    testWidgets('a pasted control character is dropped', (tester) async {
      await pumpPage(tester, const Scaffold(body: JoinSheet(code: 'ABC234')));

      await tester.enterText(find.byType(TextField), 'Bu\u0007di');

      expect(find.text('Budi'), findsOneWidget);
    });

    testWidgets('the code field drops O and Open stays disabled at 5 '
        'characters', (tester) async {
      await pumpPage(tester, HomePage(session: ValueNotifier(null)));
      final field = find.widgetWithText(TextField, 'Join code');
      FilledButton open() =>
          tester.widget(find.widgetWithText(FilledButton, 'Open the board'));

      await tester.enterText(field, 'abco23');
      await tester.pump();

      expect(find.text('ABC23'), findsOneWidget);
      expect(open().onPressed, isNull);

      await tester.enterText(field, 'abc234');
      await tester.pump();
      expect(open().onPressed, isNotNull);
    });
  });
}
