import 'package:gavel_server/src/generated/protocol.dart';
import 'package:serverpod/protocol.dart' show FutureCallEntry;
import 'package:serverpod/serverpod.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Protocol;

/// Deletes every row of the TaroDomain module's tables, the app's own and
/// the scheduled future calls, so each test starts empty.
Future<void> clearTables(Session session) async {
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
  await AuctionView.db.deleteWhere(session, where: (_) => everything);
  await LotCard.db.deleteWhere(session, where: (_) => everything);
  await LedgerEntry.db.deleteWhere(session, where: (_) => everything);
  await FutureCallEntry.db.deleteWhere(session, where: (_) => everything);
}
