import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';
import 'package:tarodomain_testing/tarodomain_testing.dart';

import 'tables.dart';
import 'test_tools/serverpod_test_tools.dart';

/// The module's own tests run on PostgreSQL. This app runs on SQLite, so
/// the same suites check the module there.
void main() {
  withServerpod(
    'Given the Serverpod provider on SQLite',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, _) {
      providerContract(() async {
        final session = sessionBuilder.build();
        await clearTables(session);
        return ServerpodProvider(session);
      });
    },
  );
}
