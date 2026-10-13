import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';

import 'account.dart';
import 'balance_projection.dart';
import 'commands.dart';
import 'transfer.dart';
import 'transfer_saga.dart';

/// The read model of account balances.
const accountBalances = Token<AccountBalances>('accountBalances');

/// The bank application, configured with the builder (spec §25.1) on the
/// in-memory provider.
///
/// Commands default to [consistency]; opening an account is always strong.
FrameworkDefinition bankDefinition({
  LocalDatabase? database,
  ConsistencyMode consistency = ConsistencyMode.eventual,
}) => registerBank(TaroDomain.builder().useLocal(database: database))
    .consistency(consistency)
    .snapshotEvery(100)
    .bindSingleton(accountBalances, (_) => AccountBalances())
    .projection(
      (c) => BalanceProjection(
        c.resolve(accountBalances),
        processedEvents: c.processedEvents,
      ),
    )
    .build();

/// Registers the bank's aggregates, commands and saga on [builder], with no
/// provider or read model, so other hosts (such as the Serverpod example)
/// reuse the domain unchanged.
TaroDomainBuilder registerBank(TaroDomainBuilder builder) {
  AccountHandler<C> account<C extends Command>(CommandContext c) =>
      AccountHandler<C>(c.repository());
  TransferHandler<C> transfer<C extends Command>(CommandContext c) =>
      TransferHandler<C>(c.repository());

  return builder
      .aggregate<BankAccount, AccountId>(
        'BankAccount',
        (a) => a
            .factory(BankAccount.new)
            .event<AccountOpened>('AccountOpened', AccountOpened.fromData)
            .event<MoneyDeposited>('MoneyDeposited', MoneyDeposited.fromData)
            .event<MoneyWithdrawn>('MoneyWithdrawn', MoneyWithdrawn.fromData)
            .event<WithdrawalRejected>(
              'WithdrawalRejected',
              WithdrawalRejected.fromData,
            ),
      )
      .aggregate<MoneyTransfer, TransferId>(
        'MoneyTransfer',
        (a) => a
            .factory(MoneyTransfer.new)
            .event<TransferRequested>(
              'TransferRequested',
              TransferRequested.fromData,
            )
            .event<TransferCompleted>(
              'TransferCompleted',
              TransferCompleted.fromData,
            )
            .event<TransferFailed>('TransferFailed', TransferFailed.fromData),
      )
      .command<OpenAccount>(
        'OpenAccount',
        (c) => OpenAccountHandler(c.repository()),
        consistency: ConsistencyMode.strong,
      )
      .command<DepositMoney>('DepositMoney', account)
      .command<WithdrawMoney>('WithdrawMoney', account)
      .command<TransferMoney>('TransferMoney', transfer)
      .command<CompleteTransfer>('CompleteTransfer', transfer)
      .command<FailTransfer>('FailTransfer', transfer)
      .saga(TransferSaga.new, timeout: const Duration(minutes: 5));
}
