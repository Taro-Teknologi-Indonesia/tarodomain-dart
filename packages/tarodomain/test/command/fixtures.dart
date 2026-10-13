import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';

import '../event_sourcing/fixtures.dart';

export '../event_sourcing/fixtures.dart';

class OpenAccount extends Command {
  OpenAccount({required this.accountId, required this.owner, super.id});

  final AccountId accountId;
  final String owner;
}

class Deposit extends Command {
  Deposit({required this.accountId, required this.cents, super.id});

  final AccountId accountId;
  final int cents;
}

class OpenAccountHandler
    extends AggregateCommandHandler<OpenAccount, BankAccount, AccountId> {
  OpenAccountHandler(super.repository);

  @override
  Future<void> handle(OpenAccount command) async {
    if (await exists(command.accountId)) {
      throw AggregateAlreadyExistsError('Account exists');
    }
    await save(BankAccount.open(command.accountId, command.owner));
  }
}

class DepositHandler
    extends AggregateCommandHandler<Deposit, BankAccount, AccountId> {
  DepositHandler(super.repository, {this.beforeSave});

  /// Runs after loading, before saving; used to force conflicts.
  final Future<void> Function()? beforeSave;

  int attempts = 0;

  @override
  Future<void> handle(Deposit command) async {
    final account = await load(command.accountId);
    account.deposit(command.cents);
    attempts++;
    await beforeSave?.call();
    await save(account);
  }
}

/// Records the events it sees and can write to storage, then fail.
class RecordingProjection implements EventHandler {
  RecordingProjection(this.name, {this.processedEvents});

  @override
  final String name;

  final ProcessedEventStore? processedEvents;
  final seen = <DomainEvent>[];
  final contexts = <ExecutionContext?>[];
  Object? failWith;

  @override
  Future<void> handle(DomainEvent event) async {
    seen.add(event);
    contexts.add(ExecutionContext.current);
    await processedEvents?.markProcessed(name, name, event.id);
    if (failWith case final error?) throw error;
  }
}

/// A local provider with both pipelines and an account repository per bus.
class Harness {
  Harness({ConcurrencyChecker? concurrency})
    : concurrency =
          concurrency ?? ConcurrencyChecker(sleep: (_) async {}, maxRetries: 3);

  final provider = LocalProvider();
  final ConcurrencyChecker concurrency;
  final registry = CommandRegistry();

  late final eventStore = EventStore(
    provider.createEventStoreAdapter(),
    accountRegistry(),
  );
  late final commands = provider.createCommandIdempotencyStore();
  late final processedEvents = provider.createProcessedEventStore();
  late final strongBus = InMemoryEventBus(name: 'strong');
  late final eventualBus = InMemoryEventBus(name: 'eventual');

  late final strong = StrongConsistencyPipeline(
    unitOfWork: provider.createUnitOfWork(),
    eventBus: strongBus,
    idempotencyStore: commands,
    concurrency: concurrency,
  );
  late final eventual = EventualConsistencyPipeline(
    eventBus: eventualBus,
    idempotencyStore: commands,
    concurrency: concurrency,
  );

  CommandDispatcher dispatcher({
    ConsistencyMode defaultConsistency = ConsistencyMode.strong,
  }) => CommandDispatcher(
    registry: registry,
    defaultConsistency: defaultConsistency,
    strong: strong,
    eventual: eventual,
  );

  EventSourcedRepository<BankAccount, AccountId> repository(EventBus bus) =>
      EventSourcedRepository(
        eventStore: eventStore,
        eventBus: bus,
        factory: BankAccount.new,
        aggregateType: 'BankAccount',
      );

  /// Saves a deposit outside any handler, as a competing writer would.
  Future<void> depositDirectly(AccountId id, int cents) async {
    final repo = repository(RecordingEventBus());
    await repo.save((await repo.load(id))..deposit(cents));
  }

  Future<List<DomainEvent>> stream(AccountId id) =>
      eventStore.loadStream(StreamIds.forAggregate('BankAccount', id));
}
