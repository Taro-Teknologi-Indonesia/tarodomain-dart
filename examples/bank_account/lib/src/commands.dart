import 'package:tarodomain/tarodomain.dart';

import 'account.dart';
import 'transfer.dart';

/// Opens an account.
class OpenAccount extends Command {
  /// Creates the command.
  OpenAccount(this.accountId, this.owner);

  /// The new account's ID.
  final AccountId accountId;

  /// The account holder.
  final String owner;
}

/// Pays money into an account.
class DepositMoney extends Command {
  /// Creates the command.
  DepositMoney(this.accountId, this.cents);

  /// The account.
  final AccountId accountId;

  /// The amount, in cents.
  final int cents;
}

/// Pays money out of an account.
class WithdrawMoney extends Command {
  /// Creates the command.
  WithdrawMoney(this.accountId, this.cents);

  /// The account.
  final AccountId accountId;

  /// The amount, in cents.
  final int cents;
}

/// Moves money between two accounts, through [TransferSaga].
class TransferMoney extends Command {
  /// Creates the command.
  TransferMoney(
    this.transferId, {
    required this.from,
    required this.to,
    required this.cents,
  });

  /// The new transfer's ID.
  final TransferId transferId;

  /// The account to take the money from.
  final AccountId from;

  /// The account to pay the money into.
  final AccountId to;

  /// The amount, in cents.
  final int cents;
}

/// Records that a transfer's money arrived.
class CompleteTransfer extends Command {
  /// Creates the command.
  CompleteTransfer(this.transferId);

  /// The transfer.
  final TransferId transferId;
}

/// Records that a transfer failed.
class FailTransfer extends Command {
  /// Creates the command.
  FailTransfer(this.transferId, this.reason);

  /// The transfer.
  final TransferId transferId;

  /// Why it failed.
  final String reason;
}

/// Handles [OpenAccount].
class OpenAccountHandler
    extends AggregateCommandHandler<OpenAccount, BankAccount, AccountId> {
  /// Creates the handler.
  OpenAccountHandler(super.repository);

  @override
  Future<void> handle(OpenAccount command) async {
    if (await exists(command.accountId)) {
      throw AggregateAlreadyExistsError(
        'Account ${command.accountId} already exists',
        context: {'accountId': command.accountId.uuid},
      );
    }
    await save(BankAccount.open(command.accountId, command.owner));
  }
}

/// Handles [DepositMoney] and [WithdrawMoney].
class AccountHandler<C extends Command>
    extends AggregateCommandHandler<C, BankAccount, AccountId> {
  /// Creates the handler.
  AccountHandler(super.repository);

  @override
  Future<void> handle(C command) async {
    switch (command) {
      case DepositMoney(:final accountId, :final cents):
        await save((await load(accountId))..deposit(cents));
      case WithdrawMoney(:final accountId, :final cents):
        await save((await load(accountId))..withdraw(cents));
    }
  }
}

/// Handles [TransferMoney], [CompleteTransfer] and [FailTransfer].
class TransferHandler<C extends Command>
    extends AggregateCommandHandler<C, MoneyTransfer, TransferId> {
  /// Creates the handler.
  TransferHandler(super.repository);

  @override
  Future<void> handle(C command) async {
    switch (command) {
      case TransferMoney(
        :final transferId,
        :final from,
        :final to,
        :final cents,
      ):
        if (from == to) {
          throw CommandValidationError('Cannot transfer to the same account');
        }
        await save(
          MoneyTransfer.request(transferId, from: from, to: to, cents: cents),
        );
      case CompleteTransfer(:final transferId):
        await save((await load(transferId))..complete());
      case FailTransfer(:final transferId, :final reason):
        await save((await load(transferId))..fail(reason));
    }
  }
}
