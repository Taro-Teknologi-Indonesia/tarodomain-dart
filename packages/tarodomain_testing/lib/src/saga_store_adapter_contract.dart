import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Tests that the adapters [create] makes follow the [SagaStoreAdapter]
/// contract (spec §9, §19.1).
void sagaStoreAdapterContract(ContractFactory<SagaStoreAdapter> create) {
  group('SagaStoreAdapter contract', () {
    late SagaStoreAdapter store;
    late TestEvents ids;

    setUp(() async {
      store = await create();
      ids = TestEvents();
    });

    SagaSaveInput saga({
      UuidValue? id,
      String type = 'TransferMoney',
      SagaStatus status = SagaStatus.running,
      Map<String, Object?> state = const {'step': 1},
      String? currentStep = 'debit',
      String? failureReason,
    }) {
      id ??= ids.nextId();
      return SagaSaveInput(
        sagaId: id,
        sagaType: type,
        correlationId: id,
        state: state,
        status: status,
        currentStep: currentStep,
        failureReason: failureReason,
      );
    }

    List<UuidValue> sagaIds(List<SagaRecord> sagas) => [
      for (final s in sagas) s.sagaId,
    ];

    test('saves and loads every field', () async {
      final before = DateTime.timestamp();
      final input = saga(
        state: {
          'amount': 500,
          'accounts': ['a', 'b'],
          'meta': {'retry': false, 'note': null},
        },
      );

      await store.save(input);

      final loaded = (await store.load('TransferMoney', input.sagaId))!;
      expect(loaded.sagaId, input.sagaId);
      expect(loaded.sagaType, 'TransferMoney');
      expect(loaded.correlationId, input.correlationId);
      expect(loaded.state, input.state);
      expect(loaded.status, SagaStatus.running);
      expect(loaded.currentStep, 'debit');
      expect(loaded.failureReason, isNull);
      expect(loaded.startedAt.isBefore(before), isFalse);
      expect(loaded.startedAt.isUtc, isTrue);
      expect(loaded.updatedAt, loaded.startedAt);
      expect(loaded.completedAt, isNull);
    });

    test('load returns null for an unknown ID or type', () async {
      final input = saga();
      await store.save(input);

      expect(await store.load('TransferMoney', ids.nextId()), isNull);
      expect(await store.load('Other', input.sagaId), isNull);
    });

    test('save replaces the saga and keeps startedAt', () async {
      final id = ids.nextId();
      await store.save(saga(id: id));
      final first = (await store.load('TransferMoney', id))!;
      await tick();

      await store.save(
        saga(
          id: id,
          status: SagaStatus.compensating,
          state: {'step': 2},
          currentStep: 'refund',
        ),
      );

      final second = (await store.load('TransferMoney', id))!;
      expect(second.status, SagaStatus.compensating);
      expect(second.state, {'step': 2});
      expect(second.currentStep, 'refund');
      expect(second.startedAt, first.startedAt);
      expect(second.updatedAt.isAfter(first.updatedAt), isTrue);
      expect(await store.count(sagaType: 'TransferMoney'), 1);
    });

    test('the same ID under two saga types is two sagas', () async {
      final id = ids.nextId();
      await store.save(saga(id: id));
      await store.save(saga(id: id, type: 'Other', state: {'other': true}));

      expect((await store.load('TransferMoney', id))!.state, {'step': 1});
      expect((await store.load('Other', id))!.state, {'other': true});
    });

    test('loadByCorrelationId finds the saga', () async {
      final input = saga();
      await store.save(input);

      final loaded = await store.loadByCorrelationId(
        'TransferMoney',
        input.correlationId,
      );

      expect(loaded?.sagaId, input.sagaId);
      expect(
        await store.loadByCorrelationId('Other', input.correlationId),
        isNull,
      );
      expect(
        await store.loadByCorrelationId('TransferMoney', ids.nextId()),
        isNull,
      );
    });

    group('complete', () {
      test('marks a running saga completed', () async {
        final input = saga();
        await store.save(input);
        await tick();

        await store.complete('TransferMoney', input.sagaId);

        final loaded = (await store.load('TransferMoney', input.sagaId))!;
        expect(loaded.status, SagaStatus.completed);
        expect(loaded.completedAt, isNotNull);
        expect(loaded.completedAt!.isAfter(loaded.startedAt), isTrue);
        expect(loaded.state, input.state);
      });

      test('does nothing to a terminal or missing saga', () async {
        final input = saga();
        await store.save(input);
        await store.fail('TransferMoney', input.sagaId, 'declined');
        final failed = (await store.load('TransferMoney', input.sagaId))!;

        await store.complete('TransferMoney', input.sagaId);
        await store.complete('TransferMoney', ids.nextId());

        final loaded = (await store.load('TransferMoney', input.sagaId))!;
        expect(loaded.status, SagaStatus.failed);
        expect(loaded.completedAt, failed.completedAt);
        expect(await store.count(), 1);
      });
    });

    group('fail', () {
      test('marks a compensating saga failed with the reason', () async {
        final input = saga(status: SagaStatus.compensating);
        await store.save(input);

        await store.fail('TransferMoney', input.sagaId, 'insufficient funds');

        final loaded = (await store.load('TransferMoney', input.sagaId))!;
        expect(loaded.status, SagaStatus.failed);
        expect(loaded.failureReason, 'insufficient funds');
        expect(loaded.completedAt, isNotNull);
      });

      test('does nothing to a terminal or missing saga', () async {
        final input = saga();
        await store.save(input);
        await store.complete('TransferMoney', input.sagaId);

        await store.fail('TransferMoney', input.sagaId, 'too late');
        await store.fail('TransferMoney', ids.nextId(), 'missing');

        final loaded = (await store.load('TransferMoney', input.sagaId))!;
        expect(loaded.status, SagaStatus.completed);
        expect(loaded.failureReason, isNull);
        expect(await store.count(), 1);
      });
    });

    test('saving a terminal status sets completedAt', () async {
      final input = saga(status: SagaStatus.failed, failureReason: 'timed out');

      await store.save(input);

      final loaded = (await store.load('TransferMoney', input.sagaId))!;
      expect(loaded.completedAt, isNotNull);
      expect(loaded.failureReason, 'timed out');
    });

    test('loadByStatus is oldest update first and honours limit', () async {
      final a = saga();
      final b = saga();
      final c = saga();
      await store.save(a);
      await tick();
      await store.save(b);
      await tick();
      await store.save(saga(status: SagaStatus.compensating));
      await store.save(c);
      await tick();
      await store.save(a);

      expect(sagaIds(await store.loadByStatus(SagaStatus.running)), [
        b.sagaId,
        c.sagaId,
        a.sagaId,
      ]);
      expect(sagaIds(await store.loadByStatus(SagaStatus.running, limit: 1)), [
        b.sagaId,
      ]);
      expect(await store.loadByStatus(SagaStatus.completed), isEmpty);
    });

    test('loadTimedOut returns stale running and compensating sagas', () async {
      final running = saga();
      final compensating = saga(status: SagaStatus.compensating);
      final completed = saga();
      await store.save(running);
      await tick();
      await store.save(compensating);
      await store.save(completed);
      await store.complete('TransferMoney', completed.sagaId);
      await tick();
      final cutoff = DateTime.timestamp();
      await tick();
      await store.save(saga());

      expect(sagaIds(await store.loadTimedOut(cutoff)), [
        running.sagaId,
        compensating.sagaId,
      ]);
      expect(sagaIds(await store.loadTimedOut(cutoff, limit: 1)), [
        running.sagaId,
      ]);
    });

    test('loadTimedOut filters by saga type', () async {
      final transfer = saga();
      final refund = saga(type: 'Refund');
      await store.save(transfer);
      await store.save(refund);
      await tick();
      final cutoff = DateTime.timestamp();

      expect(sagaIds(await store.loadTimedOut(cutoff, sagaType: 'Refund')), [
        refund.sagaId,
      ]);
      expect(
        sagaIds(await store.loadTimedOut(cutoff, sagaType: 'TransferMoney')),
        [transfer.sagaId],
      );
      expect(await store.loadTimedOut(cutoff, sagaType: 'Other'), isEmpty);
    });

    test('delete removes one saga', () async {
      final input = saga();
      final kept = saga();
      await store.save(input);
      await store.save(kept);

      await store.delete('TransferMoney', input.sagaId);
      await store.delete('TransferMoney', ids.nextId());

      expect(await store.load('TransferMoney', input.sagaId), isNull);
      expect(await store.load('TransferMoney', kept.sagaId), isNotNull);
    });

    test('count filters by type and status', () async {
      await store.save(saga());
      await store.save(saga());
      await store.save(saga(status: SagaStatus.compensating));
      await store.save(saga(type: 'Other'));

      expect(await store.count(), 4);
      expect(await store.count(sagaType: 'TransferMoney'), 3);
      expect(await store.count(status: SagaStatus.running), 3);
      expect(
        await store.count(
          sagaType: 'TransferMoney',
          status: SagaStatus.running,
        ),
        2,
      );
      expect(await store.count(sagaType: 'Missing'), 0);
    });
  });
}
