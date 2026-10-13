import 'package:tarodomain/tarodomain.dart';

import 'account.dart';

/// One row of [AccountBalances].
class AccountSummary {
  /// Creates the row.
  AccountSummary(this.accountId, this.owner);

  /// The account.
  final String accountId;

  /// The account holder.
  final String owner;

  /// The balance, in cents.
  int balanceCents = 0;

  /// How many withdrawals were rejected.
  int rejectedWithdrawals = 0;
}

/// The read model [BalanceProjection] keeps: account balances, queried
/// without loading aggregates.
class AccountBalances {
  final _rows = <String, AccountSummary>{};

  /// The summary of [accountId], or null if it doesn't exist.
  AccountSummary? operator [](AggregateId accountId) => _rows[accountId.uuid];

  /// Every account, richest first.
  List<AccountSummary> get richestFirst =>
      _rows.values.toList()
        ..sort((a, b) => b.balanceCents.compareTo(a.balanceCents));

  /// The sum of every balance.
  int get totalCents => _rows.values.fold(0, (sum, r) => sum + r.balanceCents);

  /// Forgets every account, before a rebuild.
  void clear() => _rows.clear();
}

/// Keeps [AccountBalances] up to date (spec §12).
class BalanceProjection extends Projection {
  /// Creates the projection over [balances].
  BalanceProjection(this.balances, {required super.processedEvents}) {
    on<AccountOpened>(
      (e) => balances._rows[e.accountId] = AccountSummary(e.accountId, e.owner),
    );
    on<MoneyDeposited>((e) => _row(e).balanceCents += e.cents);
    on<MoneyWithdrawn>((e) => _row(e).balanceCents -= e.cents);
    on<WithdrawalRejected>((e) => _row(e).rejectedWithdrawals++);
  }

  /// The read model.
  final AccountBalances balances;

  AccountSummary _row(AccountEvent e) => balances._rows[e.accountId]!;

  @override
  String get name => 'balances';

  @override
  Future<void> onRebuildStart() async => balances.clear();
}
