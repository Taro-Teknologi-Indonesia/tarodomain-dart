import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  // The local provider's eventual bus also delivers in the caller's zone, so
  // both modes run the saga re-entrantly: each command the saga dispatches
  // publishes the next event before the saga has been saved.
  for (final mode in ConsistencyMode.values) {
    group('TransferMoney saga, ${mode.name}', () {
      late TransferHarness h;

      setUp(() => h = TransferHarness(mode));

      test('happy path', () async {
        await h.openWallets();
        final request = await h.requestTransfer(cents: 30, fee: 5);

        expect(h.sentTypes, [
          'Withdraw',
          'DepositMoney',
          'ChargeFee',
          'CompleteTransfer',
        ]);
        expect(await h.balance(h.from), 65);
        expect(await h.balance(h.to), 30);
        expect(await h.transferStatus(), 'completed');

        final record = (await h.sagaRecord(request))!;
        expect(record.status, SagaStatus.completed);
        expect(record.currentStep, 'completedWhenTransferCompleted');
        expect(record.completedAt, isNotNull);
        expect(record.failureReason, isNull);
      });

      test('every command and event shares the correlation ID', () async {
        await h.openWallets();
        final request = await h.requestTransfer();

        for (final command in h.sent) {
          expect(command.correlationId, request.correlationId);
          expect(command.causationId, isNotNull);
        }
        final events = [
          ...await h.stream('Transfer', h.transferId),
          ...(await h.stream('Wallet', h.from)).skip(1),
          ...(await h.stream('Wallet', h.to)).skip(1),
        ];
        expect(events, hasLength(5));
        for (final event in events) {
          expect(event.correlationId, request.correlationId);
        }
        // The deposit was caused by the command the saga dispatched when
        // the withdrawal happened.
        final deposit = h.sent.whereType<DepositMoney>().single;
        final withdrawn = (await h.stream(
          'Wallet',
          h.from,
        )).whereType<MoneyWithdrawn>().single;
        expect(deposit.causationId, withdrawn.id);
      });

      test('a rejected deposit refunds the withdrawal', () async {
        await h.openWallets(toFrozen: true);
        final request = await h.requestTransfer(cents: 30);

        expect(h.sentTypes, [
          'Withdraw',
          'DepositMoney',
          'Refund',
          'FailTransfer',
        ]);
        expect(await h.balance(h.from), 100);
        expect(await h.balance(h.to), 0);
        expect(await h.transferStatus(), 'failed');

        final record = (await h.sagaRecord(request))!;
        expect(record.status, SagaStatus.failed);
        expect(record.failureReason, 'compensated');
        expect(record.completedAt, isNotNull);
      });

      test('a rejected fee undoes both steps in reverse order', () async {
        await h.openWallets(fromCents: 100);
        final request = await h.requestTransfer(cents: 100, fee: 5);

        expect(h.sentTypes, [
          'Withdraw',
          'DepositMoney',
          'ChargeFee',
          'ReverseDeposit',
          'Refund',
          'FailTransfer',
        ]);
        expect(await h.balance(h.from), 100);
        expect(await h.balance(h.to), 0);
        expect(
          (await h.stream('Wallet', h.to)).map((e) => e.eventName).toList(),
          ['WalletOpened', 'MoneyDeposited', 'DepositReversed'],
        );
        expect((await h.sagaRecord(request))!.status, SagaStatus.failed);
      });

      test('a rejected withdrawal fails without compensating', () async {
        await h.openWallets(fromCents: 10);
        final request = await h.requestTransfer(cents: 30);

        expect(h.sentTypes, ['Withdraw', 'FailTransfer']);
        expect(await h.balance(h.from), 10);
        final record = (await h.sagaRecord(request))!;
        expect(record.status, SagaStatus.failed);
        expect(record.failureReason, 'insufficient funds');
      });

      test('redelivering a handled event does nothing', () async {
        await h.openWallets();
        await h.requestTransfer();
        final sent = h.sent.length;

        for (final event in await h.stream('Transfer', h.transferId)) {
          await h.saga.handle(event);
        }
        for (final event in await h.stream('Wallet', h.from)) {
          await h.saga.handle(event);
        }
        expect(h.sent, hasLength(sent));
      });

      test('events for a finished saga are skipped', () async {
        await h.openWallets();
        final request = await h.requestTransfer();
        final sent = h.sent.length;

        // A new event in the same trace that the saga would react to.
        final late = ExecutionContext.run(
          ExecutionContext.forCommand(request),
          () => MoneyWithdrawn(1),
        );
        await h.saga.handle(late);

        expect(h.sent, hasLength(sent));
        expect(
          await h.processedEvents.exists(
            'TransferSaga',
            request.correlationId.uuid,
            late.id,
          ),
          isTrue,
        );
      });

      test('events of other traces are ignored', () async {
        await h.openWallets();
        expect(h.sent, isEmpty);
        expect(await h.sagaStore.count(sagaType: 'TransferSaga'), 0);
      });
    });
  }

  group('dispatch failure', () {
    late TransferHarness h;

    setUp(() => h = TransferHarness(ConsistencyMode.eventual));

    test('leaves the saga unsaved, so a retry starts over', () async {
      await h.openWallets();
      h.failOn = (command) => command is Withdraw;

      final request = h.requestTransfer();
      await expectLater(request, throwsA(isA<EventHandlerFailedError>()));
      final requested = (await h.stream('Transfer', h.transferId)).single;
      final sagaId = requested.correlationId;
      expect(await h.sagaStore.load('TransferSaga', sagaId), isNull);
      expect(
        await h.processedEvents.exists(
          'TransferSaga',
          sagaId.uuid,
          requested.id,
        ),
        isFalse,
      );

      // Redelivery, as the catch-up subscription would do.
      h.failOn = null;
      await h.saga.handle(requested);
      expect(
        (await h.sagaStore.load('TransferSaga', sagaId))!.status,
        SagaStatus.completed,
      );
      expect(h.sentTypes, [
        'Withdraw',
        'Withdraw',
        'DepositMoney',
        'ChargeFee',
        'CompleteTransfer',
      ]);
    });

    test('mid-saga keeps the last saved step', () async {
      await h.openWallets();
      h.failOn = (command) => command is ChargeFee;

      await expectLater(h.requestTransfer(), throwsA(anything));

      // Eventual: the withdrawal and deposit committed on their own, and
      // the saga was saved after each step that completed.
      final record = (await h.sagaStore.loadByStatus(
        SagaStatus.running,
      )).single;
      expect(record.currentStep, 'continueWhenMoneyWithdrawn');
      expect(await h.balance(h.from), 70);
      expect(await h.balance(h.to), 30);
    });
  });

  test(
    'eventual: a crash after dispatch does not run commands twice',
    () async {
      final h = TransferHarness(ConsistencyMode.eventual);
      await h.openWallets();
      h.sagaStore.failSave = (input) => input.status == SagaStatus.running;

      // The withdrawal commits, then saving the saga fails.
      await expectLater(h.requestTransfer(), throwsA(anything));
      expect(await h.balance(h.from), 70);
      expect(await h.sagaStore.count(), 0);

      // Redelivery runs the saga again from scratch.
      h.sagaStore.failSave = null;
      final requested = (await h.stream('Transfer', h.transferId)).single;
      await h.saga.handle(requested);

      final withdrawals = h.sent.whereType<Withdraw>().toList();
      expect(withdrawals, hasLength(2));
      expect(withdrawals[1].id, withdrawals[0].id);
      expect(await h.balance(h.from), 70, reason: 'withdrawn once');

      // The duplicate published nothing, so catch-up delivers the original
      // MoneyWithdrawn, and the saga carries on.
      final withdrawn = (await h.stream('Wallet', h.from)).last;
      await h.saga.handle(withdrawn);
      expect(await h.balance(h.from), 65);
      expect(await h.balance(h.to), 30);
      expect(await h.transferStatus(), 'completed');
    },
  );

  test(
    'strong: a failure anywhere in the saga rolls back the request',
    () async {
      final h = TransferHarness(ConsistencyMode.strong);
      await h.openWallets();
      h.failOn = (command) => command is ChargeFee;

      await expectLater(h.requestTransfer(), throwsA(anything));

      expect(await h.stream('Transfer', h.transferId), isEmpty);
      expect(await h.balance(h.from), 100);
      expect(await h.balance(h.to), 0);
      expect(await h.sagaStore.count(sagaType: 'TransferSaga'), 0);
      expect(await h.processedEvents.count('TransferSaga'), 0);
    },
  );
}
