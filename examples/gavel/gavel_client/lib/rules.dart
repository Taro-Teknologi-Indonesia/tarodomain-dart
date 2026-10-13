/// The server's input rules, checked in the app before a call (X5).
///
/// The domain stays the authority: these only spare a round trip. Each rule
/// uses the domain's limit, `field`, `reason` and message, and
/// `gavel_server`'s parity test fails if the two drift apart.
library;

/// What's wrong with one field: the same `field`/`reason` the server puts in
/// `CommandValidationError.context`, and the server's message.
final class FieldError {
  /// An error on [field] for [reason], shown as [message].
  const FieldError(this.field, this.reason, this.message);

  /// The command field, such as `title`.
  final String field;

  /// Why it's refused, such as `TOO_LONG`.
  final String reason;

  /// The server's message for it.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is FieldError &&
      other.field == field &&
      other.reason == reason &&
      other.message == message;

  @override
  int get hashCode => Object.hash(field, reason, message);

  @override
  String toString() => 'FieldError($field, $reason, $message)';
}

/// `Auction.create` and `Auction.registerLot`.
abstract final class AuctionRules {
  /// The longest title, after trimming.
  static const maxTitleLength = 80;

  /// How far ahead of creation the close time must be.
  static const minimumLeadTime = Duration(minutes: 5);

  /// The most lots one auction takes.
  static const maxLots = 20;

  /// The error of [title], or null if the server takes it.
  static FieldError? title(String title) {
    final trimmed = title.trim();
    if (trimmed.isNotEmpty && trimmed.length <= maxTitleLength) return null;
    return FieldError(
      'title',
      trimmed.isEmpty ? 'EMPTY' : 'TOO_LONG',
      'The title must be 1 to $maxTitleLength characters',
    );
  }

  /// The error of [closeAt] when creating at [now], or null if the server
  /// takes it.
  static FieldError? closeAt(DateTime closeAt, {required DateTime now}) =>
      closeAt.isBefore(now.add(minimumLeadTime))
      ? FieldError(
          'closeAt',
          'TOO_SOON',
          'The auction must close at least '
              '${minimumLeadTime.inMinutes} minutes from now',
        )
      : null;

  /// The error of adding a lot to an auction that has [lotCount], or null.
  static FieldError? lotCount(int lotCount) => lotCount >= maxLots
      ? const FieldError(
          'lots',
          'TOO_MANY',
          'An auction takes at most $maxLots lots',
        )
      : null;
}

/// `Lot.create`.
abstract final class LotRules {
  /// The longest name, after trimming.
  static const maxNameLength = 80;

  /// The longest description.
  static const maxDescriptionLength = 2000;

  /// The longest tile emoji, in UTF-16 code units.
  static const maxEmojiLength = 16;

  /// The longest unpaid note, after trimming (UC-14).
  static const maxUnpaidNoteLength = 140;

  static final _hexColor = RegExp(r'^#[0-9A-Fa-f]{6}$');

  /// Every field error of a new lot, in the server's check order. The
  /// server stops at the first; this lists them all, so a form can mark
  /// every bad field at once.
  static List<FieldError> newLot({
    required String name,
    required int openBid,
    required int? buyNowPrice,
    required List<int> increments,
    required String description,
    required String? imageUrl,
    required String tileEmoji,
    required String tileColor,
  }) => [
    ?LotRules.name(name),
    ?LotRules.openBid(openBid),
    ?LotRules.buyNowPrice(buyNowPrice, openBid: openBid),
    ?LotRules.increments(increments),
    ?LotRules.description(description),
    ?LotRules.imageUrl(imageUrl),
    ?LotRules.tileEmoji(tileEmoji),
    ?LotRules.tileColor(tileColor),
  ];

