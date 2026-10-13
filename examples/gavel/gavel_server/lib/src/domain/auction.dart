import 'package:tarodomain/tarodomain.dart';

import 'errors.dart';
import 'keys.dart';

/// Identifies an [Auction].
class AuctionId extends AggregateId {
  /// A new ID.
  AuctionId.generate() : super.generate();

  /// An ID read back from storage or a request.
  AuctionId.fromExisting(super.uuid) : super.fromExisting();
}

/// Where an auction is in its life.
enum AuctionStatus {
  /// Taking lots and bids.
  open('OPEN'),

  /// Past its close time; its lots are closing.
  closing('CLOSING'),

  /// Every lot is closed.
  closed('CLOSED');

  const AuctionStatus(this.code);

  /// The value stored in the read model and sent to the client.
  final String code;

  /// The status whose [code] is [code].
  static AuctionStatus fromCode(String code) =>
      values.firstWhere((s) => s.code == code);
}

/// Events of an [Auction]. Each carries the auction ID, so projections can
/// key their read models by it.
sealed class AuctionEvent extends DomainEvent {
  AuctionEvent(this.auctionId);

  /// The auction the event belongs to.
  final String auctionId;
}

/// An auction was created.
class AuctionCreated extends AuctionEvent {
  /// Creates the event.
  AuctionCreated(
    super.auctionId, {
    required this.code,
    required this.title,
    required this.closeAt,
    required this.organizerKeyHash,
  });

  /// Rebuilds the event from [toData]'s output.
  factory AuctionCreated.fromData(Map<String, Object?> data) => AuctionCreated(
    data['auctionId']! as String,
    code: data['code']! as String,
    title: data['title']! as String,
    closeAt: DateTime.parse(data['closeAt']! as String),
    organizerKeyHash: data['organizerKeyHash']! as String,
  );

  /// The join code in the share link.
  final String code;

  /// The auction's title.
  final String title;

  /// When the auction closes, in UTC.
  final DateTime closeAt;

  /// The SHA-256 of the organizer key, never the key itself.
  final String organizerKeyHash;

  @override
  String get eventName => 'AuctionCreated';

  @override
  Map<String, Object?> toData() => {
    'auctionId': auctionId,
    'code': code,
    'title': title,
    'closeAt': closeAt.toUtc().toIso8601String(),
    'organizerKeyHash': organizerKeyHash,
  };
}

/// A lot was added to an auction. Recorded on the auction so its close
/// knows the lots without reading a projection.
class LotRegistered extends AuctionEvent {
  /// Creates the event.
  LotRegistered(super.auctionId, {required this.lotId});

  /// Rebuilds the event from [toData]'s output.
  factory LotRegistered.fromData(Map<String, Object?> data) => LotRegistered(
    data['auctionId']! as String,
    lotId: data['lotId']! as String,
  );

  /// The new lot.
  final String lotId;

  @override
  String get eventName => 'LotRegistered';

  @override
  Map<String, Object?> toData() => {'auctionId': auctionId, 'lotId': lotId};
}

/// An auction: a title, a join code and one close time for all its lots.
class Auction extends AggregateRoot<AuctionId, AuctionEvent> {
  /// An empty auction, before its events are applied.
  Auction(super.id);

  /// Creates an auction at [now].
  ///
  /// Throws [CommandValidationError] if the trimmed [title] is empty or
  /// longer than [maxTitleLength], or if [closeAt] is less than
  /// [minimumLeadTime] after [now].
  factory Auction.create(
    AuctionId id, {
    required String title,
    required DateTime closeAt,
    required String code,
    required String organizerKeyHash,
    required DateTime now,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed.length > maxTitleLength) {
      throw CommandValidationError(
        'The title must be 1 to $maxTitleLength characters',
        context: {
          'field': 'title',
          'reason': trimmed.isEmpty ? 'EMPTY' : 'TOO_LONG',
        },
      );
    }
    if (closeAt.isBefore(now.add(minimumLeadTime))) {
      throw CommandValidationError(
        'The auction must close at least '
        '${minimumLeadTime.inMinutes} minutes from now',
        context: {'field': 'closeAt', 'reason': 'TOO_SOON'},
      );
    }
    return Auction(id)..raise(
      AuctionCreated(
        id.uuid,
        code: code,
        title: trimmed,
        closeAt: closeAt.toUtc(),
        organizerKeyHash: organizerKeyHash,
      ),
    );
  }

  /// The longest title, after trimming.
  static const maxTitleLength = 80;

  /// How far ahead of creation the close time must be.
  static const minimumLeadTime = Duration(minutes: 5);

  /// The most lots one auction takes: a sanity cap, not a business rule.
  static const maxLots = 20;

  /// The auction's title.
  String title = '';

  /// The join code in the share link.
  String code = '';

  /// When the auction closes, in UTC.
  DateTime closeAt = DateTime.utc(0);

  /// The SHA-256 of the organizer key.
  String organizerKeyHash = '';

  /// The auction's lots, in the order they were added.
  List<String> lotIds = [];

  /// Where the auction is in its life.
  AuctionStatus status = AuctionStatus.open;

  /// Whether [key] is this auction's organizer key.
  bool isOrganizer(String key) => keyMatches(key, organizerKeyHash);

  /// Adds the lot [lotId] at [now].
  ///
  /// Throws [LotClosedError] if the auction is no longer open or [now] is at
  /// or past [closeAt], and [CommandValidationError] if it already has
  /// [maxLots] lots.
  void registerLot(String lotId, DateTime now) {
    if (status != AuctionStatus.open || !now.isBefore(closeAt)) {
      throw LotClosedError(closedAt: closeAt);
    }
    if (lotIds.length >= maxLots) {
      throw CommandValidationError(
        'An auction takes at most $maxLots lots',
        context: {'field': 'lots', 'reason': 'TOO_MANY'},
      );
    }
    raise(LotRegistered(id.uuid, lotId: lotId));
  }

  @override
  void apply(AuctionEvent event) {
    switch (event) {
      case AuctionCreated():
        title = event.title;
        code = event.code;
        closeAt = event.closeAt;
        organizerKeyHash = event.organizerKeyHash;
      case LotRegistered():
        lotIds = [...lotIds, event.lotId];
    }
  }

  @override
  Map<String, Object?> toSnapshot() => {
    'title': title,
    'code': code,
    'closeAt': closeAt.toIso8601String(),
    'organizerKeyHash': organizerKeyHash,
    'lotIds': lotIds,
    'status': status.code,
  };

  @override
  void restoreSnapshotState(Map<String, Object?> data) {
    title = data['title']! as String;
    code = data['code']! as String;
    closeAt = DateTime.parse(data['closeAt']! as String);
    organizerKeyHash = data['organizerKeyHash']! as String;
    lotIds = [for (final id in data['lotIds']! as List) id as String];
    status = AuctionStatus.fromCode(data['status']! as String);
  }
}
