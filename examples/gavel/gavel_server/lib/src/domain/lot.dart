import 'package:tarodomain/tarodomain.dart';

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
    'description': description,
    'imageUrl': imageUrl,
    'tileEmoji': tileEmoji,
    'tileColor': tileColor,
    'closeAt': closeAt.toUtc().toIso8601String(),
    'position': position,
  };
}

/// One item for sale in an auction, with its kelipatan ladder and, from
/// UC-06 on, its bids.
class Lot extends AggregateRoot<LotId, LotEvent> {
  /// An empty lot, before its events are applied.
  Lot(super.id);

  /// Creates a lot of the auction [auctionId].
  ///
  /// Throws [CommandValidationError], with the offending `field`, if the
  /// trimmed [name] is empty or longer than [maxNameLength], [openBid] isn't
  /// positive, [increments] is empty or has a step that isn't positive or
  /// appears twice, [description] is longer than [maxDescriptionLength],
  /// [imageUrl] isn't an http(s) URL, or the tile is malformed.
  factory Lot.create(
    LotId id, {
    required String auctionId,
    required String code,
    required String name,
    required int openBid,
    required List<int> increments,
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

  /// When the lot closes, in UTC.
  DateTime closeAt = DateTime.utc(0);

  /// The lot's place in the auction, from 0.
  int position = 0;

  /// Where the lot is in its life.
  LotStatus status = LotStatus.open;

  @override
  void apply(LotEvent event) {
    switch (event) {
      case LotCreated():
        auctionId = event.auctionId;
        name = event.name;
        openBid = event.openBid;
        increments = event.increments;
        closeAt = event.closeAt;
        position = event.position;
    }
  }

  @override
  Map<String, Object?> toSnapshot() => {
    'auctionId': auctionId,
    'name': name,
    'openBid': openBid,
    'increments': increments,
    'closeAt': closeAt.toIso8601String(),
    'position': position,
    'status': status.code,
  };

  @override
  void restoreSnapshotState(Map<String, Object?> data) {
    auctionId = data['auctionId']! as String;
    name = data['name']! as String;
    openBid = data['openBid']! as int;
    increments = [for (final step in data['increments']! as List) step as int];
    closeAt = DateTime.parse(data['closeAt']! as String);
    position = data['position']! as int;
    status = LotStatus.fromCode(data['status']! as String);
  }
}
