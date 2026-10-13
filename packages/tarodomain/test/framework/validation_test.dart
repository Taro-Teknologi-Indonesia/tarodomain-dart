import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// Matches an [InvalidConfigurationError] whose issues contain each of
/// [fragments].
Matcher invalidWith(List<String> fragments) => throwsA(
  isA<InvalidConfigurationError>().having(
    (e) => (e.context['issues']! as List<String>).join('\n'),
    'issues',
    allOf([for (final f in fragments) contains(f)]),
  ),
);

void main() {
  group('startup validation', () {
    test('a valid configuration builds without warnings', () {
      final warnings = <String>[];
      transferApp(ConsistencyMode.eventual).onWarning(warnings.add).build();
      expect(warnings, isEmpty);
    });

    test('rejects catch-up settings below 1', () {
      final builder = transferApp(
        ConsistencyMode.eventual,
      ).catchUpBatchSize(0).catchUpMaxAttempts(0);
      expect(
        builder.build,
        invalidWith([
          'catchUpBatchSize must be at least 1',
          'catchUpMaxAttempts must be at least 1',
        ]),
      );
    });

    test('reports every error at once', () {
      final builder = transferDomain(TaroDomain.builder())
          .aggregate<Wallet, WalletId>('Wallet', (a) => a.factory(Wallet.new))
          .command<OpenWallet>(
            'OpenWallet',
            (c) => WalletHandler(c.repository()),
          )
          .event<WalletOpened>('WalletOpened', (_) => WalletOpened(0))
          .saga(NoStartSaga.new);
      expect(
        builder.build,
        invalidWith([
          'Aggregate Wallet is registered twice',
          'Aggregate type "Wallet" is registered twice',
          'Command OpenWallet is registered twice',
          'Command type "OpenWallet" is registered twice',
          'Event type WalletOpened is already registered',
          'Saga "NoStartSaga" has no startsWhen handler',
        ]),
      );
    });

    test('an event-sourced aggregate needs a factory', () {
      expect(
        transferEvents(
          TaroDomain.builder(),
        ).aggregate<Wallet, WalletId>('Wallet', (_) {}).build,
        invalidWith(['Aggregate "Wallet" needs a factory']),
      );
    });

    test('aggregate type names must not contain "-"', () {
      expect(
        TaroDomain.builder()
            .aggregate<Wallet, WalletId>(
              'My-Wallet',
              (a) => a.factory(Wallet.new),
            )
            .build,
        invalidWith(['must be non-empty and contain no "-"']),
      );
    });

    test('the global snapshot interval applies to every event-sourced '
        'aggregate', () {
      final definition = TaroDomain.builder()
          .snapshotEvery(50)
          .aggregate<Wallet, WalletId>('Wallet', (a) => a.factory(Wallet.new))
          .aggregate<Counter, CounterId>(
            'Counter',
            (a) => a.factory(Counter.new).snapshotEvery(5),
          )
          .aggregate<Counter2, CounterId>(
            'Counter2',
            (a) => a.stateRepository((_) => throw UnimplementedError()),
          )
          .build();
      expect(
        [for (final a in definition.aggregates) a.snapshotEvery],
        [50, 5, 0],
      );
    });

    test('snapshots of state-based aggregates are ignored with a warning', () {
      final warnings = <String>[];
      TaroDomain.builder()
          .onWarning(warnings.add)
          .aggregate<Counter, CounterId>(
            'Counter',
            (a) => a
                .stateRepository((_) => throw UnimplementedError())
                .snapshotEvery(5),
          )
          .build();
      expect(warnings.single, contains('snapshotEvery is ignored'));
    });

    test('saga event types must be registered', () {
      expect(
        TaroDomain.builder().saga(TransferSaga.new).build,
        invalidWith([
          'Saga "TransferSaga" handles TransferRequested, which is not '
              'registered',
          'handles MoneyWithdrawn',
        ]),
      );
    });

    test('a saga may handle SagaTimeout without registering it', () {
      transferEvents(
        TaroDomain.builder(),
      ).saga(TimeoutSaga.new, timeout: const Duration(minutes: 1)).build();
    });

    test('saga warnings', () {
      final warnings = <String>[];
      transferEvents(TaroDomain.builder())
          .onWarning(warnings.add)
          .saga(TimeoutSaga.new)
          .saga(OpenEndedSaga.new)
          .build();
      expect(warnings, [
        contains('"TimeoutSaga" handles SagaTimeout but has no timeout'),
        contains('"OpenEndedSaga" has no completedWhen handler'),
      ]);
    });

    test('saga timeouts must be positive', () {
      expect(
        transferEvents(
          TaroDomain.builder(),
        ).saga(TimeoutSaga.new, timeout: Duration.zero).build,
        invalidWith(['timeout that is not positive']),
      );
    });

    test('a saga that cannot be created is reported', () {
      expect(
        TaroDomain.builder().saga(() => throw StateError('nope')).build,
        invalidWith(['Saga #1 could not be created']),
      );
    });

    test('skipValidation builds an invalid configuration', () {
      final definition = TaroDomain.builder()
          .saga(NoStartSaga.new)
          .skipValidation()
          .build();
      expect(definition.validate, isFalse);
    });

    test('conflicting event registrations fail even without validation', () {
      expect(
        transferEvents(TaroDomain.builder())
            .event<WalletOpened>('WalletOpened', (_) => WalletOpened(0))
            .skipValidation()
            .build,
        invalidWith(['WalletOpened is already registered']),
      );
    });

    test('upcasters are registered through the builder', () {
      final definition = transferEvents(TaroDomain.builder())
          .upcaster(
            'WalletOpened',
            '0.9.0',
            '1.0.0',
            (d) => {...d, 'frozen': false},
          )
          .build();
      expect(definition.events.knows('WalletOpened', '0.9.0'), isTrue);
    });
  });

  group('projection validation', () {
    TaroDomainBuilder app() => transferApp(ConsistencyMode.eventual);

    test('runs once, when the first runtime is created', () {
      var created = 0;
      final definition = app().projection((c) {
        created++;
        return EmptyProjection(c.processedEvents);
      }).build();
      expect(created, 0);
      expect(
        definition.createRuntime,
        invalidWith(['"empty" has no event handlers']),
      );
    });

    test('projection event types must be registered', () {
      expect(
        app()
            .projection((c) => OrphanProjection(c.processedEvents))
            .build()
            .createRuntime,
        invalidWith(['"orphans" handles Orphan, which is not registered']),
      );
    });

    test('projection names must be unique among handlers', () {
      expect(
        app()
            .projection(
              (c) => LedgerProjection(
                Ledger(),
                processedEvents: c.processedEvents,
              ),
            )
            .projection(
              (c) => NamedProjection('TransferSaga', c.processedEvents),
            )
            .build()
            .createRuntime,
        invalidWith([
          '"ledger" has the name of another handler',
          '"TransferSaga" has the name of another handler',
        ]),
      );
    });

    test('a supertype handler covers registered subtypes', () {
      app()
          .projection((c) => WalletEventProjection(c.processedEvents))
          .build()
          .createRuntime();
    });

    test('is skipped with skipValidation', () {
      app()
          .projection((c) => EmptyProjection(c.processedEvents))
          .skipValidation()
          .build()
          .createRuntime();
    });
  });

  group('DispatchGuard', () {
    TaroDomain runtime(
      ProjectionValidationMode mode, {
      List<String>? warnings,
    }) => transferDomain(TaroDomain.builder())
        .useLocal()
        .projection((c) => OpenedOnlyProjection(c.processedEvents))
        .validation(projectionMode: mode)
        .onWarning(warnings?.add ?? (_) {})
        .build()
        .createRuntime();

    test('skip ignores events a projection has no handler for', () async {
      final framework = runtime(ProjectionValidationMode.skip);
      final id = WalletId.generate();
      await framework.dispatch(OpenWallet(id, 5));
      await framework.dispatch(Withdraw(id, 1));
      expect(await balanceOf(framework, id), 4);
    });

    test('warn logs once per projection and event type', () async {
      final warnings = <String>[];
      final framework = runtime(
        ProjectionValidationMode.warn,
        warnings: warnings,
      );
      final id = WalletId.generate();
      await framework.dispatch(OpenWallet(id, 5));
      await framework.dispatch(Withdraw(id, 1));
      await framework.dispatch(Withdraw(id, 1));
      expect(warnings, [
        'Projection "opened" has no handler for MoneyWithdrawn',
      ]);
    });

    test('strict fails the dispatch', () async {
      final framework = runtime(ProjectionValidationMode.strict);
      final id = WalletId.generate();
      await framework.dispatch(OpenWallet(id, 5));
      await expectLater(
        framework.dispatch(Withdraw(id, 1)),
        throwsA(isA<MissingEventHandlerError>()),
      );
    });

    test(
      'strict leaves the event unrecorded, so catch-up stops on it',
      () async {
        final framework = runtime(ProjectionValidationMode.strict);
        final id = WalletId.generate();
        await framework.dispatch(OpenWallet(id, 5));
        await expectLater(
          framework.dispatch(Withdraw(id, 1)),
          throwsA(isA<MissingEventHandlerError>()),
        );
        final opened = framework.projection('opened');
        final pass = await framework.cron.catchUp(
          opened.name,
          stopOnError: true,
        );
        expect(pass.error, isA<MissingEventHandlerError>());
      },
    );

    test('validateCommand checks the handler and the pipeline', () {
      final registry = CommandRegistry()
        ..register<StrongOnly>(
          'StrongOnly',
          (_) => throw UnimplementedError(),
          consistency: ConsistencyMode.strong,
        );
      final provider = LocalProvider();
      final guard = DispatchGuard(
        dispatcher: CommandDispatcher(
          registry: registry,
          defaultConsistency: ConsistencyMode.eventual,
          eventual: EventualConsistencyPipeline(
            eventBus: InMemoryEventBus(),
            idempotencyStore: provider.createCommandIdempotencyStore(),
          ),
        ),
        events: EventRegistry(),
      );
      expect(
        () => guard.validateCommand(StrongOnly()),
        throwsA(isA<InvalidConfigurationError>()),
      );
      expect(
        () => guard.validateCommand(OpenWallet(WalletId.generate(), 1)),
        throwsA(isA<CommandHandlerNotRegisteredError>()),
      );
    });

    test('validateEvent rejects unregistered event types', () {
      final framework = transferApp(
        ConsistencyMode.eventual,
      ).build().createRuntime();
      expect(
        () => framework.guard.validateEvent(WalletOpened(1)),
        returnsNormally,
      );
      expect(
        () => framework.guard.validateEvent(Orphan()),
        throwsA(isA<UnknownEventTypeError>()),
      );
    });
  });

  group('EventRegistry.mayProduce', () {
    final registry = EventRegistry()
      ..register<WalletEvent>('MoneyWithdrawn', (d) => MoneyWithdrawn(0))
      ..register<TransferCompleted>(
        'TransferCompleted',
        (_) => TransferCompleted(),
      );

    test('matches the registered class, its supertypes and its subtypes', () {
      expect(registry.mayProduce<WalletEvent>(), isTrue);
      expect(registry.mayProduce<MoneyWithdrawn>(), isTrue);
      expect(registry.mayProduce<TransferEvent>(), isTrue);
      expect(registry.mayProduce<DomainEvent>(), isTrue);
    });

    test('rejects unrelated classes', () {
      expect(registry.mayProduce<TransferFailed>(), isFalse);
      expect(registry.mayProduce<Orphan>(), isFalse);
    });
  });
}

