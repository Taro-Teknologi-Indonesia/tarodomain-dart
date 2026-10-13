# Implementation plan: TaroDomain core and Serverpod adaptation

Status: draft, updated 2026-10-12. Targets the [TaroDomain spec v1.0](../spec/README.md) at commit `983d2cb` (the `spec/` submodule), Dart 3.12 and Serverpod 4.0.x.

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
| `toSnapshot()` via own enumerable properties (§5.4) | Aggregates that support snapshots implement `Snapshottable`: `Map<String, Object?> toSnapshot()` and `restoreSnapshotState(data)` are explicit overrides. Snapshotting an aggregate that doesn't implement them is a configuration error caught at `build()`. | No reflection over fields. |
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
| Subscription `lastSeen` only moves forward (§18.2) | `SubscriptionManager.advance` skips a move to the event the cursor is already on, and otherwise trusts the caller. `CronDispatcher` acks in read order. | The cursor holds only an event ID, and event IDs don't order events within a millisecond or across servers (see Risks), so the manager can't tell forward from backward without a position. |
| A timeout handler that throws marks the saga `FAILED` (§19.1) | Only a non-retryable error does. A retryable one (a conflict, an outage) leaves the saga for the next run. The `SagaTimeout` event's ID and timestamp are derived from the saga's type, ID and `updatedAt`, so the retry dispatches the same command IDs. | Failing a saga for good over a transient error is out of step with the rest of the error hierarchy. |
| `loadTimedOut(threshold, { maxCount })` (§19.1) | `loadTimedOut(before, {sagaType, limit})` | One scheduler per saga type (§19.3) needs to filter by type in the store; filtering afterwards lets other types fill the limit. |
| Events carry `correlationId` and `causationId` (§28.1) | Plus an optional `commandCausationId`: for an event raised by a command, that command's own `causationId`. `ExecutionContext.forCommand` sets it, and the envelope JSON omits it when null. | Commands aren't stored, so without it `CorrelationTrace` can't link a command to the event that caused it, and a saga's trace falls apart into unconnected pieces. |
| TS type helpers `ProjectionOf`, `SagaOf` (§29.3) | Not needed. Sealed event families plus `on<T>` registration cover this. | |
| `TransactionalDatabase` write-collecting proxy (§11.4) | Not needed on Serverpod, which has real transactions. The in-memory provider uses a copy-on-begin store. | |
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
- ~~`AggregateRoot<TId, E>`: `raise`, `loadFromHistory`, version and committedVersion, uncommitted buffer, snapshots.~~ Done. Snapshots go through the `Snapshottable` interface.
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

### Phase 7: DI, builder, validation (§23, §25, §29)
- `Token<T>` and `Container` with singleton, transient and scoped lifetimes, `createScope`, and circular-dependency detection.
- `TaroDomain.builder()` covering the §25.1 DSL; `useLocal()` lives in `tarodomain_local` as an extension.
- `FrameworkValidator` (startup) and `DispatchGuard` (runtime, skip/warn/strict).
- **Split between definition and runtime.** `build()` produces an immutable `FrameworkDefinition` (registries, handler factories, routing) once per process. Each request creates a cheap runtime scope that binds that request's provider resources. Serverpod needs this, because every database call goes through a per-request `Session`.
- **Exit:** `examples/bank_account` runs the full spec scenario on the local provider: open, deposit, transfer saga, projection query and correlation trace.

### Phase 8: Serverpod module
The module is already scaffolded (2026-10-11): `packages/tarodomain_serverpod_server` and `packages/tarodomain_serverpod_client`, generated with `serverpod create --template module`, the template samples removed, both packages in the workspace, and an integration smoke test passing against the embedded PostgreSQL.

**Repositories.** `EventSourcedRepository` and `StateRepository` are defined in core (Phase 2); the module adds the Serverpod side for both persistence modes (§15.4):

- **Event-sourced:** an aggregate configured with `repository('event_sourced')` uses core's `EventSourcedRepository` with the module's `ServerpodEventStoreAdapter`. Saving appends the aggregate's events to the module's `tarodomain_events` tables through the ORM.
- **State:** an aggregate configured with `repository('state')` gets a `ServerpodStateRepository<A, TId, R extends TableRow>`. The app's own Serverpod model `R` (for example an `Expense` table in the expense app) stores the current state. The subclass provides only `toRow(aggregate)` and `fromRow(row)`; the base class implements `load`, `exists` and `saveState` with Serverpod's `find`/`insertRow`/`updateWhere`. It checks optimistic concurrency with a `version` column, and it publishes the aggregate's events after the row is written so projections and sagas still run.

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

