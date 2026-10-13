import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  for (final mode in ConsistencyMode.values) {
    group('transfer through the framework, ${mode.name} by default', () {
      late TaroDomain framework;
      final from = WalletId.generate();
      final to = WalletId.generate();

      setUp(() async {
        framework = transferApp(mode).build().createRuntime();
        await framework.dispatch(OpenWallet(from, 100));
        await framework.dispatch(OpenWallet(to, 0));
      });

      test('the saga moves the money and the projection follows', () async {
        final transferId = TransferId.generate();
        final request = RequestTransfer(
          transferId: transferId,
          from: from,
          to: to,
          cents: 30,
          fee: 5,
        );
        final result = await framework.dispatch(request);

        expect(result.consistency, mode);
        expect(await balanceOf(framework, from), 65);
        expect(await balanceOf(framework, to), 30);
        final ledger = framework.di.resolve(ledgerToken);
        expect(ledger.totalCents, 95);
        expect(ledger.completedTransfers, 1);

        final record = await framework.sagaStore.load(
          'TransferSaga',
          request.correlationId,
        );
        expect(record?.status, SagaStatus.completed);

        final trace = await framework.formatTrace(request.correlationId);
        expect(trace, contains('command ${request.id.uuid}'));
        expect(trace, contains('TransferCompleted'));
      });

      test('a rejected deposit compensates', () async {
        final frozen = WalletId.generate();
        await framework.dispatch(OpenWallet(frozen, 0, frozen: true));
        await framework.dispatch(
          RequestTransfer(
            transferId: TransferId.generate(),
            from: from,
            to: frozen,
            cents: 30,
          ),
        );
        expect(await balanceOf(framework, from), 100);
        expect(framework.di.resolve(ledgerToken).failedTransfers, 1);
      });

      test(
        'runScheduled catches every handler up without redoing work',
        () async {
          final result = await framework.runScheduled();
          expect(
            [for (final r in result.catchUp) r.subscription],
            ['ledger', 'TransferSaga'],
          );
          expect(result.catchUp.every((r) => r.error == null), isTrue);
          expect(framework.di.resolve(ledgerToken).totalCents, 100);
          expect(await framework.subscriptions.areAllCaughtUp(), isTrue);
        },
      );
    });
  }

  group('runtime', () {
    test('a command can override the default consistency', () async {
      final framework = transferEvents(TaroDomain.builder())
          .useLocal()
          .aggregate<Wallet, WalletId>('Wallet', (a) => a.factory(Wallet.new))
          .command<OpenWallet>(
            'OpenWallet',
            (c) => WalletHandler(c.repository()),
            consistency: ConsistencyMode.strong,
          )
          .command<Withdraw>('Withdraw', (c) => WalletHandler(c.repository()))
          .build()
          .createRuntime();
      final id = WalletId.generate();
      final opened = await framework.dispatch(OpenWallet(id, 5));
      final withdrawn = await framework.dispatch(Withdraw(id, 1));
      expect(opened.consistency, ConsistencyMode.strong);
      expect(withdrawn.consistency, ConsistencyMode.eventual);
      expect(framework.consistencyOf(OpenWallet), ConsistencyMode.strong);
      expect(framework.consistencyOf(Withdraw), ConsistencyMode.eventual);
      expect(
        () => framework.consistencyOf(Refund),
        throwsA(isA<CommandHandlerNotRegisteredError>()),
      );
    });

    test('the strong pipeline runs a strong command atomically', () async {
      final framework = transferApp(ConsistencyMode.strong)
          .projection((c) => ExplodingProjection(c.processedEvents))
          .build()
          .createRuntime();
      final id = WalletId.generate();
      await expectLater(
        framework.dispatch(OpenWallet(id, 10)),
        throwsA(isA<ProjectionHandlerFailedError>()),
      );
      expect(
        await framework.repository<Wallet, WalletId>().exists(id),
        isFalse,
      );
    });

    test('createRuntime needs a provider', () {
      final definition = transferDomain(TaroDomain.builder()).build();
      expect(
        definition.createRuntime,
        throwsA(isA<InvalidConfigurationError>()),
      );
      expect(
        definition.createRuntime(provider: LocalProvider()),
        isA<TaroDomain>(),
      );
    });

    test('strong commands need a provider with a unit of work', () {
      final definition = transferDomain(
        TaroDomain.builder(),
      ).consistency(ConsistencyMode.strong).build();
      expect(
        () => definition.createRuntime(provider: NoTransactionProvider()),
        throwsA(
          isA<InvalidConfigurationError>().having(
            (e) => e.context['commands'],
            'commands',
            contains('OpenWallet'),
          ),
        ),
      );
    });

    test(
      'eventual commands run on a provider without a unit of work',
      () async {
        final framework = transferDomain(
          TaroDomain.builder(),
        ).build().createRuntime(provider: NoTransactionProvider());
        expect(framework.strongEventBus, isNull);
        final id = WalletId.generate();
        await framework.dispatch(OpenWallet(id, 10));
        expect(await balanceOf(framework, id), 10);
      },
    );

    test('runtimes share singletons and have their own scope', () {
      final definition = transferApp(
        ConsistencyMode.eventual,
      ).bindScoped(requestToken, (_) => Object()).build();
      final a = definition.createRuntime();
      final b = definition.createRuntime();
      expect(a.di.resolve(ledgerToken), same(b.di.resolve(ledgerToken)));
      expect(
        a.di.resolve(requestToken),
        isNot(same(b.di.resolve(requestToken))),
      );
      expect(a.di.resolve(TaroTokens.framework), same(a));
      expect(a.di.resolve(TaroTokens.provider), same(a.provider));
      expect(definition.container.has(TaroTokens.framework), isFalse);
    });

    test('runtimes on one local provider share its storage', () async {
      final definition = transferApp(ConsistencyMode.eventual).build();
      final id = WalletId.generate();
      await definition.createRuntime().dispatch(OpenWallet(id, 10));
      expect(await balanceOf(definition.createRuntime(), id), 10);
    });

    test('dispatching an unregistered command throws', () {
      final framework = transferEvents(
        TaroDomain.builder(),
      ).useLocal().build().createRuntime();
      expect(
        () => framework.dispatch(OpenWallet(WalletId.generate(), 1)),
        throwsA(isA<CommandHandlerNotRegisteredError>()),
      );
    });

    test('repository of an unregistered aggregate throws', () {
      final framework = transferEvents(
        TaroDomain.builder(),
      ).useLocal().build().createRuntime();
      expect(
        () => framework.repository<Wallet, WalletId>(),
        throwsA(isA<AggregateNotRegisteredError>()),
      );
    });

    test('a state repository replaces the event-sourced one', () async {
      final saved = <Wallet>[];
      final framework = transferEvents(TaroDomain.builder())
          .useLocal()
          .aggregate<Wallet, WalletId>(
            'Wallet',
            (a) => a.stateRepository((c) => RecordingRepository(saved)),
          )
          .command<OpenWallet>(
            'OpenWallet',
            (c) => WalletHandler(c.repository()),
          )
          .build()
          .createRuntime();
      await framework.dispatch(OpenWallet(WalletId.generate(), 7));
      expect(saved.single.balance, 7);
    });

    test('the global snapshot interval snapshots every aggregate', () async {
      final framework = transferDomain(
        TaroDomain.builder(),
      ).useLocal().snapshotEvery(2).build().createRuntime();
      final id = WalletId.generate();
      await framework.dispatch(OpenWallet(id, 10));
      await framework.dispatch(DepositMoney(id, 5));
      await framework.dispatch(DepositMoney(id, 1));

      final snapshot = await framework.snapshotStore.loadLatest(
        id.value,
        'Wallet',
      );
      expect(snapshot?.sourceVersion, 2);
      expect(snapshot?.data, {'balance': 15, 'frozen': false});
      expect(await balanceOf(framework, id), 16);
    });

    test('projection and saga lookups', () {
      final framework = transferApp(
        ConsistencyMode.eventual,
      ).build().createRuntime();
      expect(framework.projection('ledger'), isA<LedgerProjection>());
      expect(framework.saga('TransferSaga').sagaType, 'TransferSaga');
      expect(
        () => framework.projection('nope'),
        throwsA(isA<ProjectionNotRegisteredError>()),
      );
      expect(
        () => framework.saga('nope'),
        throwsA(isA<SagaNotRegisteredError>()),
      );
    });

    test('handleEvents delivers queued events to every handler', () async {
      final framework = transferApp(
        ConsistencyMode.eventual,
      ).build().createRuntime();
      await framework.handleEvents([WalletOpened(40), MoneyDeposited(2)]);
      expect(framework.di.resolve(ledgerToken).totalCents, 42);
    });

    test(
      'handleEvents rejects unregistered events before handling any',
      () async {
        final framework = transferApp(
          ConsistencyMode.eventual,
        ).build().createRuntime();
        await expectLater(
          framework.handleEvents([WalletOpened(40), Orphan()]),
          throwsA(isA<UnknownEventTypeError>()),
        );
        expect(framework.di.resolve(ledgerToken).totalCents, 0);
      },
    );

    test('the projection rebuilder rebuilds the live projection', () async {
      final framework = transferApp(
        ConsistencyMode.eventual,
      ).build().createRuntime();
      await framework.dispatch(OpenWallet(WalletId.generate(), 10));
      final ledger = framework.di.resolve(ledgerToken)..totalCents = 0;
      final result = await framework.projectionRebuilder.rebuild(
        framework.projection('ledger'),
        callHooks: false,
      );
      expect(result.completed, isTrue);
      expect(ledger.totalCents, 10);
    });

    test('runScheduled times out stuck sagas', () async {
      final framework = transferEvents(TaroDomain.builder())
          .useLocal()
          .aggregate<Transfer, TransferId>(
            'Transfer',
            (a) => a.factory(Transfer.new),
          )
          .command<RequestTransfer>(
            'RequestTransfer',
            (c) => TransferHandler(c.repository()),
          )
          .saga(StuckSaga.new, timeout: const Duration(minutes: 1))
          .clock(() => DateTime.timestamp().add(const Duration(hours: 1)))
          .build()
          .createRuntime();
      final request = RequestTransfer(
        transferId: TransferId.generate(),
        from: WalletId.generate(),
        to: WalletId.generate(),
        cents: 1,
      );
      await framework.dispatch(request);

      final result = await framework.runScheduled();
      expect(result.timeouts['StuckSaga'], hasLength(1));
      expect(
        result.timeouts['StuckSaga']!.single.outcome,
        SagaTimeoutOutcome.failed,
      );
      final record = await framework.sagaStore.load(
        'StuckSaga',
        request.correlationId,
      );
      expect(record?.status, SagaStatus.failed);
    });
  });
}

