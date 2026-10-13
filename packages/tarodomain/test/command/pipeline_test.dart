import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late Harness h;
  late AccountId id;
  late DepositHandler depositHandler;
  Future<void> Function()? beforeSave;

  setUp(() {
    h = Harness();
    id = AccountId.generate();
    beforeSave = null;
    h.registry
      ..register<OpenAccount>(
        'OpenAccount',
        (c) => OpenAccountHandler(h.repository(c.eventBus)),
      )
      ..register<Deposit>(
        'Deposit',
        (c) => depositHandler = DepositHandler(
          h.repository(c.eventBus),
          beforeSave: beforeSave,
        ),
      );
  });

  Future<CommandDispatchResult> run(
    CommandPipeline pipeline,
    Command command,
  ) => pipeline.dispatch(command, h.registry.resolve(command));

  for (final mode in ConsistencyMode.values) {
    CommandPipeline pipeline() =>
        mode == ConsistencyMode.strong ? h.strong : h.eventual;

    group('${mode.name} pipeline', () {
      setUp(() => run(pipeline(), OpenAccount(accountId: id, owner: 'ann')));

      test('runs the handler and reports the result', () async {
        final command = Deposit(accountId: id, cents: 5);
        final result = await run(pipeline(), command);

        expect(result.status, CommandDispatchStatus.processed);
        expect(result.commandId, command.id);
        expect(result.commandType, 'Deposit');
        expect(result.handlerName, 'DepositHandler');
        expect(result.consistency, mode);
        expect(result.attempts, 1);
        expect(await h.commands.exists(command.id), isTrue);
        expect(
          (await h.commands.list('DepositHandler')).single.commandType,
          'Deposit',
        );
      });

      test('events carry the command as cause', () async {
        final command = Deposit(accountId: id, cents: 5);
        await run(pipeline(), command);

        final deposited = (await h.stream(id)).last;
        expect(deposited.correlationId, command.correlationId);
        expect(deposited.causationId, command.id);
      });

      test('retries after a forced conflict', () async {
        var calls = 0;
        beforeSave = () async {
          if (++calls == 1) await h.depositDirectly(id, 100);
        };
        final result = await run(pipeline(), Deposit(accountId: id, cents: 5));

        expect(result.attempts, 2);
        expect(calls, 2);
        expect(depositHandler.attempts, 1, reason: 'a fresh handler per try');
        final deposits = (await h.stream(id)).whereType<FundsDeposited>();
        // Strong: the competing write ran inside the rolled-back unit of
        // work. Eventual: it stays, and the retry deposits on top of it.
        expect(
          deposits.map((e) => e.cents),
          mode == ConsistencyMode.strong ? [5] : [100, 5],
        );
      });

      test('a duplicate command ID is a no-op', () async {
        final command = Deposit(accountId: id, cents: 5);
        await run(pipeline(), command);
        final again = await run(pipeline(), command);

        expect(again.status, CommandDispatchStatus.duplicate);
        expect(again.isDuplicate, isTrue);
        expect(await h.stream(id), hasLength(2));
      });

      test('domain errors are not retried and mark nothing', () async {
        final command = OpenAccount(accountId: id, owner: 'bob');
        await expectLater(
          run(pipeline(), command),
          throwsA(isA<AggregateAlreadyExistsError>()),
        );
        expect(await h.commands.exists(command.id), isFalse);
      });

      test('gives up after the configured retries', () async {
        var attempts = 0;
        beforeSave = () async {
          attempts++;
          await h.depositDirectly(id, 1);
        };
        await expectLater(
          run(pipeline(), Deposit(accountId: id, cents: 5)),
          throwsA(isA<OptimisticConcurrencyError>()),
        );
        expect(attempts, 4);
      });
    });
  }

  group('strong pipeline', () {
    late RecordingProjection projection;

    setUp(() {
      projection = RecordingProjection(
        'balance',
        processedEvents: h.processedEvents,
      );
      h.strongBus.subscribe(projection);
    });

    test('projections run inside the command context', () async {
      final command = OpenAccount(accountId: id, owner: 'ann');
      await run(h.strong, command);

      expect(projection.seen.single, isA<AccountOpened>());
      expect(projection.contexts.single?.causationId, command.id);
      expect(await h.processedEvents.count('balance'), 1);
    });

    test('a failing projection rolls back the whole command', () async {
      projection.failWith = StateError('projection down');
      final command = OpenAccount(accountId: id, owner: 'ann');

      await expectLater(
        run(h.strong, command),
        throwsA(
          isA<EventHandlerFailedError>().having(
            (e) => e.context['handler'],
            'handler',
            'balance',
          ),
        ),
      );
      expect(projection.seen, hasLength(1), reason: 'not retried');
      expect(await h.stream(id), isEmpty);
      expect(await h.processedEvents.count('balance'), 0);
      expect(await h.commands.exists(command.id), isFalse);
    });

    test('a conflict in a projection is retried', () async {
      var failures = 1;
      h.strongBus
        ..unsubscribe(projection)
        ..subscribe(
          _Callback('flaky', () {
            if (failures-- > 0) throw OptimisticConcurrencyError('conflict');
          }),
        );

      final result = await run(
        h.strong,
        OpenAccount(accountId: id, owner: 'a'),
      );

      expect(result.attempts, 2);
      expect(await h.stream(id), hasLength(1));
    });

    test('a nested dispatch joins the outer unit of work', () async {
      final unitOfWork = h.strong.unitOfWork;
      await expectLater(
        unitOfWork.execute(() async {
          await run(h.strong, OpenAccount(accountId: id, owner: 'ann'));
          throw StateError('outer fails');
        }),
        throwsStateError,
      );
      expect(await h.stream(id), isEmpty);
    });

    test('a nested dispatch does not retry conflicts itself', () async {
      await run(h.strong, OpenAccount(accountId: id, owner: 'ann'));
      var calls = 0;
      beforeSave = () async {
        calls++;
        await h.depositDirectly(id, 1);
      };

      await expectLater(
        h.strong.unitOfWork.execute(
          () => run(h.strong, Deposit(accountId: id, cents: 5)),
        ),
        throwsA(isA<OptimisticConcurrencyError>()),
      );
      expect(calls, 1);
    });
  });

  group('eventual pipeline', () {
    setUp(() => run(h.eventual, OpenAccount(accountId: id, owner: 'ann')));

    test('a retry re-checks idempotency', () async {
      final command = Deposit(accountId: id, cents: 5);
      beforeSave = () async {
        // Another worker processes the same command meanwhile.
        await h.depositDirectly(id, 5);
        await h.commands.markProcessed(command.id, 'Deposit', 'other');
      };
      final result = await run(h.eventual, command);

      expect(result.status, CommandDispatchStatus.duplicate);
      expect(result.attempts, 2);
      expect(await h.stream(id), hasLength(2));
    });

    test('a failing handler leaves the events stored', () async {
      final projection = RecordingProjection('balance')
        ..failWith = StateError('down');
      h.eventualBus.subscribe(projection);
      final command = Deposit(accountId: id, cents: 5);

      await expectLater(
        run(h.eventual, command),
        throwsA(isA<EventHandlerFailedError>()),
      );
      expect(await h.stream(id), hasLength(2));
      expect(await h.commands.exists(command.id), isFalse);
    });
  });
}

class _Callback implements EventHandler {
  _Callback(this.name, this.callback);

  @override
  final String name;
  final void Function() callback;

  @override
  Future<void> handle(DomainEvent event) async => callback();
}
