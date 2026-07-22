# Scaffold an event-sourced Haskell service ({{project.name}}) on the Keiro runtime

You are scaffolding a new event-sourced Haskell backend named **{{project.name}}**, with module
namespace **{{project.namespace}}**, in the current empty or nearly-empty Git repository. It uses
the released Keiro runtime, Effectful, PostgreSQL, Servant/Warp, Settei, and OpenTelemetry. The
`nix-haskell-flake` base module already supplied the development shell, formatter, and `.gitignore`.

## Critical rules

- **GHC 9.12.4 / GHC2024, no hpack.** Every package uses `cabal-version: 3.4` and
  `default-language: GHC2024`. Hand-write Cabal files; never create `package.yaml`.
- **Two shared common stanzas.** Every package declares and every buildable stanza imports
  (`import: warnings, shared`) exactly this shape:

  ```cabal
  common warnings
    ghc-options: -Wall -Wcompat -Widentities -Wincomplete-record-updates
                 -Wincomplete-uni-patterns -Wpartial-fields -Wredundant-constraints

  common shared
    default-language: GHC2024
    default-extensions: BlockArguments DataKinds DeriveAnyClass DuplicateRecordFields
      LambdaCase MultilineStrings OverloadedLabels OverloadedRecordDot OverloadedStrings
      QualifiedDo TemplateHaskell TypeApplications TypeFamilies TypeOperators
  ```

- **Custom prelude.** Every module imports `{{project.namespace}}.Prelude`. The prelude is a thin
  re-export over `base`, uses `{-# LANGUAGE PackageImports #-}` only there, and re-exports
  `Control.Lens`. Do not re-export `Data.Generics.Labels ()`; modules using `#field` import it
  locally from `generic-lens`.
- **Records and deriving.** Make every `data` record field strict, but never put `!` on a
  `newtype` field. Use explicit deriving strategies and generic-lens field access. Never use record
  update syntax. Put the aggregate id first in every event and command record.
- **Imports and Cabal style.** Use postpositive qualified imports, never qualify operators, and
  write `build-depends` in leading-comma style.
- **Released Hackage cohort.** Keep the reference `index-state: 2026-07-22T18:04:31Z` or move it
  later only after re-verifying every bound as one coherent cohort. The runtime resolves from
  Hackage: do not add runtime `source-repository-package` stanzas, `file://` sources, or corpus
  paths.
- **Settei configuration.** Declare configuration with Settei and resolve general files, mounted
  Secret directories, then explicit environment bindings. Use `RejectUnknownKeys`; expose
  `--describe-config`, `--explain-config`, and `--check-config`; preserve exit codes 2/3/4. This is
  the fleet target even though older services predate it. Read `config/settei-service-standard.md`
  (`config-settei-service-standard`) and `config/kubernetes-deployment.md`
  (`config-kubernetes-deployment`) in `shinzui/keiro-runtime-patterns`.
- **Validated event streams and two schemas.** Generated `Generated.EventStream` modules construct
  `ValidatedEventStream` values with `mkEventStreamOrThrow`; any Keiki replay warning rejects
  startup. `mkEventStreamUnchecked` is forbidden. Application SQL explicitly schema-qualifies
  framework tables under `keiro`; the event-store connection search path remains `kiroku`.
- **Real observability.** Both server and worker mains acquire OpenTelemetry SDK resources, use W3C
  trace-context propagation, flush and shut providers down, create Keiro metrics with
  `newKeiroMetrics`, and thread them into runtime options using `& #metrics .~ metrics`. Implement
  structured request logging and the fleet liveness/readiness contract. `logStdoutDev` and
  `runTracingNoop` are forbidden. Read `api/opentelemetry-integration.md`
  (`api-opentelemetry-integration`), `api/request-logging.md` (`api-request-logging`), and
  `api/health-endpoints.md` (`api-health-endpoints`) in `shinzui/haskell-jitsurei`.
- **Keiro DSL first.** Author and check the `.keiro` spec before domain Haskell. Generated modules
  are disposable; hand-owned `Holes` modules are not.
- **Generated artifacts have freshness gates.** Regenerate lifecycle diagrams from transducers and
  fail tests when committed output is stale. Never hand-edit generated blocks.
- **Never commit.** Create and validate files, but do not run `git add`, `git commit`, or `git push`.
  A human reviews and commits with a Conventional Commit message.

## Current standards via Mori

Before deviating from this prompt, discover the current standards and read every relevant entry in
`files/standards-map.md`:

```bash
mori registry docs shinzui/keiro-runtime-patterns
mori registry docs shinzui/haskell-jitsurei
```

The checked-in map couples this blueprint to normative docs without copying their full prose.

## Reference files

The blueprint's `files/` directory is read-only. Adapt each reference to the project; do not copy
placeholder names blindly:

- `cabal.project` and `core.cabal` — released bounds, packages, common stanzas, and vertical layout.
- `Prelude.hs`, `AppConfig.hs`, and `Settings.hs` — prelude, runtime dependencies, and Settei inputs.
- `Migrations.hs` and `manifest` — embedded application component, plan, CLI, and strict manifest.
- `Telemetry.hs` — production tracer/meter acquisition and Keiro metrics.
- `Api.hs` — Servant NamedRoutes, DTOs, and probe routes.
- `Diagrams.hs`, `domain.keiro`, and `fourmolu.yaml` — generated workflow and formatting.
- `standards-map.md` — normative paths, DocRef keys, and reasons to read them.

## How to proceed

### 1. Author and validate the domain first

Install the verified released tool once, create `domain/{{keiro.context}}.keiro` from the reference,
and keep its `layout collocated` clause. Define aggregate ids and prefixes, commands, events,
projections, and operations. Explicitly annotate enum-typed payloads such as `kind:MyEnum`.

