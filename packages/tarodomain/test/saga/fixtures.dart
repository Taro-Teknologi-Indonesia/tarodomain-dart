import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';

class WalletId extends AggregateId {
  WalletId.generate() : super.generate();
  WalletId.fromExisting(super.uuid) : super.fromExisting();
}

class TransferId extends AggregateId {
  TransferId.generate() : super.generate();
  TransferId.fromExisting(super.uuid) : super.fromExisting();
}

// ---------------------------------------------------------------------------
// Wallet: rejections are events, not errors, so the saga can react to them.

sealed class WalletEvent extends DomainEvent {
  WalletEvent(this.cents);

  final int cents;

  @override
  Map<String, Object?> toData() => {'cents': cents};
}

class WalletOpened extends WalletEvent {
  WalletOpened(super.cents, {this.frozen = false});

  final bool frozen;

  @override
  String get eventName => 'WalletOpened';

  @override
  Map<String, Object?> toData() => {'cents': cents, 'frozen': frozen};
}

class MoneyWithdrawn extends WalletEvent {
  MoneyWithdrawn(super.cents);

  @override
  String get eventName => 'MoneyWithdrawn';
}

class WithdrawalRejected extends WalletEvent {
  WithdrawalRejected(super.cents);

  @override
  String get eventName => 'WithdrawalRejected';
}

class MoneyDeposited extends WalletEvent {
  MoneyDeposited(super.cents);

  @override
  String get eventName => 'MoneyDeposited';
}

class DepositRejected extends WalletEvent {
  DepositRejected(super.cents);

  @override
  String get eventName => 'DepositRejected';
}

class FeeCharged extends WalletEvent {
  FeeCharged(super.cents);

  @override
  String get eventName => 'FeeCharged';
}

class FeeRejected extends WalletEvent {
  FeeRejected(super.cents);

  @override
  String get eventName => 'FeeRejected';
}

class MoneyRefunded extends WalletEvent {
  MoneyRefunded(super.cents);

  @override
  String get eventName => 'MoneyRefunded';
}

class DepositReversed extends WalletEvent {
  DepositReversed(super.cents);

  @override
  String get eventName => 'DepositReversed';
}

class Wallet extends AggregateRoot<WalletId, WalletEvent> {
  Wallet(super.id);

  factory Wallet.open(WalletId id, int cents, {bool frozen = false}) =>
      Wallet(id)..raise(WalletOpened(cents, frozen: frozen));

  int balance = 0;
  bool frozen = false;

  void withdraw(int cents) => raise(
    cents <= balance ? MoneyWithdrawn(cents) : WithdrawalRejected(cents),
  );

  void deposit(int cents) =>
      raise(frozen ? DepositRejected(cents) : MoneyDeposited(cents));

  void chargeFee(int cents) =>
      raise(cents <= balance ? FeeCharged(cents) : FeeRejected(cents));

  void refund(int cents) => raise(MoneyRefunded(cents));

  void reverseDeposit(int cents) => raise(DepositReversed(cents));

  @override
  void apply(WalletEvent event) => switch (event) {
    WalletOpened(:final cents, :final frozen) => (
      balance = cents,
      this.frozen = frozen,
    ),
    MoneyWithdrawn(:final cents) ||
    FeeCharged(:final cents) ||
    DepositReversed(:final cents) => balance -= cents,
    MoneyDeposited(:final cents) ||
    MoneyRefunded(:final cents) => balance += cents,
    WithdrawalRejected() || DepositRejected() || FeeRejected() => null,
  };

  @override
  Map<String, Object?> toSnapshot() => {'balance': balance, 'frozen': frozen};

  @override
  void restoreSnapshotState(Map<String, Object?> data) {
    balance = data['balance']! as int;
    frozen = data['frozen']! as bool;
  }
}

// ---------------------------------------------------------------------------
// Transfer

sealed class TransferEvent extends DomainEvent {}