  /// The error of the lot's [name], or null.
  static FieldError? name(String name) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty && trimmed.length <= maxNameLength) return null;
    return FieldError(
      'name',
      trimmed.isEmpty ? 'EMPTY' : 'TOO_LONG',
      'The name must be 1 to $maxNameLength characters',
    );
  }

  /// The error of [openBid], or null.
  static FieldError? openBid(int openBid) => openBid <= 0
      ? const FieldError(
          'openBid',
          'NOT_POSITIVE',
          'The open bid must be above 0',
        )
      : null;

  /// The error of [buyNowPrice] for a lot opening at [openBid], or null.
  static FieldError? buyNowPrice(int? buyNowPrice, {required int openBid}) =>
      buyNowPrice != null && buyNowPrice <= openBid
      ? const FieldError(
          'buyNowPrice',
          'NOT_ABOVE_OPEN_BID',
          'The BN price must be above the open bid',
        )
      : null;

  /// The error of the kelipatan [increments], or null.
  static FieldError? increments(List<int> increments) {
    if (increments.isEmpty) {
      return const FieldError(
        'increments',
        'EMPTY',
        'Choose at least one step',
      );
    }
    if (increments.any((step) => step <= 0)) {
      return const FieldError(
        'increments',
        'NOT_POSITIVE',
        'Every step must be above 0',
      );
    }
    if (increments.toSet().length != increments.length) {
      return const FieldError(
        'increments',
        'DUPLICATE',
        'Each step must be different',
      );
    }
    return null;
  }

  /// The error of [description], or null.
  static FieldError? description(String description) =>
      description.length > maxDescriptionLength
      ? const FieldError(
          'description',
          'TOO_LONG',
          'The description must be at most $maxDescriptionLength characters',
        )
      : null;

  /// The error of [imageUrl], or null. Empty or null is no image.
  static FieldError? imageUrl(String? imageUrl) {
    final url = imageUrl?.trim() ?? '';
    if (url.isEmpty || isWebUrl(url)) return null;
    return const FieldError(
      'imageUrl',
      'NOT_A_URL',
      'The image must be an http or https URL',
    );
  }

  /// The error of [tileEmoji], or null.
  static FieldError? tileEmoji(String tileEmoji) {
    final emoji = tileEmoji.trim();
    if (emoji.isNotEmpty && emoji.length <= maxEmojiLength) return null;
    return const FieldError(
      'tileEmoji',
      'INVALID',
      'Choose one emoji for the tile',
    );
  }

  /// The error of [tileColor], or null.
  static FieldError? tileColor(String tileColor) =>
      _hexColor.hasMatch(tileColor)
      ? null
      : const FieldError(
          'tileColor',
          'INVALID',
          'The tile color must be #RRGGBB',
        );

  /// Whether [value] is an http or https URL with a host.
  static bool isWebUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }
}

/// `Participant.join`.
abstract final class ParticipantRules {
  /// The longest display name, counted in runes like the server.
  static const maxNameLength = 24;

  /// The error of the display name [name], or null if the server takes it.
  static FieldError? displayName(String name) {
    final trimmed = name.trim();
    final length = trimmed.runes.length;
    final reason = length == 0
        ? 'EMPTY'
        : length > maxNameLength
        ? 'TOO_LONG'
        : trimmed.runes.any(isControl)
        ? 'CONTROL_CHARACTER'
        : null;
    if (reason == null) return null;
    return FieldError(
      'displayName',
      reason,
      'The name must be 1 to $maxNameLength characters, with no control '
          'characters',
    );
  }

  /// Whether [rune] is a C0 or C1 control character, which a name can't
  /// hold.
  static bool isControl(int rune) =>
      rune < 0x20 || (rune >= 0x7F && rune <= 0x9F);

  /// [name] without its control characters.
  static String withoutControl(String name) =>
      String.fromCharCodes(name.runes.where((r) => !isControl(r)));
}

/// The join code in the share link.
abstract final class JoinCodeRules {
  /// The code's characters: no 0/O, 1/I/L.
  static const alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// How many characters a code has.
  static const length = 6;

  /// [input] trimmed and uppercased, as the router reads a code.
  static String normalize(String input) => input.trim().toUpperCase();

  /// Whether [code], already normalized, could be a join code.
  static bool isValid(String code) =>
      code.length == length && code.split('').every(alphabet.contains);
}
