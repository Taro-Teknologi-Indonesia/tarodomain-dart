# Implementation plan: TaroDomain core and Serverpod adaptation

Status: Phases 0–8 done, updated 2026-10-13. Targets the [TaroDomain spec v1.0](../spec/README.md) at commit `983d2cb` (the `spec/` submodule), Dart 3.12 and Serverpod 4.0.x.

## Goal

1. **`tarodomain`**: a pure-Dart implementation of the spec's platform-agnostic parts (§2–23, §25, §28–29). It depends on no database, server or Flutter.
2. **`tarodomain_serverpod`**: a Serverpod module that implements the spec's Provider (§24) on top of Serverpod. Persistence uses Serverpod's ORM and migrations, the unit of work uses Serverpod transactions, scheduling uses future calls, and Serverpod endpoints replace the spec's worker entry points (§26).

## Decisions

- **Persistence goes through repositories, and repositories go through Serverpod.** Domain code and command handlers only ever see `Repository<T>`. The Serverpod repositories save and load through Serverpod's ORM and nothing else: no raw SQL, and no database driver imported by TaroDomain. As a result, whichever database Serverpod is configured with (PostgreSQL or SQLite) works without extra code.
- **The packages are private.** Every pubspec has `publish_to: none`. Other projects, such as the expense app, depend on them through a git or path dependency.
- **AWS is out of scope.** The spec's AWS provider (§24, §26.2, §27.3) won't be ported.
- **UUIDs come from the [`uuid`](https://pub.dev/packages/uuid) package.** TaroDomain doesn't write its own UUIDv7 generator or parser. IDs are carried as the package's `UuidValue`, which is also the type Serverpod uses for `UuidValue` model fields, so IDs reach the database without conversion. Serverpod already pulls in `uuid` 4.6.0, so this adds no new package to the workspace.

## Packages

| Package | Kind | Contents |
|---|---|---|
| `packages/tarodomain` | Dart library | Core framework |
| `packages/tarodomain_local` | Dart library | In-memory provider (spec's LocalProvider) |
| `packages/tarodomain_testing` | Dart library | Contract test suites that every provider must pass |
| `packages/tarodomain_serverpod_server` | Serverpod module (server) | Tables, adapters, future calls, endpoint helpers |
| `packages/tarodomain_serverpod_client` | Serverpod module (client) | Generated client protocol, including the exception model |
| `examples/bank_account` | Dart app | The spec's BankAccount / TransferMoney example, on the in-memory provider |
| `examples/bank_account_serverpod` | Serverpod app | The same domain code, served by Serverpod |

Dependency direction: `serverpod_server → tarodomain ← local`, and `testing → tarodomain`. `tarodomain` dev-depends on `tarodomain_local` and `tarodomain_testing` for its own tests, which pub allows. Nothing outside the example and Serverpod packages imports Serverpod.

## Dart design decisions

The spec was written with JavaScript in mind. These are the places where the Dart version deliberately differs. The behaviour stays the same; only the mechanism changes.

| Spec mechanism | Dart replacement | Why |
|---|---|---|
| `on[EventName]` dispatch by method name (§5.2, §12.2) | **Aggregates:** override `apply(E event)` with an exhaustive `switch` over a `sealed` event family. **Projections:** register handlers in the constructor with `on<AccountOpened>(handler)`. | No runtime reflection in AOT or Flutter. Sealed families give compile-time exhaustiveness, which is stronger than the spec's runtime `MissingEventHandlerError`. Projections still skip unknown events, as §12.2 requires. |
| `startsWhen…` / `continueWhen…` / `compensateWhen…` / `completedWhen…` (§13.1) | Registration methods with the same names: `startsWhen<TransferRequested>(…)`, `continueWhen<…>`, etc. | Keeps the spec's vocabulary, and the routing table needed by §19.1 and §29.1 falls out of the registrations. |
| Rehydration without the constructor (`Object.create`) (§2.1) | `EventRegistry.register<E>(name, fromData, version: …)`, where each event provides `toData()` and a `fromData` factory | Dart has no way to bypass constructors. Code generation (`json_serializable`) can be added later; it is not required. |
| Envelope fields set on the event and frozen (§2.1) | The `DomainEvent` base class holds a `final EventEnvelope` (id, correlationId, causationId, metadata, occurredAt), assigned in the base constructor from `ExecutionContext.current`. Rehydration constructs the event inside `DomainEvent.withEnvelope(stored, () => …)`, which hands the stored envelope to the constructor through a zone value. `eventName` and `eventVersion` are getters on the event class. Business fields are `final`. | Events are created inside the command's execution context, so they already carry the right correlation and causation when constructed, and `raise()` has nothing to enrich. Nothing is mutated after construction, and event classes need no envelope parameter or `copyWith`. |
| Module-level `ExecutionContext` (§5.5) | `Zone` values: `ExecutionContext.run(ctx, () => …)` and `ExecutionContext.current`. Commands also default their correlation and causation from it, so a command a saga creates while handling an event is linked to that event. | Each request gets its own context, which removes the §5.5 concurrency caveat. |
| `toSnapshot()` via own enumerable properties (§5.4) | `Map<String, Object?> toSnapshot()` and `restoreSnapshotState(data)` are abstract methods on `AggregateRoot`, so every aggregate implements them and the compiler checks it. | No reflection over fields. Requiring them everywhere means any aggregate can be snapshotted, and the global `snapshotEvery` never skips one silently. |
| `with(mutator)` on value objects (§2.3) | No generic version. Subclasses write their own `copyWith`. | `with` is reserved in Dart, and a base class can't construct an instance of its subclass. |
| Error class named after `CONCURRENT_MODIFICATION` (§22.2) | `ConcurrentModificationConflictError` | `ConcurrentModificationError` would shadow the `dart:core` class of the same name. |
| `begin()` / `commit()` / `rollback()` on `UnitOfWork` (§11.4) | A single `execute(work)`; a nested `execute` joins the outer one. | Serverpod only offers callback-style transactions (`session.db.transaction`). |
| `CommandHandler<C, A>` (§4.1) | `CommandHandler<C>` with only `handle`, and `AggregateCommandHandler<C, A, TId>` with the `load`/`loadOrNull`/`save`/`exists` helpers. No `aggregateType` member and no event bus constructor parameter: the repository already publishes. | Some handlers touch several aggregates or none, and the dispatcher only needs `handle`. |
| `CommandDispatcher.resolve(command) → CommandHandler` (§4.2) | `resolve` returns the `CommandRegistration`; the pipeline creates the handler from it. | Which handler instance runs depends on the pipeline's event bus. |
| `Repository<T>` (§6.1) | `Repository<A extends AggregateRoot<TId, DomainEvent>, TId extends AggregateId>` | Dart can't extract the ID type from `A`, and `load(TId id)` keeps typed IDs from being mixed up. |
| `loadFromHistory(events, snapshotVersion?)` (§5.1) | `loadFromHistory(events)` continues from the current version, which `restoreSnapshot` sets. State repositories set it with the protected `restoreVersion(version)`. | One place sets the version. |
| Snapshot when `newVersion % snapshotEvery == 0` (§6.2) | Snapshot when the save crosses a multiple of `snapshotEvery`. | A save of several events can skip over the exact multiple. |
| `Projection<TDb>` with a `db` property (§12.1) | `Projection` with no type parameter; each projection holds its own storage. | The framework never touches the read model, so the type parameter adds nothing. |
| Saga `handle` returns a `Promise` of commands (§13.1) | Saga handlers are synchronous: `List<Command> Function(E)`, and the commands they create get UUIDv7 IDs derived from the event's timestamp and a hash of the saga type, event ID and position. | Keeps sagas pure decision logic, so a rebuild that replays them has no side effects, and an event handled twice dispatches the same command IDs, which command idempotency then skips. |
| `CompensationStack` of closures, "not persisted, rebuilt on replay" (§13.5, §17) | Compensations are defined by name in the constructor (`defineCompensation('refund', () => [...])`) and a step pushes the name (`registerCompensation('refund')`). The stack of names is saved with the saga's state. Factories still run at compensation time. | `SagaEventHandler` loads the saga from the saga store for every event, never by replay, so a stack of closures registered for an earlier event would be empty when a later event triggers compensation. |
| `SagaEventHandler` dispatches before saving (§13.3) | Same, plus a per-saga mailbox: an event for a saga that is still being handled in the same zone waits until that saga is saved, then is handled in the same call. | With a bus that delivers in the caller's zone (strong consistency, and the local provider's eventual bus), a command the saga dispatches publishes the next event before the saga is saved. Without the mailbox the saga would load stale state, or none at all, and skip it. |
| Subscription `lastSeen` only moves forward (§18.2) | `SubscriptionManager.advance` skips a move to the event the cursor is already on, and otherwise trusts the caller. `CronDispatcher` acks in read order. | The cursor holds only an event ID, and event IDs don't order events within a millisecond or across servers (see Risks), so the manager can't tell forward from backward without a position. The Serverpod adapter has positions, so it also refuses to move a cursor back. |
| A timeout handler that throws marks the saga `FAILED` (§19.1) | Only a non-retryable error does. A retryable one (a conflict, an outage) leaves the saga for the next run. The `SagaTimeout` event's ID and timestamp are derived from the saga's type, ID and `updatedAt`, so the retry dispatches the same command IDs. | Failing a saga for good over a transient error is out of step with the rest of the error hierarchy. |
| `loadTimedOut(threshold, { maxCount })` (§19.1) | `loadTimedOut(before, {sagaType, limit})` | One scheduler per saga type (§19.3) needs to filter by type in the store; filtering afterwards lets other types fill the limit. |
| Events carry `correlationId` and `causationId` (§28.1) | Plus an optional `commandCausationId`: for an event raised by a command, that command's own `causationId`. `ExecutionContext.forCommand` sets it, and the envelope JSON omits it when null. | Commands aren't stored, so without it `CorrelationTrace` can't link a command to the event that caused it, and a saga's trace falls apart into unconnected pieces. |
| TS type helpers `ProjectionOf`, `SagaOf` (§29.3) | Not needed. Sealed event families plus `on<T>` registration cover this. | |
| `TransactionalDatabase` write-collecting proxy (§11.4) | Not needed on Serverpod, which has real transactions. The in-memory provider uses a copy-on-begin store. | |
| `DddFramework.builder()` → `build()` → `Framework` (§25) | `TaroDomain.builder()` → `build()` → `FrameworkDefinition`, then `createRuntime({provider})` → `TaroDomain` | A Serverpod request binds its own `Session`, so the provider is per request. Registries and validation happen once per process; a runtime is cheap. |
| Events listed by class on the aggregate (§25.1), validated by name (§29.1) | `event<E>(name, fromData, version:)`. Handlers that refer to an event class are checked with `EventRegistry.mayProduce<T>()`: some registered class is a subtype or supertype of `T`. | Dart can't map a `Type` to an event name, or compare `Type`s for subtyping, without an instance; reified generics (`<E>[] is List<T>`) can. |
| `CircularDependencyError` via `resolutionStack` (§23.2) | Same, on the root, shared by every scope | A singleton's factory resolves from its owning container, so a cycle can run through two containers. |
| `fetchHandler` / `queueHandler` / `scheduledHandler` (§25.2, §26) | Core exposes `dispatch`, `handleEvents` and `runScheduled`. Each provider wires them to its host: Serverpod endpoints and future calls. | Dart doesn't run on Cloudflare Workers, and the AWS provider is out of scope (see Decisions). |

## Phases

Each phase ends with `melos run analyze` and `melos run test` passing.

### Phase 0: Prerequisites (done 2026-10-11)
- ~~Upgrade the Dart SDK to 3.12.2 or newer and raise the `sdk:` constraints.~~ Done: Dart 3.13.5, all packages on `^3.12.2`, Serverpod CLI 4.0.4 installed.
- ~~Add `uuid: ^4.6.0` and `meta` to `tarodomain` as direct dependencies.~~ Done, plus `collection` for structural equality. `uuid` was already in the lockfile as a transitive dependency of Serverpod; declaring it directly keeps both packages on the same version. The core re-exports `UuidValue`, so apps don't need their own `uuid` dependency.
- ~~Create `tarodomain_testing`.~~ Done (empty until Phase 3).
- ~~Add CI.~~ Done: [`.github/workflows/ci.yaml`](../.github/workflows/ci.yaml) runs format check, analyze and test. No Postgres service: the Serverpod tests start an embedded PostgreSQL.

### Phase 1: Domain primitives (§2, §5.5, §22, §28) (done 2026-10-11)
- `AggregateId` with typed subclasses, as a thin wrapper over `UuidValue` from the `uuid` package. No custom UUID code:
  - `generate()` → `UuidValue.fromString(const Uuid().v7())`.
  - `fromExisting(s)` → `UuidValue.withValidation(s)`, which accepts any version.
  - `fromUuidv7(s)` → `withValidation`, then reject unless `isV7`.
  - Envelope IDs (`id`, `correlationId`, `causationId`) are generated the same way.
  - Tests that need fixed IDs or timestamps build an `EventEnvelope` and use `DomainEvent.withEnvelope`, or pass the IDs to the `Command` constructor. No injectable clock yet; one comes with `ConcurrencyChecker` in Phase 4.
- `ValueObject<T>`: `validate`, `==`/`hashCode` (deep for collections), optional ordering through the `OrderedValueObject` mixin. Subclasses write their own `copyWith` (see the design table).
- `DomainEvent` with `EventEnvelope`, and `Command` with the same envelope fields.
- Complete error hierarchy: all 51 codes from §22.2 as concrete classes, built on the existing `FrameworkError` with one abstract base per category (`DomainError`, `ConcurrencyError`, `InfrastructureError`, `ConfigurationError`).
- `ExecutionContext` on zones.
- **Exit:** unit tests for envelope defaults, immutability, ID parsing, and the retryability matrix for every error class.

### Phase 2: Event sourcing (§3, §5, §6, §7, §8) (done 2026-10-11)
- ~~Adapter interfaces: `EventStoreAdapter`, `SnapshotStoreAdapter`, `SagaStoreAdapter`, `ProcessedEventStore`, `CommandIdempotencyStore`, `DeadLetterStore`, `UnitOfWork`, `Provider`.~~ Done, with their data types (`SerializedEvent`, `AppendResult`, `StreamMetadata`, `Subscription`, `Snapshot`, `SagaRecord`, `SagaStatus`, `ProcessedCommand`, `DeadLetterEntry`) and the `EventBus` interface that repositories publish to. The doc comments pin down the semantics the Phase 3 contract suites will test: versions count from 1, a missing stream has version 0, loads order by version or event ID, and deletes of missing rows are no-ops. `StreamIds` holds the §3.1 stream ID conventions.
- ~~`EventRegistry` with the upcaster chain, and the `EventStore` serialization wrapper.~~ Done. One factory per event type at its current version; older versions are upcast one step at a time. `EventStore` refuses to append an event whose type or version isn't registered, so nothing is stored that can't be read back, and wraps non-framework adapter failures in `EventAppendFailedError` / `EventLoadFailedError`.
- ~~`AggregateRoot<TId, E>`: `raise`, `loadFromHistory`, version and committedVersion, uncommitted buffer, snapshots.~~ Done. Snapshots go through `toSnapshot` and `restoreSnapshotState`, which every aggregate implements (an opt-in `Snapshottable` interface until 2026-10-13).
- ~~`EventSourcedRepository` (non-critical snapshot load and save, `snapshotEvery`) and the `StateRepository` base.~~ Done. Snapshot failures go to an optional `onSnapshotError` callback and the repository carries on.
- **Exit:** ~~repository tests against fakes, and an upcaster chain test for v1.0.0 → v1.2.0.~~ Done: `test/event_sourcing/`, 53 tests.

### Phase 3: In-memory provider and contract tests (§24 LocalProvider) (done 2026-10-11)
- ~~`tarodomain_local`: in-memory versions of every adapter, plus `InMemoryUnitOfWork`, which snapshots the stores on begin and restores them on rollback.~~ Done. Every adapter of one `LocalProvider` shares a `LocalDatabase` with an injectable clock. Its rows are immutable, so the unit of work's copy on begin is shallow. Units of work on one database run one at a time, so a rollback can't undo another unit's writes; writes made outside any unit of work while one is running are still lost if it rolls back. `createEventBus` throws `UnimplementedError` until `InMemoryEventBus` lands in Phase 4.
- ~~`tarodomain_testing`: `eventStoreAdapterContract(factory)`, `sagaStoreContract(…)` and so on.~~ Done: `eventStoreAdapterContract`, `snapshotStoreAdapterContract`, `sagaStoreAdapterContract`, `processedEventStoreContract`, `commandIdempotencyStoreContract`, `deadLetterStoreContract` and `unitOfWorkContract`, plus `providerContract(create)`, which runs them all. They cover optimistic-concurrency conflicts (including two racing appends), ordering, cursors, idempotent upserts, TTL deletes and status queries. Each factory must return storage that starts empty. Time-ordered assertions wait a few milliseconds between writes instead of injecting a clock, so the same suites work against a real database.
- **Ordering pinned down.** Cross-stream reads (`loadAll`, `loadStreamAfterEvent`, `loadByCorrelationId`) return events in global append order, and an `afterEventId` cursor marks a position in that order. A contract test appends two IDs from one millisecond that sort in reverse and expects append order back (see Risks). The `EventStoreAdapter` doc comments say so instead of "ordered by event ID".
- **Exit:** ~~the local provider passes every contract suite.~~ Done: `packages/tarodomain_local/test/`, 80 tests. The same suites gate the Serverpod provider in Phase 8.

### Phase 4: Commands and pipelines (§4, §10, §11, §14, §16) (done 2026-10-11)
- ~~`CommandHandler<C, A>`, `CommandRegistry`, `CommandDispatcher` (`dispatch`, `dispatchAll` with `continueOnError`).~~ Done. `CommandRegistry.register<C>(name, factory, {handlerName, consistency})` stores a factory, not a handler: the factory receives a `CommandHandlerContext` with the pipeline's consistency and event bus, which is how one command class gets the strong repository in one pipeline and the eventual one in the other (spec §11.3). Pipelines create a fresh handler for each attempt. Commands match on their exact runtime type. `dispatchAll` never throws: it returns a `BatchDispatchResult` with one outcome per dispatched command and, when it stops at a failure, the skipped rest.
- ~~`InMemoryEventBus`: fail-fast `publishAll` plus `publishAllWithResults`.~~ Done, with the `EventHandler` and `SubscribableEventBus` interfaces. `publishAll` rethrows a `FrameworkError` from a handler unchanged, so a conflict stays retryable and a domain error stays a domain error, and wraps anything else in `EventHandlerFailedError`. Subscribing the same handler twice is a no-op; a different handler with the same name is a configuration error. `LocalProvider.createEventBus` now returns one for both modes.
- ~~`ConcurrencyChecker.withRetry`: 3 retries, 10/20/40 ms, ±10% jitter, with an injectable clock and random source for tests.~~ Done, with an injectable `sleep` and `Random`, a 1 s cap and an `onRetry` hook. Only `OptimisticConcurrencyError` is retried. The spec's `assert` is `check`, because `assert` is reserved.
- ~~Command idempotency: check before dispatch, mark after, and re-check on each retry.~~ Done inside each attempt, so every retry checks again. A command already processed returns `CommandDispatchStatus.duplicate` without running the handler. In strong mode the idempotency record commits in the same unit of work as the events.
- ~~`StrongConsistencyPipeline` and `EventualConsistencyPipeline`, plus per-command consistency routing.~~ Done. A strong dispatch that starts while a unit of work is already active (a saga dispatching from inside another strong command) joins it and is not retried on its own, because after a conflict the outer transaction has to restart.
- **Exit:** ~~tests for retry after a forced conflict, rollback when a projection throws in strong mode, and a duplicate command ID being a no-op.~~ Done: `test/command/`, 47 tests, run against `LocalProvider` (`tarodomain` now dev-depends on `tarodomain_local`).

### Phase 5: Projections and sagas (§12, §13, §17) (done 2026-10-11)
- ~~`Projection` with `on<T>` registration, idempotency through `ProcessedEventStore`, and rebuild hooks. Also `ShardProjection`.~~ Done. A handler registered for a supertype also receives its subtypes; an exact-type registration wins. Events with no handler are recorded as processed (§12.2). A `FrameworkError` from a handler is rethrown as it is; anything else becomes `ProjectionHandlerFailedError`, and the event is not recorded. `ShardProjection` shards by a user-supplied `shardKey(event)` with 32-bit FNV-1a, which is the same in every process (unlike `String.hashCode`). Each shard is a separate handler named `<projection>-shard-<i>` and records events under the shared projection name with its own name as the instance, as §12.3 specifies.
- ~~`ProcessManager<TState>` with the `SagaStateMachine` transition table and `CompensationStack` (LIFO; factories called at compensation time).~~ Done. Handlers are registered with `startsWhen<E>`, `continueWhen<E>`, `compensateWhen<E>` and `completedWhen<E>` and run in the event's `ExecutionContext`, so the commands they create carry the saga ID as correlation and the event as cause. `markFailed(reason)` ends the saga `FAILED`. The state is serialized by the subclass (`stateToJson` / `stateFromJson`); the stored `state` holds it under `state`, next to the compensation stack under `compensations`. The spec's table leaves `COMPENSATING + startsWhen` out; it throws `InvalidSagaTransitionError`.
- ~~`SagaEventHandler`: idempotency, load by correlation ID, dispatch commands before saving state, terminal-state handling.~~ Done. It takes a `SagaCommandDispatch` function (usually `dispatcher.dispatch`), so Phase 6's rebuilder can pass one that discards commands. Events for a completed or failed saga are recorded and skipped instead of throwing, so a late event in the same trace can't fail the command that published it. Events a running saga has no handler for are skipped without saving, so they don't push back its timeout.
- **Exit:** ~~TransferMoney saga tests for the happy path, compensation in reverse order, and every invalid transition in §13.2.~~ Done: `test/saga/` and `test/projection/`, 83 tests. The TransferMoney saga runs end to end through both pipelines on `LocalProvider` (happy path, one- and two-step compensation, rejected first step, redelivery, a dispatch failure and its retry, and a strong-mode rollback of the whole saga), plus the full §13.2 table.
- ~~**Open:** saga commands got fresh random IDs, so a redelivered event dispatched them again.~~ Fixed: commands a saga handler creates get a deterministic UUIDv7 (`Command.withDerivedIds`): the triggering event's `occurredAt` as the timestamp, and a SHA-1 hash of the saga type, event ID and the command's position as the 74 bits RFC 9562 leaves to the implementation. They stay UUIDv7 as the spec requires, and still sort by time. Saga handlers are synchronous and must be deterministic, so handling the same event again from the same state recreates the same IDs, and the pipeline skips them as duplicates. A test crashes the saga save after the withdrawal commits, redelivers the event, and checks the money moves once.

### Phase 6: Catch-up and operations (§18–21, §28.3) (done 2026-10-12)
- ~~`SubscriptionManager`, `CronDispatcher` (stops on a retryable error; skips and advances on a non-retryable one), `BackpressureController`.~~ Done. `CronDispatcher.register(handler, {streamId})` subscribes a handler under its own name to every event, a category or one stream. It reads raw events and deserializes them one at a time, so an event that can't be read is skipped like any non-retryable failure instead of blocking the batch. Skipped events go to an optional `DeadLetterStore`; an optional `UnitOfWork` commits each event's handler and cursor move together. `catchUp` and `runAll` never throw for a failing event; the `CatchUpResult` reports it. `BackpressureController` takes one batch from each subscription in turn, so one far-behind subscription can't starve the rest, within a time budget, an event budget and a pass limit per subscription, with an optional throttle and a progress callback. `SubscriptionManager.getLagReport` counts pending events up to a limit.
- ~~`SagaTimeoutScheduler` with the synthetic `SagaTimeout` event.~~ Done. One scheduler per saga type; `SagaStoreAdapter.loadTimedOut` gained a `sagaType` filter (with a contract test). A saga that handles `SagaTimeout` (usually `compensateWhen<SagaTimeout>`) gets the event through its `SagaEventHandler`; one that doesn't is failed with the reason `timeout`. See the design table for retryable errors and the event's derived ID.
- ~~`ProjectionRebuilder`, `SagaRebuilder` (using a `NullCommandDispatcher`).~~ Done. `ProjectionRebuilder` runs on a `CronDispatcher` and supports the spec's options (`continueOnError`, `resetIdempotency`, `callHooks`, `batchSize`, `maxPasses`). By default a failing event stops the rebuild. `rebuildShards` takes the shard instances, since there is no shard manager. `SagaRebuilder.rebuildType` finds a type's sagas by scanning for events the saga starts on. Synthetic `SagaTimeout` events aren't stored, so they aren't replayed.
- ~~`RetryPolicy`, `DeadLetterWriter`.~~ Done. `RetryPolicy` defaults to 3 retries after 100/200/400 ms with ±10% jitter, and retries only errors the hierarchy marks retryable. `DeadLetterWriter.executeWithRetry` dead-letters an event after the last attempt, or at once for a non-retryable error, and rethrows. If the dead-letter write also fails, it throws `DeadLetterError` so that the caller doesn't ack.
- ~~`CorrelationTrace`: causation tree and formatter.~~ Done. The tree has inferred command nodes between events, linked through the new `commandCausationId` envelope field (see the design table). The TransferMoney saga traces as a single chain from the root command to `TransferCompleted`.
- **Exit:** ~~a rebuilt projection matches the live one, and a timed-out saga either compensates or fails.~~ Done: `test/operations/`, 76 tests. Both run in both consistency modes. A projection rebuilt in place, or rebuilt fresh from the store, matches the live one after a transfer saga. A saga stuck waiting compensates on timeout (the refund runs, then it fails), and one without a timeout handler is failed. A crash while saving the compensating saga, followed by a retry, refunds only once.
- **Open:** a projection handler that keeps throwing a retryable error (any non-framework error becomes the retryable `ProjectionHandlerFailedError`) stops its subscription on that event on every run, as §18.3 specifies. The lag report shows it stuck. A per-event attempt limit would need attempts stored next to the cursor; revisit in Phase 8 with the `subscriptions` table.

### Phase 7: DI, builder, validation (§23, §25, §29) (done 2026-10-13)
- ~~`Token<T>` and `Container` with singleton, transient and scoped lifetimes, `createScope`, and circular-dependency detection.~~ Done. A singleton is created with the container it was bound on, so it can't capture a dependency bound only in a scope; scoped and transient dependencies are created with the container they are resolved from. Resolving a scoped binding from the root treats the root as a scope. Cycles are detected across the whole tree and reported with their path.
- ~~`TaroDomain.builder()` covering the §25.1 DSL; `useLocal()` lives in `tarodomain_local` as an extension.~~ Done: `useProvider`, `consistency`, `snapshotEvery`, `event<E>`/`upcaster`, `aggregate<A, TId>(type, (a) => a.factory(…).snapshotEvery(…).stateRepository(…).event<E>(…))`, `command<C>(type, factory, consistency:)`, `projection(factory)`, `saga(create, timeout:)`, the `bind*` methods, `validation(projectionMode:)`, `skipValidation`, plus `onWarning`, `concurrency`, `clock` and `catchUpBatchSize`. Command factories get a `CommandContext` whose `repository<A, TId>()` builds the registered aggregate's repository on the running pipeline's bus. The global `snapshotEvery` applies to every event-sourced aggregate; state-based aggregates ignore it, and setting it on one explicitly logs a warning.
- ~~`FrameworkValidator` (startup) and `DispatchGuard` (runtime, skip/warn/strict).~~ Done. `build()` reports every error at once in one `InvalidConfigurationError` (duplicate aggregates, commands, sagas and event types; aggregates without a factory or state repository; sagas without `startsWhen`; non-positive timeouts; saga handlers for unregistered events) and logs warnings (a saga that never completes, a saga that handles `SagaTimeout` without a timeout). Projections need the provider's stores, so they are created and checked when the first runtime is created: duplicate names (also against saga types, since they share the buses), no handlers, unregistered events. `DispatchGuard` hooks into projections through `Projection.onUnhandledEvent`.
- ~~**Split between definition and runtime.**~~ Done. `build()` returns an immutable `FrameworkDefinition`; `createRuntime({provider})` returns a `TaroDomain` runtime bound to the provider: adapters, buses, pipelines, projections, saga handlers, a `CronDispatcher` and the timeout schedulers, plus a container scope with `TaroTokens.framework` and `TaroTokens.provider` bound. Every runtime on one `LocalProvider` shares its storage. The entry points are `dispatch`, `handleEvents` (queue consumer) and `runScheduled` (catch-up, then saga timeouts). A provider without a unit of work can't create a runtime if any command needs strong consistency.
- **Exit:** ~~`examples/bank_account` runs the full spec scenario on the local provider: open, deposit, transfer saga, projection query and correlation trace.~~ Done: `dart run bin/main.dart` runs it, and `test/` checks it in both consistency modes, including a failed transfer, a projection rebuild and the saga's timeout refund. Core tests: `test/di/` and `test/framework/`, 67 tests.

### Phase 8: Serverpod module (done 2026-10-13)
The module was scaffolded on 2026-10-11 (`serverpod create --template module`, template samples removed, both packages in the workspace).

**Repositories.** `EventSourcedRepository` and `StateRepository` are defined in core (Phase 2); the module adds the Serverpod side for both persistence modes (§15.4):

- **Event-sourced:** an aggregate configured with `.factory(…)` uses core's `EventSourcedRepository` with the module's `ServerpodEventStoreAdapter`. Saving appends the aggregate's events to `tarodomain_events` through the ORM.
- **State:** an aggregate configured with `.stateRepository(…)` gets a `ServerpodStateRepository<A, TId, R extends TableRow<UuidValue?>>`. The app's own Serverpod model `R` (for example an `Expense` table in the expense app) stores the current state; it needs a `UuidValue` ID and an `int` column named `version`. The subclass provides only `toRow(aggregate)` and `fromRow(row)`. The base class finds `R`'s table through Serverpod's serialization manager, the `version` column by name, and the aggregate type from the definition, and implements `load`, `exists` and `saveState`. Saving checks the version with `updateWhere`, writes the row, and **also appends the aggregate's events to its stream**, in one transaction, before publishing them. On Serverpod the eventual bus only schedules catch-up, which reads the event store, so without the append a state-based aggregate's events would never reach projections or sagas under eventual consistency (and would be missing from traces). The stream's version therefore follows the row's.

In both modes the repository joins the current unit of work, so the aggregate write, projections and saga state commit or roll back together under strong consistency.

```dart
// App code: the aggregate's state lives in the app's own Expense table.
class ExpenseRepository
    extends ServerpodStateRepository<ExpenseAggregate, ExpenseId, Expense> {
  ExpenseRepository(super.context);

  @override
  Expense toRow(ExpenseAggregate a) =>
      Expense(id: a.id.value, amount: a.amount, category: a.category, version: a.version);

  @override
  ExpenseAggregate fromRow(Expense row) => ExpenseAggregate.fromState(row);
}
```

**Tables.** Module models (`.spy.yaml`, `serverOnly`) for the spec's §27 tables, prefixed `tarodomain_`: `events`, `streams`, `subscriptions`, `snapshots`, `sagas`, `processed_events`, `processed_commands`, `dead_letters`, plus `counters` (the sequencer's position counter) and `locks` (job leases). ID columns use `UuidValue`. Serverpod migrations replace `schema_migrations`. The spec's `stream_events` is folded into `events`, which carries `streamId` and `version` with a unique index on the pair. An event row stores the whole serialized event as JSON in `payload`, plus the columns queries need. `events.position` is nullable with a unique index: the **global position**, assigned only after commit (see Risks). Serverpod's auto-increment `id` is insert order, used only to break ties. `subscriptions` stores `lastPosition` next to `lastSeen`. The only client-visible model is the `TaroDomainException` exception.

