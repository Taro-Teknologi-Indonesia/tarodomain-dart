import 'package:tarodomain/tarodomain.dart';

import 'errors.dart';

/// Identifies a [Lot].
class LotId extends AggregateId {
  /// A new ID.
  LotId.generate() : super.generate();

  /// An ID read back from storage or a request.
  LotId.fromExisting(super.uuid) : super.fromExisting();
}

/// Where a lot is in its life.
enum LotStatus {
  /// Taking bids.
  open('OPEN'),

  /// Closed with a winner.
  sold('SOLD'),

  /// Closed with no bid.
  passed('PASSED');

  const LotStatus(this.code);

  /// The value stored in the read model and sent to the client.
  final String code;

  /// The status whose [code] is [code].
  static LotStatus fromCode(String code) =>
      values.firstWhere((s) => s.code == code);
}

/// Events of a [Lot]. Each carries the lot ID, so projections can key their
/// read models by it.
sealed class LotEvent extends DomainEvent {
  LotEvent(this.lotId);

  /// The lot the event belongs to.
  final String lotId;
}

/// A lot was added to an auction.
class LotCreated extends LotEvent {
  /// Creates the event.
  LotCreated(
    super.lotId, {
    required this.auctionId,
    required this.code,
    required this.name,
    required this.openBid,
    required this.increments,
    required this.buyNowPrice,
    required this.description,
    required this.imageUrl,
    required this.tileEmoji,
    required this.tileColor,
    required this.closeAt,
    required this.position,
  });

  /// Rebuilds the event from [toData]'s output.
  factory LotCreated.fromData(Map<String, Object?> data) => LotCreated(
    data['lotId']! as String,
    auctionId: data['auctionId']! as String,
    code: data['code']! as String,
    name: data['name']! as String,
    openBid: data['openBid']! as int,
    increments: [for (final step in data['increments']! as List) step as int],
    buyNowPrice: data['buyNowPrice'] as int?,
    description: data['description']! as String,
    imageUrl: data['imageUrl'] as String?,
    tileEmoji: data['tileEmoji']! as String,
    tileColor: data['tileColor']! as String,
    closeAt: DateTime.parse(data['closeAt']! as String),
    position: data['position']! as int,
  );

  /// The auction the lot belongs to.
  final String auctionId;

  /// The auction's join code, so the lot's projection can post to its live
  /// channel without reading another read model.
  final String code;

  /// The lot's name.
  final String name;

  /// The first bid's minimum, in rupiah.
  final int openBid;

  /// The allowed raises (kelipatan), in rupiah, ascending.
  final List<int> increments;

  /// The Buy Now (BN) price, in rupiah, or null for no BN. Events stored
  /// before BN existed have no key and read as null.
  final int? buyNowPrice;

  /// The seller's description, newlines kept.
  final String description;

  /// A photo of the lot, or null to show the tile.
  final String? imageUrl;

  /// The tile's emoji, shown when there is no photo.
  final String tileEmoji;

  /// The tile's background, as `#RRGGBB`.
  final String tileColor;

  /// When the lot closes, in UTC: the auction's close time.
  final DateTime closeAt;

  /// The lot's place in the auction, from 0.
  final int position;

  @override
  String get eventName => 'LotCreated';

  @override
  Map<String, Object?> toData() => {
    'lotId': lotId,
    'auctionId': auctionId,
    'code': code,
    'name': name,
    'openBid': openBid,
    'increments': increments,
    'buyNowPrice': buyNowPrice,
    'description': description,
    'imageUrl': imageUrl,
    'tileEmoji': tileEmoji,
    'tileColor': tileColor,
    'closeAt': closeAt.toUtc().toIso8601String(),
    'position': position,
  };
}

/// A bid was placed on a lot.
///
/// [bidderName] is copied from the participant, so the ledger and
/// `OutbidError` name the leader without a join.
class BidPlaced extends LotEvent {
  /// Creates the event.
  BidPlaced(
    super.lotId, {
    required this.participantId,
    required this.bidderName,
    required this.amount,
    required this.sequence,
  });

  /// Rebuilds the event from [toData]'s output.
  factory BidPlaced.fromData(Map<String, Object?> data) => BidPlaced(
    data['lotId']! as String,
    participantId: data['participantId']! as String,
    bidderName: data['bidderName']! as String,
    amount: data['amount']! as int,
    sequence: data['sequence']! as int,
  );

  /// Who bid.
  final String participantId;

  /// The bidder's display name when they bid.
  final String bidderName;

  /// The bid, in rupiah: the price before it plus one kelipatan step.
  final int amount;

  /// The bid's place in the lot's ledger, from 1.
  final int sequence;

  @override
  String get eventName => 'BidPlaced';