```bash
cabal install keiro-dsl-0.3.0.0 --overwrite-policy=always
keiro-dsl check domain/{{keiro.context}}.keiro
```

Fix all diagnostics before writing domain Haskell. Add `just keiro-check`, `just keiro-scaffold`,
and `just keiro-diff` recipes so checking, regenerating, and reviewing drift remain one command.

### 2. Lay down the six-package vertical structure

Create flat-root packages with hand-written Cabal files. Read models live in `-core`; there is no
separate persistence package.

- `{{project.name}}-core` owns the custom prelude, `App.Config`, `Postgres.{Pool,Runner}`, and each
  concept's `Generated.{Domain,Codec,EventStream,Projection,Harness}`, `Holes`, and `ReadModel`.
- `{{project.name}}-api` owns concept `Api` modules and the API umbrella.
- `{{project.name}}-migrations` owns SQL under
  `{{project.name}}-migrations/migrations/application/` as `NNNN-slug.sql`, an exhaustive strict
  `manifest`, and `{{project.namespace}}.Migrations`. The module exports the
  `"{{project.name}}"` `MigrationComponent`, dependent on `"keiro"`, using
  `embedMigrationManifest` with the RecompilePlugin pragma. Compose Kiroku, Keiro, optional PGMQ,
  then application migrations into one plan. Add a `{{project.name}}-migrate` executable using
  `pg-migrate-cli`; bare invocation is a usage error. Its public `test-support` sublibrary wraps
  `pg-migrate-test-support`'s `withMigratedDatabase`. Remember that the helper's error wraps the
  callback result, so a callback returning `Either` produces nested `Either`; unwrap both and fail
  loudly.
- `{{project.name}}-workers` owns concept worker adapters, `Workers.{Subscription,Registry}`, and
  the `{{project.name}}-worker` executable.
- `{{project.name}}-server` owns concept handlers, `Server.{Config,App,Seam,Boot}`, and the
  `{{project.name}}-server` executable.
- `{{project.name}}-client` is generated from the API package.

Keep concept code together across packages. Only shared infrastructure retains technical-layer
names. Build every package around the same strict `AppConfig` dependency contract.

### 3. Scaffold generated modules idempotently

Run the released scaffolder directly into core, then format:

```bash
keiro-dsl scaffold domain/{{keiro.context}}.keiro --out {{project.name}}-core/src
nix fmt
```

The collocated layout emits a disposable `.Generated` leaf and creates `Holes` only when absent.
Gitignore the informational `keiro-dsl-manifest.<context>.txt`. Never edit a module marked
`-- @generated`; change the spec and re-scaffold. Fill each `Holes` module with the Keiki
command-to-event transducer and read-model apply fold. Gate writes on a per-stream `streamVersion`
watermark so redelivery remains ordered and idempotent.

### 4. Wire migrations, validated streams, configuration, telemetry, and HTTP

Embed the strict application manifest and expose one complete migration plan and CLI. Add Hasql
read models and Shibuya adapters. Construct every generated stream with `mkEventStreamOrThrow` at
startup; pass only validated values into `runCommand` and worker registrations. Explicitly qualify
all Keiro framework SQL and keep the Kiroku event-store connection schema separate.

Declare typed settings in `{{project.namespace}}.Settings`, then resolve files, mounted Secrets,
and environment sources before constructing `AppConfig`. Wire diagnostic modes before opening a
listener, pool consumer, or worker; `--check-config` must exercise the real resolution path and
exit. Do not log the resolved record or secret values.

Acquire the OpenTelemetry tracer and meter providers in `Server.Boot` and the worker main using a
bracket that force-flushes and shuts both down. Create Keiro metrics from the meter and thread them
into command and worker run options. Install W3C context propagation around message publication and
consumption. Add structured request logging and these probe semantics:

- liveness reports only process/event-loop viability;
- readiness reports whether the process may receive traffic and becomes false during drain;
- transient downstream failure never triggers a liveness restart loop.

Use NamedRoutes and RFC 7807 problem responses. Validate every closed-enum wire value in its handler
and return a 400 problem for unknown values.

### 5. Generate and gate lifecycle diagrams

Render each hand-owned transducer with `Keiki.Render.Mermaid.toMermaid` into
`docs/diagrams/domain-lifecycles.md`. Put each `stateDiagram-v2` block inside a matched marker pair.
Add a `{{project.namespace}}.Diagrams` module, a `{{project.name}}-diagrams` executable with
`--write` and `--check`, and a test that checks freshness and calls
`Keiki.Render.Validate.validateMermaidDiagram`. Add `just diagrams` and `just diagrams-check`.

### 6. Build and test the complete service

Create and run the full fleet test layout:

- core `test-domain` runs every generated `harnessAssertions`;
- core `test-diagrams` guards committed Mermaid output;
- core `test-postgres` uses the public migrated-database support;
- migrations tests apply, verify ledger/schema rows, and reapply with zero work;
- server tests run a handler against an ephemeral migrated database;
- workers use per-concept `*Spec` modules mirroring `src`.

Then run:

```bash
cabal run {{project.name}}-migrate -- plan
cabal build all
cabal test all
nix fmt
git diff --check
```

The database-free `plan` command must print the complete ordered plan. Report compiler or test
errors verbatim; do not add unverified compatibility workarounds.

### 7. Hand off

Summarize the package tree, selected Hackage index-state, migration component order, successful DSL
check and idempotent re-scaffold, configuration diagnostics, telemetry/probe wiring, diagram
freshness, and build/test results. Call out anything unresolved. Do not commit.
