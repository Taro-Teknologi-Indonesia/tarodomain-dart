import 'package:tarodomain/tarodomain.dart';

class AccountId extends AggregateId {
  AccountId.generate() : super.generate();
  AccountId.fromExisting(super.uuid) : super.fromExisting();
  AccountId.fromUuidv7(super.uuid) : super.fromUuidv7();
}

class TransferId extends AggregateId {
  TransferId.fromExisting(super.uuid) : super.fromExisting();
}

class MoneyDeposited extends DomainEvent {
  MoneyDeposited({required this.cents});

  final int cents;

  @override
  String get eventName => 'MoneyDeposited';

  @override
  Map<String, Object?> toData() => {'cents': cents};
}

class Deposit extends Command {
  Deposit({
    required this.cents,
    super.id,
    super.correlationId,
    super.causationId,
    super.metadata,
  });

  final int cents;
}

const v4 = '9b2f6c1e-3d4a-4f5b-8c6d-7e8f9a0b1c2d';
const v7 = '01909e3c-4a5b-7c6d-8e7f-0a1b2c3d4e5f';
