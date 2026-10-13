import 'package:tarodomain/tarodomain.dart';

import 'keys.dart';

/// Identifies a [Participant].
class ParticipantId extends AggregateId {
  /// A new ID.
  ParticipantId.generate() : super.generate();

  /// An ID read back from storage or a request.
  ParticipantId.fromExisting(super.uuid) : super.fromExisting();
}

/// Events of a [Participant].
sealed class ParticipantEvent extends DomainEvent {
  ParticipantEvent(this.participantId);

  /// The participant the event belongs to.
  final String participantId;
}

/// A bidder joined an auction.
///
/// The participant's key hash is left out: the event log is public
/// history, and the hash lives only in the participant's row.
class ParticipantJoined extends ParticipantEvent {
  /// Creates the event.
  ParticipantJoined(
    super.participantId, {
    required this.auctionId,
    required this.displayName,
  });

  /// Rebuilds the event from [toData]'s output.
  factory ParticipantJoined.fromData(Map<String, Object?> data) =>
      ParticipantJoined(
        data['participantId']! as String,
        auctionId: data['auctionId']! as String,
        displayName: data['displayName']! as String,
      );

  /// The auction joined.
  final String auctionId;

  /// The name shown to the other bidders.
  final String displayName;

  @override
  String get eventName => 'ParticipantJoined';

  @override
  Map<String, Object?> toData() => {
    'participantId': participantId,
    'auctionId': auctionId,
    'displayName': displayName,
  };
}

/// A bidder in one auction: a state-based aggregate (spec §6.3), stored as
/// a row of `gavel_participants` instead of as events.
///
/// Bids are event-sourced because they need time travel and an audit
/// trail; joins don't, so they are a plain row, and `ParticipantJoined` is
/// still recorded.
class Participant extends AggregateRoot<ParticipantId, ParticipantEvent> {
  /// An empty participant, before its state is set.
  Participant(super.id);

  /// Joins the auction [auctionId] as [displayName], trimmed.
  ///
  /// [keyHash] is the hash of the participant's secret key (see [hashKey]).
  ///
  /// Throws [CommandValidationError] on `displayName` if the trimmed name is
  /// empty, longer than [maxNameLength] characters, or has a control
  /// character.
  factory Participant.join(
    ParticipantId id, {
    required String auctionId,
    required String displayName,
    required String keyHash,
  }) {
    final trimmed = displayName.trim();
    final length = trimmed.runes.length;
    final reason = length == 0
        ? 'EMPTY'
        : length > maxNameLength
        ? 'TOO_LONG'
        : trimmed.runes.any(_isControl)
        ? 'CONTROL_CHARACTER'
        : null;
    if (reason != null) {
      throw CommandValidationError(
        'The name must be 1 to $maxNameLength characters, with no control '
        'characters',
        context: {'field': 'displayName', 'reason': reason},
      );
    }
    return Participant(id)
      ..keyHash = keyHash
      ..raise(
        ParticipantJoined(id.uuid, auctionId: auctionId, displayName: trimmed),
      );
  }

  /// The participant stored at [version], as a state repository reads it.
  Participant.restore(
    super.id, {
    required this.auctionId,
    required this.displayName,
    required this.keyHash,
    required int version,
  }) {
    restoreVersion(version);
  }

  /// The longest display name, in characters.
  static const maxNameLength = 24;

  /// The auction joined.
  String auctionId = '';

  /// The name shown to the other bidders.
  String displayName = '';

  /// The hash of the participant's secret key. Never the key itself.
  String keyHash = '';

  /// Whether [key] is this participant's secret key, compared in constant
  /// time.
  bool hasKey(String key) => keyHash.isNotEmpty && keyMatches(key, keyHash);

  static bool _isControl(int rune) =>
      rune < 0x20 || (rune >= 0x7F && rune <= 0x9F);

  @override
  void apply(ParticipantEvent event) => switch (event) {
    ParticipantJoined(:final auctionId, :final displayName) => (
      this.auctionId = auctionId,
      this.displayName = displayName,
    ),
  };

  @override
  Map<String, Object?> toSnapshot() => {
    'auctionId': auctionId,
    'displayName': displayName,
    'keyHash': keyHash,
  };

  @override
  void restoreSnapshotState(Map<String, Object?> data) {
    auctionId = data['auctionId']! as String;
    displayName = data['displayName']! as String;
    keyHash = data['keyHash']! as String;
  }
}

/// Keeps [Participant]s in memory, as snapshots, for the domain tests on
/// `tarodomain_local`. The server stores them in `gavel_participants`
/// instead.
class InMemoryParticipantRepository
    extends StateRepository<Participant, ParticipantId> {
  /// Creates the repository over [rows], which outlives each repository
  /// the runtime makes.
  InMemoryParticipantRepository(super.eventBus, this.rows);

  /// The stored participants: their snapshot and version, by ID.
  final Map<String, (Map<String, Object?>, int)> rows;

  @override
  Future<Participant> load(ParticipantId id) async {
    final row = rows[id.uuid];
    if (row == null) {
      throw AggregateNotFoundError(
        'Participant ${id.uuid} not found',
        context: {'aggregateType': 'Participant', 'aggregateId': id.uuid},
      );
    }
    return Participant(id)..restoreSnapshot(row.$1, row.$2);
  }

  @override
  Future<bool> exists(ParticipantId id) async => rows.containsKey(id.uuid);

  @override
  Future<void> saveState(Participant participant) async {
    final stored = rows[participant.id.uuid]?.$2 ?? 0;
    if (stored != participant.committedVersion) {
      throw OptimisticConcurrencyError(
        'Participant ${participant.id.uuid} changed since it was loaded',
        context: {
          'aggregateType': 'Participant',
          'aggregateId': participant.id.uuid,
          'expectedVersion': participant.committedVersion,
        },
      );
    }
    rows[participant.id.uuid] = (participant.toSnapshot(), participant.version);
  }
}
