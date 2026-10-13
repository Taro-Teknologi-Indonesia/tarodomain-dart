import 'package:tarodomain/tarodomain.dart';

/// Gavel's TaroDomain definition.
///
/// Every command is strong (use-cases §5): projections update in the
/// command's transaction, so the read model and the live push are never
/// ahead of or behind the event store.
FrameworkDefinition gavelServerDefinition() => TaroDomain.builder()
    .consistency(ConsistencyMode.strong)
    .snapshotEvery(100)
    // Catch-up runs at least every 5 seconds, so an event that keeps failing
    // is dead-lettered after about 100 seconds instead of stopping its
    // projection for good.
    .catchUpMaxAttempts(20)
    .build();
