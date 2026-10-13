import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late TransferSaga saga;
  late TransferRequested requested;
  final from = WalletId.generate();
  final to = WalletId.generate();
  final transferId = TransferId.generate();

  /// An event in the saga's trace, caused by [cause].
  E inTrace<E extends DomainEvent>(DomainEvent cause, E Function() create) =>
      ExecutionContext.run(ExecutionContext.forEvent(cause), create);

  setUp(() {
    saga = TransferSaga();
    requested = TransferRequested(
      transferId: '$transferId',
      from: '$from',
      to: '$to',
      cents: 30,
      fee: 5,
    );
  });

  group('handle', () {
    test('a starting event starts the saga', () {
      final commands = saga.handle(requested);

      expect(saga.sagaId, requested.correlationId);
      expect(saga.status, SagaStatus.running);
      expect(saga.currentStep, 'startsWhenTransferRequested');
      expect(saga.state.cents, 30);
      expect(commands.single, isA<Withdraw>());
    });

    test('commands carry the saga ID and the event as cause', () {
      final withdraw = saga.handle(requested).single;

      expect(withdraw.correlationId, saga.sagaId);
      expect(withdraw.causationId, requested.id);
    });

    test('command IDs are derived from the saga type and event', () {
      final first = saga.handle(requested).single;
      final again = TransferSaga().handle(requested).single;
      final other = TransferSaga().handle(
        TransferRequested(
          transferId: '$transferId',
          from: '$from',
          to: '$to',
          cents: 30,
          fee: 5,
        ),
      );

      expect(again.id, first.id);
      expect(first.id.version, 7);
      expect(
        first.id.uuid.replaceAll('-', '').substring(0, 12),
        requested.occurredAt.millisecondsSinceEpoch
            .toRadixString(16)
            .padLeft(12, '0'),
      );
      expect(other.single.id, isNot(first.id));
    });

    test('compensation commands get distinct derived IDs', () {
      saga.handle(requested);
      final withdrawn = MoneyWithdrawn(30);
      final deposited = MoneyDeposited(30);
      saga.handle(withdrawn);
      saga.handle(deposited);
      final rejected = FeeRejected(5);
      final commands = saga.handle(rejected);

      final replay = TransferSaga()
        ..handle(requested)
        ..handle(withdrawn)
        ..handle(deposited);
      expect(
        replay.handle(rejected).map((c) => c.id),
        commands.map((c) => c.id),
      );
      expect(commands[0].id, isNot(commands[1].id));
    });

    test('happy path ends completed', () {
      saga.handle(requested);
      final withdrawn = inTrace(requested, () => MoneyWithdrawn(30));
      expect(saga.handle(withdrawn).single, isA<DepositMoney>());
      expect(
        saga.handle(inTrace(withdrawn, () => MoneyDeposited(30))).single,
        isA<ChargeFee>(),
      );
      expect(
        saga.handle(inTrace(withdrawn, () => FeeCharged(5))).single,
        isA<CompleteTransfer>(),
      );
      expect(saga.handle(inTrace(withdrawn, TransferCompleted.new)), isEmpty);

      expect(saga.status, SagaStatus.completed);
      expect(saga.isTerminal, isTrue);
      expect(saga.currentStep, 'completedWhenTransferCompleted');
      expect(saga.compensations.names, ['refundWithdrawal', 'reverseDeposit']);
    });

    test('compensation returns the undo commands in reverse order', () {
      saga.handle(requested);
      saga.handle(MoneyWithdrawn(30));
      saga.handle(MoneyDeposited(30));

      final commands = saga.handle(FeeRejected(5));

      expect(commands, [isA<ReverseDeposit>(), isA<Refund>()]);
      expect((commands[0] as ReverseDeposit).walletId, to);
      expect((commands[1] as Refund).walletId, from);
      expect(saga.status, SagaStatus.compensating);
      expect(saga.compensations.isEmpty, isTrue);
    });

    test('compensation factories see the state at compensation time', () {
      saga.handle(requested);
      saga.handle(MoneyWithdrawn(30));
      saga.state = TransferState(
        transferId: transferId,
        from: from,
        to: to,
        cents: 7,
      );

      final refund = saga.handle(DepositRejected(30)).single as Refund;
      expect(refund.cents, 7);
    });

    test('a compensating saga continues, then fails through markFailed', () {
      saga.handle(requested);
      saga.handle(MoneyWithdrawn(30));
      saga.handle(DepositRejected(30));

      expect(saga.handle(MoneyRefunded(30)).single, isA<FailTransfer>());
      expect(saga.status, SagaStatus.compensating);

      expect(saga.handle(TransferFailed('compensated')), isEmpty);
      expect(saga.status, SagaStatus.failed);
      expect(saga.failureReason, 'compensated');
      expect(saga.currentStep, 'completedWhenTransferFailed');
    });

    test('an event with no handler is ignored once started', () {
      saga.handle(requested);
      expect(saga.handle(WalletOpened(1)), isEmpty);
      expect(saga.currentStep, 'startsWhenTransferRequested');
    });

    group('invalid transitions (spec §13.2)', () {
      test('initial + unhandled event: not started', () {
        expect(
          () => saga.handle(WalletOpened(1)),
          throwsA(isA<SagaNotStartedError>()),
        );
      });

      for (final (kind, event) in [
        ('continueWhen', () => MoneyWithdrawn(1)),
        ('compensateWhen', () => DepositRejected(1)),
        ('completedWhen', TransferCompleted.new),
      ]) {
        test('initial + $kind: not started', () {
          expect(
            () => saga.handle(event()),
            throwsA(isA<SagaNotStartedError>()),
          );
          expect(saga.status, isNull);
          expect(saga.sagaId, isNull);
        });
      }

      test('running + startsWhen: already started', () {
        saga.handle(requested);
        expect(
          () => saga.handle(requested),
          throwsA(isA<SagaAlreadyStartedError>()),
        );
        expect(saga.status, SagaStatus.running);
      });

      test('compensating + startsWhen: invalid transition', () {
        saga.handle(requested);
        saga.handle(WithdrawalRejected(30));
        expect(
          () => saga.handle(requested),
          throwsA(isA<InvalidSagaTransitionError>()),
        );
      });

      for (final (status, events) in [
        ('completed', [MoneyWithdrawn(30), TransferCompleted()]),
        ('failed', [TransferFailed('no')]),
      ]) {
        test('$status + any event: already completed', () {
          saga.handle(requested);
          events.forEach(saga.handle);
          expect(saga.status?.code, status.toUpperCase());

          for (final event in [requested, MoneyWithdrawn(1), WalletOpened(1)]) {
            expect(
              () => saga.handle(event),
              throwsA(isA<SagaAlreadyCompletedError>()),
            );
          }
        });
      }
    });
  });

  group('routing', () {
    test('completedWhen beats continueWhen for the same event', () {
      final saga = _PrioritySaga()..handle(requested);
      saga.handle(MoneyWithdrawn(1));
      expect(saga.status, SagaStatus.completed);
    });

    test('an exact type beats a supertype within one kind', () {
      final saga = _PrioritySaga()..handle(requested);
      saga.handle(MoneyDeposited(1));
      expect(saga.currentStep, 'continueWhenMoneyDeposited');
      expect(saga.state, ['exact']);
    });

    test('canStart and routes', () {
      expect(saga.canStart(requested), isTrue);
      expect(saga.canStart(MoneyWithdrawn(1)), isFalse);
      expect(saga.routeFor(WalletOpened(1)), isNull);
      expect(
        saga.routes.map((r) => (r.kind, r.eventType)),
        contains((SagaHandlerKind.compensateWhen, FeeRejected)),
      );
    });

    test('duplicate handlers are rejected', () {
      expect(() => _DuplicateSaga(), throwsA(isA<InvalidConfigurationError>()));
    });
  });

  group('persistence', () {
    SagaRecord recordOf(SagaSaveInput input) => SagaRecord(
      sagaId: input.sagaId,
      sagaType: input.sagaType,
      correlationId: input.correlationId,
      state: input.state,
      status: input.status,
      currentStep: input.currentStep,
      failureReason: input.failureReason,
      startedAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

    test('round-trips state, status and the compensation stack', () {
      saga.handle(requested);
      saga.handle(MoneyWithdrawn(30));
      saga.handle(MoneyDeposited(30));
      final input = saga.toSaveInput();

      expect(input.sagaId, requested.correlationId);
      expect(input.correlationId, requested.correlationId);
      expect(input.sagaType, 'TransferSaga');
      expect(input.status, SagaStatus.running);
      expect(input.currentStep, 'continueWhenMoneyDeposited');
      expect(input.state['compensations'], [
        'refundWithdrawal',
        'reverseDeposit',
      ]);

      final restored = TransferSaga()..restore(recordOf(input));
      expect(restored.sagaId, saga.sagaId);
      expect(restored.status, SagaStatus.running);
      expect(restored.currentStep, saga.currentStep);
      expect(restored.state.to, to);
      expect(restored.handle(FeeRejected(5)), [
        isA<ReverseDeposit>(),
        isA<Refund>(),
      ]);
    });

    test('a saga that has not started cannot be saved', () {
      expect(saga.toSaveInput, throwsStateError);
    });

    test('restoring an undefined compensation is a configuration error', () {
      saga.handle(requested);
      final input = saga.toSaveInput();
      final record = recordOf(input);
      final tampered = SagaRecord(
        sagaId: record.sagaId,
        sagaType: record.sagaType,
        correlationId: record.correlationId,
        state: {
          ...record.state,
          'compensations': ['renamed'],
        },
        status: record.status,
        startedAt: record.startedAt,
        updatedAt: record.updatedAt,
      );
      expect(
        () => TransferSaga().restore(tampered),
        throwsA(isA<InvalidConfigurationError>()),
      );
    });

    test('restoring malformed state is a serialization error', () {
      saga.handle(requested);
      final record = recordOf(saga.toSaveInput());
      expect(
        () => TransferSaga().restore(
          SagaRecord(
            sagaId: record.sagaId,
            sagaType: record.sagaType,
            correlationId: record.correlationId,
            state: {'cents': 1},
            status: record.status,
            startedAt: record.startedAt,
            updatedAt: record.updatedAt,
          ),
        ),
        throwsA(isA<SerializationError>()),
      );
    });
  });

  group('CompensationStack', () {
    late CompensationStack stack;
    late List<String> calls;

    setUp(() {
      calls = [];
      stack = CompensationStack()
        ..define('a', () {
          calls.add('a');
          return [_Undo('a')];
        })
        ..define('b', () {
          calls.add('b');
          return [_Undo('b1'), _Undo('b2')];
        });
    });

    test('factories run only when popped', () {
      stack
        ..push('a')
        ..push('b');
      expect(calls, isEmpty);
      expect(stack.length, 2);
    });

    test('pop takes one entry, most recent first', () {
      stack
        ..push('a')
        ..push('b');
      expect(stack.pop().map((c) => '$c'), ['b1', 'b2']);
      expect(stack.names, ['a']);
      expect(stack.pop().map((c) => '$c'), ['a']);
      expect(stack.pop(), isEmpty);
    });

    test('takeAll empties the stack in LIFO order', () {
      stack
        ..push('a')
        ..push('b')
        ..push('a');
      expect(stack.takeAll().map((c) => '$c'), ['a', 'b1', 'b2', 'a']);
      expect(calls, ['a', 'b', 'a']);
      expect(stack.isEmpty, isTrue);
    });

    test('unknown and duplicate names are configuration errors', () {
      expect(() => stack.push('c'), throwsA(isA<InvalidConfigurationError>()));
      expect(
        () => stack.restore(['a', 'c']),
        throwsA(isA<InvalidConfigurationError>()),
      );
      expect(
        () => stack.define('a', () => []),
        throwsA(isA<InvalidConfigurationError>()),
      );
    });
  });
}

class _Undo extends Command {
  _Undo(this.label);

  final String label;

  @override
  String toString() => label;
}

class _PrioritySaga extends ProcessManager<List<String>> {
  _PrioritySaga() : super([]) {
    startsWhen<TransferRequested>((e) => const []);
    continueWhen<MoneyWithdrawn>((e) => const []);
    completedWhen<MoneyWithdrawn>((e) => const []);
    continueWhen<WalletEvent>((e) {
      state = ['supertype'];
      return const [];
    });
    continueWhen<MoneyDeposited>((e) {
      state = ['exact'];
      return const [];
    });
  }

  @override
  String get sagaType => 'Priority';

  @override
  Map<String, Object?> stateToJson(List<String> state) => {'s': state};

  @override
  List<String> stateFromJson(Map<String, Object?> json) =>
      (json['s']! as List<Object?>).cast();
}

class _DuplicateSaga extends _PrioritySaga {
  _DuplicateSaga() {
    continueWhen<MoneyWithdrawn>((e) => const []);
  }
}