class TransferRequested extends TransferEvent {
  TransferRequested({
    required this.transferId,
    required this.from,
    required this.to,
    required this.cents,
    required this.fee,
  });

  factory TransferRequested.fromData(Map<String, Object?> data) =>
      TransferRequested(
        transferId: data['transferId']! as String,
        from: data['from']! as String,
        to: data['to']! as String,
        cents: data['cents']! as int,
        fee: data['fee']! as int,
      );

  final String transferId;
  final String from;
  final String to;
  final int cents;
  final int fee;

  @override
  String get eventName => 'TransferRequested';

  @override
  Map<String, Object?> toData() => {
    'transferId': transferId,
    'from': from,
    'to': to,
    'cents': cents,
    'fee': fee,
  };
}

class TransferCompleted extends TransferEvent {
  @override
  String get eventName => 'TransferCompleted';

  @override
  Map<String, Object?> toData() => {};
}

class TransferFailed extends TransferEvent {
  TransferFailed(this.reason);

  final String reason;

  @override
  String get eventName => 'TransferFailed';

  @override
  Map<String, Object?> toData() => {'reason': reason};
}

class Transfer extends AggregateRoot<TransferId, TransferEvent> {
  Transfer(super.id);

  factory Transfer.request(RequestTransfer command) =>
      Transfer(command.transferId)..raise(
        TransferRequested(
          transferId: '${command.transferId}',
          from: '${command.from}',
          to: '${command.to}',
          cents: command.cents,
          fee: command.fee,
        ),
      );

  String status = 'none';

  void complete() => raise(TransferCompleted());

  void fail(String reason) => raise(TransferFailed(reason));

  @override
  void apply(TransferEvent event) => status = switch (event) {
    TransferRequested() => 'requested',
    TransferCompleted() => 'completed',
    TransferFailed() => 'failed',
  };

  @override
  Map<String, Object?> toSnapshot() => {'status': status};

  @override
  void restoreSnapshotState(Map<String, Object?> data) =>
      status = data['status']! as String;
}

EventRegistry transferRegistry() {
  WalletEvent Function(Map<String, Object?>) cents(
    WalletEvent Function(int cents) create,
  ) =>
      (data) => create(data['cents']! as int);

  return EventRegistry()
    ..register(
      'WalletOpened',
      (data) =>
          WalletOpened(data['cents']! as int, frozen: data['frozen']! as bool),
    )
    ..register('MoneyWithdrawn', cents(MoneyWithdrawn.new))
    ..register('WithdrawalRejected', cents(WithdrawalRejected.new))
    ..register('MoneyDeposited', cents(MoneyDeposited.new))
    ..register('DepositRejected', cents(DepositRejected.new))
    ..register('FeeCharged', cents(FeeCharged.new))
    ..register('FeeRejected', cents(FeeRejected.new))
    ..register('MoneyRefunded', cents(MoneyRefunded.new))
    ..register('DepositReversed', cents(DepositReversed.new))
    ..register('TransferRequested', TransferRequested.fromData)
    ..register('TransferCompleted', (_) => TransferCompleted())
    ..register(
      'TransferFailed',
      (data) => TransferFailed(data['reason']! as String),
    );
}

// ---------------------------------------------------------------------------
// Commands

class OpenWallet extends Command {
  OpenWallet(this.walletId, this.cents, {this.frozen = false});

  final WalletId walletId;
  final int cents;
  final bool frozen;
}

/// A command that changes one wallet by [cents].
abstract class WalletCommand extends Command {
  WalletCommand(this.walletId, this.cents);

  final WalletId walletId;
  final int cents;

  void applyTo(Wallet wallet);

  @override
  String toString() => '$runtimeType($cents)';
}

class Withdraw extends WalletCommand {
  Withdraw(super.walletId, super.cents);

  @override
  void applyTo(Wallet wallet) => wallet.withdraw(cents);
}

class DepositMoney extends WalletCommand {
  DepositMoney(super.walletId, super.cents);

  @override
  void applyTo(Wallet wallet) => wallet.deposit(cents);
}

