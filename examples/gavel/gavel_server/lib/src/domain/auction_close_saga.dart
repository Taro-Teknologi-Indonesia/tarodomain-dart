import 'package:tarodomain/tarodomain.dart';

import 'auction.dart';
import 'auction_commands.dart';
import 'lot.dart';
import 'lot_commands.dart';

/// What [AuctionCloseSaga] remembers between events.
class AuctionCloseState {
  /// Creates the state.
  const AuctionCloseState({this.auctionId, this.remaining = const {}});

  /// Reads the state back from [toJson]'s output.
  factory AuctionCloseState.fromJson(Map<String, Object?> json) =>
      AuctionCloseState(
        auctionId: json['auctionId'] as String?,
        remaining: {for (final id in json['remaining']! as List) id as String},
      );

  /// The auction closing.
  final String? auctionId;

  /// The lots whose `LotClosed` hasn't arrived yet.
  final Set<String> remaining;

  /// The state as JSON.
  Map<String, Object?> toJson() => {
    'auctionId': auctionId,
    'remaining': remaining.toList(),
  };
}

/// Closes an auction's lots once the auction closes (UC-08), then
/// finalizes it.
///
/// The deadline itself is a future call (or the sweep) dispatching
/// `CloseAuction`: a saga timeout fires after a saga makes no progress, so
/// it isn't a wall-clock alarm. Here the timeout is the safety net. It
/// covers a lot that closed outside this saga (a Buy Now, UC-13): its
/// `CloseLot` is a no-op that raises nothing, so its `LotClosed` never
/// arrives. On a timeout the saga closes every remaining lot again, which
/// is idempotent, and finalizes.
class AuctionCloseSaga extends ProcessManager<AuctionCloseState> {
  /// Creates an unstarted saga.
  AuctionCloseSaga() : super(const AuctionCloseState()) {
    startsWhen<AuctionClosed>((e) {
      state = AuctionCloseState(
        auctionId: e.auctionId,
        remaining: e.lotIds.toSet(),
      );
      if (e.lotIds.isEmpty) return [FinalizeAuction(_auctionId)];
      return [
        for (final lotId in e.lotIds)
          CloseLot(LotId.fromExisting(lotId), LotCloseCause.deadline),
      ];
    });
    continueWhen<LotClosed>((e) {
      if (!state.remaining.contains(e.lotId)) return const [];
      state = AuctionCloseState(
        auctionId: state.auctionId,
        remaining: {...state.remaining}..remove(e.lotId),
      );
      return state.remaining.isEmpty ? [FinalizeAuction(_auctionId)] : [];
    });
    compensateWhen<SagaTimeout>((_) {
      final remaining = state.remaining;
      state = AuctionCloseState(auctionId: state.auctionId);
      return [
        for (final lotId in remaining)
          CloseLot(LotId.fromExisting(lotId), LotCloseCause.deadline),
        FinalizeAuction(_auctionId),
      ];
    });
    completedWhen<AuctionFinalized>((_) => const []);
  }

  AuctionId get _auctionId => AuctionId.fromExisting(state.auctionId!);

  @override
  String get sagaType => 'AuctionCloseSaga';

  @override
  Map<String, Object?> stateToJson(AuctionCloseState state) => state.toJson();

  @override
  AuctionCloseState stateFromJson(Map<String, Object?> json) =>
      AuctionCloseState.fromJson(json);
}
