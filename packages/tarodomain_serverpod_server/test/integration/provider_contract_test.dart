import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';
import 'package:tarodomain_testing/tarodomain_testing.dart';

import 'tables.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  // The suites race appends and run real transactions, which the default
  // per-test rollback (one shared transaction) doesn't allow.
  withServerpod(
    'Given the Serverpod provider on PostgreSQL',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, _) {
      providerContract(() async {
        final session = sessionBuilder.build();
        await clearTaroTables(session);
        return ServerpodProvider(session);
      });
    },
  );
}