class ChargeFee extends WalletCommand {
  ChargeFee(super.walletId, super.cents);

  @override
  void applyTo(Wallet wallet) => wallet.chargeFee(cents);
}

class Refund extends WalletCommand {
  Refund(super.walletId, super.cents);

  @override
  void applyTo(Wallet wallet) => wallet.refund(cents);
}

class ReverseDeposit extends WalletCommand {
  ReverseDeposit(super.walletId, super.cents);

  @override
  void applyTo(Wallet wallet) => wallet.reverseDeposit(cents);
}

class RequestTransfer extends Command {
  RequestTransfer({
    required this.transferId,
    required this.from,
    required this.to,
    required this.cents,
    this.fee = 0,
  });

  final TransferId transferId;
  final WalletId from;
  final WalletId to;
  final int cents;
  final int fee;
}

class CompleteTransfer extends Command {
  CompleteTransfer(this.transferId);

  final TransferId transferId;
}

class FailTransfer extends Command {
  FailTransfer(this.transferId, this.reason);

  final TransferId transferId;
  final String reason;
}

// ---------------------------------------------------------------------------
// The TransferMoney saga

class TransferState {
  const TransferState({
    this.transferId,
    this.from,
    this.to,
    this.cents = 0,
    this.fee = 0,
  });

  factory TransferState.fromJson(Map<String, Object?> json) => TransferState(
    transferId: TransferId.fromExisting(json['transferId']! as String),
    from: WalletId.fromExisting(json['from']! as String),
    to: WalletId.fromExisting(json['to']! as String),
    cents: json['cents']! as int,
    fee: json['fee']! as int,
  );

  final TransferId? transferId;
  final WalletId? from;
  final WalletId? to;
  final int cents;
  final int fee;

  Map<String, Object?> toJson() => {
    'transferId': '$transferId',
    'from': '$from',
    'to': '$to',
    'cents': cents,
    'fee': fee,
  };
}

/// Withdraw from `from`, deposit to `to`, charge the fee to `from`, then
/// complete the transfer. A rejected step undoes the earlier ones in reverse
/// order and fails the transfer.
class TransferSaga extends ProcessManager<TransferState> {
  TransferSaga() : super(const TransferState()) {
    startsWhen<TransferRequested>((e) {
      state = TransferState(
        transferId: TransferId.fromExisting(e.transferId),
        from: WalletId.fromExisting(e.from),
        to: WalletId.fromExisting(e.to),
        cents: e.cents,
        fee: e.fee,
      );
      return [Withdraw(state.from!, state.cents)];
    });
    continueWhen<MoneyWithdrawn>((e) {
      registerCompensation('refundWithdrawal');
      return [DepositMoney(state.to!, state.cents)];
    });
    continueWhen<MoneyDeposited>((e) {
      registerCompensation('reverseDeposit');
      return [ChargeFee(state.from!, state.fee)];
    });
    continueWhen<FeeCharged>((e) => [CompleteTransfer(state.transferId!)]);
    completedWhen<TransferCompleted>((e) => const []);

    compensateWhen<WithdrawalRejected>(
      (e) => [FailTransfer(state.transferId!, 'insufficient funds')],
    );
    compensateWhen<DepositRejected>((e) => getCompensationCommands());
    compensateWhen<FeeRejected>((e) => getCompensationCommands());
    continueWhen<DepositReversed>((e) => const []);
    continueWhen<MoneyRefunded>(
      (e) => [FailTransfer(state.transferId!, 'compensated')],
    );
    completedWhen<TransferFailed>((e) {
      markFailed(e.reason);
      return const [];
    });

    defineCompensation(
      'refundWithdrawal',
      () => [Refund(state.from!, state.cents)],
    );
    defineCompensation(
      'reverseDeposit',
      () => [ReverseDeposit(state.to!, state.cents)],
    );
  }

  @override
  String get sagaType => 'TransferSaga';

  @override
  Map<String, Object?> stateToJson(TransferState state) => state.toJson();

