import 'package:tarodomain/tarodomain.dart';

import 'dead_letter_store_contract.dart';
import 'event_store_adapter_contract.dart';
import 'fixtures.dart';
import 'idempotency_store_contracts.dart';
import 'saga_store_adapter_contract.dart';
import 'snapshot_store_adapter_contract.dart';
import 'unit_of_work_contract.dart';

/// Runs every contract suite against the adapters of the providers [create]
/// makes. Each test gets a new provider over empty storage.
///
/// The unit of work suite runs only when [hasUnitOfWork] is true.
void providerContract(
  ContractFactory<Provider> create, {
  bool hasUnitOfWork = true,
}) {
  eventStoreAdapterContract(
    () async => (await create()).createEventStoreAdapter(),
  );
  snapshotStoreAdapterContract(
    () async => (await create()).createSnapshotStoreAdapter(),
  );
  sagaStoreAdapterContract(
    () async => (await create()).createSagaStoreAdapter(),
  );
  processedEventStoreContract(
    () async => (await create()).createProcessedEventStore(),
  );
  commandIdempotencyStoreContract(
    () async => (await create()).createCommandIdempotencyStore(),
  );
  deadLetterStoreContract(() async => (await create()).createDeadLetterStore());
  if (hasUnitOfWork) unitOfWorkContract(create);
}
