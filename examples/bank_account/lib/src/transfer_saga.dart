import 'package:tarodomain/tarodomain.dart';

import 'account.dart';
import 'commands.dart';
import 'transfer.dart';

/// What [TransferSaga] remembers between events.
class TransferSagaState {
  /// Creates the state.
  const TransferSagaState({
    this.transferId,
    this.from,
    this.to,
    this.cents = 0,
  });

  /// Reads the state back from [toJson]'s output.
  factory TransferSagaState.fromJson(Map<String, Object?> json) =>
      TransferSagaState(
        transferId: json['transferId'] as String?,
        from: json['from'] as String?,
        to: json['to'] as String?,
        cents: json['cents']! as int,
      );

  /// The transfer.
  final String? transferId;

  /// The account to take the money from.
  final String? from;

  /// The account to pay the money into.
  final String? to;

  /// The amount, in cents.
  final int cents;

  /// The state as JSON.
  Map<String, Object?> toJson() => {
    'transferId': transferId,
    'from': from,
    'to': to,
    'cents': cents,
  };
}

/// Moves the money of a requested transfer (spec §13): withdraw from the
/// source account, deposit into the target account, then complete the
/// transfer. A rejected withdrawal fails the transfer. If the transfer
/// stalls after the withdrawal, the timeout refunds the source account.
class TransferSaga extends ProcessManager<TransferSagaState> {
  /// Creates an unstarted saga.
  TransferSaga() : super(const TransferSagaState()) {
    startsWhen<TransferRequested>((e) {
      state = TransferSagaState(
        transferId: e.transferId,
        from: e.from,
        to: e.to,
        cents: e.cents,
      );
      return [WithdrawMoney(_from, e.cents)];
    });
    continueWhen<MoneyWithdrawn>((e) {
      registerCompensation('refund');
      return [DepositMoney(AccountId.fromExisting(state.to!), state.cents)];
    });
    // While compensating, the deposit is the refund, not the transfer.
    continueWhen<MoneyDeposited>(
      (_) => sagaState == SagaState.compensating
          ? const []
          : [CompleteTransfer(_transferId)],
    );
    completedWhen<TransferCompleted>((_) => const []);

    compensateWhen<WithdrawalRejected>(
      (_) => [FailTransfer(_transferId, 'insufficient funds')],
    );
    compensateWhen<SagaTimeout>(
      (_) => [
        ...getCompensationCommands(),
        FailTransfer(_transferId, 'timeout'),
      ],
    );
    completedWhen<TransferFailed>((e) {
      markFailed(e.reason);
      return const [];
    });

    defineCompensation('refund', () => [DepositMoney(_from, state.cents)]);
  }

  AccountId get _from => AccountId.fromExisting(state.from!);

  TransferId get _transferId => TransferId.fromExisting(state.transferId!);

  @override
  String get sagaType => 'TransferSaga';

  @override
  Map<String, Object?> stateToJson(TransferSagaState state) => state.toJson();

  @override
  TransferSagaState stateFromJson(Map<String, Object?> json) =>
      TransferSagaState.fromJson(json);
}
