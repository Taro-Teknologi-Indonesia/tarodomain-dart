import 'package:tarodomain/tarodomain.dart';

import 'local_database.dart';

/// A [SagaStoreAdapter] over a [LocalDatabase].
final class InMemorySagaStoreAdapter implements SagaStoreAdapter {
  /// Creates the adapter.
  InMemorySagaStoreAdapter(this.database);

  /// The database the sagas live in.
  final LocalDatabase database;

  Map<(String, String), SagaRecord> get _sagas => database.tables.sagas;

  @override
  Future<void> save(SagaSaveInput input) async {
    final key = (input.sagaType, input.sagaId.uuid);
    final existing = _sagas[key];
    final now = database.now();
    _sagas[key] = SagaRecord(
      sagaId: input.sagaId,
      sagaType: input.sagaType,
      correlationId: input.correlationId,
      state: input.state,
      status: input.status,
      currentStep: input.currentStep,
      failureReason: input.failureReason,
      startedAt: existing?.startedAt ?? now,
      updatedAt: now,
      completedAt: input.status.isTerminal
          ? existing?.completedAt ?? now
          : null,
    );
  }

  @override
  Future<SagaRecord?> load(String sagaType, UuidValue sagaId) async =>
      _sagas[(sagaType, sagaId.uuid)];

  @override
  Future<SagaRecord?> loadByCorrelationId(
    String sagaType,
    UuidValue correlationId,
  ) async => _sagas.values
      .where((s) => s.sagaType == sagaType && s.correlationId == correlationId)
      .firstOrNull;

  @override
  Future<void> complete(String sagaType, UuidValue sagaId) =>
      _finish(sagaType, sagaId, SagaStatus.completed, null);

  @override
  Future<void> fail(String sagaType, UuidValue sagaId, String reason) =>
      _finish(sagaType, sagaId, SagaStatus.failed, reason);

  Future<void> _finish(
    String sagaType,
    UuidValue sagaId,
    SagaStatus status,
    String? failureReason,
  ) async {
    final key = (sagaType, sagaId.uuid);
    final saga = _sagas[key];
    if (saga == null || saga.status.isTerminal) return;
    final now = database.now();
    _sagas[key] = SagaRecord(
      sagaId: saga.sagaId,
      sagaType: saga.sagaType,
      correlationId: saga.correlationId,
      state: saga.state,
      status: status,
      currentStep: saga.currentStep,
      failureReason: failureReason ?? saga.failureReason,
      startedAt: saga.startedAt,
      updatedAt: now,
      completedAt: now,
    );
  }

  @override
  Future<List<SagaRecord>> loadByStatus(
    SagaStatus status, {
    int? limit,
  }) async => _oldestFirst((s) => s.status == status, limit);

  @override
  Future<List<SagaRecord>> loadTimedOut(
    DateTime before, {
    String? sagaType,
    int? limit,
  }) async => _oldestFirst(
    (s) =>
        !s.status.isTerminal &&
        s.updatedAt.isBefore(before) &&
        (sagaType == null || s.sagaType == sagaType),
    limit,
  );

  @override
  Future<void> delete(String sagaType, UuidValue sagaId) async {
    _sagas.remove((sagaType, sagaId.uuid));
  }

  @override
  Future<int> count({String? sagaType, SagaStatus? status}) async => _sagas
      .values
      .where(
        (s) =>
            (sagaType == null || s.sagaType == sagaType) &&
            (status == null || s.status == status),
      )
      .length;

  List<SagaRecord> _oldestFirst(bool Function(SagaRecord) test, int? limit) =>
      sortedByTime(_sagas.values.where(test), (s) => s.updatedAt, limit: limit);
}
