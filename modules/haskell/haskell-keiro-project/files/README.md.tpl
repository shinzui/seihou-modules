# {{project.name}}

{{project.description}}

This seed contains six Cabal libraries, shared injected health routes and a typed OpenAPI
exporter. Follow [the implementation brief](docs/bootstrap-keiro.md) or run the
`haskell-keiro-service` blueprint to implement domain routes, workers, migrations and clients.

```bash
nix develop
just build
just test
just openapi
just openapi-check
just test-tools
just api-validate
just api-render
just fixture-plan
```

`just openapi` writes `docs/openapi.json` without a database or running server. The API owns
`ServiceApi` and the derived OpenAPI 3.1 schema. The server exports `mkApp liveCheck readyCheck`
and `serviceServer` using servant-health's contract and handlers. Inject real process-only
liveness and dependency/drain readiness policy when assembling the service. The probes are
`/health/live` and `/health/ready`; no bare `/health` route exists. The health test uses the
library conformance kit against this builder. Freshness checking catches edited/stale schemas.

The domain workspace is `domain/{{project.name}}.keiro-workspace`, with shared declarations
in `domain/{{project.name}}/shared.keiro`. An optional context override affects DSL context
only. Core has no sibling dependencies; API depends on core, server on core/API, workers on
core, client on API, and migrations is independent. Add real members before scaffolding.

```bash
process-compose -f process-compose.yaml up
# From a second shell, create a fresh scratch target:
createdb -- bootstrap_scratch
just fixture-load bootstrap_scratch
just fixture-with
# Once the real application is running with its checks:
just api-test http://127.0.0.1:8080
```

`just create-database` creates only the development database until real migrations are wired.
Fixture loading always requires an existing explicit target. The marker is test-only plumbing,
never loaded automatically or placed in production migrations. `fixture-with` loads it into an
owned clone, verifies `ready`, and releases it. Stop consumers before releasing clones; only
remove scratch targets you created. Hinagata's helper resolves absolute paths/private storage
and explicit roles/endpoints, defaulting PGUSER to your user and PGPORT to 5432; maintenance
and role connection databases default to postgres. Caller HINAGATA_* overrides are preserved.
Add migration up/verify hooks and map leased child PG fields into application configuration
before domain tests. The initial hook-free setup does not reuse a persistent baseline.

Tool wrappers fetch immutable flake packages on first use. Workbench/schema are pinned
together at `a29d26ad5e90aa762de88be18f06fddf67b6d02f` (unpublished tooling), Hinagata at
`a0c1059743e5957e66e4b8cee9e485ad89471937` (0.1.0.0). See
`mori://shinzui/hurl-workbench` and `mori://shinzui/hinagata`. Update schema/tool pins together.
CLI tools stay outside application Cabal dependencies and do not change the compiler/runtime.
PostgreSQL/process-compose are enabled. Private Redpanda is separately opt-in on macOS with
Apple Container; Linux can use an external broker. Kafka client libraries are independent.

If you opted into initial Mori generation, `mori.dhall` describes the six packages, actual
component dependency scopes/bounds, and API owner/path. Run `mori validate` and `mori show --json`
locally after `just openapi`. The Mori organization/user namespace is separate from the Haskell
namespace; generation does not register the project. Empty/false skips it; skipping later
preserves an existing descriptor. Maintain opted-in metadata as application code changes.

Customize Nix in unmanaged `flake.module.nix` and process-compose in its override. The seed
owns `nix/keiro-dev-tools.nix`; it adds tools without a generic single-root Nix package build.
Use Cabal in the shell. Review Seihou diffs before reapplying; protect authored files and
context-named workspaces during upgrades. No automatic rename or deletion is provided.

Standards: `mori://shinzui/keiro-runtime-patterns/docs/runtime-patterns-getting-started`.
