import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';

/// Deletes every row of the module's tables, so each test starts empty.
Future<void> clearTaroTables(Session session) async {
  final everything = Constant.bool(true);
  await TaroEventRow.db.deleteWhere(session, where: (_) => everything);
  await TaroStreamRow.db.deleteWhere(session, where: (_) => everything);
  await TaroSubscriptionRow.db.deleteWhere(session, where: (_) => everything);
  await TaroSnapshotRow.db.deleteWhere(session, where: (_) => everything);
  await TaroSagaRow.db.deleteWhere(session, where: (_) => everything);
  await TaroProcessedEventRow.db.deleteWhere(session, where: (_) => everything);
  await TaroProcessedCommandRow.db.deleteWhere(
    session,
    where: (_) => everything,
  );
  await TaroDeadLetterRow.db.deleteWhere(session, where: (_) => everything);
  await TaroLockRow.db.deleteWhere(session, where: (_) => everything);
  await TaroCounterRow.db.deleteWhere(session, where: (_) => everything);
}
