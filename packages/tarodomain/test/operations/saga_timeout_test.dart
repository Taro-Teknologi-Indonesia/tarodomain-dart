import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Withdraws, then waits for an approval that never comes. On timeout it
/// refunds the withdrawal, and fails once the refund is done.
class ApprovalSaga extends ProcessManager<TransferState> {
  ApprovalSaga({bool handlesTimeout = true, this.onTimeout})
    : super(const TransferState()) {
    startsWhen<TransferRequested>((e) {
      state = TransferState(
        transferId: TransferId.fromExisting(e.transferId),
        from: WalletId.fromExisting(e.from),
        to: WalletId.fromExisting(e.to),
        cents: e.cents,
      );
      return [Withdraw(state.from!, state.cents)];
    });
    continueWhen<MoneyWithdrawn>((e) {
      registerCompensation('refund');
      return const [];
    });
    if (handlesTimeout) {
      compensateWhen<SagaTimeout>(
        (e) => onTimeout?.call(e) ?? getCompensationCommands(),
      );
    }
    continueWhen<MoneyRefunded>((e) {
      markFailed('timed out');
      return const [];
    });
    defineCompensation('refund', () => [Refund(state.from!, state.cents)]);
  }

  final List<Command>? Function(SagaTimeout event)? onTimeout;

  @override
  String get sagaType => 'ApprovalSaga';

  @override
  Map<String, Object?> stateToJson(TransferState state) => state.toJson();

  @override
  TransferState stateFromJson(Map<String, Object?> json) =>
      TransferState.fromJson(json);
}

/// A scheduler for [h]'s saga whose clock is an hour ahead, so every
/// running saga has timed out.
SagaTimeoutScheduler lateScheduler(TransferHarness h) => SagaTimeoutScheduler(
  handler: h.saga,
  timeout: const Duration(minutes: 1),
  clock: () => DateTime.timestamp().add(const Duration(hours: 1)),
);

