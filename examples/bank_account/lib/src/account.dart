import 'package:tarodomain/tarodomain.dart';

/// Identifies a [BankAccount].
class AccountId extends AggregateId {
  /// A new ID.
  AccountId.generate() : super.generate();

  /// An ID read back from storage or a request.
  AccountId.fromExisting(super.uuid) : super.fromExisting();
}

/// Events of a [BankAccount]. Each carries the account ID, so projections
/// can key their read models by it.
sealed class AccountEvent extends DomainEvent {
  AccountEvent(this.accountId);

  /// The account the event belongs to.
  final String accountId;
}

/// An account was opened.
class AccountOpened extends AccountEvent {
  /// Creates the event.
  AccountOpened(super.accountId, this.owner);

  /// Rebuilds the event from [toData]'s output.
  factory AccountOpened.fromData(Map<String, Object?> data) =>
      AccountOpened(data['accountId']! as String, data['owner']! as String);

  /// The account holder.
  final String owner;

  @override
  String get eventName => 'AccountOpened';

  @override
  Map<String, Object?> toData() => {'accountId': accountId, 'owner': owner};
}

/// An event that moves money in or out of an account.
sealed class AccountMoneyEvent extends AccountEvent {
  AccountMoneyEvent(super.accountId, this.cents);

  /// The amount, in cents.
  final int cents;

  @override
  Map<String, Object?> toData() => {'accountId': accountId, 'cents': cents};
}

/// Money was paid in.
class MoneyDeposited extends AccountMoneyEvent {
  /// Creates the event.
  MoneyDeposited(super.accountId, super.cents);

  /// Rebuilds the event from [toData]'s output.
  factory MoneyDeposited.fromData(Map<String, Object?> data) =>
      MoneyDeposited(data['accountId']! as String, data['cents']! as int);

  @override
  String get eventName => 'MoneyDeposited';
}

/// Money was paid out.
class MoneyWithdrawn extends AccountMoneyEvent {
  /// Creates the event.
  MoneyWithdrawn(super.accountId, super.cents);

  /// Rebuilds the event from [toData]'s output.
  factory MoneyWithdrawn.fromData(Map<String, Object?> data) =>
      MoneyWithdrawn(data['accountId']! as String, data['cents']! as int);

  @override
  String get eventName => 'MoneyWithdrawn';
}

/// A withdrawal was refused because the balance was too low. It is an event
/// rather than an error, so a transfer saga can react to it.
class WithdrawalRejected extends AccountMoneyEvent {
  /// Creates the event.
  WithdrawalRejected(super.accountId, super.cents);

  /// Rebuilds the event from [toData]'s output.
  factory WithdrawalRejected.fromData(Map<String, Object?> data) =>
      WithdrawalRejected(data['accountId']! as String, data['cents']! as int);

  @override
  String get eventName => 'WithdrawalRejected';
}

/// A bank account (spec §5).
class BankAccount extends AggregateRoot<AccountId, AccountEvent> {
  /// An empty account, before its events are applied.
  BankAccount(super.id);

  /// Opens a new account for [owner].
  factory BankAccount.open(AccountId id, String owner) =>
      BankAccount(id)..raise(AccountOpened(id.uuid, owner));

  /// The account holder.
  String owner = '';

  /// The balance, in cents.
  int balanceCents = 0;

  /// Pays in [cents].
  void deposit(int cents) {
    _checkPositive(cents);
    raise(MoneyDeposited(id.uuid, cents));
  }

  /// Pays out [cents], or records a rejection if the balance is too low.
  void withdraw(int cents) {
    _checkPositive(cents);
    raise(
      cents <= balanceCents
          ? MoneyWithdrawn(id.uuid, cents)
          : WithdrawalRejected(id.uuid, cents),
    );
  }

  static void _checkPositive(int cents) {
    if (cents <= 0) {
      throw CommandValidationError(
        'Amount must be positive: $cents',
        context: {'cents': cents},
      );
    }
  }

  @override
  void apply(AccountEvent event) => switch (event) {
    AccountOpened(:final owner) => this.owner = owner,
    MoneyDeposited(:final cents) => balanceCents += cents,
    MoneyWithdrawn(:final cents) => balanceCents -= cents,
    WithdrawalRejected() => null,
  };

  @override
  Map<String, Object?> toSnapshot() => {
    'owner': owner,
    'balanceCents': balanceCents,
  };

  @override
  void restoreSnapshotState(Map<String, Object?> data) {
    owner = data['owner']! as String;
    balanceCents = data['balanceCents']! as int;
  }
}
