part of 'taro_domain.dart';

/// Configures a TaroDomain application (spec §25.1).
///
/// ```dart
/// final definition = TaroDomain.builder()
///     .useLocal()
///     .consistency(ConsistencyMode.eventual)
///     .event<AccountOpened>('AccountOpened', AccountOpened.fromData)
///     .aggregate<BankAccount, AccountId>(
///       'BankAccount',
///       (a) => a.factory(BankAccount.new).snapshotEvery(100),
///     )
///     .command<OpenAccount>(
///       'OpenAccount',
///       (c) => OpenAccountHandler(c.repository()),
///       consistency: ConsistencyMode.strong,
///     )
///     .projection((c) => BalanceProjection(
///           c.resolve(balances),
///           processedEvents: c.processedEvents,
///         ))
///     .saga(TransferSaga.new, timeout: const Duration(minutes: 5))
///     .build();
///
/// final framework = definition.createRuntime();
/// await framework.dispatch(OpenAccount(...));
/// ```
///
/// [build] validates the configuration and returns an immutable
/// [FrameworkDefinition]; `FrameworkDefinition.createRuntime` binds it to a
/// provider.
final class TaroDomainBuilder {
  TaroDomainBuilder._();

  ConsistencyMode _consistency = ConsistencyMode.eventual;
  String? _transport;
  int _snapshotEvery = 0;
  Provider? _provider;
  final _events = <void Function(EventRegistry registry)>[];
  final _aggregates = <AggregateDefinition Function(int snapshotEvery)>[];
  final _commands = <CommandDefinition>[];
  final _sagas = <(ProcessManager<Object?> Function(), Duration?)>[];
  final _projections = <ProjectionFactory>[];
  final _container = Container();
  bool _validate = true;
  ProjectionValidationMode _projectionMode = ProjectionValidationMode.skip;
  ValidationLogger _logger = defaultValidationLogger;
  ConcurrencyChecker? _concurrency;
  DateTime Function()? _clock;
  int _catchUpBatchSize = 100;
  int? _catchUpMaxAttempts;

  /// Uses [provider] for runtimes created without one. Providers also add
  /// shortcuts, such as `useLocal()` from `tarodomain_local`.
  TaroDomainBuilder useProvider(Provider provider) {
    _provider = provider;
    return this;
  }

  /// Sets the consistency mode of commands registered without one, and the
  /// provider-specific [transport] of the eventual event bus. Defaults to
  /// eventual.
  TaroDomainBuilder consistency(ConsistencyMode mode, {String? transport}) {
    _consistency = mode;
    _transport = transport;
    return this;
  }

  /// Snapshots every [n] events for event-sourced aggregates that don't set
  /// their own interval. Defaults to 0, no snapshots.
  TaroDomainBuilder snapshotEvery(int n) {
    _snapshotEvery = n;
    return this;
  }

  /// Registers the event type [eventType], class [E], at its current
  /// [version], built by [fromData] (see [EventRegistry.register]).
  TaroDomainBuilder event<E extends DomainEvent>(
    String eventType,
    EventFactory<E> fromData, {
    String version = '1.0.0',
  }) {
    _events.add((r) => r.register<E>(eventType, fromData, version: version));
    return this;
  }

  /// Registers an upcaster for [eventType] from [fromVersion] to [toVersion]
  /// (see [EventRegistry.registerUpcaster]).
  TaroDomainBuilder upcaster(
    String eventType,
    String fromVersion,
    String toVersion,
    Upcaster upcast,
  ) {
    _events.add(
      (r) => r.registerUpcaster(eventType, fromVersion, toVersion, upcast),
    );
    return this;
  }

  /// Registers the aggregate class [A] as [aggregateType], configured by
  /// [configure].
  TaroDomainBuilder aggregate<
    A extends AggregateRoot<TId, DomainEvent>,
    TId extends AggregateId
  >(String aggregateType, void Function(AggregateBuilder<A, TId> a) configure) {
    final builder = AggregateBuilder<A, TId>._(this, aggregateType);
    configure(builder);
    _aggregates.add(builder._build);
    return this;
  }

