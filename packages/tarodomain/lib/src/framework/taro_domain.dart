import 'package:uuid/uuid_value.dart';

import '../adapters/dead_letter_store.dart';
import '../adapters/event_store_adapter.dart';
import '../adapters/idempotency_stores.dart';
import '../adapters/provider.dart';
import '../adapters/saga_store_adapter.dart';
import '../adapters/snapshot_store_adapter.dart';
import '../adapters/unit_of_work.dart';
import '../bus/event_bus.dart';
import '../bus/event_handler.dart';
import '../bus/in_memory_event_bus.dart';
import '../catch_up/cron_dispatcher.dart';
import '../catch_up/subscription_manager.dart';
import '../command/command_dispatch_result.dart';
import '../command/command_dispatcher.dart';
import '../command/command_handler.dart';
import '../command/command_pipeline.dart';
import '../command/command_registry.dart';
import '../command/concurrency_checker.dart';
import '../di/container.dart';
import '../domain/aggregate_id.dart';
import '../domain/aggregate_root.dart';
import '../domain/command.dart';
import '../domain/domain_event.dart';
import '../errors/error_codes.dart';
import '../errors/framework_error.dart';
import '../event_sourcing/event_registry.dart';
import '../event_sourcing/event_store.dart';
import '../projection/projection.dart';
import '../rebuild/projection_rebuilder.dart';
import '../rebuild/saga_rebuilder.dart';
import '../repository/event_sourced_repository.dart';
import '../repository/repository.dart';
import '../saga/process_manager.dart';
import '../saga/saga_event_handler.dart';
import '../saga/saga_timeout_scheduler.dart';
import '../trace/correlation_trace.dart';
import 'validation.dart';

part 'builder.dart';
part 'definition.dart';

/// Tokens the framework binds in each runtime's container scope.
abstract final class TaroTokens {
  /// The runtime itself.
  static const framework = Token<TaroDomain>('tarodomain.framework');

  /// The runtime's provider, for read models that use the provider's
  /// storage.
  static const provider = Token<Provider>('tarodomain.provider');
}

/// What a projection or repository factory gets from the runtime.
class FactoryContext {
  FactoryContext._(this.framework);

  /// The runtime being created.
  final TaroDomain framework;

  /// The runtime's container scope.
  Container get container => framework.di;

  /// The dependency bound to [token] (see [Container.resolve]).
  T resolve<T>(Token<T> token) => framework.di.resolve(token);

  /// The runtime's provider.
  Provider get provider => framework.provider;

  /// The event store.
  EventStore get eventStore => framework.eventStore;

  /// The idempotency store of projections and sagas.
  ProcessedEventStore get processedEvents => framework.processedEvents;
}

/// What a state repository factory gets: the runtime and the event bus the
/// repository publishes to.
final class RepositoryContext extends FactoryContext {
  RepositoryContext._(super.framework, this.eventBus) : super._();

  /// The bus saved events are published to.
  final EventBus eventBus;
}

/// What a command handler factory gets: the runtime and the pipeline
/// running the handler.
final class CommandContext extends FactoryContext {
  CommandContext._(super.framework, this.pipeline) : super._();

  /// The pipeline running the handler.
  final CommandHandlerContext pipeline;

  /// The pipeline's consistency mode.
  ConsistencyMode get consistency => pipeline.consistency;

  /// The pipeline's event bus.
  EventBus get eventBus => pipeline.eventBus;

  /// The repository of aggregate class [A], publishing to the pipeline's
  /// bus.
  ///
  /// Throws [AggregateNotRegisteredError] if [A] isn't registered.
  Repository<A, TId> repository<
    A extends AggregateRoot<TId, DomainEvent>,
    TId extends AggregateId
  >() => framework._repository<A, TId>(eventBus);
}

/// The outcome of [TaroDomain.runScheduled].
final class ScheduledRunResult {
  ScheduledRunResult._(this.catchUp, this.timeouts);

  /// One catch-up pass per subscription.
  final List<CatchUpResult> catchUp;

