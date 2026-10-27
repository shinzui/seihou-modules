# haskell-keiro-project

Generate a six-package Haskell seed, project-named Keiro workspace, shared health routes,
a database-free OpenAPI generator, PostgreSQL/process-compose, and HTTP/fixture test tools.
The companion `haskell-keiro-service` blueprint implements the business domain afterward.

```bash
seihou run haskell-keiro-project
# Optional noninteractive Mori inventory:
seihou run haskell-keiro-project --var project.name=sample-service --var project.namespace=SampleService --var project.description="Sample service" --var mori.generate=true --var mori.namespace=example
```

Prompts collect project name, Haskell namespace, synopsis, author, maintainer, copyright year,
and Hackage index-state. Metadata defaults can be reviewed with `--confirm-defaults`.
`project.name` determines all six package directories and `domain/<name>.keiro-workspace`
with `domain/<name>/shared.keiro`. Optional `keiro.context` changes only the logical DSL
context; no second naming prompt is required. Names use lowercase letters, digits and hyphens.
The shared-only DSL seed is a place to author real members before scaffolding business code.

An optional question offers an initial `mori.dhall`. Empty input or `mori.generate=false`
skips it; true asks for the separate Mori organization/user namespace (`mori.namespace`).
This namespace uses lowercase letters, digits and hyphens and starts with a letter. It does
not change the PascalCase Haskell namespace. Opt-in requires the namespace before writes.
The descriptor inventories six actual packages, component dependency bounds/scopes, and one
OpenAPI API owned by the API package at `docs/openapi.json`. It uses a hash-pinned schema,
invents no remote repository, and never registers the project. Run `mori validate` locally.
Existing authored descriptors are protected; opting out later preserves an existing file.
Maintain the inventory as Cabal components change. No placeholder schema is created.

Enter `nix develop`, then run `just build`, `just test`, `just openapi`, and
`just openapi-check`. The API library owns `ServiceApi` and derives OpenAPI 3.1 from that type;
the server exports `serviceServer` and `mkApp` with liveness then readiness checks. Both probes
use `mori://shinzui/servant-health/packages/servant-health`; the schema uses
`mori://shinzui/openapi-hs/packages/openapi-hs` and
`mori://shinzui/servant-openapi-hs/packages/servant-openapi-hs`.
The threaded health suite exercises real HTTP dispatch and both independent failure cases.
The schema exporter narrowly corrects the released generic Maybe timestamp schema to permit
null and require the fixed wire key; remove that correction when upstream fixes derivation.
OpenAPI generation needs no configuration, database, or running server. Freshness checking
fails on stale or edited JSON; regeneration restores it. After generation, an opted-in Mori
API record points to the real artifact. The seed supplies no production checks or business
server executable; inject bounded process liveness and actual readiness/drain policy later.
There is no bare `/health` endpoint.

The managed `nix/keiro-dev-tools.nix` adds Hurl/Hurlfmt, Dhall, and tool wrappers through
`haskellProject.extraDevPackages`. Wrappers use immutable upstream flake packages:
`mori://shinzui/hinagata` at released `a0c1059743e5957e66e4b8cee9e485ad89471937` and
`mori://shinzui/hurl-workbench` at unpublished `a29d26ad5e90aa762de88be18f06fddf67b6d02f`.
First invocation may download/build them. Workbench's schema import is pinned and hashed at
the same revision: update and verify both selections together. These CLI pins are separate
from application Cabal dependencies. They preserve the base canonical lock and compiler.

```bash
just test-tools
just api-validate
just api-render
just fixture-plan
process-compose -f process-compose.yaml up
# In a second nix develop shell, with a new scratch database:
createdb -- bootstrap_scratch
just fixture-load bootstrap_scratch
just fixture-with
# After implementing and starting the real service:
just api-test http://127.0.0.1:8080
```

`just create-database` is the process-compose entry point; it creates the development database
only. `fixture-load` requires an explicit existing target and grants no deletion rights.
The test-only `hinagata_bootstrap.marker` row is repeatable and reports `ready`; it is never
a production migration or automatically loaded into the development database. `fixture-with`
loads an owned clone, checks the row, and releases it. The helper sets absolute fixture/bundle
roots, private artifact storage and explicit `HINAGATA_*` endpoints/role databases, preserving
caller overrides. It requires PGHOST/PGDATABASE from the shell, defaults PGPORT to 5432 and
PGUSER to the local user, and uses postgres for maintenance/role connection databases. Local
smoke roles can be identical; this is not a production privilege model. Add real migration
up/verify hooks before domain scenarios; hook-free fixtures claim no persistent baseline reuse.
Leased children receive explicit PG fields: map those into service config. Stop consumers
before releasing their clone. Remove only scratch databases you created yourself.

PostgreSQL/process-compose default on; Kafka libraries and a private Redpanda broker remain
independent toggles. `nix.pg-database` overrides the development database. `nix.redpanda`,
`nix.redpanda-console` and `redpanda.*-port` configure the existing Apple Container helper on
macOS; Linux can use an external broker. Render checks do not prove broker startup.

Run `seihou agent run haskell-keiro-service` to implement the domain, following the generated
`docs/bootstrap-keiro.md`. Keep custom Nix in unmanaged `flake.module.nix` and process-compose
changes in its override. The scaffold owns only its managed tools import. The multi-package
seed uses Cabal; no generic single-root Nix package is enabled.

For upgrades from 0.1, inspect the Seihou ledger, domain files, recipes, Cabal and authored
extensions together. Review diffs and rename context-named paths/service identities only as
a deliberate migration, preserving authored members and ledger backups. Never force this
seed over implemented work or delete old workspace members automatically. Update the base
Nix module independently when appropriate.

Structure follows `mori://shinzui/keiro-runtime-patterns/docs/architecture-service-packages`
and `mori://shinzui/keiro-runtime-patterns/docs/keiro-service-workspaces`.
Repository checks: `python3 scripts/check-keiro-bootstrap.py` and
`python3 scripts/test-keiro-bootstrap.py --live`. Live acceptance uses its own PostgreSQL
cluster and a temporary Haskell consumer of the actual generated probe assembly; it proves
seeded HTTP assertions, distinct leases, failure propagation, and cleanup.
