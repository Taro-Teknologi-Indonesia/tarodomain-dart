import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';

import '../saga/fixtures.dart';

export '../saga/fixtures.dart';

/// A read model kept by [LedgerProjection].
class Ledger {
  int totalCents = 0;
  int completedTransfers = 0;
  int failedTransfers = 0;
}

const ledgerToken = Token<Ledger>('ledger');

/// Totals the money in every wallet, and counts finished transfers.
class LedgerProjection extends Projection {
  LedgerProjection(this.ledger, {required super.processedEvents}) {
    on<WalletOpened>((e) => ledger.totalCents += e.cents);
    on<MoneyWithdrawn>((e) => ledger.totalCents -= e.cents);
    on<MoneyDeposited>((e) => ledger.totalCents += e.cents);
    on<FeeCharged>((e) => ledger.totalCents -= e.cents);
    on<MoneyRefunded>((e) => ledger.totalCents += e.cents);
    on<DepositReversed>((e) => ledger.totalCents -= e.cents);
    on<TransferCompleted>((_) => ledger.completedTransfers++);
    on<TransferFailed>((_) => ledger.failedTransfers++);
  }

  final Ledger ledger;

  @override
  String get name => 'ledger';
}

/// Registers every transfer event on [builder].
TaroDomainBuilder transferEvents(TaroDomainBuilder builder) {
  WalletEvent Function(Map<String, Object?>) cents(
    WalletEvent Function(int cents) create,
  ) =>
      (data) => create(data['cents']! as int);

  return builder
      .event<WalletOpened>(
        'WalletOpened',
        (data) => WalletOpened(
          data['cents']! as int,
          frozen: data['frozen']! as bool,
        ),
      )
      .event<WalletEvent>('MoneyWithdrawn', cents(MoneyWithdrawn.new))
      .event<WalletEvent>('WithdrawalRejected', cents(WithdrawalRejected.new))
      .event<WalletEvent>('MoneyDeposited', cents(MoneyDeposited.new))
      .event<WalletEvent>('DepositRejected', cents(DepositRejected.new))
      .event<WalletEvent>('FeeCharged', cents(FeeCharged.new))
      .event<WalletEvent>('FeeRejected', cents(FeeRejected.new))
      .event<WalletEvent>('MoneyRefunded', cents(MoneyRefunded.new))
      .event<WalletEvent>('DepositReversed', cents(DepositReversed.new))
      .event<TransferRequested>('TransferRequested', TransferRequested.fromData)
      .event<TransferCompleted>('TransferCompleted', (_) => TransferCompleted())
      .event<TransferFailed>(
        'TransferFailed',
        (data) => TransferFailed(data['reason']! as String),
      );
}

/// Registers the wallet and transfer aggregates and their commands.
TaroDomainBuilder transferDomain(TaroDomainBuilder builder) {
  WalletHandler<C> wallet<C extends Command>(CommandContext c) =>
      WalletHandler<C>(c.repository());
  TransferHandler<C> transfer<C extends Command>(CommandContext c) =>
      TransferHandler<C>(c.repository());

  return transferEvents(builder)
      .aggregate<Wallet, WalletId>('Wallet', (a) => a.factory(Wallet.new))
      .aggregate<Transfer, TransferId>(
        'Transfer',
        (a) => a.factory(Transfer.new),
      )
      .command<OpenWallet>('OpenWallet', wallet)
      .command<Withdraw>('Withdraw', wallet)
      .command<DepositMoney>('DepositMoney', wallet)
      .command<ChargeFee>('ChargeFee', wallet)
      .command<Refund>('Refund', wallet)
      .command<ReverseDeposit>('ReverseDeposit', wallet)
      .command<RequestTransfer>('RequestTransfer', transfer)
      .command<CompleteTransfer>('CompleteTransfer', transfer)
      .command<FailTransfer>('FailTransfer', transfer);
}

/// The transfer domain with [LedgerProjection] and [TransferSaga], on a
/// fresh local provider, defaulting to [mode].
TaroDomainBuilder transferApp(
  ConsistencyMode mode, {
  LocalDatabase? database,
}) => transferDomain(TaroDomain.builder())
    .useLocal(database: database)
    .consistency(mode)
    .concurrency(ConcurrencyChecker(sleep: (_) async {}))
    .bindSingleton(ledgerToken, (_) => Ledger())
    .projection(
      (c) => LedgerProjection(
        c.resolve(ledgerToken),
        processedEvents: c.processedEvents,
      ),
    )
    .saga(TransferSaga.new);

/// Wallet balances read through the runtime's repository.
Future<int> balanceOf(TaroDomain framework, WalletId id) async =>
    (await framework.repository<Wallet, WalletId>().load(id)).balance;

/// Delegates to a [LocalProvider] but has no unit of work, like a platform
/// without transactions.
class NoTransactionProvider extends Provider {
  final _inner = LocalProvider();

  @override
  String get type => 'no-transactions';

  @override
  EventStoreAdapter createEventStoreAdapter() =>
      _inner.createEventStoreAdapter();

  @override
  SnapshotStoreAdapter createSnapshotStoreAdapter() =>
      _inner.createSnapshotStoreAdapter();

  @override
  SagaStoreAdapter createSagaStoreAdapter() => _inner.createSagaStoreAdapter();

  @override
  ProcessedEventStore createProcessedEventStore() =>
      _inner.createProcessedEventStore();

  @override
  CommandIdempotencyStore createCommandIdempotencyStore() =>
      _inner.createCommandIdempotencyStore();

  @override
  DeadLetterStore createDeadLetterStore() => _inner.createDeadLetterStore();

  @override
  EventBus createEventBus(EventBusConfig config) =>
      _inner.createEventBus(config);

  @override
  UnitOfWork? createUnitOfWork() => null;
}