**Tables.** Module models (`.spy.yaml`) for the spec's §27 tables, prefixed `tarodomain_`. ID columns use Serverpod's `UuidValue` type, so the core's IDs are stored as they are. Serverpod migrations replace the spec's `schema_migrations` table. Each table gets the spec's key and indexes. `events` additionally keeps Serverpod's auto-increment `id` as a **global position** (see risks).

**Adapters** (all take the request's `Session`):

| Spec need | Serverpod mechanism |
|---|---|
| Append with expected version (§7.3) | Inside a transaction: `updateWhere` on the stream row with `version = expected`. No rows returned means `OptimisticConcurrencyError`. For a new stream, `insert` and treat a unique violation as a conflict. Then insert the events and stream_events rows. |
| Idempotent inserts (§14.3) | `insert(…, ignoreConflicts: true)` and `upsert` |
| UnitOfWork (§11.4) | `session.db.transaction(...)`. The active `Transaction` is kept in a `Zone` value, and every adapter call passes it on, because Serverpod's ORM does not pick up an ambient transaction by itself. |
| Eventual event bus (§10.3) | `FutureCallEventBus`. The event store already holds the events durably, so publishing just schedules an immediate catch-up future call. A recurring cron future call is the safety net, the same role as the spec's CronDispatcher. No external queue is needed. |
| Cron / timeouts / TTL cleanup (§18.3, §19, §14.1) | Module future calls: `TaroDomainCatchUpCall` (every few seconds), `TaroDomainSagaTimeoutCall`, `TaroDomainCleanupCall` (7-day / 30-day TTL deletes), registered with `callRecurring().cron(...)`. |
| HTTP entry point (§26) | Apps keep their own typed endpoints and call `taro.dispatch(session, command)`. A `FrameworkError` is converted to a module-defined serializable `TaroDomainException` (code, category, message, context), so Flutter clients get typed errors. |
| Live updates to apps | Optional `LiveProjectionNotifier` that posts to `session.messages` channels after a projection commits. Endpoint streams forward these to Flutter clients. |

**Testing:** run the Phase 3 contract suites through `serverpod_test`'s `withServerpod`, against both PostgreSQL and SQLite. Add a `ServerpodStateRepository` test that uses a test-only table.

**Example:** `examples/bank_account_serverpod` reuses the domain code from `examples/bank_account` unchanged. That shows the core really is platform-agnostic.

- **Exit:** contract suites green on Serverpod, and the example's strong and eventual commands both reach the projection.

### Phase 9: Documentation
- Dartdoc for every public API (the `public_member_api_docs` lint is already on), plus a getting-started guide.
- A guide to consuming the private packages from another repo with a git dependency pinned to a tag.

## Risks

- **Global ordering under concurrency.** `loadAll` cursors that use UUIDv7, which the spec specifies, or an auto-increment ID can **skip events**. A transaction that obtained a lower ID may commit after a higher one has been read and the cursor advanced. Mitigation: catch-up reads only events older than a short settle window. That works through the ORM on both databases; a PostgreSQL-only fix based on transaction IDs would break the ORM-only rule. The window length has to be decided in Phase 8 and covered by a contract test with concurrent appends.
- **UUIDv7 order within one millisecond.** The `uuid` package's v7 generator fills everything after the 48-bit timestamp with random bits. It has no monotonic counter, so two IDs generated in the same millisecond can sort in either order. Nothing may rely on event IDs for ordering within a millisecond: per-stream order comes from the stream version, and global order from the `events` table's auto-increment position. The spec's `lastSeen` cursor (§18) uses that position instead of the event ID.
- **No ambient transaction in Serverpod.** If any adapter call forgets to pass the zone's `Transaction`, it silently runs outside the unit of work. Mitigation: route every database call through one internal helper, and add a contract test that rolls back and checks that nothing persisted.
- **Serverpod 4 is new** (4.0.4, 2026-10-06). Module and future-call APIs may still shift. Pin `4.0.x` and adapt in one place.
- **Scope.** The spec is large. Phases 1–7 are worth shipping by themselves on the local provider before the Serverpod work starts.
