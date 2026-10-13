import 'package:bank_account/bank_account.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

import 'balances/balance_table_projection.dart';
import 'holders/account_holder.dart';

/// The bank on Serverpod: the `bank_account` example's domain unchanged,
/// plus a state-based [AccountHolder] and a table-backed balance read model.
///
/// Commands default to [consistency]; opening an account and registering a
/// holder are always strong.
FrameworkDefinition bankServerDefinition({
  ConsistencyMode consistency = ConsistencyMode.eventual,
}) => registerBank(TaroDomain.builder())
    .consistency(consistency)
    .snapshotEvery(100)
    .aggregate<AccountHolder, HolderId>(
      'AccountHolder',
      (a) => a
          .stateRepository(AccountHolderRepository.new)
          .event<HolderRegistered>(
            'HolderRegistered',
            HolderRegistered.fromData,
          )
          .event<HolderEmailChanged>(
            'HolderEmailChanged',
            HolderEmailChanged.fromData,
          ),
    )
    .command<RegisterHolder>(
      'RegisterHolder',
      (c) => HolderHandler<RegisterHolder>(c.repository()),
      consistency: ConsistencyMode.strong,
    )
    .command<ChangeHolderEmail>(
      'ChangeHolderEmail',
      (c) => HolderHandler<ChangeHolderEmail>(c.repository()),
    )
    .projection(
      (c) => BalanceTableProjection(
        (c.provider as ServerpodProvider).session,
        processedEvents: c.processedEvents,
      ),
    )
    .build();
