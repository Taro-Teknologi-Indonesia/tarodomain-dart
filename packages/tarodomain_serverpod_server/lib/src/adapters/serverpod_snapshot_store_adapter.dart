import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';

import '../db/taro_db.dart';
import '../generated/protocol.dart';

/// A [SnapshotStoreAdapter] on the module's `tarodomain_snapshots` table.
final class ServerpodSnapshotStoreAdapter implements SnapshotStoreAdapter {
  /// Creates the adapter on [session].
  ServerpodSnapshotStoreAdapter(Session session, {DateTime Function()? clock})
    : _db = TaroDb(session, clock: clock);

  final TaroDb _db;

  static final _t = TaroSnapshotRow.t;

  @override
  Future<void> save(SnapshotInput input) async {
    await _db.upsert<TaroSnapshotRow>(
      [
        TaroSnapshotRow(
          sourceUuid: input.sourceUuid,
          sourceType: input.sourceType,
          sourceVersion: input.sourceVersion,
          data: jsonEncode(input.data),
          metadata: jsonEncode(input.metadata),
          createdAt: _db.now(),
        ),
      ],
      conflictColumns: [_t.sourceUuid, _t.sourceVersion],
      noReturn: true,
    );
  }

  @override
  Future<Snapshot?> loadLatest(UuidValue sourceUuid, String sourceType) async {
    final row = await _db.findFirstRow<TaroSnapshotRow>(
      where: _of(sourceUuid, sourceType),
      orderBy: _t.sourceVersion.desc(),
    );
    return row == null ? null : _snapshot(row);
  }

  @override
  Future<Snapshot?> loadAtVersion(
    UuidValue sourceUuid,
    String sourceType,
    int version,
  ) async {
    final row = await _db.findFirstRow<TaroSnapshotRow>(
      where: _of(sourceUuid, sourceType) & _t.sourceVersion.equals(version),
    );
    return row == null ? null : _snapshot(row);
  }

  @override
  Future<List<Snapshot>> list(
    UuidValue sourceUuid,
    String sourceType, {
    int? limit,
  }) async => [
    for (final row in await _db.find<TaroSnapshotRow>(
      where: _of(sourceUuid, sourceType),
      orderBy: _t.sourceVersion.desc(),
      limit: limit,
    ))
      _snapshot(row),
  ];

  @override
  Future<void> deleteAll(UuidValue sourceUuid, String sourceType) async {
    await _db.deleteWhere<TaroSnapshotRow>(where: _of(sourceUuid, sourceType));
  }

  @override
  Future<int> deleteBefore(
    UuidValue sourceUuid,
    String sourceType,
    int version,
  ) => _db.deleteWhere<TaroSnapshotRow>(
    where: _of(sourceUuid, sourceType) & (_t.sourceVersion < version),
  );

  @override
  Future<int> count(UuidValue sourceUuid, String sourceType) =>
      _db.count<TaroSnapshotRow>(where: _of(sourceUuid, sourceType));

  static Expression<Object?> _of(UuidValue sourceUuid, String sourceType) =>
      _t.sourceUuid.equals(sourceUuid) & _t.sourceType.equals(sourceType);

  static Snapshot _snapshot(TaroSnapshotRow row) => Snapshot(
    sourceUuid: row.sourceUuid,
    sourceType: row.sourceType,
    sourceVersion: row.sourceVersion,
    data: jsonDecode(row.data) as Map<String, Object?>,
    metadata: jsonDecode(row.metadata) as Map<String, Object?>,
    createdAt: row.createdAt.toUtc(),
  );
}