class CounterId extends AggregateId {
  CounterId.generate() : super.generate();
}

class CounterEvent extends DomainEvent {
  @override
  String get eventName => 'CounterEvent';

  @override
  Map<String, Object?> toData() => {};
}

class Counter extends AggregateRoot<CounterId, CounterEvent> {
  Counter(super.id);

  @override
  void apply(CounterEvent event) {}

  @override
  Map<String, Object?> toSnapshot() => {};

  @override
  void restoreSnapshotState(Map<String, Object?> data) {}
}

class Counter2 extends Counter {
  Counter2(super.id);
}

class Orphan extends DomainEvent {
  @override
  String get eventName => 'Orphan';

  @override
  Map<String, Object?> toData() => {};
}

class StrongOnly extends Command {}

class NamedProjection extends Projection {
  NamedProjection(this.name, ProcessedEventStore processedEvents)
    : super(processedEvents: processedEvents) {
    on<WalletOpened>((_) {});
  }

  @override
  final String name;
}

class EmptyProjection extends Projection {
  EmptyProjection(ProcessedEventStore processedEvents)
    : super(processedEvents: processedEvents);

  @override
  String get name => 'empty';
}

class OrphanProjection extends Projection {
  OrphanProjection(ProcessedEventStore processedEvents)
    : super(processedEvents: processedEvents) {
    on<WalletOpened>((_) {});
    on<Orphan>((_) {});
  }

