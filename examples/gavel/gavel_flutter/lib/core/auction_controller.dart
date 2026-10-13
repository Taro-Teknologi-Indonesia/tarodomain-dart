import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gavel_client/gavel_client.dart';

import 'failures.dart';
import 'live.dart';

/// One auction as the app holds it: the auction, its lot cards, and the
/// live feed that keeps both current.
class AuctionController extends ChangeNotifier {
  AuctionController(Client client, this.code)
    : live = LiveConnection(client, code);

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

  /// The lots, in the order they were added.
  List<LotCard> get lots =>
      [..._lots.values]..sort((a, b) => a.position.compareTo(b.position));

  /// The lot with [lotId], if the board has it.
  LotCard? lot(UuidValue lotId) => _lots[lotId];

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
      case UpdateArrived(:final update):
        auction = update.auction ?? auction;
        if (update.lot case final lot?) _take(lot);
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
