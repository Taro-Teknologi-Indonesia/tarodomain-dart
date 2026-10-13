import 'package:bank_account/bank_account.dart';
import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import '../generated/protocol.dart';
import '../holders/account_holder.dart';

/// The bank's API. Each method dispatches one command on a runtime for the
/// request's session; a `FrameworkError` reaches the client as a
/// `TaroDomainException`.
class BankEndpoint extends Endpoint {
  TaroDomainServerpod get _taro => TaroDomainServerpod.instance;

  /// Opens an account for [owner] and returns its ID.
  Future<UuidValue> openAccount(Session session, String owner) async {
    final id = AccountId.generate();
    await _taro.dispatch(session, OpenAccount(id, owner));
    return id.value;
  }

  /// Pays [cents] into [accountId].
  Future<void> deposit(Session session, UuidValue accountId, int cents) async {
    await _taro.dispatch(session, DepositMoney(_account(accountId), cents));
  }

  /// Pays [cents] out of [accountId].
  Future<void> withdraw(Session session, UuidValue accountId, int cents) async {
    await _taro.dispatch(session, WithdrawMoney(_account(accountId), cents));
  }

  /// Starts moving [cents] from [from] to [to] and returns the transfer ID.
  Future<UuidValue> transfer(
    Session session,
    UuidValue from,
    UuidValue to,
    int cents,
  ) async {
    final id = TransferId.generate();
    await _taro.dispatch(
      session,
      TransferMoney(id, from: _account(from), to: _account(to), cents: cents),
    );
    return id.value;
  }

  /// The balance of [accountId] from the read model, or null.
  Future<AccountBalance?> balance(Session session, UuidValue accountId) =>
      AccountBalance.db.findFirstRow(
        session,
        where: (t) => t.accountId.equals(accountId),
      );

  /// Registers an account holder and returns their ID.
  Future<UuidValue> registerHolder(
    Session session,
    String name,
    String email,
  ) async {
    final id = HolderId.generate();
    await _taro.dispatch(session, RegisterHolder(id, name, email));
    return id.value;
  }

  /// Changes a holder's email address.
  Future<void> changeHolderEmail(
    Session session,
    UuidValue holderId,
    String email,
  ) async {
    await _taro.dispatch(
      session,
      ChangeHolderEmail(HolderId.fromExisting(holderId.uuid), email),
    );
  }

  static AccountId _account(UuidValue id) => AccountId.fromExisting(id.uuid);
}