  @override
  String get name => 'orphans';
}

class WalletEventProjection extends Projection {
  WalletEventProjection(ProcessedEventStore processedEvents)
    : super(processedEvents: processedEvents) {
    on<WalletEvent>((_) {});
  }

  @override
  String get name => 'wallet-events';
}

class OpenedOnlyProjection extends Projection {
  OpenedOnlyProjection(ProcessedEventStore processedEvents)
    : super(processedEvents: processedEvents) {
    on<WalletOpened>((_) {});
  }

  @override
  String get name => 'opened';
}

abstract class _IntSaga extends ProcessManager<int> {
  _IntSaga() : super(0);

  @override
  Map<String, Object?> stateToJson(int state) => {'n': state};

  @override
  int stateFromJson(Map<String, Object?> json) => json['n']! as int;
}

class NoStartSaga extends _IntSaga {
  NoStartSaga() {
    completedWhen<TransferCompleted>((_) => const []);
  }

  @override
  String get sagaType => 'NoStartSaga';
}

class TimeoutSaga extends _IntSaga {
  TimeoutSaga() {
    startsWhen<TransferRequested>((_) => const []);
    compensateWhen<SagaTimeout>((_) => const []);
    completedWhen<TransferCompleted>((_) => const []);
  }

  @override
  String get sagaType => 'TimeoutSaga';
}

class OpenEndedSaga extends _IntSaga {
  OpenEndedSaga() {
    startsWhen<TransferRequested>((_) => const []);
  }

  @override
  String get sagaType => 'OpenEndedSaga';
}
