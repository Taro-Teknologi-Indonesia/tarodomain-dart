/// The bank account example from the TaroDomain spec: a BankAccount
/// aggregate, a TransferSaga moving money between accounts, and a
/// BalanceProjection answering balance queries, wired with the builder on
/// the in-memory provider.
library;

export 'src/account.dart';
export 'src/app.dart';
export 'src/balance_projection.dart';
export 'src/commands.dart';
export 'src/transfer.dart';
export 'src/transfer_saga.dart';
