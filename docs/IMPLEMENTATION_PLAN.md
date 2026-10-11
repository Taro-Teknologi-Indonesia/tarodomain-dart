# Implementation plan: TaroDomain core and Serverpod adaptation

Status: draft, updated 2026-10-11. Targets the [TaroDomain spec v1.0](../spec/README.md) at commit `983d2cb` (the `spec/` submodule), Dart 3.12 and Serverpod 4.0.x.

## Goal

1. **`tarodomain`**: a pure-Dart implementation of the spec's platform-agnostic parts (§2–23, §25, §28–29). It depends on no database, server or Flutter.
2. **`tarodomain_serverpod`**: a Serverpod module that implements the spec's Provider (§24) on top of Serverpod. Persistence uses Serverpod's ORM and migrations, the unit of work uses Serverpod transactions, scheduling uses future calls, and Serverpod endpoints replace the spec's worker entry points (§26).

## Decisions

- **Persistence goes through repositories, and repositories go through Serverpod.** Domain code and command handlers only ever see `Repository<T>`. The Serverpod repositories save and load through Serverpod's ORM and nothing else: no raw SQL, and no database driver imported by TaroDomain. As a result, whichever database Serverpod is configured with (PostgreSQL or SQLite) works without extra code.
- **The packages are private.** Every pubspec has `publish_to: none`. Other projects, such as the expense app, depend on them through a git or path dependency.
- **AWS is out of scope.** The spec's AWS provider (§24, §26.2, §27.3) won't be ported.

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
| Rehydration without the constructor (`Object.create`) (§2.1) | `EventRegistry.register<E>(name, version, fromData)`, where each event provides `toData()` and a `fromData` factory | Dart has no way to bypass constructors. Code generation (`json_serializable`) can be added later; it is not required. |
| Envelope fields set on the event and frozen (§2.1) | The `DomainEvent` base class holds an `EventEnvelope` (id, eventVersion, correlationId, causationId, metadata, occurredAt). Only the framework can assign it, and only once, through a library-private method. Business fields are `final`. | Enrichment in `raise()` has to set correlation and causation after the user has constructed the event. Requiring a per-class `copyWith` would put a burden on every event class. |
| Module-level `ExecutionContext` (§5.5) | `Zone` values: `ExecutionContext.run(ctx, () => …)` and `ExecutionContext.current` | Each request gets its own context, which removes the §5.5 concurrency caveat. |
| `toSnapshot()` via own enumerable properties (§5.4) | `Map<String, Object?> toSnapshot()` / `restoreSnapshot(data)` are explicit overrides. Snapshotting an aggregate that doesn't implement them is a configuration error caught at `build()`. | No reflection over fields. |
| TS type helpers `ProjectionOf`, `SagaOf` (§29.3) | Not needed. Sealed event families plus `on<T>` registration cover this. | |
| `TransactionalDatabase` write-collecting proxy (§11.4) | Not needed on Serverpod, which has real transactions. The in-memory provider uses a copy-on-begin store. | |
| `fetchHandler` / `queueHandler` / `scheduledHandler` (§25.2, §26) | Core exposes `dispatch`, `handleEvents` and `runScheduled`. Each provider wires them to its host: Serverpod endpoints and future calls. | Dart doesn't run on Cloudflare Workers, and the AWS provider is out of scope (see Decisions). |

## Phases

Each phase ends with `melos run analyze` and `melos run test` passing.

### Phase 0: Prerequisites
- ~~Upgrade the Dart SDK to 3.12.2 or newer and raise the `sdk:` constraints.~~ Done: Dart 3.13.5, all packages on `^3.12.2`, Serverpod CLI 4.0.4 installed.
- Add `uuid` (v7 support) and `meta` to `tarodomain`.
- Create `tarodomain_testing`.
- Add CI: GitHub Actions running format check, analyze and test, with a Postgres service for the Serverpod phase.

### Phase 1: Domain primitives (§2, §5.5, §22, §28)
- `Uuid7` helpers, `AggregateId` (`generate`, `fromExisting`, `fromUuidv7`) with typed subclasses.
- `ValueObject<T>`: `validate`, `==`/`hashCode`, optional `Comparable`, `copyWith` in place of `with`, which is reserved in Dart.
- `DomainEvent` with `EventEnvelope`, and `Command` with the same envelope fields.
- Complete error hierarchy: all 51 codes from §22.2 as concrete classes, built on the existing `FrameworkError`.
- `ExecutionContext` on zones.
- **Exit:** unit tests for envelope defaults, immutability, ID parsing, and the retryability matrix for every error class.