  /// Registers [create] as the handler factory for commands of class [C],
  /// named [commandType]. [consistency] overrides the default for this
  /// command; [handlerName] defaults to `<commandType>Handler`.
  ///
  /// [create] runs for every dispatch attempt, with the runtime and
  /// pipeline in its [CommandContext].
  TaroDomainBuilder command<C extends Command>(
    String commandType,
    CommandFactory<C> create, {
    ConsistencyMode? consistency,
    String? handlerName,
  }) {
    _commands.add(
      CommandDefinition<C>._(
        commandType: commandType,
        factory: create,
        handlerName: handlerName,
        consistency: consistency,
      ),
    );
    return this;
  }

  /// Registers a projection. [create] runs once per runtime.
  TaroDomainBuilder projection(ProjectionFactory create) {
    _projections.add(create);
    return this;
  }

  /// Registers the saga that [create] makes; it must return a new,
  /// unstarted saga each time. With a [timeout], `runScheduled` times out
  /// sagas that made no progress for that long (spec §19).
  TaroDomainBuilder saga(
    ProcessManager<Object?> Function() create, {
    Duration? timeout,
  }) {
    _sagas.add((create, timeout));
    return this;
  }

  /// Binds [token] in the root container (see [Container.bind]).
  TaroDomainBuilder bind<T>(
    Token<T> token,
    Provide<T> create, {
    Lifetime lifetime = Lifetime.singleton,
  }) {
    _container.bind(token, create, lifetime: lifetime);
    return this;
  }

  /// Binds [token] to one instance for the whole process.
  TaroDomainBuilder bindSingleton<T>(Token<T> token, Provide<T> create) =>
      bind(token, create);

  /// Binds [token] to a new instance per resolve.
  TaroDomainBuilder bindTransient<T>(Token<T> token, Provide<T> create) =>
      bind(token, create, lifetime: Lifetime.transient);

  /// Binds [token] to one instance per runtime.
  TaroDomainBuilder bindScoped<T>(Token<T> token, Provide<T> create) =>
      bind(token, create, lifetime: Lifetime.scoped);

  /// Binds [token] to [instance].
  TaroDomainBuilder bindInstance<T>(Token<T> token, T instance) {
    _container.bindInstance(token, instance);
    return this;
  }

  /// Sets runtime validation (spec §29.2): what happens when a projection
  /// gets an event it has no handler for.
  TaroDomainBuilder validation({
    ProjectionValidationMode projectionMode = ProjectionValidationMode.skip,
  }) {
    _projectionMode = projectionMode;
    return this;
  }

  /// Skips startup validation (spec §29.1). Event registrations that
  /// conflict still fail [build].
  TaroDomainBuilder skipValidation() {
    _validate = false;
    return this;
  }

  /// Sends validation and snapshot warnings to [logger] instead of
  /// `dart:developer`.
  TaroDomainBuilder onWarning(ValidationLogger logger) {
    _logger = logger;
    return this;
  }

  /// Retries commands after concurrency conflicts with [checker].
  TaroDomainBuilder concurrency(ConcurrencyChecker checker) {
    _concurrency = checker;
    return this;
  }

  /// Uses [clock] for saga timeouts, for tests.
  TaroDomainBuilder clock(DateTime Function() clock) {
    _clock = clock;
    return this;
  }

  /// Sets the number of events per catch-up pass. Defaults to 100.
  TaroDomainBuilder catchUpBatchSize(int n) {
    _catchUpBatchSize = n;
    return this;
  }

  /// Dead-letters an event and moves past it once a projection or saga has
  /// failed on it [n] times in a row with a retryable error during
  /// catch-up. By default, as in spec §18.3, catch-up retries it forever and
  /// the subscription stays stuck on it.
  ///
  /// Every catch-up run counts as an attempt, so choose [n] to outlast a
  /// short outage. Pass null to retry forever again.
  TaroDomainBuilder catchUpMaxAttempts(int? n) {
    _catchUpMaxAttempts = n;
    return this;
  }

