import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  late Harness h;

  setUp(() => h = Harness());

  void registerAccounts({ConsistencyMode? openWith}) => h.registry
    ..register<OpenAccount>(
      'OpenAccount',
      (c) => OpenAccountHandler(h.repository(c.eventBus)),
      consistency: openWith,
    )
    ..register<Deposit>(
      'Deposit',
      (c) => DepositHandler(h.repository(c.eventBus)),
      handlerName: 'Deposits',
    );

  group('CommandRegistry', () {
    test('resolves by class and by name', () {
      registerAccounts(openWith: ConsistencyMode.strong);
      final command = Deposit(accountId: AccountId.generate(), cents: 1);

      final registration = h.registry.resolve(command);
      expect(registration.commandClass, Deposit);
      expect(registration.handlerName, 'Deposits');
      expect(registration.consistency, isNull);
      expect(h.registry.byName('OpenAccount')?.commandClass, OpenAccount);
      expect(
        h.registry.byName('OpenAccount')?.handlerName,
        'OpenAccountHandler',
      );
      expect(h.registry.byName('Nope'), isNull);
      expect(h.registry.registrations, hasLength(2));
    });

    test('rejects duplicate classes and names', () {
      registerAccounts();
      expect(
        () => h.registry.register<Deposit>(
          'Deposit2',
          (c) => DepositHandler(h.repository(c.eventBus)),
        ),
        throwsA(isA<InvalidConfigurationError>()),
      );
      expect(
        () => h.registry.register<_Other>('Deposit', (_) => _OtherHandler()),
        throwsA(isA<InvalidConfigurationError>()),
      );
    });

    test('rejects the Command base class', () {
      expect(
        () => h.registry.register<Command>('Any', (_) => _AnyHandler()),
        throwsA(isA<InvalidConfigurationError>()),
      );
    });

    test('an unregistered command throws', () {
      expect(
        () => h.registry.resolve(_Other()),
        throwsA(isA<CommandHandlerNotRegisteredError>()),
      );
      expect(h.registry.isRegistered(_Other()), isFalse);
    });
  });

  group('CommandDispatcher', () {
    late RecordingProjection strongSide;
    late RecordingProjection eventualSide;

    setUp(() {
      strongSide = RecordingProjection('strong-side');
      eventualSide = RecordingProjection('eventual-side');
      h.strongBus.subscribe(strongSide);
      h.eventualBus.subscribe(eventualSide);
    });

    test('routes by per-command override, else the default', () async {
      registerAccounts(openWith: ConsistencyMode.strong);
      final dispatcher = h.dispatcher(
        defaultConsistency: ConsistencyMode.eventual,
      );
      final id = AccountId.generate();
      final open = OpenAccount(accountId: id, owner: 'ann');
      final deposit = Deposit(accountId: id, cents: 5);

      expect(dispatcher.consistencyFor(open), ConsistencyMode.strong);
      expect(dispatcher.consistencyFor(deposit), ConsistencyMode.eventual);
      expect(
        (await dispatcher.dispatch(open)).consistency,
        ConsistencyMode.strong,
      );
      expect(
        (await dispatcher.dispatch(deposit)).consistency,
        ConsistencyMode.eventual,
      );

      expect(strongSide.seen.single, isA<AccountOpened>());
      expect(eventualSide.seen.single, isA<FundsDeposited>());
    });

    test('dispatch of an unregistered command throws', () async {
      final dispatcher = h.dispatcher();
      expect(dispatcher.canDispatch(_Other()), isFalse);
      await expectLater(
        dispatcher.dispatch(_Other()),
        throwsA(isA<CommandHandlerNotRegisteredError>()),
      );
    });

    test('the default pipeline is required', () {
      expect(
        () => CommandDispatcher(
          registry: h.registry,
          defaultConsistency: ConsistencyMode.eventual,
          strong: h.strong,
        ),
        throwsA(isA<InvalidConfigurationError>()),
      );
    });

    test('an override without its pipeline throws on dispatch', () async {
      registerAccounts(openWith: ConsistencyMode.eventual);
      final dispatcher = CommandDispatcher(
        registry: h.registry,
        defaultConsistency: ConsistencyMode.strong,
        strong: h.strong,
      );
      final open = OpenAccount(accountId: AccountId.generate(), owner: 'a');

      expect(dispatcher.canDispatch(open), isFalse);
      await expectLater(
        dispatcher.dispatch(open),
        throwsA(isA<InvalidConfigurationError>()),
      );
    });

    group('dispatchAll', () {
      late CommandDispatcher dispatcher;
      late AccountId id;
      late List<Command> commands;

      setUp(() {
        registerAccounts();
        dispatcher = h.dispatcher();
        id = AccountId.generate();
        commands = [
          OpenAccount(accountId: id, owner: 'ann'),
          Deposit(accountId: AccountId.generate(), cents: 1), // missing
          Deposit(accountId: id, cents: 5),
        ];
      });

      test('stops at the first failure by default', () async {
        final result = await dispatcher.dispatchAll(commands);

        expect(result.outcomes, hasLength(2));
        expect(result.succeeded.single.command, commands[0]);
        expect(result.failed.single.error, isA<AggregateNotFoundError>());
        expect(result.skipped, [commands[2]]);
        expect(result.allSucceeded, isFalse);
        expect(await h.stream(id), hasLength(1));
      });

      test('continueOnError dispatches every command', () async {
        final result = await dispatcher.dispatchAll(
          commands,
          continueOnError: true,
        );

        expect(result.outcomes.map((o) => o.succeeded), [true, false, true]);
        expect(result.skipped, isEmpty);
        expect(await h.stream(id), hasLength(2));
      });

      test('reports success when every command completes', () async {
        final result = await dispatcher.dispatchAll([commands[0], commands[2]]);
        expect(result.allSucceeded, isTrue);
        expect(
          result.outcomes.map((o) => o.result?.status),
          everyElement(CommandDispatchStatus.processed),
        );
      });
    });
  });
}

class _Other extends Command {}

class _OtherHandler extends CommandHandler<_Other> {
  @override
  Future<void> handle(_Other command) async {}
}

class _AnyHandler extends CommandHandler<Command> {
  @override
  Future<void> handle(Command command) async {}
}
