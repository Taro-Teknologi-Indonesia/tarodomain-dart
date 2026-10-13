import 'package:tarodomain/tarodomain.dart';

import 'local_database.dart';

/// A [SnapshotStoreAdapter] over a [LocalDatabase].
final class InMemorySnapshotStoreAdapter implements SnapshotStoreAdapter {
  /// Creates the adapter.
  InMemorySnapshotStoreAdapter(this.database);

  /// The database the snapshots live in.
  final LocalDatabase database;

  Map<(String, int), Snapshot> get _snapshots => database.tables.snapshots;

  @override
  Future<void> save(SnapshotInput input) async {
    _snapshots[(input.sourceUuid.uuid, input.sourceVersion)] = Snapshot(
      sourceUuid: input.sourceUuid,
      sourceType: input.sourceType,
      sourceVersion: input.sourceVersion,
      data: input.data,
      metadata: input.metadata,
      createdAt: database.now(),
    );
  }

  @override
  Future<Snapshot?> loadLatest(UuidValue sourceUuid, String sourceType) async =>
      _newestFirst(sourceUuid, sourceType).firstOrNull;

  @override
  Future<Snapshot?> loadAtVersion(
    UuidValue sourceUuid,
    String sourceType,
    int version,
  ) async {
    final snapshot = _snapshots[(sourceUuid.uuid, version)];
    return snapshot?.sourceType == sourceType ? snapshot : null;
  }

  @override
  Future<List<Snapshot>> list(
    UuidValue sourceUuid,
    String sourceType, {
    int? limit,
  }) async {
    final snapshots = _newestFirst(sourceUuid, sourceType);
    return limit == null ? snapshots : snapshots.take(limit).toList();
  }

  @override
  Future<void> deleteAll(UuidValue sourceUuid, String sourceType) async {
    _snapshots.removeWhere((_, s) => _matches(s, sourceUuid, sourceType));
  }

  @override
  Future<int> deleteBefore(
    UuidValue sourceUuid,
    String sourceType,
    int version,
  ) async {
    final before = _snapshots.length;
    _snapshots.removeWhere(
      (_, s) =>
          _matches(s, sourceUuid, sourceType) && s.sourceVersion < version,
    );
    return before - _snapshots.length;
  }

  @override
  Future<int> count(UuidValue sourceUuid, String sourceType) async => _snapshots
      .values
      .where((s) => _matches(s, sourceUuid, sourceType))
      .length;

  List<Snapshot> _newestFirst(UuidValue sourceUuid, String sourceType) =>
      _snapshots.values
          .where((s) => _matches(s, sourceUuid, sourceType))
          .toList()
        ..sort((a, b) => b.sourceVersion.compareTo(a.sourceVersion));

  static bool _matches(Snapshot s, UuidValue sourceUuid, String sourceType) =>
      s.sourceUuid == sourceUuid && s.sourceType == sourceType;
}