  /// The sagas timed out, by saga type.
  final Map<String, List<SagaTimeoutResult>> timeouts;
}

/// A TaroDomain runtime: a [FrameworkDefinition] bound to a [Provider]'s
/// resources (spec §25.2).
///
/// Create one with `FrameworkDefinition.createRuntime`. It is cheap, so a
/// server can create one per request. The provider's three entry points
/// call [dispatch] for commands, [handleEvents] for events from a queue,
/// and [runScheduled] periodically for catch-up and saga timeouts.
///
/// Projections and sagas are subscribed to the event buses the provider
/// creates, if those accept subscriptions, and to catch-up through [cron].
final class TaroDomain {
  TaroDomain._(this.definition, this.provider) {
    di = definition.container.createScope()
      ..bindInstance(TaroTokens.framework, this)
      ..bindInstance(TaroTokens.provider, provider);

    eventStoreAdapter = provider.createEventStoreAdapter();
    eventStore = EventStore(eventStoreAdapter, definition.events);
    snapshotStore = provider.createSnapshotStoreAdapter();
    sagaStore = provider.createSagaStoreAdapter();
    processedEvents = provider.createProcessedEventStore();
    commandIdempotency = provider.createCommandIdempotencyStore();
    deadLetters = provider.createDeadLetterStore();
    unitOfWork = provider.createUnitOfWork();

    final uow = unitOfWork;
    if (uow == null) _checkNoStrongCommands();
    strongEventBus = uow == null
        ? null
        : provider.createEventBus(
            const EventBusConfig(consistency: ConsistencyMode.strong),
          );
    eventualEventBus = provider.createEventBus(
      EventBusConfig(
        consistency: ConsistencyMode.eventual,
        transport: definition.eventTransport,
      ),
    );

    commands = CommandRegistry();
    for (final command in definition.commands) {
      command._registerOn(commands, this);
    }
    dispatcher = CommandDispatcher(
      registry: commands,
      defaultConsistency: definition.defaultConsistency,
      strong: uow == null
          ? null
          : StrongConsistencyPipeline(
              unitOfWork: uow,
              eventBus: strongEventBus!,
              idempotencyStore: commandIdempotency,
              concurrency: definition.concurrency,
            ),
      eventual: EventualConsistencyPipeline(
        eventBus: eventualEventBus,
        idempotencyStore: commandIdempotency,
        concurrency: definition.concurrency,
      ),
    );
    guard = DispatchGuard(
      dispatcher: dispatcher,
      events: definition.events,
      projectionMode: definition.projectionMode,
      logger: definition.logger,
    );

    sagas = [
      for (final saga in definition.sagas)
        SagaEventHandler(
          create: saga.create,
          sagaStore: sagaStore,
          processedEvents: processedEvents,
          dispatch: dispatch,
        ),
    ];
    projections = [
      for (final create in definition.projections)
        create(FactoryContext._(this)),
    ];
    _validateProjections();
    if (definition.projectionMode != ProjectionValidationMode.skip) {
      for (final projection in projections) {
        projection.onUnhandledEvent = (event) =>
            guard.validateProjectionDispatch(projection, event);
      }
    }

    cron = CronDispatcher(
      eventStore: eventStore,
      subscriptions: SubscriptionManager(eventStoreAdapter),
      batchSize: definition.catchUpBatchSize,
      maxAttempts: definition.catchUpMaxAttempts,
      unitOfWork: uow,
      deadLetters: deadLetters,
    );
    final handlers = <EventHandler>[...projections, ...sagas];
    _consumer = InMemoryEventBus(name: 'consumer');
    for (final handler in handlers) {
      for (final bus in [strongEventBus, eventualEventBus]) {
        if (bus is SubscribableEventBus) bus.subscribe(handler);
      }
      _consumer.subscribe(handler);
      cron.register(handler);
    }

    timeoutSchedulers = [
      for (final (i, saga) in definition.sagas.indexed)
        if (saga.timeout case final timeout?)
          SagaTimeoutScheduler(
            handler: sagas[i],
            timeout: timeout,
            clock: definition.clock,
          ),
    ];
  }

