import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import 'domain/gavel_domain.dart';
import 'infra/auction_table_projection.dart';
import 'infra/lot_table_projection.dart';
import 'infra/participant_repository.dart';

/// Gavel's TaroDomain definition: the domain from [registerGavel] plus the
/// table-backed read models, with participants in `gavel_participants`.
///
/// Every command is strong (use-cases §5): projections update in the
/// command's transaction, so the read model and the live push are never
/// ahead of or behind the event store.
FrameworkDefinition gavelServerDefinition() =>
    registerGavel(TaroDomain.builder(), participants: ParticipantRepository.new)
        .consistency(ConsistencyMode.strong)
        .snapshotEvery(100)
        // Catch-up runs at least every 5 seconds, so an event that keeps
        // failing is dead-lettered after about 100 seconds instead of
        // stopping its projection for good.
        .catchUpMaxAttempts(20)
        .projection(
          (c) => AuctionTableProjection(
            (c.provider as ServerpodProvider).session,
            processedEvents: c.processedEvents,
          ),
        )
        .projection(
          (c) => LotTableProjection(
            (c.provider as ServerpodProvider).session,
            processedEvents: c.processedEvents,
          ),
        )
        .build();
