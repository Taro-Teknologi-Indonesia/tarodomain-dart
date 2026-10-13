import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Tests that the units of work of the providers [create] makes follow the
/// [UnitOfWork] contract (spec §11.4): the provider's adapters join the
/// active unit of work, and its writes commit or roll back together.
void unitOfWorkContract(ContractFactory<Provider> create) {
  group('UnitOfWork contract', () {
    late UnitOfWork unitOfWork;
    late EventStoreAdapter eventStore;
    late SagaStoreAdapter sagaStore;
    late ProcessedEventStore processedEvents;
    late TestEvents events;

    setUp(() async {
      final provider = await create();
      final created = provider.createUnitOfWork();
      if (created == null) {
        fail('${provider.type} provider has no unit of work');
      }
      unitOfWork = created;
      eventStore = provider.createEventStoreAdapter();
      sagaStore = provider.createSagaStoreAdapter();
      processedEvents = provider.createProcessedEventStore();
      events = TestEvents();
    });

    SagaSaveInput saga(UuidValue id) => SagaSaveInput(
      sagaId: id,
      sagaType: 'TransferMoney',
      correlationId: id,
      state: const {'step': 1},
      status: SagaStatus.running,
    );

    test('isActive only inside execute, including nested calls', () async {
      expect(unitOfWork.isActive, isFalse);
      await unitOfWork.execute(() async {
        expect(unitOfWork.isActive, isTrue);
        await unitOfWork.execute(() async {
          expect(unitOfWork.isActive, isTrue);
        });
        expect(unitOfWork.isActive, isTrue);
      });
      expect(unitOfWork.isActive, isFalse);
    });

    test('commits every adapter\'s writes and returns the result', () async {
      final streamId = events.streamId();
      final sagaId = events.nextId();
      final eventId = events.nextId();

      final result = await unitOfWork.execute(() async {
        await eventStore.appendToStream(streamId, events.events(2), 0);
        await sagaStore.save(saga(sagaId));
        await processedEvents.markProcessed('Balances', 'Balances', eventId);
        return 42;
      });

      expect(result, 42);
      expect(await eventStore.getStreamVersion(streamId), 2);
      expect(await sagaStore.load('TransferMoney', sagaId), isNotNull);
      expect(
        await processedEvents.exists('Balances', 'Balances', eventId),
        isTrue,
      );
    });

    test('reads inside the unit of work see its writes', () async {
      final streamId = events.streamId();

      await unitOfWork.execute(() async {
        await eventStore.appendToStream(streamId, events.events(1), 0);
        expect(await eventStore.getStreamVersion(streamId), 1);
        await eventStore.appendToStream(streamId, events.events(1), 1);
      });

      expect(await eventStore.getStreamVersion(streamId), 2);
    });

    test('rolls back every adapter\'s writes and rethrows', () async {
      final existing = events.streamId();
      await eventStore.appendToStream(existing, events.events(1), 0);
      final streamId = events.streamId();
      final sagaId = events.nextId();
      final eventId = events.nextId();
      final error = StateError('projection failed');

      await expectLater(
        unitOfWork.execute(() async {
          await eventStore.appendToStream(streamId, events.events(2), 0);
          await eventStore.appendToStream(existing, events.events(1), 1);
          await sagaStore.save(saga(sagaId));
          await processedEvents.markProcessed('Balances', 'Balances', eventId);
          throw error;
        }),
        throwsA(same(error)),
      );

      expect(await eventStore.streamExists(streamId), isFalse);
      expect(await eventStore.getStreamVersion(existing), 1);
      expect(await eventStore.loadAll(), hasLength(1));
      expect(await sagaStore.load('TransferMoney', sagaId), isNull);
      expect(
        await processedEvents.exists('Balances', 'Balances', eventId),
        isFalse,
      );
      // The rolled-back append left no trace of its version.
      final result = await eventStore.appendToStream(
        streamId,
        events.events(1),
        0,
      );
      expect(result.version, 1);
    });

    test('rolls back on an optimistic concurrency conflict', () async {
      final streamId = events.streamId();
      final sagaId = events.nextId();
      await eventStore.appendToStream(streamId, events.events(1), 0);

      await expectLater(
        unitOfWork.execute(() async {
          await sagaStore.save(saga(sagaId));
          await eventStore.appendToStream(streamId, events.events(1), 0);
        }),
        throwsA(isA<OptimisticConcurrencyError>()),
      );

      expect(await sagaStore.load('TransferMoney', sagaId), isNull);
    });

    test('a nested execute joins the outer one', () async {
      final inner = events.streamId();

      await expectLater(
        unitOfWork.execute(() async {
          await unitOfWork.execute(
            () => eventStore.appendToStream(inner, events.events(1), 0),
          );
          throw StateError('outer failed');
        }),
        throwsStateError,
      );

      expect(await eventStore.streamExists(inner), isFalse);
    });

    test('a later unit of work is unaffected by an earlier rollback', () async {
      final committed = events.streamId();
      final rolledBack = events.streamId();

      await expectLater(
        unitOfWork.execute(() async {
          await eventStore.appendToStream(rolledBack, events.events(1), 0);
          throw StateError('rollback');
        }),
        throwsStateError,
      );
      await unitOfWork.execute(
        () => eventStore.appendToStream(committed, events.events(1), 0),
      );

      expect(await eventStore.streamExists(committed), isTrue);
      expect(await eventStore.streamExists(rolledBack), isFalse);
    });
  });
}