  /// Starts configuring an application (spec §25.1).
  static TaroDomainBuilder builder() => TaroDomainBuilder._();

  /// What this runtime was created from.
  final FrameworkDefinition definition;

  /// Where this runtime's storage and buses come from.
  final Provider provider;

  /// This runtime's container scope, with [TaroTokens] bound.
  late final Container di;

  /// The provider's event store.
  late final EventStoreAdapter eventStoreAdapter;

  /// The event store, serializing with the registered event types.
  late final EventStore eventStore;

  /// The snapshot store.
  late final SnapshotStoreAdapter snapshotStore;

  /// The saga store.
  late final SagaStoreAdapter sagaStore;

  /// The idempotency store of projections and sagas.
  late final ProcessedEventStore processedEvents;

  /// The idempotency store of commands.
  late final CommandIdempotencyStore commandIdempotency;

  /// The dead letter store.
  late final DeadLetterStore deadLetters;

  /// The provider's unit of work, or null if it has none.
  late final UnitOfWork? unitOfWork;

  /// The bus of the strong pipeline, or null without a unit of work.
  late final EventBus? strongEventBus;

  /// The bus of the eventual pipeline.
  late final EventBus eventualEventBus;

  /// The command registrations.
  late final CommandRegistry commands;

  /// Routes commands to their pipelines.
  late final CommandDispatcher dispatcher;

  /// Validates commands and events at dispatch time.
  late final DispatchGuard guard;

  /// The projections, in registration order.
  late final List<Projection> projections;

  /// The saga handlers, in registration order.
  late final List<SagaEventHandler> sagas;

  /// Catches projections and sagas up from the event store.
  late final CronDispatcher cron;

  /// The timeout schedulers of sagas with a timeout.
  late final List<SagaTimeoutScheduler> timeoutSchedulers;

  late final InMemoryEventBus _consumer;

  /// The bus of the default consistency mode.
  EventBus get eventBus => switch (definition.defaultConsistency) {
    ConsistencyMode.strong => strongEventBus!,
    ConsistencyMode.eventual => eventualEventBus,
  };

  /// The catch-up cursors.
  SubscriptionManager get subscriptions => cron.subscriptions;

  /// Prepares the provider's storage, for example by running migrations.
  Future<void> initialize() => provider.initialize();

  /// Runs [command] through the pipeline of its consistency mode.
  ///
  /// Throws [CommandHandlerNotRegisteredError] if it isn't registered, and
  /// whatever the handler throws after any retries.
  Future<CommandDispatchResult> dispatch(Command command) async {
    guard.validateCommand(command);
    return dispatcher.dispatch(command);
  }

  /// Dispatches [commands] one after another; see
  /// [CommandDispatcher.dispatchAll].
  Future<BatchDispatchResult> dispatchAll(
    List<Command> commands, {
    bool continueOnError = false,
  }) => dispatcher.dispatchAll(commands, continueOnError: continueOnError);

  /// The consistency mode of commands of class [commandClass].
  ///
  /// Throws [CommandHandlerNotRegisteredError] if it isn't registered.
  ConsistencyMode consistencyOf(Type commandClass) {
    for (final registration in commands.registrations) {
      if (registration.commandClass == commandClass) {
        return registration.consistency ?? definition.defaultConsistency;
      }
    }
    throw CommandHandlerNotRegisteredError(
      'No handler registered for $commandClass',
      context: {'commandClass': '$commandClass'},
    );
  }

  /// Hands [events] to every projection and saga, in order: the entry
  /// point for a queue consumer (spec §26).
  ///
  /// Throws [UnknownEventTypeError] before handling anything if an event's
  /// type isn't registered, and the first error a handler throws.
  Future<void> handleEvents(List<DomainEvent> events) async {
    events.forEach(guard.validateEvent);
    await _consumer.publishAll(events);
  }