void main() {
  for (final mode in ConsistencyMode.values) {
    group('saga timeout, ${mode.name}', () {
      test('a timed-out saga compensates, then fails', () async {
        final h = TransferHarness(mode, create: ApprovalSaga.new);
        await h.openWallets();
        final request = await h.requestTransfer(cents: 30);
        expect(await h.balance(h.from), 70);
        expect((await h.sagaRecord(request))!.status, SagaStatus.running);

        final results = await lateScheduler(h).run();

        expect(results.single.outcome, SagaTimeoutOutcome.handled);
        expect(results.single.sagaId, request.correlationId);
        expect(h.sentTypes, ['Withdraw', 'Refund']);
        expect(await h.balance(h.from), 100);
        final record = (await h.sagaRecord(request))!;
        expect(record.status, SagaStatus.failed);
        expect(record.failureReason, 'timed out');

        expect(await lateScheduler(h).run(), isEmpty);
      });

      test('a saga with no timeout handler is marked failed', () async {
        final h = TransferHarness(
          mode,
          create: () => ApprovalSaga(handlesTimeout: false),
        );
        await h.openWallets();
        final request = await h.requestTransfer(cents: 30);

        final results = await lateScheduler(h).run();

        expect(results.single.outcome, SagaTimeoutOutcome.failed);
        final record = (await h.sagaRecord(request))!;
        expect(record.status, SagaStatus.failed);
        expect(record.failureReason, 'timeout');
        expect(await h.balance(h.from), 70);
      });
    });
  }

  group('SagaTimeoutScheduler', () {
    late TransferHarness h;
    late RequestTransfer request;

    Future<void> start({
      List<Command>? Function(SagaTimeout event)? onTimeout,
    }) async {
      h = TransferHarness(
        ConsistencyMode.strong,
        create: () => ApprovalSaga(onTimeout: onTimeout),
      );
      await h.openWallets();
      request = await h.requestTransfer(cents: 30);
    }

    test('leaves sagas that have not timed out', () async {
      await start();

      final results = await SagaTimeoutScheduler(
        handler: h.saga,
        timeout: const Duration(hours: 1),
      ).run();

      expect(results, isEmpty);
    });

    test('a non-retryable handler error fails the saga', () async {
      await start(onTimeout: (_) => throw domainError());

      final results = await lateScheduler(h).run();

      expect(results.single.outcome, SagaTimeoutOutcome.failed);
      expect(results.single.error, isA<InvalidAggregateStateError>());
      final record = (await h.sagaRecord(request))!;
      expect(record.status, SagaStatus.failed);
      expect(record.failureReason, startsWith('timeout handler failed'));
    });

    test('a retryable error leaves the saga for the next run, which '
        'dispatches the same commands', () async {
      await start();
      h.sagaStore.saveError = retryableError();
      h.sagaStore.failSave = (input) => input.status == SagaStatus.compensating;

      final first = await lateScheduler(h).run();

      expect(first.single.outcome, SagaTimeoutOutcome.retryLater);
      expect((await h.sagaRecord(request))!.status, SagaStatus.running);
      expect(await h.balance(h.from), 100);

      h.sagaStore.failSave = null;
      final second = await lateScheduler(h).run();

      expect(second.single.outcome, SagaTimeoutOutcome.handled);
      final refunds = h.sent.whereType<Refund>().toList();
      expect(refunds, hasLength(2));
      expect(refunds[0].id, refunds[1].id);
      expect(await h.balance(h.from), 100);
    });

    test('only times out its own saga type', () async {
      await start();
      final other = SagaEventHandler(
        create: TransferSaga.new,
        sagaStore: h.sagaStore,
        processedEvents: h.processedEvents,
        dispatch: (_) async {},
      );

      final results = await SagaTimeoutScheduler(
        handler: other,
        timeout: const Duration(minutes: 1),
        clock: () => DateTime.timestamp().add(const Duration(hours: 1)),
      ).run();

      expect(results, isEmpty);
      expect((await h.sagaRecord(request))!.status, SagaStatus.running);
    });

    test('rejects invalid settings', () async {
      await start();
      expect(
        () => SagaTimeoutScheduler(handler: h.saga, timeout: Duration.zero),
        throwsA(isA<InvalidConfigurationError>()),
      );
    });
  });

  group('SagaTimeout', () {
    final record = SagaRecord(
      sagaId: MoneyDeposited(0).id,
      sagaType: 'ApprovalSaga',
      correlationId: MoneyDeposited(0).id,
      state: const {},
      status: SagaStatus.running,
      currentStep: 'continueWhenMoneyWithdrawn',
      startedAt: DateTime.utc(2026, 10, 12, 9),
      updatedAt: DateTime.utc(2026, 10, 12, 10),
    );

    test('is correlated with the saga and derived from its state', () {
      final event = SagaTimeout.forRecord(record, const Duration(minutes: 5));

      expect(event.correlationId, record.sagaId);
      expect(event.causationId, isNull);
      expect(event.occurredAt, DateTime.utc(2026, 10, 12, 10, 5));
      expect(event.toData(), {
        'sagaType': 'ApprovalSaga',
        'sagaId': record.sagaId.uuid,
        'lastStep': 'continueWhenMoneyWithdrawn',
      });
      final again = SagaTimeout.forRecord(record, const Duration(minutes: 5));
      expect(again.id, event.id);
    });

    test('a saga updated since gets a new event', () {
      final later = SagaRecord(
        sagaId: record.sagaId,
        sagaType: record.sagaType,
        correlationId: record.correlationId,
        state: record.state,
        status: record.status,
        startedAt: record.startedAt,
        updatedAt: record.updatedAt.add(const Duration(seconds: 1)),
      );
      const timeout = Duration(minutes: 5);

      expect(
        SagaTimeout.forRecord(later, timeout).id,
        isNot(SagaTimeout.forRecord(record, timeout).id),
      );
    });
  });
}
