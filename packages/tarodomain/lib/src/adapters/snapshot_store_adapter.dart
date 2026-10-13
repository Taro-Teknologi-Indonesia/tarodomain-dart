import 'package:uuid/uuid.dart';

/// A snapshot to store (spec §8.2).
class SnapshotInput {
  /// Creates the input. [data] and [metadata] are copied into unmodifiable
  /// maps.
  SnapshotInput({
    required this.sourceUuid,
    required this.sourceType,
    required this.sourceVersion,
    required Map<String, Object?> data,
    Map<String, Object?> metadata = const {},
  }) : data = Map.unmodifiable(data),
       metadata = Map.unmodifiable(metadata);

  /// ID of the aggregate the snapshot was taken from.
  final UuidValue sourceUuid;

  /// The aggregate type, as configured on its repository.
  final String sourceType;

  /// The aggregate version the snapshot represents.
  final int sourceVersion;

  /// The aggregate's state, from `Snapshottable.toSnapshot`.
  final Map<String, Object?> data;

  /// Free-form metadata.
  final Map<String, Object?> metadata;
}

/// A stored snapshot.
final class Snapshot extends SnapshotInput {
  /// Creates the snapshot.
  Snapshot({
    required super.sourceUuid,
    required super.sourceType,
    required super.sourceVersion,
    required super.data,
    super.metadata,
    required this.createdAt,
  });

  /// When the snapshot was stored, in UTC.
  final DateTime createdAt;

  @override
  String toString() =>
      'Snapshot($sourceType-$sourceUuid, version: $sourceVersion)';
}

/// Storage for aggregate snapshots (spec §8.1). Snapshots are keyed by
/// `(sourceUuid, sourceVersion)`; [sourceType] is stored alongside and
/// filtered on.
abstract interface class SnapshotStoreAdapter {
  /// Stores [input], replacing any snapshot with the same UUID and version.
  Future<void> save(SnapshotInput input);

  /// The snapshot with the highest version, or null if there is none.
  Future<Snapshot?> loadLatest(UuidValue sourceUuid, String sourceType);

  /// The snapshot at exactly [version], or null if there is none.
  Future<Snapshot?> loadAtVersion(
    UuidValue sourceUuid,
    String sourceType,
    int version,
  );

  /// The snapshots of one aggregate, newest first, at most [limit] of them.
  Future<List<Snapshot>> list(
    UuidValue sourceUuid,
    String sourceType, {
    int? limit,
  });

  /// Deletes every snapshot of one aggregate.
  Future<void> deleteAll(UuidValue sourceUuid, String sourceType);

  /// Deletes the snapshots with a version lower than [version], and returns
  /// how many were deleted.
  Future<int> deleteBefore(
    UuidValue sourceUuid,
    String sourceType,
    int version,
  );

  /// How many snapshots one aggregate has.
  Future<int> count(UuidValue sourceUuid, String sourceType);
}