  @override
  Map<String, Object?> toData() => {
    'lotId': lotId,
    'participantId': participantId,
    'bidderName': bidderName,
    'amount': amount,
    'sequence': sequence,
  };
}

/// One bid on a [Lot]. Retracted bids stay, marked, so the ledger never
/// loses a line.
class Bid {
  /// Creates the bid.
  const Bid({
    required this.sequence,
    required this.bidder,
    required this.bidderName,
    required this.amount,
    required this.at,
    this.retracted = false,
  });

  /// Restores a bid from [toJson]'s output.
  factory Bid.fromJson(Map<String, Object?> json) => Bid(
    sequence: json['sequence']! as int,
    bidder: json['bidder']! as String,
    bidderName: json['bidderName']! as String,
    amount: json['amount']! as int,
    at: DateTime.parse(json['at']! as String),
    retracted: json['retracted']! as bool,
  );

  /// The bid's place in the ledger, from 1.
  final int sequence;

  /// The bidder's participant ID.
  final String bidder;

  /// The bidder's display name.
  final String bidderName;

  /// The bid, in rupiah.
  final int amount;

  /// When the bid was placed, in UTC.
  final DateTime at;

  /// Whether the bidder took it back (UC-07).
  final bool retracted;

  /// The bid as JSON, for snapshots.
  Map<String, Object?> toJson() => {
    'sequence': sequence,
    'bidder': bidder,
    'bidderName': bidderName,
    'amount': amount,
    'at': at.toUtc().toIso8601String(),
    'retracted': retracted,
  };
}

/// One item for sale in an auction, with its kelipatan ladder and its bids.
class Lot extends AggregateRoot<LotId, LotEvent> {
  /// An empty lot, before its events are applied.
  Lot(super.id);

  /// Creates a lot of the auction [auctionId].
  ///
  /// Throws [CommandValidationError], with the offending `field`, if the
  /// trimmed [name] is empty or longer than [maxNameLength], [openBid] isn't
  /// positive, [buyNowPrice] is set but not above [openBid], [increments] is empty or has a step that isn't positive or
  /// appears twice, [description] is longer than [maxDescriptionLength],
  /// [imageUrl] isn't an http(s) URL, or the tile is malformed.
  factory Lot.create(
    LotId id, {
    required String auctionId,
    required String code,
    required String name,
    required int openBid,
    required List<int> increments,
    required int? buyNowPrice,
    required String description,
    required String? imageUrl,
    required String tileEmoji,
    required String tileColor,
    required DateTime closeAt,
    required int position,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > maxNameLength) {
      throw _invalid(
        'name',
        trimmed.isEmpty ? 'EMPTY' : 'TOO_LONG',
        'The name must be 1 to $maxNameLength characters',
      );
    }
    if (openBid <= 0) {
      throw _invalid('openBid', 'NOT_POSITIVE', 'The open bid must be above 0');
    }
    if (buyNowPrice != null && buyNowPrice <= openBid) {
      throw _invalid(
        'buyNowPrice',
        'NOT_ABOVE_OPEN_BID',
        'The BN price must be above the open bid',
      );
    }
    if (increments.isEmpty) {
      throw _invalid('increments', 'EMPTY', 'Choose at least one step');
    }
    if (increments.any((step) => step <= 0)) {
      throw _invalid(
        'increments',
        'NOT_POSITIVE',
        'Every step must be above 0',
      );
    }
    if (increments.toSet().length != increments.length) {
      throw _invalid('increments', 'DUPLICATE', 'Each step must be different');
    }
    if (description.length > maxDescriptionLength) {
      throw _invalid(
        'description',
        'TOO_LONG',
        'The description must be at most $maxDescriptionLength characters',
      );
    }
    final url = imageUrl?.trim();
    final image = url == null || url.isEmpty ? null : url;
    if (image != null && !_isWebUrl(image)) {
      throw _invalid(
        'imageUrl',
        'NOT_A_URL',
        'The image must be an http or https URL',
      );
    }
    final emoji = tileEmoji.trim();
    if (emoji.isEmpty || emoji.length > maxEmojiLength) {
      throw _invalid('tileEmoji', 'INVALID', 'Choose one emoji for the tile');
    }
    if (!_hexColor.hasMatch(tileColor)) {
      throw _invalid('tileColor', 'INVALID', 'The tile color must be #RRGGBB');
    }
    return Lot(id)..raise(
      LotCreated(
        id.uuid,
        auctionId: auctionId,
        code: code,
        name: trimmed,
        openBid: openBid,
        increments: [...increments]..sort(),
        buyNowPrice: buyNowPrice,
        description: description,
        imageUrl: image,
        tileEmoji: emoji,
        tileColor: tileColor.toUpperCase(),
        closeAt: closeAt.toUtc(),
        position: position,
      ),
    );
  }

