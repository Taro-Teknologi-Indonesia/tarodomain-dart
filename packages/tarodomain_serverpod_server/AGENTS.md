# Serverpod module

This package is the Serverpod adapter for TaroDomain (`package:tarodomain`, in `../tarodomain`). It implements the TaroDomain Provider on Serverpod: the spec's tables as Serverpod models, the store adapters and repositories (ORM only, no raw SQL, so PostgreSQL and SQLite both work), the unit of work on `session.db.transaction`, scheduled catch-up / saga timeout / cleanup as future calls, and helpers for dispatching commands from app endpoints. See `docs/IMPLEMENTATION_PLAN.md` at the repo root, Phase 8.

It is a Serverpod module: a reusable package with server code (`tarodomain_serverpod_server`) and client code (`tarodomain_serverpod_client`) that other Serverpod projects add as a dependency. Both packages are members of the repo's pub workspace, so run `dart pub get` from the repo root. A module is not a runnable server, so there is no `serverpod start` and no `serverpod` MCP here.

Working loop, run from `tarodomain_serverpod_server`:

- Add models (`.spy.yaml`) and endpoints under `lib/src/`.
- `serverpod generate` after every change to a model or an endpoint.
- `serverpod create-migration` after changing a model with a `table` (add `--force` for destructive changes). The migration ships with the module and is applied by the projects that depend on it.
- `dart analyze` and `dart format`.
- `dart test` to run the tests. They use `withServerpod` from the generated test tools together with `config/test.yaml`. No Docker is needed: `config/test.yaml` sets `database.dataPath`, so Serverpod starts and manages the test database (an embedded PostgreSQL) itself.

Prefix table names with `tarodomain_` (for example `tarodomain_events`) so they cannot collide with the tables of the projects that use this module.

NEVER edit generated code. `tarodomain_serverpod_server/lib/src/generated/` and the whole `tarodomain_serverpod_client` package are rewritten by the code generator. Change the models, the endpoints or `lib/tarodomain_serverpod_server.dart` instead.

Migrations are a narrow exception: the `migration.sql` of a generated migration MAY be edited by hand when the generated SQL would lose data — to add a data transformation, or to reach a destructive change through non-destructive steps. Never touch the other files in the migration directory, and keep the schema the SQL ends up with identical to `definition.sql` — new databases are created from that file and never run `migration.sql`.

Projects that depend on this module reference its types as `module:tarodomain_serverpod:MyType`, where `tarodomain_serverpod` is the `nickname` in `config/generator.yaml`.