**Adapters** (all take the request's `Session`):

| Spec need | Serverpod mechanism |
|---|---|
| Append with expected version (§7.3) | Inside a transaction: `updateWhere` on the stream row with `version = expected`, or for a new stream `insert(ignoreConflicts: true)`. No rows back means `OptimisticConcurrencyError`. Neither raises a database error, so a PostgreSQL transaction is never left aborted. Then insert the event rows. |
| Global order for cursor reads (§18) | `EventSequencer` assigns `position` to committed events in its own transaction. `loadAll` and `loadStreamAfterEvent` return only positioned events, ordered by `position`. See Risks. |
| Idempotent inserts (§14.3) | `insert(…, ignoreConflicts: true)` and `upsert` |
| UnitOfWork (§11.4) | `ServerpodUnitOfWork` on `session.db.transaction(...)`. The active `Transaction` is kept in a `Zone` value, per session. Adapters never call the ORM directly; they go through the internal `TaroDb`, which passes that transaction on every call. `ServerpodUnitOfWork.join` lets an endpoint that opened its own transaction run commands in it, and `afterCommit` runs callbacks only once the transaction commits. |
| Eventual event bus (§10.3) | `FutureCallEventBus`. The event store already holds the events durably, so publishing just calls the app's `CatchUpScheduler`, which schedules an immediate catch-up future call. The recurring catch-up is the safety net. No external queue is needed. |
| Cron / timeouts / TTL cleanup (§18.3, §19, §14.1) | `TaroDomainFutureCall`, an abstract future call with `catchUp` (runs the sequencer, then catch-up), `sagaTimeouts` and `cleanup` (7-day processed commands and events, 30-day dead letters). Serverpod generates future calls only from the app's own code (`serverpod generate` drops future call classes from packages), so the app declares `class TaroDomainCalls extends TaroDomainFutureCall {}` and gets all three. The example schedules catch-up and timeouts with `callRecurring().every(Duration(seconds: 5))` and cleanup with `.cron('0 3 * * *')`. Each job takes a lease in `tarodomain_locks` so one server runs it at a time; that saves duplicate work and isn't needed for correctness. |
| HTTP entry point (§26) | Apps keep their own typed endpoints and call `TaroDomainServerpod.dispatch(session, command)`, which creates a runtime for the session and converts a `FrameworkError` to the serializable `TaroDomainException` (code, category, retryable, HTTP status, message, context as JSON), so Flutter clients get typed errors. |
| Live updates to apps | `LiveProjectionNotifier.post(channel, message)` posts to `session.messages` after the unit of work commits, and not at all if it rolls back. |

**Runtime per request.** `TaroDomainServerpod` holds the `FrameworkDefinition` and the provider settings, and is `install()`ed once so the future calls can find it. `runtime(session)` creates a `ServerpodProvider` and a runtime for the request.

**Startup validation.** `TaroDomainServerpod.validate(pod)` creates one runtime on a session from `pod.withSession` and discards it. The example calls it right after `pod.start()` and exits with status 1 if it throws, so an invalid configuration stops the server.

**Timestamps.** SQLite stores `DateTime` as milliseconds and PostgreSQL as microseconds, so `TaroDb.now()` rounds up to the next whole millisecond. Both databases then read back the same value, and never one earlier than the moment of the write, which the contract suites check.

**Example.** `examples/bank_account_serverpod/` holds a Serverpod server and its generated client, on SQLite. The server reuses `bank_account`'s domain through the new `registerBank(builder)` (aggregates, commands and saga, without provider or read model), adds a table-backed `BalanceTableProjection`, a state-based `AccountHolder` stored by `AccountHolderRepository`, a `BankEndpoint`, and `TaroDomainCalls`. `bankDefinition` in `bank_account` now calls `registerBank` too.

- **Exit:** ~~contract suites green on Serverpod, the example's strong and eventual commands both reach the projection, and a server with an invalid projection fails to start.~~ Done.
  - `packages/tarodomain_serverpod_server/test/` (100 tests, PostgreSQL): the contract suites; the ordering test (12 appenders, half holding their transactions open, against a cursor reader that must see every event once); 16 readers racing appenders for the sequencer's counter without failing; a late commit positioned after an early one; no position reuse after a delete; a cursor that survives its event's deletion; forward-only acks; the unit of work (after-commit, per session, `join`); the event bus; leases and cleanup; the exception mapping; `LiveProjectionNotifier`; and the `TaroDb` source scan.
  - `examples/bank_account_serverpod/bank_account_serverpod_server/test/` (94 tests, SQLite): the same contract suites, and the bank in both consistency modes through the generated test endpoints: a strong command reaches the projection at once and an eventual one after catch-up, the transfer saga, a failed transfer, typed client errors, the state repository (row and stream, a stale save rejected, a duplicate registration), a strong-mode rollback when the projection fails, and `validate` rejecting a projection that handles an unregistered event.
  - Run by hand: the example server started on SQLite, and over HTTP an eventual deposit reached the read model through the scheduled future call within 3 seconds.
- **Open:** the Phase 6 per-event attempt limit is still open. `subscriptions` could store attempts next to `lastPosition`.

### Phase 9: Documentation
- Dartdoc for every public API (the `public_member_api_docs` lint is already on), plus a getting-started guide.
- A guide to consuming the private packages from another repo with a git dependency pinned to a tag.

## Risks

Each risk has a resolution. The Serverpod facts below were checked against the 4.0.4 sources on 2026-10-13.

### Global ordering under concurrency (resolved, built in Phase 8)

**Problem.** A position handed out at insert time (an auto-increment ID or a UUIDv7) follows insert order, but other readers see events in commit order. A reader that sees position 11 and moves its cursor past it skips position 10 if 10's transaction commits later. A settle window (read only events older than N seconds) doesn't close the gap: under strong consistency the append's transaction also runs projections, sagas and the commands sagas dispatch, so there is no bound on how long it stays open, and `storedAt` is the app server's clock at insert, not the commit time.

**Resolution: positions are assigned after commit.**

- Appends leave `tarodomain_events.position` null.
- `EventSequencer.run` assigns positions in its own transaction: it reads the `event-position` counter in `tarodomain_counters`, takes the unpositioned events it can see ordered by `id`, claims the counter with `updateWhere(value = read value)`, and sets `value + 1, value + 2, …`. A transaction only sees committed rows, so no event gets a position before it has committed, and no event committed later can get a lower one.
- Two sequencers running at once read the same counter value. The claim locks the counter row, so the second waits for the first to commit, then finds the value changed, claims nothing and retries. No lock or lease is needed beyond that short row lock.
- The counter, unlike `max(position) + 1`, never hands out a position twice. With `max + 1`, deleting the stream that holds the highest event would let the next event reuse its position, behind a cursor that has already passed it.
- Per-stream order holds: appending version n+1 updates the stream row where `version = n`, which waits until version n has committed, so n+1 always gets a higher `id`.
- `loadAll` and `loadStreamAfterEvent` return only positioned events, ordered by `position`. Outside a unit of work they run the sequencer first, so a read right after an append sees the event. Inside one they don't: on SQLite a second transaction would wait on the open one. A read uses `EventSequencer.tryRun`, which stops at the first lost claim instead of retrying: the winner is positioning the same events, and the claim waited until it committed, so the read sees them. Only the catch-up job, which holds the job lease, uses `run`, which retries and throws after 10 losses in a row.
- `loadStream` and `loadByCorrelationId` don't need positions. They order by version and by `id`.

**Cost.** In eventual mode an event reaches projections one sequencer run after it commits. Writers are never serialized against each other.

**Test.** A Serverpod test runs several appenders at once, some holding their transaction open, while a reader loops `loadAll` with a cursor. The reader must see every event exactly once. Another runs 16 readers against the appenders; none may fail. A contract test appends a cause and its effect to different streams in one millisecond with IDs that sort the other way, and expects the cause first.

**Ruled out.** A global counter row updated by every append is also correct, but it holds a row lock for the whole strong-mode transaction, so every strong command in the cluster would run one at a time. PostgreSQL transaction IDs (`pg_current_snapshot()`) would need raw SQL, which the Decisions rule out. Using the event ID as the primary key, instead of the auto-increment `id`, would save a column and an index, but the sequencer would then have to order a batch by event ID. Within one millisecond that order is random, so an effect in one stream could be positioned before its cause in another; insert order (`id`) keeps the cause first.

### UUIDv7 order within one millisecond (resolved)

The `uuid` package's v7 generator has no monotonic counter, so two IDs from the same millisecond sort in either order. Nothing relies on that order:

- Per-stream order comes from the stream version, and global order from `position`.
- The Serverpod subscription row stores `lastPosition` next to `lastSeen`. The adapter resolves an `afterEventId` to its position, and falls back to `lastPosition` if that event was deleted with its stream.
- `ackSubscription` only moves `lastPosition` forward (`updateWhere` with `lastPosition < new`). Two catch-up runs on one subscription, such as the recurring call and one scheduled by `FutureCallEventBus`, can't move it back. Projection idempotency already makes the double delivery harmless.
- The local provider orders by its own append position. It compares event IDs only when the cursor's event has been deleted, which is accepted.
- The Phase 3 contract test that appends two same-millisecond IDs in reverse order keeps this from regressing.

### No ambient transaction in Serverpod (mitigated)

In 4.0.4 the ORM falls back to `session.transaction` when no `transaction:` is passed, but a server `Session` always returns null there; only `serverpod_test` sessions override it. A call that forgets `transaction:` therefore runs outside the unit of work on PostgreSQL. On SQLite, which has one connection, it waits on the open transaction and hangs.

**Resolution.**

1. **One way in.** Adapters never call the ORM directly. They use the internal `TaroDb` (`lib/src/db/taro_db.dart`), which wraps `find`, `findFirstRow`, `findById`, `count`, `insert`, `insertRow`, `updateWhere`, `updateRow`, `deleteWhere` and `upsert` and passes the zone's transaction on every call. Only `ServerpodUnitOfWork` opens a transaction; `EventSequencer` asks it for one of its own with `separately`.
2. **Enforced by a test.** A source-scan test (`test/taro_db_scan_test.dart`) fails if any file under `lib/src/` other than `taro_db.dart`, the unit of work and generated code uses `.db.` or `transaction:`. A forgotten transaction becomes a test failure instead of something code review has to catch.
3. **Every write rolls back.** The `unitOfWorkContract` rollback test covers event appends, subscription acks, saga saves, processed events, snapshots, processed commands and dead letters, so every adapter's writes are checked on every provider.
4. **Tests don't hide it.** The Serverpod suites run with `RollbackDatabase.disabled`. With the default, the test session's own transaction would absorb a forgotten `transaction:` and the bug wouldn't show. The racing-append tests need separate transactions anyway.

### Serverpod 4 is new (mitigated)

Serverpod 4.0.4 was released on 2026-10-06. Mitigation:

- The module and its test tools pin exactly `4.0.4`. An upgrade is a deliberate change: bump the pin, run `serverpod generate`, run the contract suites.
- Every Serverpod import stays in `tarodomain_serverpod_server`; the core and the local provider never see it.
- The APIs Phase 8 depends on exist in 4.0.4: `insert(ignoreConflicts:)`, `upsert`/`upsertRow`, `updateWhere`, `transaction` with `TransactionSettings(isolationLevel:)`, and `callRecurring()` with `.every(…)` and `.cron(…)`. Cron expressions only go down to the minute, so the catch-up call uses `.every`.

### Scope (resolved)

Phases 1–8 are done. Phases 1–7 are usable on the local provider by themselves.
