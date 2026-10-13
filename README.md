# TaroDomain (Dart)

Dart implementation of the [TaroDomain framework specification](spec/README.md): event sourcing, CQRS and DDD with strong or eventual consistency per command.

The spec is a git submodule at [`spec/`](spec), pinned to the version this code implements. Its upstream is [Taro-Teknologi-Indonesia/tarodomain](https://github.com/Taro-Teknologi-Indonesia/tarodomain).

## Serverpod hackathon entry: Gavel

> **Jury: start with [`examples/gavel/README.md`](examples/gavel/README.md)**: the live link, a 2-minute try-it, the Serverpod mapping and the proof. The rest of this repo is the framework Gavel runs on.

**Gavel is a live silent auction that closes itself.** In Indonesia, sellers of gemstones, keris, blades and other collectibles run auctions (*lelang*) in Facebook comment threads. That leads to arguments over who bid first, deleted comments, and auctions closed by hand whenever the seller checks their phone. With Gavel the crowd stays on Facebook, and the seller pastes one link under the photos. Bidders open it in their phone browser, type a name, and bid. The server keeps a bid ledger that nobody can edit and closes the auction at the deadline, even with the seller's laptop shut.

**A note on sign-in.** Since Gavel's sellers and bidders already live on Facebook, Facebook login would be the natural choice. We couldn't add it: Meta has to review and verify an app before people outside its developer team can log in with Facebook, and that couldn't be done before the hackathon deadline. So Gavel ships with:

- **Organizers:** Serverpod's own auth module (email plus a verification code, JWT sessions). The server refuses to create an auction without a signed-in user.
- **Bidders:** no account. A bidder types a display name and gets a random participant key kept in that browser. Making people sign up before they can bid would lose most of the crowd coming from a Facebook post.

Facebook login can be added later as one more identity provider in Serverpod's auth module once the app is verified. The design is in [X6 — Organizer sign-in](examples/gavel/docs/plans/x6-organizer-sign-in.md).

- **Live:** https://gavel-auction.serverpod.space (Flutter web, served by Serverpod on Serverpod Cloud)
- **Use cases:** [examples/gavel/docs/use-cases.md](examples/gavel/docs/use-cases.md)
- **Per-use-case build plans and design decisions:** [examples/gavel/docs/plans/](examples/gavel/docs/plans/README.md)

### What to look for

| Where | What it shows |
|---|---|
| [`gavel_server/lib/src/domain/`](examples/gavel/gavel_server/lib/src/domain) | Event-sourced `Auction` and `Lot` aggregates, commands and typed domain errors (`OutbidError`, `LotClosedError`, …). This code is pure Dart and its tests run in memory. |
| [`gavel_server/lib/src/endpoints/`](examples/gavel/gavel_server/lib/src/endpoints) | Serverpod endpoints dispatch commands through the TaroDomain pipeline. `LiveEndpoint.watch` is a streaming endpoint backed by `session.messages`, and it pushes board updates over WebSocket. |
| [`gavel_server/lib/src/infra/`](examples/gavel/gavel_server/lib/src/infra) | Projections into Serverpod ORM tables (the board's read model) and the live-update channels. |
| [`gavel_server/lib/src/future_calls/`](examples/gavel/gavel_server/lib/src/future_calls) | Server-side deadlines through Serverpod future calls. On Serverpod Cloud, where future calls are off for this plan, in-process timers run the same jobs ([`timer_jobs.dart`](examples/gavel/gavel_server/lib/src/infra/timer_jobs.dart)). |
| [`gavel_flutter/`](examples/gavel/gavel_flutter) | The Flutter web app. The join link `/a/<CODE>` is the whole funnel, so there's no install and no account. |
| [`packages/tarodomain_serverpod_server`](packages/tarodomain_serverpod_server) | The Serverpod module underneath: an event store, outbox, sagas and idempotency, all on ORM tables and migrations. |

### How Gavel uses Serverpod

| Gavel feature | Serverpod part |
|---|---|
| Commands (create auction, add lot, …) | Endpoints with typed `SerializableException` errors |
| Event store, read models, participants | ORM tables and migrations (from the TaroDomain module plus Gavel's own models) |
| Live board in every open browser | Streaming endpoint over WebSocket and `session.messages` |
| Auctions close on time with no client online | Future calls, or an in-process timer sweep where they're unavailable |
| The app itself | Serverpod web server hosting the Flutter web build, with a fallback route for deep links |
| Hosting | Serverpod Cloud with managed PostgreSQL, deployed by [`tool/deploy.sh`](examples/gavel/tool/deploy.sh) |

### Run Gavel locally

```sh
dart pub get                                  # at the repo root (pub workspace)
examples/gavel/tool/build_web.sh              # build the Flutter web app into gavel_server/web/app
cd examples/gavel/gavel_server
dart run bin/main.dart --apply-migrations     # embedded PostgreSQL; the app is on http://localhost:8082
```

## Packages

| Package | Spec sections | Contents |
|---|---|---|
| [`tarodomain`](packages/tarodomain) | §2–23, §25, §28–29 | Domain primitives, event store wrapper and registry, aggregates, repositories, event bus, command pipelines, projections, sagas, idempotency, rebuild, DLQ, errors, DI, builder DSL |
| [`tarodomain_local`](packages/tarodomain_local) | §24 (LocalProvider) | In-memory adapters for tests and local development |
| [`tarodomain_testing`](packages/tarodomain_testing) | §24 | Contract test suites that every provider must pass |
| [`tarodomain_serverpod_server`](packages/tarodomain_serverpod_server) | §24, §26, §27 | Serverpod module: tables, adapters, repositories, future calls, endpoint helpers (scaffold) |
| [`tarodomain_serverpod_client`](packages/tarodomain_serverpod_client) | — | Client code generated by `serverpod generate`; never edit by hand |
| [`examples/bank_account`](examples/bank_account) | — | The BankAccount / TransferMoney example used throughout the spec |
| [`examples/gavel`](examples/gavel) | — | Gavel, the Serverpod hackathon entry: server, generated client and Flutter web app |

`tarodomain` must stay platform-agnostic: it never imports a provider or a database driver.

See the [implementation plan](docs/IMPLEMENTATION_PLAN.md) for the roadmap, including the Serverpod module.

## Development

Requires Dart 3.12.2+ (Serverpod 4.0.4's minimum). Working on the Serverpod module also needs `dart pub global activate serverpod_cli 4.0.4`. The repo is a [pub workspace](https://dart.dev/tools/pub/workspaces), so one `dart pub get` at the root resolves every package. [Melos](https://melos.invertase.dev) runs scripts across packages.

```sh
git clone --recurse-submodules <this repo>   # or, after a plain clone: git submodule update --init
dart pub get
dart run melos run analyze       # dart analyze --fatal-infos
dart run melos run test          # dart test in every package with a test/ folder (Serverpod tests start an embedded PostgreSQL)
dart run melos run format        # dart format .
dart run melos run format:check  # fail if anything is unformatted
```

To add a package, create it under `packages/` with `resolution: workspace` in its `pubspec.yaml`, then list it under `workspace:` in the root `pubspec.yaml`.

## Updating the spec

```sh
git submodule update --remote spec              # move to the latest upstream spec
git -C spec log -p --reverse HEAD@{1}..HEAD     # read what changed in the spec
```

Bring the code and [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) in line with the changes, then commit the new `spec` pointer in the same commit as the code that implements it.

## Where Dart differs from the spec

The spec is language-agnostic, but a few mechanisms assume JavaScript:

- **Dispatch by method name** (`on[EventName]`, `startsWhen[EventName]`, …): Dart has no runtime reflection in AOT or Flutter builds. Handlers have to be registered explicitly, for example with a map from event type to handler, or generated with `build_runner`.
- **Rehydration without the constructor** (`Object.create` + `defineProperty`): use `fromJson` factories registered in the `EventRegistry`.
- **ExecutionContext as a module-level variable**: use `Zone` values, which give each request its own context and remove the concurrency caveat in spec §5.5.
- **Providers**: Cloudflare Workers don't run Dart, so the Cloudflare D1 / Queue provider is out of scope. Serverpod is the first server provider, as a Serverpod module.