const requestToken = Token<Object>('request');

/// An event no registration can produce.
class Orphan extends DomainEvent {
  @override
  String get eventName => 'Orphan';

  @override
  Map<String, Object?> toData() => {};
}

class ExplodingProjection extends Projection {
  ExplodingProjection(ProcessedEventStore processedEvents)
    : super(processedEvents: processedEvents) {
    on<WalletOpened>((_) => throw StateError('boom'));
  }

  @override
  String get name => 'exploding';
}

/// Starts on a transfer request and then waits forever.
class StuckSaga extends ProcessManager<int> {
  StuckSaga() : super(0) {
    startsWhen<TransferRequested>((_) => const []);
    completedWhen<TransferCompleted>((_) => const []);
  }

  @override
  String get sagaType => 'StuckSaga';

  @override
  Map<String, Object?> stateToJson(int state) => {'n': state};

  @override
  int stateFromJson(Map<String, Object?> json) => json['n']! as int;
}

/// Records saved wallets instead of storing them.
class RecordingRepository implements Repository<Wallet, WalletId> {
  RecordingRepository(this.saved);

  final List<Wallet> saved;

  @override
  Future<Wallet> load(WalletId id) =>
      throw AggregateNotFoundError('not stored');

  @override
  Future<bool> exists(WalletId id) async => false;

  @override
  Future<void> save(Wallet aggregate) async => saved.add(aggregate);
}
