import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';

import '../db/taro_db.dart';
import '../generated/protocol.dart';

/// A [SagaStoreAdapter] on the module's `tarodomain_sagas` table.
final class ServerpodSagaStoreAdapter implements SagaStoreAdapter {
  /// Creates the adapter on [session].
  ServerpodSagaStoreAdapter(Session session, {DateTime Function()? clock})
    : _db = TaroDb(session, clock: clock);

  final TaroDb _db;

  static final _t = TaroSagaRow.t;

  static final _active = {
    SagaStatus.running.code,
    SagaStatus.compensating.code,
  };

  @override
  Future<void> save(SagaSaveInput input) => _db.atomically(() async {
    final existing = await _find(input.sagaType, input.sagaId);
    final now = _db.now();
    await _db.upsert<TaroSagaRow>(
      [
        TaroSagaRow(
          sagaType: input.sagaType,
          sagaId: input.sagaId,
          correlationId: input.correlationId,
          state: jsonEncode(input.state),
          status: input.status.code,
          currentStep: input.currentStep,
          failureReason: input.failureReason,
          startedAt: existing?.startedAt ?? now,
          updatedAt: now,
          completedAt: input.status.isTerminal
              ? existing?.completedAt ?? now
              : null,
        ),
      ],
      conflictColumns: [_t.sagaType, _t.sagaId],
      updateColumns: [
        _t.correlationId,
        _t.state,
        _t.status,
        _t.currentStep,
        _t.failureReason,
        _t.updatedAt,
        _t.completedAt,
      ],
      noReturn: true,
    );
  });

  @override
  Future<SagaRecord?> load(String sagaType, UuidValue sagaId) async {
    final row = await _find(sagaType, sagaId);
    return row == null ? null : _record(row);
  }

  @override
  Future<SagaRecord?> loadByCorrelationId(
    String sagaType,
    UuidValue correlationId,
  ) async {
    final row = await _db.findFirstRow<TaroSagaRow>(
      where:
          _t.sagaType.equals(sagaType) & _t.correlationId.equals(correlationId),
    );
    return row == null ? null : _record(row);
  }

  @override
  Future<void> complete(String sagaType, UuidValue sagaId) async {
    final now = _db.now();
    await _db.updateWhere<TaroSagaRow>(
      columnValues: [
        ColumnValue(_t.status, SagaStatus.completed.code),
        ColumnValue(_t.updatedAt, now),
        ColumnValue(_t.completedAt, now),
      ],
      where: _activeSaga(sagaType, sagaId),
      noReturn: true,
    );
  }

  @override
  Future<void> fail(String sagaType, UuidValue sagaId, String reason) async {
    final now = _db.now();
    await _db.updateWhere<TaroSagaRow>(
      columnValues: [
        ColumnValue(_t.status, SagaStatus.failed.code),
        ColumnValue(_t.failureReason, reason),
        ColumnValue(_t.updatedAt, now),
        ColumnValue(_t.completedAt, now),
      ],
      where: _activeSaga(sagaType, sagaId),
      noReturn: true,
    );
  }

  @override
  Future<List<SagaRecord>> loadByStatus(SagaStatus status, {int? limit}) =>
      _oldestFirst(_t.status.equals(status.code), limit);

  @override
  Future<List<SagaRecord>> loadTimedOut(
    DateTime before, {
    String? sagaType,
    int? limit,
  }) {
    final stale = _t.status.inSet(_active) & (_t.updatedAt < before.toUtc());
    return _oldestFirst(
      sagaType == null ? stale : stale & _t.sagaType.equals(sagaType),
      limit,
    );
  }

  @override
  Future<void> delete(String sagaType, UuidValue sagaId) async {
    await _db.deleteWhere<TaroSagaRow>(
      where: _t.sagaType.equals(sagaType) & _t.sagaId.equals(sagaId),
    );
  }

  @override
  Future<int> count({String? sagaType, SagaStatus? status}) {
    final conditions = [
      if (sagaType != null) _t.sagaType.equals(sagaType),
      if (status != null) _t.status.equals(status.code),
    ];
    return _db.count<TaroSagaRow>(
      where: conditions.isEmpty ? null : conditions.reduce((a, b) => a & b),
    );
  }

  Future<TaroSagaRow?> _find(String sagaType, UuidValue sagaId) =>
      _db.findFirstRow<TaroSagaRow>(
        where: _t.sagaType.equals(sagaType) & _t.sagaId.equals(sagaId),
      );

  Future<List<SagaRecord>> _oldestFirst(
    Expression<Object?> where,
    int? limit,
  ) async => [
    for (final row in await _db.find<TaroSagaRow>(
      where: where,
      orderByList: [_t.updatedAt, _t.id],
      limit: limit,
    ))
      _record(row),
  ];

  static Expression<Object?> _activeSaga(String sagaType, UuidValue sagaId) =>
      _t.sagaType.equals(sagaType) &
      _t.sagaId.equals(sagaId) &
      _t.status.inSet(_active);

  static SagaRecord _record(TaroSagaRow row) => SagaRecord(
    sagaId: row.sagaId,
    sagaType: row.sagaType,
    correlationId: row.correlationId,
    state: jsonDecode(row.state) as Map<String, Object?>,
    status: SagaStatus.fromCode(row.status),
    currentStep: row.currentStep,
    failureReason: row.failureReason,
    startedAt: row.startedAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
    completedAt: row.completedAt?.toUtc(),
  );
}
