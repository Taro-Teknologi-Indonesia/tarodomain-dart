import 'package:serverpod/serverpod.dart';

import '../db/taro_db.dart';
import '../generated/protocol.dart';

/// Assigns global positions to committed events, which order cursor reads
/// (spec §18).
///
/// A position handed out when an event is inserted, such as an
/// auto-increment ID, follows insert order, but readers see events in
/// commit order: a reader that moves its cursor past position 11 skips 10
/// if 10's transaction commits later. So appends leave `position` null, and
/// [run] assigns positions in a transaction of its own. A transaction only
/// sees committed events, so no event gets a position before it has
/// committed, and none committed later can get a lower one.
///
/// Positions come from the `event-position` counter, claimed with a
/// compare-and-set, so concurrent runs never hand out the same position and
/// a position is never reused after its event is deleted. Within a run,
/// events get positions in insert order. Per-stream order holds: appending
/// version n+1 waits on the stream row until version n has committed.
final class EventSequencer {
  /// Creates the sequencer on [session].
  EventSequencer(Session session, {this.batchSize = 500})
    : _db = TaroDb(session);

  /// How many events one transaction positions at most.
  final int batchSize;

  final TaroDb _db;

  static const _counter = 'event-position';
  static const _attempts = 10;

  /// Positions every committed event that has none and returns how many it
  /// positioned.
  ///
  /// Runs in its own transactions, even inside a unit of work. On SQLite,
  /// which has one writer, don't call it while a unit of work is active on
  /// the same database: it would wait on that transaction.
  Future<int> run() async {
    if (!await _hasPending()) return 0;
    var total = 0;
    while (true) {
      final positioned = await _runBatch();
      total += positioned;
      if (positioned < batchSize) return total;
    }
  }

  /// Like [run], but stops as soon as another run claims the counter first,
  /// instead of retrying, and returns how many this call positioned.
  ///
  /// For reads: the other run is positioning the same events, and the claim
  /// waited until it committed, so they are already visible. Retrying would
  /// only make concurrent readers fight over the counter, and [run] throws
  /// after losing [_attempts] times in a row.
  Future<int> tryRun() async {
    if (!await _hasPending()) return 0;
    var total = 0;
    while (true) {
      final positioned = await _db.separately(_claimAndPosition);
      if (positioned == null) return total;
      total += positioned;
      if (positioned < batchSize) return total;
    }
  }

  /// Whether any visible event still has no position. One lookup on the
  /// `position` index, outside any transaction, so a read with nothing to
  /// position costs one query instead of a transaction and two.
  Future<bool> _hasPending() async =>
      await _db.findFirstRow<TaroEventRow>(
        where: TaroEventRow.t.position.equals(null),
      ) !=
      null;

  Future<int> _runBatch() async {
    for (var attempt = 1; ; attempt++) {
      final positioned = await _db.separately(_claimAndPosition);
      if (positioned != null) return positioned;
      if (attempt == _attempts) {
        throw StateError(
          'EventSequencer lost the position counter $_attempts times in a row',
        );
      }
    }
  }

  /// Positions one batch, or returns null if another run claimed the
  /// counter first.
  Future<int?> _claimAndPosition() async {
    final counters = TaroCounterRow.t;
    var counter = await _db.findFirstRow<TaroCounterRow>(
      where: counters.name.equals(_counter),
    );
    if (counter == null) {
      await _db.insert<TaroCounterRow>([
        TaroCounterRow(name: _counter, value: 0),
      ], ignoreConflicts: true);
      counter = (await _db.findFirstRow<TaroCounterRow>(
        where: counters.name.equals(_counter),
      ))!;
    }

    final events = TaroEventRow.t;
    final pending = await _db.find<TaroEventRow>(
      where: events.position.equals(null),
      orderBy: events.id,
      limit: batchSize,
    );
    if (pending.isEmpty) return 0;

    // Claiming the counter locks its row until this transaction ends, so
    // runs that read the same value fail here and retry.
    final last = counter.value;
    final claimed = await _db.updateWhere<TaroCounterRow>(
      columnValues: [ColumnValue(counters.value, last + pending.length)],
      where: counters.name.equals(_counter) & counters.value.equals(last),
    );
    if (claimed.isEmpty) return null;

    for (final (i, row) in pending.indexed) {
      await _db.updateWhere<TaroEventRow>(
        columnValues: [ColumnValue(events.position, last + i + 1)],
        where: events.id.equals(row.id),
        noReturn: true,
      );
    }
    return pending.length;
  }
}
