part of 'taro_domain.dart';

/// Creates the repository of a state-based aggregate (spec §6.3).
typedef StateRepositoryFactory<
  A extends AggregateRoot<TId, DomainEvent>,
  TId extends AggregateId
> = Repository<A, TId> Function(RepositoryContext context);

/// Creates a command handler for one runtime and pipeline.
typedef CommandFactory<C extends Command> =
    CommandHandler<C> Function(CommandContext context);

/// Creates a projection for one runtime.
typedef ProjectionFactory = Projection Function(FactoryContext context);

/// An aggregate type registered with [TaroDomainBuilder.aggregate].
final class AggregateDefinition<
  A extends AggregateRoot<TId, DomainEvent>,
  TId extends AggregateId
> {
  AggregateDefinition._({
    required this.aggregateType,
    required this.snapshotEvery,
    this._factory,
    this._stateRepository,
  });

  /// The aggregate type name, used in stream IDs.
  final String aggregateType;

  /// Take a snapshot every this many events; 0 disables snapshots.
  final int snapshotEvery;

  final A Function(TId id)? _factory;
  final StateRepositoryFactory<A, TId>? _stateRepository;

  /// The aggregate class.
  Type get aggregateClass => A;

  /// Whether the aggregate has a factory for empty instances.
  bool get hasFactory => _factory != null;

  /// Whether the aggregate is stored by a state repository instead of as
  /// events.
  bool get isStateBased => _stateRepository != null;

  Repository<A, TId> _create(TaroDomain framework, EventBus eventBus) {
    if (_stateRepository case final create?) {
      return create(RepositoryContext._(framework, eventBus));
    }
    return EventSourcedRepository<A, TId>(
      eventStore: framework.eventStore,
      eventBus: eventBus,
      factory: _factory!,
      aggregateType: aggregateType,
      snapshotStore: snapshotEvery > 0 ? framework.snapshotStore : null,
      snapshotEvery: snapshotEvery,
      onSnapshotError: (error, _) => framework.definition.logger(
        'Snapshot of $aggregateType failed: $error',
      ),
    );
  }
}

/// A command registered with [TaroDomainBuilder.command].
final class CommandDefinition<C extends Command> {
  CommandDefinition._({
    required this.commandType,
    required this._factory,
    this.handlerName,
    this.consistency,
  });

  /// The command type name.
  final String commandType;

  /// The handler name, or null for `<commandType>Handler`.
  final String? handlerName;

  /// The consistency mode, or null for the framework's default.
  final ConsistencyMode? consistency;

  final CommandFactory<C> _factory;

  /// The command class.
  Type get commandClass => C;

  void _registerOn(CommandRegistry registry, TaroDomain framework) =>
      registry.register<C>(
        commandType,
        (pipeline) => _factory(CommandContext._(framework, pipeline)),
        handlerName: handlerName,
        consistency: consistency,
      );
}

/// A saga registered with [TaroDomainBuilder.saga].
final class SagaDefinition {
  SagaDefinition._(this.create, this.timeout, this.prototype);

  /// Creates a new, unstarted saga.
  final ProcessManager<Object?> Function() create;

  /// How long the saga may make no progress before it times out, or null
  /// for never.
  final Duration? timeout;

  /// An unstarted instance, for validation and routing.
  final ProcessManager<Object?> prototype;

  /// The saga type.
  String get sagaType => prototype.sagaType;
}

/// Everything [TaroDomainBuilder.build] configured, created once per
/// process.
///
/// It holds no storage. [createRuntime] binds it to a provider's resources;
/// that is cheap, so a server can create a runtime per request, for
/// example to bind a provider to the request's database session.
final class FrameworkDefinition {
  FrameworkDefinition._({
    required this.defaultConsistency,
    required this.eventTransport,
    required this.events,
    required List<AggregateDefinition> aggregates,
    required List<CommandDefinition> commands,
    required List<SagaDefinition> sagas,
    required List<ProjectionFactory> projections,
    required this.container,
    required this.validate,
    required this.projectionMode,
    required this.logger,
    required this.defaultProvider,
    required this.concurrency,
    required this.clock,
    required this.catchUpBatchSize,
    required this.catchUpMaxAttempts,
  }) : aggregates = List.unmodifiable(aggregates),
       commands = List.unmodifiable(commands),
       sagas = List.unmodifiable(sagas),
       projections = List.unmodifiable(projections),
       _aggregatesByClass = {
         for (final aggregate in aggregates.reversed)
           aggregate.aggregateClass: aggregate,
       };

  /// The consistency mode of commands registered without one.
  final ConsistencyMode defaultConsistency;

  /// The provider-specific transport of the eventual event bus.
  final String? eventTransport;

  /// The registered event types.
  final EventRegistry events;

  /// The registered aggregates, in registration order.
  final List<AggregateDefinition> aggregates;

  /// The registered commands, in registration order.
  final List<CommandDefinition> commands;

  /// The registered sagas, in registration order.
  final List<SagaDefinition> sagas;

  /// The projection factories, in registration order.
  final List<ProjectionFactory> projections;

  /// The root container. Each runtime resolves from a scope of it.
  final Container container;

  /// Whether startup validation runs.
  final bool validate;

  /// What happens when a projection gets an event it has no handler for.
  final ProjectionValidationMode projectionMode;

  /// Receives warnings.
  final ValidationLogger logger;

  /// The provider of [createRuntime] when none is passed.
  final Provider? defaultProvider;

  /// Retries commands after concurrency conflicts, or null for the default.
  final ConcurrencyChecker? concurrency;

  /// The clock of the saga timeout schedulers, or null for the system clock.
  final DateTime Function()? clock;

  /// The default number of events per catch-up pass.
  final int catchUpBatchSize;

  /// How many times in a row catch-up retries one event after a retryable
  /// error before dead-lettering it, or null to retry it forever.
  final int? catchUpMaxAttempts;

  final Map<Type, AggregateDefinition> _aggregatesByClass;
  bool _projectionsValidated = false;

  /// The definition of aggregate class [A], or null.
  AggregateDefinition? aggregateFor<A>() => _aggregatesByClass[A];

  /// Creates a runtime on [provider], or on the provider set with
  /// [TaroDomainBuilder.useProvider].
  ///
  /// The first runtime also validates the projections, unless validation is
  /// skipped.
  ///
  /// Throws [InvalidConfigurationError] if there is no provider, a command
  /// needs strong consistency and the provider has no unit of work, or the
  /// projections are invalid.
  TaroDomain createRuntime({Provider? provider}) {
    final resolved =
        provider ??
        defaultProvider ??
        (throw InvalidConfigurationError(
          'No provider: call useProvider() on the builder or pass one to '
          'createRuntime()',
        ));
    return TaroDomain._(this, resolved);
  }
}
