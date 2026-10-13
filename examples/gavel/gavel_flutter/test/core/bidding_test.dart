import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/core/bidding.dart';
import 'package:gavel_flutter/core/failures.dart';
import 'package:gavel_flutter/core/identity.dart';

import '../support.dart';

void main() {
  final me = Identity(
    participantId: budi,
    participantKey: 'budi-key',
    displayName: 'Budi',
  );
  late List<({int amount, int version, UuidValue commandId})> sent;
  late List<Object Function()> answers;
  late Bidder bidder;

  setUp(() {
    sent = [];
    answers = [];
    bidder = Bidder(({
      required lotId,
      required identity,
      required amount,
      required expectedVersion,
      required commandId,
    }) async {
      sent.add((
        amount: amount,
        version: expectedVersion,
        commandId: commandId,
      ));
      final answer = answers.removeAt(0)();
      if (answer is LotCard) return answer;
      throw answer;
    });
  });

  test('bids one step over the price, at the version seen', () async {
    final lot = lotCard(version: 3, currentPrice: 200000);
    answers.add(() => lotCard(version: 4, currentPrice: 250000));

    final outcome = await bidder.bid(me, lot, 50000);

    expect(sent.single.amount, 250000);
    expect(sent.single.version, 3);
    expect(
      outcome,
      isA<BidAccepted>().having((o) => o.card.version, 'version', 4),
    );
  });

  test('an outbid is a refusal with the leader', () async {
    answers.add(
      () => domainError('OUTBID', {
        'currentPrice': 200000,
        'leaderName': 'Siti',
        'leaderId': siti.uuid,
        'version': 2,
      }),
    );

    final outcome = await bidder.bid(me, lotCard(), 25000);

    expect(
      outcome,
      isA<BidRefused>().having(
        (o) => o.failure,
        'failure',
        isA<Outbid>().having((f) => f.leaderName, 'leaderName', 'Siti'),
      ),
    );
  });

  test('the same bid after a lost answer reuses its command ID', () async {
    answers
      ..add(() => TimeoutException('lost'))
      ..add(() => lotCard(version: 2, currentPrice: 175000));

    final first = await bidder.bid(me, lotCard(), 25000);
    await bidder.bid(me, lotCard(), 25000);

    expect(first, isA<BidRefused>());
    expect(sent[1].commandId, sent[0].commandId);
  });

  test('a different bid after a lost answer gets a new command ID', () async {
    answers
      ..add(() => TimeoutException('lost'))
      ..add(() => lotCard(version: 2, currentPrice: 200000));

    await bidder.bid(me, lotCard(), 25000);
    await bidder.bid(me, lotCard(), 50000);

    expect(sent[1].commandId, isNot(sent[0].commandId));
  });

  test('a bid after an answered one gets a new command ID', () async {
    answers
      ..add(() => lotCard(version: 2, currentPrice: 175000))
      ..add(() => lotCard(version: 3, currentPrice: 200000));

    await bidder.bid(me, lotCard(), 25000);
    await bidder.bid(me, lotCard(), 25000);

    expect(sent[1].commandId, isNot(sent[0].commandId));
  });
}
