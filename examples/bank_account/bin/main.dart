import 'package:bank_account/bank_account.dart';

/// Runs the spec's bank scenario on the in-memory provider: open accounts,
/// deposit, transfer through the saga, query the projection and print a
/// correlation trace.
Future<void> main() async {
  final bank = bankDefinition().createRuntime();

  final alice = AccountId.generate();
  final bob = AccountId.generate();
  await bank.dispatch(OpenAccount(alice, 'Alice'));
  await bank.dispatch(OpenAccount(bob, 'Bob'));
  await bank.dispatch(DepositMoney(alice, 10000));

  final transfer = TransferMoney(
    TransferId.generate(),
    from: alice,
    to: bob,
    cents: 3000,
  );
  await bank.dispatch(transfer);
  final tooMuch = TransferMoney(
    TransferId.generate(),
    from: bob,
    to: alice,
    cents: 50000,
  );
  await bank.dispatch(tooMuch);

  final transfers = bank.repository<MoneyTransfer, TransferId>();
  for (final command in [transfer, tooMuch]) {
    final t = await transfers.load(command.transferId);
    print(
      'Transfer of ${_money(command.cents)}: ${t.status.name}'
      '${t.failureReason == null ? '' : ' (${t.failureReason})'}',
    );
  }

  print('\nBalances (from the projection):');
  for (final row in bank.di.resolve(accountBalances).richestFirst) {
    print('  ${row.owner.padRight(6)} ${_money(row.balanceCents)}');
  }

  print('\nTrace of the first transfer:');
  print(await bank.formatTrace(transfer.correlationId));
}

String _money(int cents) =>
    '\$${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';
