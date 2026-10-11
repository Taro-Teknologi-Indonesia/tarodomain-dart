import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given the tarodomain_serverpod module', (sessionBuilder, _) {
    test(
      'when the test server starts then migrations apply and the database is reachable',
      () async {
        final session = sessionBuilder.build();
        expect(await session.db.testConnection(), isTrue);
      },
    );
  });
}
