import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  for (final mode in ConsistencyMode.values) {
    group('SagaRebuilder, ${mode.name}', () {
      late TransferHarness h;
      late SagaRebuilder rebuilder;

      setUp(() {
        h = TransferHarness(mode);
        rebuilder = SagaRebuilder(
          eventStore: h.eventStore,
          sagaStore: h.sagaStore,
          processedEvents: h.processedEvents,
        );
      });

      void expectSameSaga(SagaRecord actual, SagaRecord expected) {
        expect(actual.status, expected.status);
        expect(actual.currentStep, expected.currentStep);
        expect(actual.failureReason, expected.failureReason);
        expect(actual.state, expected.state);
      }

      test('rebuilds corrupted state without dispatching commands', () async {
        await h.openWallets();
        final request = await h.requestTransfer(cents: 30, fee: 5);
        final original = (await h.sagaRecord(request))!;
        await h.sagaStore.save(
          SagaSaveInput(
            sagaId: original.sagaId,
            sagaType: original.sagaType,
            correlationId: original.correlationId,
            state: const {'state': {}, 'compensations': []},
            status: SagaStatus.running,
          ),
        );
        final sent = h.sent.length;

        final result = await rebuilder.rebuildInstance(
          TransferSaga.new,
          request.correlationId,
        );

        expect(result.succeeded, isTrue, reason: '${result.error}');
        expect(result.eventsReplayed, 5);
        expect(result.commandsDiscarded, 4);
        expectSameSaga(result.record!, original);
        expectSameSaga((await h.sagaRecord(request))!, original);
        expect(h.sent, hasLength(sent));
        expect(await h.balance(h.from), 65);
        expect(await h.balance(h.to), 30);
      });

      test('rebuilds a compensated saga', () async {
        await h.openWallets(toFrozen: true);
        final request = await h.requestTransfer(cents: 30);
        final original = (await h.sagaRecord(request))!;
        await h.sagaStore.delete(original.sagaType, original.sagaId);

        final result = await rebuilder.rebuildInstance(
          TransferSaga.new,
          request.correlationId,
        );

        expect(result.record!.status, SagaStatus.failed);
        expectSameSaga(result.record!, original);
        expect(await h.balance(h.from), 100);
      });

      test('rebuildType finds every saga from its starting event', () async {
        await h.openWallets();
        final first = await h.requestTransfer(cents: 10, fee: 0);
        final second = RequestTransfer(
          transferId: TransferId.generate(),
          from: h.from,
          to: h.to,
          cents: 20,
        );
        await h.dispatcher.dispatch(second);
        final records = [
          (await h.sagaRecord(first))!,
          (await h.sagaRecord(second))!,
        ];
        for (final r in records) {
          await h.sagaStore.delete(r.sagaType, r.sagaId);
        }

        final result = await rebuilder.rebuildType(
          TransferSaga.new,
          batchSize: 4,
        );

        expect(result.sagaType, 'TransferSaga');
        expect(result.allSucceeded, isTrue);
        expect(
          [for (final r in result.results) r.sagaId],
          [first.correlationId, second.correlationId],
        );
        expectSameSaga((await h.sagaRecord(first))!, records[0]);
        expectSameSaga((await h.sagaRecord(second))!, records[1]);
      });
    });
  }

  test('NullCommandDispatcher discards commands', () async {
    final discard = NullCommandDispatcher();
    final SagaCommandDispatch dispatch = discard.call;
    final command = CompleteTransfer(TransferId.generate());

    await dispatch(command);

    expect(discard.discarded, [command]);
  });
}