### Phase 2: Event sourcing (§3, §5, §6, §7, §8)
- Adapter interfaces: `EventStoreAdapter`, `SnapshotStoreAdapter`, `SagaStoreAdapter`, `ProcessedEventStore`, `CommandIdempotencyStore`, `DeadLetterStore`, `UnitOfWork`, `Provider`.
- `EventRegistry` with the upcaster chain, and the `EventStore` serialization wrapper.
- `AggregateRoot<TId, E>`: `raise`, `loadFromHistory`, version and committedVersion, uncommitted buffer, snapshots.
- `EventSourcedRepository` (non-critical snapshot load and save, `snapshotEvery`) and the `StateRepository` base.
- **Exit:** repository tests against fakes, and an upcaster chain test for v1.0.0 → v1.2.0.

### Phase 3: In-memory provider and contract tests (§24 LocalProvider)
- `tarodomain_local`: in-memory versions of every adapter, plus `InMemoryUnitOfWork`, which snapshots the stores on begin and restores them on rollback.
- `tarodomain_testing`: `eventStoreAdapterContract(factory)`, `sagaStoreContract(…)` and so on. These cover optimistic-concurrency conflicts, ordering, cursors, idempotent upserts, TTL deletes and status queries.
- **Exit:** the local provider passes every contract suite. The same suites gate the Serverpod provider in Phase 8.

### Phase 4: Commands and pipelines (§4, §10, §11, §14, §16)
- `CommandHandler<C, A>`, `CommandRegistry`, `CommandDispatcher` (`dispatch`, `dispatchAll` with `continueOnError`).
- `InMemoryEventBus`: fail-fast `publishAll` plus `publishAllWithResults`.
- `ConcurrencyChecker.withRetry`: 3 retries, 10/20/40 ms, ±10% jitter, with an injectable clock and random source for tests.
- Command idempotency: check before dispatch, mark after, and re-check on each retry.
- `StrongConsistencyPipeline` and `EventualConsistencyPipeline`, plus per-command consistency routing.
- **Exit:** tests for retry after a forced conflict, rollback when a projection throws in strong mode, and a duplicate command ID being a no-op.

### Phase 5: Projections and sagas (§12, §13, §17)
- `Projection` with `on<T>` registration, idempotency through `ProcessedEventStore`, and rebuild hooks. Also `ShardProjection`.
- `ProcessManager<TState>` with the `SagaStateMachine` transition table and `CompensationStack` (LIFO; factories called at compensation time).
- `SagaEventHandler`: idempotency, load by correlation ID, dispatch commands before saving state, terminal-state handling.
- **Exit:** TransferMoney saga tests for the happy path, compensation in reverse order, and every invalid transition in §13.2.

### Phase 6: Catch-up and operations (§18–21, §28.3)
- `SubscriptionManager`, `CronDispatcher` (stops on a retryable error; skips and advances on a non-retryable one), `BackpressureController`.
- `SagaTimeoutScheduler` with the synthetic `SagaTimeout` event.
- `ProjectionRebuilder`, `SagaRebuilder` (using a `NullCommandDispatcher`).
- `RetryPolicy`, `DeadLetterWriter`.
- `CorrelationTrace`: causation tree and formatter.
- **Exit:** a rebuilt projection matches the live one, and a timed-out saga either compensates or fails.

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
- **State:** an aggregate configured with `repository('state')` gets a `ServerpodStateRepository<A, R extends TableRow>`. The app's own Serverpod model `R` (for example an `Expense` table in the expense app) stores the current state. The subclass provides only `toRow(aggregate)` and `fromRow(row)`; the base class implements `load`, `exists` and `saveState` with Serverpod's `find`/`insertRow`/`updateWhere`. It checks optimistic concurrency with a `version` column, and it publishes the aggregate's events after the row is written so projections and sagas still run.

In both modes the repository joins the current unit of work, so the aggregate write, projections and saga state commit or roll back together under strong consistency.

```dart
// App code: the aggregate's state lives in the app's own Expense table.
class ExpenseRepository extends ServerpodStateRepository<ExpenseAggregate, Expense> {
  ExpenseRepository(super.context);

  @override
  Expense toRow(ExpenseAggregate a) =>
      Expense(id: a.id.value, amount: a.amount, category: a.category, version: a.version);

  @override
  ExpenseAggregate fromRow(Expense row) => ExpenseAggregate.fromState(row);
}
```

**Tables.** Module models (`.spy.yaml`) for the spec's §27 tables, prefixed `tarodomain_`. Serverpod migrations replace the spec's `schema_migrations` table. Each table gets the spec's key and indexes. `events` additionally keeps Serverpod's auto-increment `id` as a **global position** (see risks).

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
- **No ambient transaction in Serverpod.** If any adapter call forgets to pass the zone's `Transaction`, it silently runs outside the unit of work. Mitigation: route every database call through one internal helper, and add a contract test that rolls back and checks that nothing persisted.
- **Serverpod 4 is new** (4.0.4, 2026-10-06). Module and future-call APIs may still shift. Pin `4.0.x` and adapt in one place.
- **Scope.** The spec is large. Phases 1–7 are worth shipping by themselves on the local provider before the Serverpod work starts.