  @override
  TransferState stateFromJson(Map<String, Object?> json) =>
      TransferState.fromJson(json);
}

// ---------------------------------------------------------------------------
// Harness

class TransferHandler<C extends Command>
    extends AggregateCommandHandler<C, Transfer, TransferId> {
  TransferHandler(super.repository);

  @override
  Future<void> handle(C command) async {
    switch (command) {
      case RequestTransfer():
        await save(Transfer.request(command));
      case CompleteTransfer(:final transferId):
        await save((await load(transferId))..complete());
      case FailTransfer(:final transferId, :final reason):
        await save((await load(transferId))..fail(reason));
    }
  }
}

class WalletHandler<C extends Command>
    extends AggregateCommandHandler<C, Wallet, WalletId> {
  WalletHandler(super.repository);

  @override
  Future<void> handle(C command) async {
    switch (command) {
      case OpenWallet(:final walletId, :final cents, :final frozen):
        await save(Wallet.open(walletId, cents, frozen: frozen));
      case WalletCommand(:final walletId):
        final wallet = await load(walletId);
        command.applyTo(wallet);
        await save(wallet);
    }
  }
}

/// A local provider running [TransferSaga], or the saga [create] makes,
/// behind a dispatcher whose default pipeline is [mode]. Every command the
/// saga dispatches is recorded.
class TransferHarness {
  TransferHarness(
    this.mode, {
    ProcessManager<Object?> Function() create = TransferSaga.new,
    LocalDatabase? database,
  }) {
    final provider = LocalProvider(database: database);
    eventStoreAdapter = provider.createEventStoreAdapter();
    final unitOfWork = provider.createUnitOfWork();
    final commands = provider.createCommandIdempotencyStore();
    final concurrency = ConcurrencyChecker(sleep: (_) async {});
    eventStore = EventStore(eventStoreAdapter, transferRegistry());
    sagaStore = FlakySagaStore(provider.createSagaStoreAdapter());
    processedEvents = provider.createProcessedEventStore();

    Repository<A, TId>
    repo<A extends AggregateRoot<TId, DomainEvent>, TId extends AggregateId>(
      CommandHandlerContext context,
      String type,
      A Function(TId) factory,
    ) => EventSourcedRepository<A, TId>(
      eventStore: eventStore,
      eventBus: context.eventBus,
      factory: factory,
      aggregateType: type,
    );

    WalletHandler<C> wallet<C extends Command>(CommandHandlerContext c) =>
        WalletHandler<C>(repo<Wallet, WalletId>(c, 'Wallet', Wallet.new));
    TransferHandler<C> transfer<C extends Command>(CommandHandlerContext c) =>
        TransferHandler<C>(
          repo<Transfer, TransferId>(c, 'Transfer', Transfer.new),
        );

    final registry = CommandRegistry()
      ..register<OpenWallet>('OpenWallet', wallet)
      ..register<Withdraw>('Withdraw', wallet)
      ..register<DepositMoney>('DepositMoney', wallet)
      ..register<ChargeFee>('ChargeFee', wallet)
      ..register<Refund>('Refund', wallet)
      ..register<ReverseDeposit>('ReverseDeposit', wallet)
      ..register<RequestTransfer>('RequestTransfer', transfer)
      ..register<CompleteTransfer>('CompleteTransfer', transfer)
      ..register<FailTransfer>('FailTransfer', transfer);

    dispatcher = CommandDispatcher(
      registry: registry,
      defaultConsistency: mode,
      strong: StrongConsistencyPipeline(
        unitOfWork: unitOfWork,
        eventBus: bus,
        idempotencyStore: commands,
        concurrency: concurrency,
      ),
      eventual: EventualConsistencyPipeline(
        eventBus: bus,
        idempotencyStore: commands,
        concurrency: concurrency,
      ),
    );
    saga = SagaEventHandler(
      create: create,
      sagaStore: sagaStore,
      processedEvents: processedEvents,
      dispatch: (command) async {
        sent.add(command);
        if (failOn?.call(command) ?? false) throw StateError('dispatch down');
        await dispatcher.dispatch(command);
      },
    );
    bus.subscribe(saga);
  }

