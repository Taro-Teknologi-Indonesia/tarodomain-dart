import 'package:tarodomain/tarodomain.dart';

/// Identifies a [MoneyTransfer].
class TransferId extends AggregateId {
  /// A new ID.
  TransferId.generate() : super.generate();

  /// An ID read back from storage or a request.
  TransferId.fromExisting(super.uuid) : super.fromExisting();
}

/// Events of a [MoneyTransfer].
sealed class TransferEvent extends DomainEvent {
  TransferEvent(this.transferId);

  /// The transfer the event belongs to.
  final String transferId;
}

/// A transfer between two accounts was requested. Starts [TransferSaga].
class TransferRequested extends TransferEvent {
  /// Creates the event.
  TransferRequested(
    super.transferId, {
    required this.from,
    required this.to,
    required this.cents,
  });

  /// Rebuilds the event from [toData]'s output.
  factory TransferRequested.fromData(Map<String, Object?> data) =>
      TransferRequested(
        data['transferId']! as String,
        from: data['from']! as String,
        to: data['to']! as String,
        cents: data['cents']! as int,
      );

  /// The account to take the money from.
  final String from;

  /// The account to pay the money into.
  final String to;

  /// The amount, in cents.
  final int cents;

  @override
  String get eventName => 'TransferRequested';

  @override
  Map<String, Object?> toData() => {
    'transferId': transferId,
    'from': from,
    'to': to,
    'cents': cents,
  };
}

/// The money arrived.
class TransferCompleted extends TransferEvent {
  /// Creates the event.
  TransferCompleted(super.transferId);

  /// Rebuilds the event from [toData]'s output.
  factory TransferCompleted.fromData(Map<String, Object?> data) =>
      TransferCompleted(data['transferId']! as String);

  @override
  String get eventName => 'TransferCompleted';

  @override
  Map<String, Object?> toData() => {'transferId': transferId};
}

/// The transfer could not be made.
class TransferFailed extends TransferEvent {
  /// Creates the event.
  TransferFailed(super.transferId, this.reason);

  /// Rebuilds the event from [toData]'s output.
  factory TransferFailed.fromData(Map<String, Object?> data) =>
      TransferFailed(data['transferId']! as String, data['reason']! as String);

  /// Why it failed.
  final String reason;

  @override
  String get eventName => 'TransferFailed';

  @override
  Map<String, Object?> toData() => {'transferId': transferId, 'reason': reason};
}

/// The state of a transfer.
enum TransferStatus {
  /// Not requested yet.
  none,

  /// Requested and in progress.
  requested,

  /// The money arrived.
  completed,

  /// It could not be made.
  failed,
}

/// A money transfer between two accounts. The accounts are changed by
/// [TransferSaga]; this aggregate records the request and the outcome.
class MoneyTransfer extends AggregateRoot<TransferId, TransferEvent> {
  /// An empty transfer, before its events are applied.
  MoneyTransfer(super.id);

  /// Requests a transfer of [cents] from [from] to [to].
  factory MoneyTransfer.request(
    TransferId id, {
    required AggregateId from,
    required AggregateId to,
    required int cents,
  }) => MoneyTransfer(id)
    ..raise(
      TransferRequested(id.uuid, from: from.uuid, to: to.uuid, cents: cents),
    );

  /// Where the transfer stands.
  TransferStatus status = TransferStatus.none;

  /// Why the transfer failed, if it did.
  String? failureReason;

  /// Records that the money arrived.
  void complete() {
    _checkInProgress();
    raise(TransferCompleted(id.uuid));
  }

  /// Records that the transfer failed.
  void fail(String reason) {
    _checkInProgress();
    raise(TransferFailed(id.uuid, reason));
  }

  void _checkInProgress() {
    if (status != TransferStatus.requested) {
      throw InvalidAggregateStateError(
        'Transfer $id is ${status.name}',
        context: {'transferId': id.uuid, 'status': status.name},
      );
    }
  }

  @override
  void apply(TransferEvent event) {
    switch (event) {
      case TransferRequested():
        status = TransferStatus.requested;
      case TransferCompleted():
        status = TransferStatus.completed;
      case TransferFailed(:final reason):
        status = TransferStatus.failed;
        failureReason = reason;
    }
  }

  @override
  Map<String, Object?> toSnapshot() => {
    'status': status.name,
    'failureReason': failureReason,
  };

  @override
  void restoreSnapshotState(Map<String, Object?> data) {
    status = TransferStatus.values.byName(data['status']! as String);
    failureReason = data['failureReason'] as String?;
  }
}