  /// The longest name, after trimming.
  static const maxNameLength = 80;

  /// The longest description.
  static const maxDescriptionLength = 2000;

  /// The longest tile emoji, in UTF-16 code units: room for one emoji with
  /// modifiers, not a sentence.
  static const maxEmojiLength = 16;

  static final _hexColor = RegExp(r'^#[0-9A-Fa-f]{6}$');

  static bool _isWebUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static CommandValidationError _invalid(
    String field,
    String reason,
    String message,
  ) => CommandValidationError(
    message,
    context: {'field': field, 'reason': reason},
  );

  /// The auction the lot belongs to.
  String auctionId = '';

  /// The lot's name.
  String name = '';

  /// The first bid's minimum, in rupiah.
  int openBid = 0;

  /// The allowed raises, in rupiah, ascending.
  List<int> increments = [];

  /// The Buy Now (BN) price, in rupiah, or null for no BN.
  int? buyNowPrice;

  /// When the lot closes, in UTC.
  DateTime closeAt = DateTime.utc(0);

  /// The lot's place in the auction, from 0.
  int position = 0;

  /// Where the lot is in its life.
  LotStatus status = LotStatus.open;

  /// Every bid, in order, retracted ones included.
  List<Bid> bids = [];

  /// The leading bid: the latest one not retracted, if any.
  Bid? get lastValidBid {
    for (final bid in bids.reversed) {
      if (!bid.retracted) return bid;
    }
    return null;
  }

  /// The leading bid's amount, or the open bid while there is none.
  int get currentPrice => lastValidBid?.amount ?? openBid;

  /// Bids [amount] as [bidder], who saw the lot at [expectedVersion].
  ///
  /// The checks run in this order, so every race has one answer:
  ///
  /// 1. A lot that isn't open, or [now] at or after [closeAt], throws
  ///    [LotClosedError]: closing beats everything, even a close call that
  ///    hasn't fired yet.
  /// 2. A lot that changed since [expectedVersion] throws [OutbidError]
  ///    with the current leader. Two bids on one version both pass this
  ///    on their first try; the loser's append conflicts, the pipeline
  ///    retries it, and the reload lands here.
  /// 3. A raise that isn't one of [increments] throws
  ///    [InvalidIncrementError].
  ///
  /// Raising your own lead is allowed.
  void placeBid({
    required String bidder,
    required String bidderName,
    required int amount,
    required int expectedVersion,
    required DateTime now,
  }) {
    if (status != LotStatus.open || !now.isBefore(closeAt)) {
      throw LotClosedError(closedAt: closeAt);
    }
    if (expectedVersion != version) {
      final leader = lastValidBid;
      throw OutbidError(
        currentPrice: currentPrice,
        leaderName: leader?.bidderName,
        leaderId: leader?.bidder,
        version: version,
      );
    }
    if (!increments.contains(amount - currentPrice)) {
      throw InvalidIncrementError(
        allowedIncrements: increments,
        currentPrice: currentPrice,
      );
    }
    raise(
      BidPlaced(
        id.uuid,
        participantId: bidder,
        bidderName: bidderName,
        amount: amount,
        sequence: bids.length + 1,
      ),
    );
  }

  @override
  void apply(LotEvent event) {
    switch (event) {
      case LotCreated():
        auctionId = event.auctionId;
        name = event.name;
        openBid = event.openBid;
        increments = event.increments;
        buyNowPrice = event.buyNowPrice;
        closeAt = event.closeAt;
        position = event.position;
      case BidPlaced():
        bids = [
          ...bids,
          Bid(
            sequence: event.sequence,
            bidder: event.participantId,
            bidderName: event.bidderName,
            amount: event.amount,
            at: event.occurredAt,
          ),
        ];
    }
  }

  @override
  Map<String, Object?> toSnapshot() => {
    'auctionId': auctionId,
    'name': name,
    'openBid': openBid,
    'increments': increments,
    'buyNowPrice': buyNowPrice,
    'closeAt': closeAt.toIso8601String(),
    'position': position,
    'status': status.code,
    'bids': [for (final bid in bids) bid.toJson()],
  };

  @override
  void restoreSnapshotState(Map<String, Object?> data) {
    auctionId = data['auctionId']! as String;
    name = data['name']! as String;
    openBid = data['openBid']! as int;
    increments = [for (final step in data['increments']! as List) step as int];
    buyNowPrice = data['buyNowPrice'] as int?;
    closeAt = DateTime.parse(data['closeAt']! as String);
    position = data['position']! as int;
    status = LotStatus.fromCode(data['status']! as String);
    // Snapshots taken before UC-06 have no bids.
    bids = [
      for (final bid in data['bids'] as List? ?? const [])
        Bid.fromJson((bid as Map).cast()),
    ];
  }
}
