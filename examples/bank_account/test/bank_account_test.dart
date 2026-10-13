import 'package:bank_account/bank_account.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

void main() {
  for (final mode in ConsistencyMode.values) {
    group('the bank scenario, ${mode.name} by default', () {
      late TaroDomain bank;
      late AccountBalances balances;
      final alice = AccountId.generate();
      final bob = AccountId.generate();

      Future<BankAccount> account(AccountId id) =>
          bank.repository<BankAccount, AccountId>().load(id);
      Future<MoneyTransfer> transfer(TransferId id) =>
          bank.repository<MoneyTransfer, TransferId>().load(id);

      setUp(() async {
        bank = bankDefinition(consistency: mode).createRuntime();
        balances = bank.di.resolve(accountBalances);
        await bank.dispatch(OpenAccount(alice, 'Alice'));
        await bank.dispatch(OpenAccount(bob, 'Bob'));
        await bank.dispatch(DepositMoney(alice, 10000));
      });

      test('opening and depositing', () async {
        expect((await account(alice)).balanceCents, 10000);
        expect(balances[alice]?.owner, 'Alice');
        expect(balances[alice]?.balanceCents, 10000);
        expect(balances[bob]?.balanceCents, 0);
      });

      test('opening an account twice is rejected', () async {
        await expectLater(
          bank.dispatch(OpenAccount(alice, 'Mallory')),
          throwsA(isA<AggregateAlreadyExistsError>()),
        );
      });

      test('a transfer moves the money through the saga', () async {
        final command = TransferMoney(
          TransferId.generate(),
          from: alice,
          to: bob,
          cents: 3000,
        );
        await bank.dispatch(command);

        expect(
          (await transfer(command.transferId)).status,
          TransferStatus.completed,
        );
        expect((await account(alice)).balanceCents, 7000);
        expect((await account(bob)).balanceCents, 3000);
        expect(
          [for (final r in balances.richestFirst) r.owner],
          ['Alice', 'Bob'],
        );
        expect(balances.totalCents, 10000);

        final saga = await bank.sagaStore.load(
          'TransferSaga',
          command.correlationId,
        );
        expect(saga?.status, SagaStatus.completed);
      });

      test('a transfer without enough money fails', () async {
        final command = TransferMoney(
          TransferId.generate(),
          from: bob,
          to: alice,
          cents: 1,
        );
        await bank.dispatch(command);

        final failed = await transfer(command.transferId);
        expect(failed.status, TransferStatus.failed);
        expect(failed.failureReason, 'insufficient funds');
        expect(balances[bob]?.rejectedWithdrawals, 1);
        expect(balances.totalCents, 10000);
      });

      test('the correlation trace links the whole transfer', () async {
        final command = TransferMoney(
          TransferId.generate(),
          from: alice,
          to: bob,
          cents: 3000,
        );
        await bank.dispatch(command);

        final entries = await bank.trace(command.correlationId);
        expect(
          [for (final e in entries) e.eventType],
          [
            'TransferRequested',
            'MoneyWithdrawn',
            'MoneyDeposited',
            'TransferCompleted',
          ],
        );
        final tree = CorrelationTrace.buildTree(
          entries,
          correlationId: command.correlationId,
        );
        // root -> command -> event -> command -> event ...: one chain.
        var node = tree;
        var depth = 0;
        while (node.children.isNotEmpty) {
          expect(node.children, hasLength(1));
          node = node.children.single;
          depth++;
        }
        expect(depth, 8);
        expect(node.entry?.eventType, 'TransferCompleted');
      });

      test('a rebuilt projection matches the live one', () async {
        await bank.dispatch(
          TransferMoney(TransferId.generate(), from: alice, to: bob, cents: 1),
        );
        final before = {
          for (final r in balances.richestFirst) r.owner: r.balanceCents,
        };
        final result = await bank.projectionRebuilder.rebuild(
          bank.projection('balances'),
        );
        expect(result.completed, isTrue);
        expect({
          for (final r in balances.richestFirst) r.owner: r.balanceCents,
        }, before);
      });

      test('scheduled catch-up finds nothing left to do', () async {
        final result = await bank.runScheduled();
        expect(result.catchUp.every((r) => r.error == null), isTrue);
        expect(result.timeouts['TransferSaga'], isEmpty);
        expect(await bank.subscriptions.areAllCaughtUp(), isTrue);
      });
    });
  }

  group('TransferSaga', () {
    final from = AccountId.generate();
    final to = AccountId.generate();
    final transferId = TransferId.generate();

    TransferSaga withdrawn() => TransferSaga()
      ..handle(
        TransferRequested(
          transferId.uuid,
          from: from.uuid,
          to: to.uuid,
          cents: 500,
        ),
      )
      ..handle(MoneyWithdrawn(from.uuid, 500));

    test('a timeout after the withdrawal refunds it and fails', () {
      final saga = withdrawn();
      final now = DateTime.timestamp();
      final timeout = SagaTimeout.forRecord(
        SagaRecord(
          sagaId: saga.sagaId!,
          sagaType: saga.sagaType,
          correlationId: saga.sagaId!,
          state: saga.toSaveInput().state,
          status: SagaStatus.running,
          startedAt: now,
          updatedAt: now,
        ),
        const Duration(minutes: 5),
      );

      final commands = saga.handle(timeout);
      expect(commands, [isA<DepositMoney>(), isA<FailTransfer>()]);
      final refund = commands.first as DepositMoney;
      expect((refund.accountId, refund.cents), (from, 500));

      // The refund's deposit doesn't complete the transfer.
      expect(saga.handle(MoneyDeposited(from.uuid, 500)), isEmpty);
      saga.handle(TransferFailed(transferId.uuid, 'timeout'));
      expect(saga.status, SagaStatus.failed);
      expect(saga.failureReason, 'timeout');
    });
  });
}
