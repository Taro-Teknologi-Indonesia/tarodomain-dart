import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:gavel_client/gavel_client.dart';

import 'failures.dart';
import 'live.dart';

/// One auction as the app holds it: the auction, its lot cards, and the
/// live feed that keeps both current.
class AuctionController extends ChangeNotifier {
  AuctionController(
    Client client,
    this.code, {
    @visibleForTesting Future<LotDetail> Function(UuidValue lotId)? detail,
  }) : live = LiveConnection(client, code),
       _detail = detail ?? client.lot.detail;

  /// The auction's join code.
  final String code;

  /// The feed this controller listens to.
  final LiveConnection live;

  /// The auction, once the first snapshot arrived.
  AuctionView? auction;

  /// Why the auction can't be shown, if it can't.
  GavelFailure? failure;

  final _lots = <UuidValue, LotCard>{};
  StreamSubscription<LiveEvent>? _events;

  final Future<LotDetail> Function(UuidValue lotId) _detail;

  /// The ledgers asked for so far, by lot and then by sequence. Entries
  /// pushed while the first fetch is in flight land here too.
  final _ledgers = <UuidValue, SplayTreeMap<int, LedgerEntry>>{};

  /// The lots whose ledger has been fetched at least once.
  final _ledgersLoaded = <UuidValue>{};

  /// The lots, in the order they were added.
  List<LotCard> get lots =>
      [..._lots.values]..sort((a, b) => a.position.compareTo(b.position));

  /// The lot with [lotId], if the board has it.
  LotCard? lot(UuidValue lotId) => _lots[lotId];

  /// Every bid on [lotId] in ledger order, retracted ones included, or
  /// null until the first fetch answers.
  ///
  /// The first call fetches it; live updates keep it current after, and
  /// every new snapshot (a reconnect) fetches it again, because updates
  /// missed while disconnected are not replayed.
  List<LedgerEntry>? ledgerFor(UuidValue lotId) {
    final ledger = _ledgers[lotId];
    if (ledger == null) {
      _ledgers[lotId] = SplayTreeMap();
      unawaited(_fetchLedger(lotId));
      return null;
    }
    return _ledgersLoaded.contains(lotId) ? [...ledger.values] : null;
  }

  Future<void> _fetchLedger(UuidValue lotId) async {
    final LotDetail detail;
    try {
      detail = await _detail(lotId);
    } catch (_) {
      // Fetched again on the next snapshot, which a reconnect brings.
      return;
    }
    final ledger = _ledgers[lotId];
    if (ledger == null) return;
    for (final entry in detail.ledger) {
      _takeEntry(ledger, entry);
    }
    _ledgersLoaded.add(lotId);
    _take(detail.lot);
    notifyListeners();
  }

  /// Holds [entry] unless the held one says more: a retraction never
  /// comes undone, so a stale fetch can't unstrike a row.
  static void _takeEntry(Map<int, LedgerEntry> ledger, LedgerEntry entry) {
    final held = ledger[entry.sequence];
    if (held != null && held.retracted && !entry.retracted) return;
    ledger[entry.sequence] = entry;
  }

  /// Whether the live stream is connected.
  ValueListenable<LiveStatus> get status => live.status;

  /// Server clock minus local clock, for countdowns.
  ValueListenable<Duration> get clockOffset => live.clockOffset;

  /// Starts the live feed.
  void start() {
    _events = live.events().listen(
      apply,
      onError: (Object e) {
        failure = GavelFailure.from(e);
        notifyListeners();
      },
    );
  }

  /// Fetches the board again and takes every lot newer than the one held,
  /// for when a command's answer says the board is behind and the push
  /// hasn't caught up yet.
  Future<void> refresh() async {
    final snapshot = await live.client.auction.board(code);
    var changed = false;
    for (final lot in snapshot.lots) {
      changed = _take(lot) || changed;
    }
    if (changed) notifyListeners();
  }

  /// Takes [card] unless a newer version of it is already held, such as the
  /// card a command returned racing its own live update.
  void merge(LotCard card) {
    if (_take(card)) notifyListeners();
  }

  /// Holds [card] if it's newer than the one held, and says whether it was.
  bool _take(LotCard card) {
    final held = _lots[card.lotId];
    if (held != null && held.version >= card.version) return false;
    _lots[card.lotId] = card;
    return true;
  }

  /// Folds [event] into the board: a snapshot replaces it, and an update
  /// replaces a lot only with a newer version of it, so a late or replayed
  /// update never rolls a price back.
  @visibleForTesting
  void apply(LiveEvent event) {
    switch (event) {
      case SnapshotArrived(:final snapshot):
        auction = snapshot.auction;
        _lots
          ..clear()
          ..addAll({for (final lot in snapshot.lots) lot.lotId: lot});
        for (final lotId in _ledgers.keys) {
          unawaited(_fetchLedger(lotId));
        }
      case UpdateArrived(:final update):
        auction = update.auction ?? auction;
        if (update.lot case final lot?) _take(lot);
        if (update.ledgerEntry case final entry?) {
          if (_ledgers[entry.lotId] case final ledger?) {
            _takeEntry(ledger, entry);
          }
        }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    unawaited(live.close());
    super.dispose();
  }
}