  final ConsistencyMode mode;
  final bus = InMemoryEventBus();
  late final EventStoreAdapter eventStoreAdapter;
  late final EventStore eventStore;
  late final FlakySagaStore sagaStore;
  late final ProcessedEventStore processedEvents;
  late final CommandDispatcher dispatcher;
  late final SagaEventHandler saga;

  /// Commands the saga dispatched, in order, including failed ones.
  final sent = <Command>[];

  /// Makes the saga's dispatch of matching commands throw.
  bool Function(Command command)? failOn;

  final from = WalletId.generate();
  final to = WalletId.generate();
  final transferId = TransferId.generate();

  Future<void> openWallets({int fromCents = 100, bool toFrozen = false}) async {
    await dispatcher.dispatch(OpenWallet(from, fromCents));
    await dispatcher.dispatch(OpenWallet(to, 0, frozen: toFrozen));
  }

  /// Requests a transfer and returns the command.
  Future<RequestTransfer> requestTransfer({int cents = 30, int fee = 5}) async {
    final command = RequestTransfer(
      transferId: transferId,
      from: from,
      to: to,
      cents: cents,
      fee: fee,
    );
    await dispatcher.dispatch(command);
    return command;
  }

  Future<List<DomainEvent>> stream(String type, AggregateId id) =>
      eventStore.loadStream(StreamIds.forAggregate(type, id));

  Future<int> balance(WalletId id) async {
    final wallet = Wallet(id);
    wallet.loadFromHistory((await stream('Wallet', id)).cast());
    return wallet.balance;
  }

  Future<String> transferStatus() async {
    final transfer = Transfer(transferId);
    transfer.loadFromHistory((await stream('Transfer', transferId)).cast());
    return transfer.status;
  }

  Future<SagaRecord?> sagaRecord(RequestTransfer command) =>
      sagaStore.load(saga.sagaType, command.correlationId);

  List<String> get sentTypes => [for (final c in sent) '${c.runtimeType}'];
}

/// Delegates to a real store; [failSave] can make a save throw, as a crash
/// between dispatching a saga's commands and saving it would.
class FlakySagaStore implements SagaStoreAdapter {
  FlakySagaStore(this.inner);

  final SagaStoreAdapter inner;
  bool Function(SagaSaveInput input)? failSave;

  /// What a failed save throws.
  Object saveError = StateError('saga store down');

  @override
  Future<void> save(SagaSaveInput input) async {
    if (failSave?.call(input) ?? false) throw saveError;
    await inner.save(input);
  }

  @override
  Future<SagaRecord?> load(String sagaType, UuidValue sagaId) =>
      inner.load(sagaType, sagaId);

  @override
  Future<SagaRecord?> loadByCorrelationId(
    String sagaType,
    UuidValue correlationId,
  ) => inner.loadByCorrelationId(sagaType, correlationId);

  @override
  Future<void> complete(String sagaType, UuidValue sagaId) =>
      inner.complete(sagaType, sagaId);

  @override
  Future<void> fail(String sagaType, UuidValue sagaId, String reason) =>
      inner.fail(sagaType, sagaId, reason);

  @override
  Future<List<SagaRecord>> loadByStatus(SagaStatus status, {int? limit}) =>
      inner.loadByStatus(status, limit: limit);

  @override
  Future<List<SagaRecord>> loadTimedOut(
    DateTime before, {
    String? sagaType,
    int? limit,
  }) => inner.loadTimedOut(before, sagaType: sagaType, limit: limit);

  @override
  Future<void> delete(String sagaType, UuidValue sagaId) =>
      inner.delete(sagaType, sagaId);

  @override
  Future<int> count({String? sagaType, SagaStatus? status}) =>
      inner.count(sagaType: sagaType, status: status);
}
