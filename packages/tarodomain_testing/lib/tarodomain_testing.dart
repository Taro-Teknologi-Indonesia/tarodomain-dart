/// Contract test suites that every TaroDomain provider must pass.
///
/// Call [providerContract] from a test file to run every suite against a
/// provider, or one suite, such as [eventStoreAdapterContract], to test a
/// single adapter. Each suite registers its tests in a `group`.
library;

export 'src/concurrency_contract.dart';
export 'src/dead_letter_store_contract.dart';
export 'src/event_store_adapter_contract.dart';
export 'src/fixtures.dart';
export 'src/idempotency_store_contracts.dart';
export 'src/provider_contract.dart';
export 'src/saga_store_adapter_contract.dart';
export 'src/snapshot_store_adapter_contract.dart';
export 'src/unit_of_work_contract.dart';
