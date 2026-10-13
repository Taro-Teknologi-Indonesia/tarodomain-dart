import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

void main() {
  const starts = SagaHandlerKind.startsWhen;
  const continues = SagaHandlerKind.continueWhen;
  const compensates = SagaHandlerKind.compensateWhen;
  const completes = SagaHandlerKind.completedWhen;

  // Every cell of the spec §13.2 table: the next state, or the error type.
  final table = <(SagaState, SagaHandlerKind), Object>{
    (SagaState.initial, starts): SagaState.running,
    (SagaState.initial, continues): isA<SagaNotStartedError>(),
    (SagaState.initial, compensates): isA<SagaNotStartedError>(),
    (SagaState.initial, completes): isA<SagaNotStartedError>(),
    (SagaState.running, starts): isA<SagaAlreadyStartedError>(),
    (SagaState.running, continues): SagaState.running,
    (SagaState.running, compensates): SagaState.compensating,
    (SagaState.running, completes): SagaState.completed,
    (SagaState.compensating, starts): isA<InvalidSagaTransitionError>(),
    (SagaState.compensating, continues): SagaState.compensating,
    (SagaState.compensating, compensates): SagaState.compensating,
    (SagaState.compensating, completes): SagaState.completed,
    for (final kind in SagaHandlerKind.values) ...{
      (SagaState.completed, kind): isA<SagaAlreadyCompletedError>(),
      (SagaState.failed, kind): isA<SagaAlreadyCompletedError>(),
    },
  };

  test('the table covers every state and handler kind', () {
    expect(
      table,
      hasLength(SagaState.values.length * SagaHandlerKind.values.length),
    );
  });

  for (final MapEntry(key: (from, kind), value: expected) in table.entries) {
    test('${from.name} + ${kind.name}', () {
      if (expected is SagaState) {
        expect(SagaStateMachine.transition(from, kind), expected);
        expect(SagaStateMachine.canTransition(from, kind), isTrue);
      } else {
        expect(
          () => SagaStateMachine.transition(from, kind),
          throwsA(
            allOf(
              expected,
              isA<FrameworkError>()
                  .having((e) => e.retryable, 'retryable', isFalse)
                  .having((e) => e.context['state'], 'state', from.name)
                  .having((e) => e.context['handler'], 'handler', kind.name),
            ),
          ),
        );
        expect(SagaStateMachine.canTransition(from, kind), isFalse);
      }
    });
  }

  test('passes extra context to the error', () {
    expect(
      () => SagaStateMachine.transition(
        SagaState.completed,
        continues,
        context: {'sagaType': 'T'},
      ),
      throwsA(
        isA<SagaAlreadyCompletedError>().having(
          (e) => e.context['sagaType'],
          'sagaType',
          'T',
        ),
      ),
    );
  });

  test('SagaState maps to and from SagaStatus', () {
    for (final state in SagaState.values) {
      expect(SagaState.of(state.status), state);
      expect(state.isTerminal, state.status?.isTerminal ?? false);
    }
  });
}