  /// Runs one catch-up pass for every projection and saga, then times out
  /// stuck sagas: the entry point for a scheduler (spec §26). Never throws
  /// for a failing event or saga; the result reports it.
  Future<ScheduledRunResult> runScheduled() async {
    final catchUp = await cron.runAll();
    final timeouts = <String, List<SagaTimeoutResult>>{
      for (final scheduler in timeoutSchedulers)
        scheduler.handler.sagaType: await scheduler.run(),
    };
    return ScheduledRunResult._(catchUp, timeouts);
  }

  /// The repository of aggregate class [A], publishing to the bus of
  /// [consistency], by default the default mode's.
  ///
  /// Saving through it outside a command skips idempotency and retries; use
  /// it to read aggregates.
  ///
  /// Throws [AggregateNotRegisteredError] if [A] isn't registered.
  Repository<A, TId> repository<
    A extends AggregateRoot<TId, DomainEvent>,
    TId extends AggregateId
  >({ConsistencyMode? consistency}) =>
      _repository<A, TId>(switch (consistency) {
        ConsistencyMode.strong => strongEventBus ?? eventBus,
        ConsistencyMode.eventual => eventualEventBus,
        null => eventBus,
      });

  Repository<A, TId> _repository<
    A extends AggregateRoot<TId, DomainEvent>,
    TId extends AggregateId
  >(EventBus bus) {
    final aggregate =
        definition.aggregateFor<A>() ??
        (throw AggregateNotRegisteredError(
          'Aggregate $A is not registered',
          context: {'aggregateClass': '$A'},
        ));
    return aggregate._create(this, bus) as Repository<A, TId>;
  }

  /// The projection named [name].
  ///
  /// Throws [ProjectionNotRegisteredError] if there is none.
  Projection projection(String name) =>
      projections.where((p) => p.name == name).firstOrNull ??
      (throw ProjectionNotRegisteredError(
        'Projection "$name" is not registered',
        context: {'projection': name},
      ));

  /// The handler of saga type [sagaType].
  ///
  /// Throws [SagaNotRegisteredError] if there is none.
  SagaEventHandler saga(String sagaType) =>
      sagas.where((s) => s.sagaType == sagaType).firstOrNull ??
      (throw SagaNotRegisteredError(
        'Saga "$sagaType" is not registered',
        context: {'sagaType': sagaType},
      ));

  /// Rebuilds projections from the event store (spec §20.1).
  ProjectionRebuilder get projectionRebuilder => ProjectionRebuilder(cron);

  /// Rebuilds saga state from the event store (spec §20.2).
  SagaRebuilder get sagaRebuilder => SagaRebuilder(
    eventStore: eventStore,
    sagaStore: sagaStore,
    processedEvents: processedEvents,
  );

  /// Every event with [correlationId], in append order (spec §28.3).
  Future<List<CorrelationTraceEntry>> trace(UuidValue correlationId) =>
      CorrelationTrace.trace(eventStoreAdapter, correlationId);

  /// The causation tree of [correlationId], formatted for reading.
  Future<String> formatTrace(UuidValue correlationId) async =>
      CorrelationTrace.formatTree(
        CorrelationTrace.buildTree(
          await trace(correlationId),
          correlationId: correlationId,
        ),
      );

  void _checkNoStrongCommands() {
    final needStrong = [
      for (final command in definition.commands)
        if ((command.consistency ?? definition.defaultConsistency) ==
            ConsistencyMode.strong)
          command.commandType,
    ];
    if (needStrong.isEmpty) return;
    throw InvalidConfigurationError(
      'Provider "${provider.type}" has no unit of work, but these commands '
      'need strong consistency: ${needStrong.join(', ')}',
      context: {'provider': provider.type, 'commands': needStrong},
    );
  }

  void _validateProjections() {
    if (!definition.validate || definition._projectionsValidated) return;
    const FrameworkValidator()
        .validateProjections(
          projections,
          definition.events,
          sagaTypes: [for (final saga in sagas) saga.sagaType],
        )
        .throwIfInvalid();
    definition._projectionsValidated = true;
  }
}
