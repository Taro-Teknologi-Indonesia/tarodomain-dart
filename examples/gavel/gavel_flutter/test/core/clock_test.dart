import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:gavel_flutter/core/clock.dart';

Widget _countdown(DateTime closeAt, {bool closed = false}) => MaterialApp(
  home: CountdownText(
    closeAt: closeAt,
    offset: ValueNotifier(Duration.zero),
    closed: closed,
  ),
);

void main() {
  testWidgets('counts down while open', (tester) async {
    await tester.pumpWidget(
      _countdown(DateTime.now().toUtc().add(const Duration(minutes: 5))),
    );
    expect(find.textContaining(' m '), findsOneWidget);
  });

  testWidgets('says Closing… past the close time until the server closes '
      'the auction', (tester) async {
    final past = DateTime.now().toUtc().subtract(const Duration(seconds: 1));
    await tester.pumpWidget(_countdown(past));
    expect(find.text('Closing…'), findsOneWidget);

    await tester.pumpWidget(_countdown(past, closed: true));
    expect(
      find.text('Closed ${DateFormat('HH:mm').format(past.toLocal())}'),
      findsOneWidget,
    );
  });
}