  /// Validates the configuration and returns the definition.
  ///
  /// Throws [InvalidConfigurationError] listing every problem found. Warnings
  /// go to the logger.
  FrameworkDefinition build() {
    final errors = <String>[];
    final events = EventRegistry();
    for (final register in _events) {
      try {
        register(events);
      } on ConfigurationError catch (error) {
        errors.add(error.message);
      }
    }
    if (_catchUpBatchSize < 1) {
      errors.add('catchUpBatchSize must be at least 1');
    }
    if (_catchUpMaxAttempts case final n? when n < 1) {
      errors.add('catchUpMaxAttempts must be at least 1');
    }

    final sagas = <SagaDefinition>[];
    for (final (index, (create, timeout)) in _sagas.indexed) {
      try {
        sagas.add(SagaDefinition._(create, timeout, create()));
      } catch (error) {
        errors.add('Saga #${index + 1} could not be created: $error');
      }
    }

    final definition = FrameworkDefinition._(
      defaultConsistency: _consistency,
      eventTransport: _transport,
      events: events,
      aggregates: [for (final build in _aggregates) build(_snapshotEvery)],
      commands: _commands,
      sagas: sagas,
      projections: _projections,
      container: _container,
      validate: _validate,
      projectionMode: _projectionMode,
      logger: _logger,
      defaultProvider: _provider,
      concurrency: _concurrency,
      clock: _clock,
      catchUpBatchSize: _catchUpBatchSize,
      catchUpMaxAttempts: _catchUpMaxAttempts,
    );

    if (_validate) {
      final report = const FrameworkValidator().validate(definition);
      errors.addAll(report.errors);
      report.warnings.forEach(_logger);
    }
    ValidationReport(errors: errors).throwIfInvalid();
    return definition;
  }
}

/// Configures one aggregate type (spec §25.1).
///
/// An event-sourced aggregate needs a [factory]. A state-based one needs a
/// [stateRepository] instead.
final class AggregateBuilder<
  A extends AggregateRoot<TId, DomainEvent>,
  TId extends AggregateId
> {
  AggregateBuilder._(this._parent, this._aggregateType);

  final TaroDomainBuilder _parent;
  final String _aggregateType;
  A Function(TId id)? _factory;
  StateRepositoryFactory<A, TId>? _stateRepository;
  int? _snapshotEvery;

  /// Builds an empty aggregate for an ID, before its events are applied.
  AggregateBuilder<A, TId> factory(A Function(TId id) create) {
    _factory = create;
    return this;
  }

  /// Snapshots every [n] events, overriding the framework default.
  AggregateBuilder<A, TId> snapshotEvery(int n) {
    _snapshotEvery = n;
    return this;
  }

  /// Stores the aggregate's state through the repository [create] makes,
  /// instead of as events (spec §6.3).
  AggregateBuilder<A, TId> stateRepository(
    StateRepositoryFactory<A, TId> create,
  ) {
    _stateRepository = create;
    return this;
  }

  /// Registers an event type, as [TaroDomainBuilder.event] does.
  AggregateBuilder<A, TId> event<E extends DomainEvent>(
    String eventType,
    EventFactory<E> fromData, {
    String version = '1.0.0',
  }) {
    _parent.event<E>(eventType, fromData, version: version);
    return this;
  }

  AggregateDefinition _build(int defaultSnapshotEvery) =>
      AggregateDefinition<A, TId>._(
        aggregateType: _aggregateType,
        // State repositories don't snapshot, so only an explicit interval
        // reaches them, and is reported.
        snapshotEvery:
            _snapshotEvery ??
            (_stateRepository == null ? defaultSnapshotEvery : 0),
        factory: _factory,
        stateRepository: _stateRepository,
      );
}
