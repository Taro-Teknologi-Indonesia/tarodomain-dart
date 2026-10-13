import 'package:bank_account/bank_account.dart';
import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../generated/protocol.dart';

/// Keeps the `bank_account_balances` table up to date (spec §12): the
/// Serverpod counterpart of the in-memory `BalanceProjection`.
///
/// Every write passes the active unit of work's transaction, so the row
/// changes commit with the event's processed record, and with the command
/// itself under strong consistency.
class BalanceTableProjection extends Projection {
  /// Creates the projection on [session].
  BalanceTableProjection(this.session, {required super.processedEvents}) {
    on<AccountOpened>(
      (e) => AccountBalance.db.insertRow(
        session,
        AccountBalance(
          accountId: UuidValue.fromString(e.accountId),
          owner: e.owner,
          balanceCents: 0,
          rejectedWithdrawals: 0,
        ),
        transaction: _transaction,
      ),
    );
    on<MoneyDeposited>((e) => _update(e, (b) => b..balanceCents += e.cents));
    on<MoneyWithdrawn>((e) => _update(e, (b) => b..balanceCents -= e.cents));
    on<WithdrawalRejected>(
      (e) => _update(e, (b) => b..rejectedWithdrawals += 1),
    );
  }

  /// The request's session.
  final Session session;

  @override
  String get name => 'balances';

  Transaction? get _transaction => ServerpodUnitOfWork.transactionOf(session);

  Future<void> _update(
    AccountEvent event,
    AccountBalance Function(AccountBalance) change,
  ) async {
    final row = await AccountBalance.db.findFirstRow(
      session,
      where: (t) => t.accountId.equals(UuidValue.fromString(event.accountId)),
      transaction: _transaction,
    );
    if (row == null) {
      throw StateError('No balance row for account ${event.accountId}');
    }
    await AccountBalance.db.updateRow(
      session,
      change(row),
      transaction: _transaction,
    );
  }

  @override
  Future<void> onRebuildStart() async {
    await AccountBalance.db.deleteWhere(
      session,
      where: (_) => Constant.bool(true),
      transaction: _transaction,
    );
  }
}
