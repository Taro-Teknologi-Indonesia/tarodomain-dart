import 'package:serverpod/serverpod.dart';

import '../demo/demo_auctions.dart';

/// Keeps the public demo running (X2).
///
/// `ensureOpen` recurs every 60 seconds where future calls are enabled,
/// with the identifier `gavel-demo`.
class DemoCalls extends FutureCall {
  /// Opens a demo auction unless one is open for at least two more minutes.
  Future<void> ensureOpen(Session session) => ensureDemoOpen(session);
}
