# tarodomain_serverpod_server

Serverpod module that runs [TaroDomain](../tarodomain) on Serverpod. Status: scaffold only; the adapters are built in Phase 8 of the [implementation plan](../../docs/IMPLEMENTATION_PLAN.md).

## Working on the module

Requires the Serverpod CLI matching the pinned version: `dart pub global activate serverpod_cli 4.0.4`.

From this directory:

```sh
serverpod generate            # after changing a model (.spy.yaml) or an endpoint
serverpod create-migration    # after changing a model that has a table
dart test                     # integration tests; starts an embedded PostgreSQL, no Docker needed
```

Never edit `lib/src/generated/` or the `tarodomain_serverpod_client` package by hand; `serverpod generate` rewrites them. See [AGENTS.md](AGENTS.md) for the full rules.

`config/passwords.yaml` holds only the throwaway password for the embedded test database. Never put real credentials in it.
