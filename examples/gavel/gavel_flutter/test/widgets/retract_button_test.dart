import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/core/identity.dart';
import 'package:gavel_flutter/widgets/retract_button.dart';

import '../support.dart';

final _me = Identity(
  participantId: siti,
  participantKey: 'siti-key',
  displayName: 'Siti',
);

void main() {
  late Completer<LotCard> answer;
  late List<int> versions;
  late List<LotCard> retracted;
  late int stale;
  late int lost;

  setUp(() {
    versions = [];
    retracted = [];
    stale = 0;
    lost = 0;
  });

  Future<void> pump(WidgetTester tester) {
    answer = Completer();
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RetractButton(
              lot: lotCard(
                version: 3,
                currentPrice: 450000,
                leaderId: siti,
                leaderName: 'Siti',
              ),
              bid: ledgerEntry(2, by: siti, name: 'Siti', amount: 450000),
              identity: _me,
              send:
                  ({
                    required lotId,
                    required identity,
                    required expectedVersion,
                    required commandId,
                  }) {
                    versions.add(expectedVersion);
                    return answer.future;
                  },
              onRetracted: retracted.add,
              onStale: () => stale++,
              onNotParticipant: () => lost++,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text('RETRACT Rp 450.000'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retract'));
    await tester.pump();
  }

  testWidgets('asks first with the exact amount, and keeping sends '
      'nothing', (tester) async {
    await pump(tester);

    await tester.tap(find.text('RETRACT Rp 450.000'));
    await tester.pumpAndSettle();

    expect(find.text('Retract your bid of Rp 450.000?'), findsOneWidget);
    expect(
      find.text('Everyone will see it struck through in the history.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Keep bid'));
    await tester.pumpAndSettle();
    expect(versions, isEmpty);
  });

  testWidgets('a retraction names who leads again', (tester) async {
    await pump(tester);

    await confirm(tester);
    expect(versions, [3]);
    answer.complete(lotCard(version: 4, leaderId: budi, leaderName: 'Budi'));
    await tester.pump();

    expect(retracted.single.version, 4);
    expect(
      find.text('Bid retracted — Budi leads again at Rp 150.000'),
      findsOneWidget,
    );
  });

  testWidgets('retracting the only bid goes back to the open bid', (
    tester,
  ) async {
    await pump(tester);

    await confirm(tester);
    answer.complete(lotCard(version: 4));
    await tester.pump();

    expect(
      find.text('Bid retracted — back to the open bid of Rp 150.000'),
      findsOneWidget,
    );
  });

  testWidgets('NOT_LATEST says someone bid after', (tester) async {
    await pump(tester);

    await confirm(tester);
    answer.completeError(
      domainError('RETRACT_NOT_ALLOWED', {'reason': 'NOT_LATEST'}),
    );
    await tester.pump();

    expect(
      find.text("Someone bid after you — you can't retract now."),
      findsOneWidget,
    );
    expect(retracted, isEmpty);
  });

  testWidgets('OUTBID refetches and says to check again', (tester) async {
    await pump(tester);

    await confirm(tester);
    answer.completeError(
      domainError('OUTBID', {
        'currentPrice': 475000,
        'leaderName': 'Siti',
        'leaderId': siti.uuid,
        'version': 4,
      }),
    );
    await tester.pump();

    expect(stale, 1);
    expect(find.text('The lot changed — check again.'), findsOneWidget);
  });

  testWidgets('LOT_CLOSED says so', (tester) async {
    await pump(tester);

    await confirm(tester);
    answer.completeError(
      domainError('LOT_CLOSED', {'closedAt': '2026-10-14T14:03:00.000Z'}),
    );
    await tester.pump();

    expect(find.text('Lot closed.'), findsOneWidget);
  });

  testWidgets('a forgotten identity asks to join again', (tester) async {
    await pump(tester);

    await confirm(tester);
    answer.completeError(domainError('NOT_PARTICIPANT'));
    await tester.pump();

    expect(lost, 1);
  });
}
