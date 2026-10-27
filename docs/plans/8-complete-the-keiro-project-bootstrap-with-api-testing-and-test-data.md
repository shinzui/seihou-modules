---
id: 8
slug: complete-the-keiro-project-bootstrap-with-api-testing-and-test-data
title: "Complete the Keiro project bootstrap with API testing and test data"
kind: exec-plan
created_at: 2026-10-27T02:08:21Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-10-27T02:08:21Z
  revisions:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-27T02:15:45Z
      mode: "other"
      note: "Ground initial plan in the existing Keiro scaffold, project-name paths, and real Workbench/Hinagata integration"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-27T02:23:35Z
      mode: "update"
      note: "Add servant-health probes and OpenAPI generation with released openapi-hs and servant-openapi-hs dependencies"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-27T02:35:58Z
      mode: "update"
      note: "Add optional prompted Mori descriptor with package/dependency inventory and generated OpenAPI reference"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-27T02:45:30Z
      mode: "implement"
      note: "Implement and validate the six-package bootstrap, health/schema plumbing, test tooling, and optional Mori inventory"
---

# Complete the Keiro project bootstrap with API testing and test data

This is a living ExecPlan. Maintain Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective during implementation. Follow `agents/skills/exec-plan/FRICTION.md` for material friction and `agents/skills/exec-plan/ADR.md` for durable decisions.


## Purpose / Big Picture


Complete the existing `haskell-keiro-project` Seihou module so that a project name produces a six-package Haskell workspace, project-named Keiro domain files, process-compose and PostgreSQL, configurable Redpanda, server probes using `servant-health`, OpenAPI schema generation using `openapi-hs` and `servant-openapi-hs`, Hurl Workbench API tests, and Hinagata test-data loading. Offer a prompt to generate an initial `mori.dhall` describing the project, its packages/dependencies, and its OpenAPI artifact. OpenAPI is a machine-readable description of HTTP routes and their request/response schemas; `mori.dhall` is Mori's typed project descriptor. Seihou generates files and tracks ownership; process-compose starts local development processes; Hurl Workbench composes HTTP tests; Hinagata loads SQL fixtures and provides isolated PostgreSQL test databases.

For `project.name=sample-service`, generate `cabal.project`, `domain/sample-service.keiro-workspace`, `domain/sample-service/shared.keiro`, and the six root directories `sample-service-{api,workers,core,client,migrations,server}`. Entering `nix develop` supplies the test tools. `just openapi` generates `docs/openapi.json` directly from the typed API without a database or running server. The server library mounts `/health/live` and `/health/ready` with injectable checks, and its tests prove their independent behavior. A developer can start PostgreSQL, compile and load a supplied test fixture, and validate/render the HTTP suite. Once the application is running, `just api-test` runs that suite against its configured URL. Repository acceptance must prove actual fixture data reaches HTTP assertions against real PostgreSQL.

This is a bootstrap feature. A name and synopsis do not define business aggregates, routes, workers, or migrations. Preserve the established separation between deterministic scaffolding and the companion `haskell-keiro-service` blueprint, which implements application behavior after its domain is specified.


## Progress


- [x] Milestone 1 (2026-10-26): Structural checker passes project naming with and without logical context overrides, sibling boundaries, database and broker render controls, canonical lock preservation, repeatability, and edit protection.
- [x] Milestone 2 (2026-10-26): All four servant-health conformance cases and all three OpenAPI schema checks pass on Darwin/aarch64 with released Servant 0.20.3.0, servant-health 0.1.0.0, openapi-hs 5.0.0, and servant-openapi-hs 5.1.0. The six libraries and schema executable build; live acceptance repeats this against generated files and detects edited schema output before regeneration restores freshness.
- [x] Milestone 3 (2026-10-26): Fresh generated wrappers execute Workbench a29d26a and Hinagata a0c1059, doctor finds supported Hurl/Hurlfmt 8.0.1, Workbench validate/render and Hinagata config/plan pass, and the early private PostgreSQL check observes ready after direct and leased fixture loads. No developer checkout paths or base lock changes are needed.
- [x] Milestone 4 (2026-10-26): python3 scripts/test-keiro-bootstrap.py --live passes on Darwin/arm64. Its private PostgreSQL cluster proves repeatable explicit-target loads, untouched sentinel data, two distinct ready HTTP leases, a real failing Hurl assertion with identical child/outer exit status, service shutdown before failed-lease release, released allocation inspection, absent clone databases, and cluster finalization.
- [x] Milestone 5 (2026-10-26): Real pseudo-terminal module and blueprint runs honor true/false/empty answers with one question and conditional namespace prompting. Dhall/Mori validation, six-package Cabal parity, independent namespace changes, missing/invalid identity, reapplication, authored-file protection, and opt-out preservation pass. Generated OpenAPI exists at the declared path; the opted-out other project also runs just openapi successfully.
- [x] Milestone 6 (2026-10-26): Module/blueprint validation, structural checks, full live acceptance, registry synchronization/validation, Mori evaluation, generated OKF catalog, strict friction validation, and git diff --check pass. ADRs 2/3 record naming, testing, schema, and managed-tool ownership. A separate actual Apple Container broker/Console lifecycle check also passes and cleans its private resources.


## Surprises & Discoveries

2026-10-26: Seihou implements only the exact validation pattern `[a-z][a-z0-9-]*`; other patterns silently accept all input. FRIC-5 in docs/friction-log/ records the finding. Both descriptors now use that supported pattern for project name, context, and Mori namespace, and tests require path-like inputs to fail before file writes. The base Nix module was already 0.35.0 while its registry/Mori/catalog entries still named 0.34.0; final sync aligns those metadata entries without changing shared Nix code.


2026-10-26: Released openapi-hs 5.0.0 strips nullability from generic Maybe record fields. The generated ProbeStatus schema referenced a non-null UTCTime and omitted failingSince from required, although the library wire codec always emits the key. FRIC-4 in docs/friction-log/ records the mismatch. The exporter corrects that derived property with an anyOf null branch and requires the fixed key; library handlers/types remain authoritative.


## Decision Log


2026-10-26: Extend `haskell-keiro-project` rather than add a competing module. It already owns the requested package layout and composes `nix-haskell-flake`; completed plan 3 and ADR 2 establish that boundary.

2026-10-26: New workspace filenames, member directories, and manifest service identity use `project.name`. Keep `keiro.context` as an optional logical DSL context override, falling back to project name in templates. A second answer must not change the requested filesystem naming. Do not automatically rename implemented workspaces.

2026-10-26: Reuse the base module's Redpanda enable, console, and port controls. Private Redpanda remains opt-in and macOS-only under the current helper; Linux may use an external broker. A portable broker implementation is outside this bootstrap change. Kafka client libraries remain an independent toggle.

2026-10-26: Supply tool wrappers through a scaffold-owned managed Nix module imported with `nix.package-module`. Wrappers invoke upstream flake packages at immutable commits. Preserve the base module's canonical lock and the unmanaged `flake.module.nix` extension point, without adding testing-tool dependencies to application Cabal packages.

2026-10-26: Generate a small, explicitly test-only SQL marker fixture and an external-service health suite. Keep the database-backed HTTP consumer used to prove integration inside the repository test harness. This establishes working setup without inventing a business domain or shipping a pretend Keiro server.

2026-10-26: Incorporate the user's additional requirements as real shared HTTP plumbing in the seed: `servant-health` provides the server probe contract/handlers, while `openapi-hs` and `servant-openapi-hs` derive OpenAPI 3.1 from the same API type. API owns the contract and schema generator; server owns application assembly and injected checks. Replace the placeholder bare `/health` test with `/health/live` and `/health/ready`. Business behavior and actual dependency/drain policies remain the blueprint's implementation responsibility.

2026-10-26: Coordinate the blueprint and baseline question with an internal mori.prompt Boolean (true in the module, false forwarded by the blueprint). Seihou forwards resolved values but an empty optional answer is absent, so gating the baseline prompt prevents a second question after Skip. Both public inputs retain their original semantics.

2026-10-26: Correct the released generic-schema nullability mismatch at the schema-export boundary, preserving the bounded released cohort and the library-derived schema. This correction is covered by the generated schema test and should be removed after an upstream release fixes the record derivation. Base is a compiler boot dependency without a registered Mori owner; retain its Hackage name/bounds rather than invent a registered project.

2026-10-26: Add an optional prompt for initial Mori descriptor generation, skipped by default, with an independently supplied Mori organization/user namespace. The descriptor inventories the actual generated packages/dependencies and declares their existing OpenAPI artifact; it neither copies the OpenAPI document into Dhall nor makes OpenAPI generation optional. Generation is local and does not register the project or overwrite an authored descriptor.


## Outcomes & Retrospective


Implementation delivers the six-package seed, project-name domain layout, injected library-owned probes, corrected derived OpenAPI 3.1 output and freshness checks, pinned testing tools, real fixture/HTTP acceptance, and optional local Mori inventory. Documentation, generated catalog, and ADRs 2/3 describe the tested ownership and handoff boundaries. Module 0.2.0 and blueprint 0.4.0 are synchronized; the pre-existing base-module metadata drift is aligned to its actual 0.35.0 source without changing its lock or templates.

FRIC-4 in docs/friction-log/ is accepted with a narrow schema-export correction and regression coverage until upstream corrects generic Maybe derivation. FRIC-5 in docs/friction-log/ is accepted with supported Seihou name validation and rejection tests rather than assuming regex enforcement. Both entries were triaged through the bundled script.

Final acceptance reports: `PASS real PostgreSQL fixture, distinct leases, generated probes, Hurl marker assertions, failure propagation, service shutdown and clone cleanup`. Logs remain with the temporary fixture printed by the harness; its private cluster is stopped. Structural checks additionally pass all module/blueprint interactive choices, inventory parity, explicit namespace changes and authored-file protection. Private broker and Console startup/readiness/down/purge were separately exercised with unique names and ports.

The native platform exercised is Darwin/arm64. Shared Nix implementation paths were unchanged, so unrelated retained-runtime regression suites were not repeated. Domain application behavior still belongs to the companion blueprint; the acceptance consumer remains temporary test code. Tool acquisition can build dependencies on first use, and the unpublished Workbench pin/schema must continue to move together.


## Context and Orientation


Work from this repository's root, `seihou-modules`. `seihou-registry.dhall` publishes modules and blueprints; `mori.dhall` separately describes them for Mori discovery. The root `README.md` documents validation and generated catalog upkeep. No local `AGENTS.md` file was found during creation; follow the user-supplied global instructions, including Mori dependency lookup, canonical cross-repository references, Conventional Commits, and the current branch.

`modules/haskell/haskell-keiro-project/module.dhall` is version 0.1.0. Its templates under `modules/haskell/haskell-keiro-project/files/` generate six minimal Cabal libraries; `api.hs.tpl` and `server.hs.tpl` currently export empty package-boundary modules. Its dependency bindings enable PostgreSQL/process-compose and disable the generic root-package Nix build. `workspace.tpl`, `shared.keiro.tpl`, `justfile.tpl`, `README.md.tpl`, and `bootstrap.md.tpl` currently use `keiro.context` for domain paths. `cabal.project.tpl` lists six application packages and an optional generated conformance package, which runs DSL behavioral tests outside the six application-package budget.

`scripts/check-keiro-bootstrap.py` uses real Seihou rendering in temporary directories. It checks package metadata, Nix composition, database creation through mocks, blueprint prompt rendering, repeat generation, and edit protection. It supplies contexts different from project names and does not exercise live fixture or HTTP behavior. [Plan 3](3-bootstrap-keiro-services-with-a-reusable-haskell-module.md) records the earlier completed bootstrap; preserve its useful package boundaries.

`modules/haskell/nix-haskell-flake/module.dhall` is currently version 0.34.0. `modules/haskell/nix-haskell-flake/files/process-compose.yaml.tpl` starts socket-only PostgreSQL and invokes `just create-database` after readiness. `modules/haskell/nix-haskell-flake/files/nix/haskell.nix.tpl` provides the PG environment and `haskellProject.extraDevPackages`. The base exposes `nix.package-module`, `nix.pg-database`, `nix.pg-package`, `nix.kafka`, `nix.redpanda`, `nix.redpanda-console`, and `redpanda.*-port`. Its `files/nix/redpanda.nix.tpl` adds Apple Container lifecycle commands on Darwin, not a process-compose Redpanda process. Other systems receive no private-broker lifecycle commands.

Relevant local records are [ADR 2](../adr/2-separate-keiro-project-seeds-from-domain-implementation.md), [ADR 3](../adr/3-separate-managed-scaffold-nix-wiring-from-user-extensions.md), and [ADR 5](../adr/5-share-one-checked-runtime-scope-and-verify-managed-adoption.md). ADR 2 reserves business behavior for the blueprint. ADR 3 gives composed scaffolds a managed Nix import while leaving `flake.module.nix` unmanaged. ADR 5 preserves the bare toolchain default and requires explicit retained-runtime selection; adding test CLIs must not change application compiler/runtime identity. The ADR directory follows ordinary Markdown conventions and has no profiled bundle declared in `mori.dhall`; preserve that convention.

The requested “seihou-runtime-patterns” did not match Mori's registry. The current module, blueprint, and ADR 2 identify `mori://shinzui/keiro-runtime-patterns` as their normative source, so use that project. Both `mori://shinzui/keiro-runtime-patterns/docs/architecture-service-packages` and `mori://shinzui/keiro-runtime-patterns/docs/keiro-service-workspaces` resolved during creation. The package standard requires core without sibling dependencies, API depending on core, server on core/API, workers on core, client on API, and migrations independent of siblings. The workspace standard requires one authoritative manifest with explicit namespace, layout, runtime package, and manifest-relative member paths.

The relevant dependency identities are `mori://shinzui/servant-health/packages/servant-health`, `mori://shinzui/servant-health/packages/servant-health:testkit`, `mori://shinzui/openapi-hs/packages/openapi-hs`, and `mori://shinzui/servant-openapi-hs/packages/servant-openapi-hs`. Within the health project read `README.md`, `src/Servant/Health.hs`, `src/Servant/Health/Check.hs`, and `src/Servant/Health/Paths.hs`; within the OpenAPI projects read `README.md`, `src/Data/OpenApi.hs`, and `src/Servant/OpenApi.hs` respectively (artifact-level source URIs pending). `HealthApi` mounts under `health`, `healthServer` takes liveness then readiness `ProbeCheck` actions, and the probe body has exactly `status`, `check`, and `failingSince`. Healthy is HTTP 200; unhealthy is HTTP 503. The library deliberately provides no bare `/health` route and no service-specific dependency checks. `Servant.OpenApi.toOpenApi` derives a `Data.OpenApi.OpenApi` document from the Servant API, including the health routes' MultiVerb alternatives, which describe multiple status responses in one endpoint type.

Additional release verification on 2026-10-26 found Hackage releases `servant-health` 0.1.0.0, `openapi-hs` 5.0.0, and `servant-openapi-hs` 5.1.0. Upstream tags peel to `c70bffdd59e9336700dde304dac1328d3cb62f6a` (`v0.1.0.0`), `06fc11713094bf39ac00353b052f4ded5a534567` (`5.0.0`), and `181ca609688af3cad994a73988492605c71bc2d0` (`v5.1.0`) respectively. Published Cabal metadata supports `servant-health >=0.1.0.0 && <0.2`, `openapi-hs >=5.0 && <5.1`, and `servant-openapi-hs >=5.1 && <5.2`; use a compatible Servant 0.20 release with MultiVerb support, verified against its published metadata. Reverify before implementing and move the seed's default Hackage index-state forward if necessary so it includes the selected releases. These are ordinary bounded Hackage application dependencies, not unpublished tooling exceptions. Do not substitute the similarly named upstream openapi3 packages, whose modules overlap these forks.

Discover `mori://shinzui/hurl-workbench` using registry show/docs. Within that project, read `README.md`, `docs/reference/cli.md`, `schema/package.dhall`, and `examples/integration-service/hurl-workbench.dhall` (artifact-level URIs pending). Its Dhall manifest names ordinary `.hurl` request fragments, workflows, read-only recipes, and suites. Actual commands include `hurl-workbench --workspace FILE validate`, `render workflow NAME`, and `test suite NAME`. Hurl and Hurlfmt are separate executables from Nix's `hurl` package. Hurl's literal `{{base_url}}` expressions must survive Seihou generation.

Hinagata documentation resolves as `mori://shinzui/hinagata/docs/user-documentation` and `mori://shinzui/hinagata/docs/guides`; the real Keiro example is `mori://shinzui/hinagata/packages/hinagata-keiro-example`. Within `mori://shinzui/hinagata`, inspect `examples/keiro-service/{hinagata.yaml,hurl-workbench.dhall,README.md}` and `scripts/example-workbench.sh` (artifact-level URIs pending). Hinagata uses caller-started PostgreSQL. Direct `fixture load` selects an existing target database explicitly. `db with` leases a clone, loads fixtures, and passes application PG connection variables to a child command. A baseline is a prepared database; a lease is one owned clone released after consumers stop. Hurl Workbench can own service startup/readiness/shutdown inside that lease.

Release lookup on 2026-10-26 found Hackage `hinagata-cli` 0.1.0.0 and upstream tag `v0.1.0.0`, peeled commit `a0c1059743e5957e66e4b8cee9e485ad89471937`. Workbench's Hackage package JSON returned HTTP 404 and its upstream release page listed no releases. Hinagata's checked example uses Workbench commit `a29d26ad5e90aa762de88be18f06fddf67b6d02f`. This is a candidate tooling pin, not a published package version. Reverify registries/tags and test selected source before finalizing pins; local corpus APIs can differ from published source. Keep unpublished CLI source pins separate from application runtime dependencies.

For Mori descriptor authoring, discover `mori://shinzui/mori-schema/packages/mori-schema` and `mori://shinzui/mori/docs/schema-spec`. Within the schema project, `Project.dhall` and `records/{ProjectIdentity,Package,Dependency,MoriRef,Api}.dhall` define the required shape (artifact-level source URIs pending). `Project.packages` holds package-local paths and dependency lists; `Dependency.WithAugmentation` carries source, scope, and versionConstraint; `Project.dependencyRefs` holds typed external artifact references. `Project.apis` holds `Schema.Api` values with `name`, `type`, `specPath`, `owner`, and optional typed `ownerRef`. Use OpenAPI type, `specPath = "docs/openapi.json"`, and the API package as owner. Within `mori://shinzui/rei`, the `mori.dhall` API declaration is a working structural example (artifact-level URI pending), not a source of this project's dependency list.

The repository already pins Mori schema commit `3522f4a51181d73c9c90fc27a7c0838bd29ae95f` with integrity hash `sha256:dcb19e2312e790bad14e622cc98a1281cd2298c5b564a2f0d0534d3c718d8803`. Its package/API/dependency records were checked directly and the upstream package URL was accessible during this revision. Upstream release discovery returned no latest release or versioned tags, so this existing verified immutable pin is the initial candidate; do not guess a schema version from the local checkout. Verify compatibility with the implementation-time Mori CLI before retaining or changing it. `mori validate`, `mori show --json`, and Dhall evaluation are local validation interfaces; `mori register` is a separate state-changing operation and is not part of scaffolding. Seihou's optional prompts skip resolved defaults, so an explicit Boolean default can accidentally suppress the requested interactive question. Inspect its actual prompt/variable behavior when adding the option.


## Plan of Work


### Milestone 1: Project identity and local services


Change `modules/haskell/haskell-keiro-project/module.dhall` destinations to `domain/{{project.name}}.keiro-workspace` and `domain/{{project.name}}/shared.keiro`. In `workspace.tpl`, emit `service {{project.name}}`, `module {{project.namespace}}`, `layout collocated`, `runtime-package {{project.name}}-core`, and `spec {{project.name}}/shared.keiro`. Make `keiro.context` optional and remove its required prompt. In `shared.keiro.tpl`, use an `IsSet` conditional to select that override or `project.name`; do not assume variable defaults themselves interpolate templates.

Update all path-bearing recipes and briefs to use project name, including the generated conformance package name keyed by manifest service. Mirror the optional context declaration and removal of its required prompt in `blueprints/haskell-keiro-service/blueprint.dhall`; update context references in its descriptions and later remove it from Mori's required-variable lists. Preserve the six root package directories, sibling dependencies, PostgreSQL/process-compose bindings, and independent base Redpanda/Kafka variables. No automatic existing-workspace rename is part of this milestone.

Extend `scripts/check-keiro-bootstrap.py` for missing context, explicit differing context, Redpanda disabled/enabled, custom ports and console, and a PostgreSQL database-name override. Check rendered content without starting a broker. Its PASS output must establish the requested paths, existing `just create-database` process-compose entry point, repeatability, and edit protection.

### Milestone 2: Health probes and OpenAPI generation


Extend `modules/haskell/haskell-keiro-project/files/api.hs.tpl` to export a minimal `ServiceApi mode` route record whose health field mounts `"health" :> NamedRoutes HealthApi`, deriving Generic. Import/re-export the library's probe contract rather than copying its types or response mapping. Add `files/openapi.hs.tpl`, generating `{{project.name}}-api/src/{{project.namespace}}/Api/OpenApi.hs`, with a public OpenApi value derived using `toOpenApi (Proxy @(NamedRoutes ServiceApi))`, plus project title/version metadata. Add `files/openapi-main.hs.tpl` at `{{project.name}}-api/app/OpenApiMain.hs` and an executable named `{{project.name}}-openapi` in `files/api.cabal.tpl`; it writes only schema JSON to stdout. API's direct dependencies include servant, servant-health, openapi-hs, servant-openapi-hs, and the serialization/metadata libraries actually imported. API must not depend on the sibling server or Warp. The health library itself has a transitive servant-server dependency; that does not reverse the application package graph.

Replace `files/server.hs.tpl`'s empty boundary with an exported `serviceServer :: ProbeCheck -> ProbeCheck -> ServiceApi (AsServerT Handler)` and a library application builder `mkApp :: ProbeCheck -> ProbeCheck -> IO Application`. The first calls `healthServer liveCheck readyCheck` in that order; the second serves that shared route record. The integration harness can compose the same record with its test-only marker route, rather than reimplementing the health handlers. Add required direct servant-health, servant-server, and wai dependencies to `files/server.cabal.tpl`. The builder does not invent database acquisition, process startup, or a production readiness verdict. Production liveness stays in-process; readiness may check PostgreSQL and must become false during drain. The blueprint supplies those policies/resources when implementing the real service. Wrap actual checks with the dependency's exception/timeout helpers as appropriate instead of hand-writing probe response behavior.

Generate `{{project.name}}-server/test/HealthSpec.hs` from a new `files/health-spec.hs.tpl`, using `Servant.Health.TestKit.probeContractTests` with the generated builder. Give the server a `{{project.name}}-server-health` test suite and keep servant-health:testkit/Tasty/Warp dependencies in the test component. Enable the threaded runtime. The suite must distinguish the two injected checks: readiness failure leaves liveness 200, liveness failure leaves readiness 200, and the failed probe returns 503 with the standard JSON body.

Add `just openapi` to build the generator, locate it with `cabal list-bin`, and atomically write `docs/openapi.json`; avoid redirecting Cabal build chatter into JSON. Add `just openapi-check` to regenerate into a temporary file and fail on drift without rewriting the tracked document. Initial generation need not run during Seihou application; document running it after the first build. Generate `{{project.name}}-api/test/OpenApiSpec.hs` from `files/openapi-spec.hs.tpl` and add the `{{project.name}}-api-openapi` test suite to `files/api.cabal.tpl`. Its tests round-trip the schema JSON through openapi-hs, require OpenAPI 3.1, project metadata, both probe paths with documented 200 and 503 responses, and the probe body's three fields including nullable failingSince. Running the actual executable twice must produce the same document. Add new generation steps/exposed modules and update the verified dependency bounds/index-state consistently. This milestone passes with all six packages building, both new suites executing, and schema generation working without PostgreSQL or a listener.

### Milestone 3: Reproducible tools and usable test assets


Add `modules/haskell/haskell-keiro-project/files/nix/keiro-dev-tools.nix.tpl`, generating `nix/keiro-dev-tools.nix`. Bind `nix.package-module` to that path while keeping `nix.builtin-package=false`. The managed flake-parts module adds `pkgs.hurl`, `pkgs.dhall`, and wrappers named `hurl-workbench` and `hinagata` through `haskellProject.extraDevPackages`. Each wrapper forwards its arguments to `nix shell` for the upstream flake's `#default` package at a full verified commit. The shell already depends on Nix; first invocation may download/build the tool. Select released Hinagata source and, if still unpublished, a tested immutable Workbench commit. Pin the Workbench schema import to the same commit with its Dhall integrity hash. Document updating those pins together. Do not modify the base flake/lock or generate `flake.module.nix`.

Generate root `hurl-workbench.dhall` from `files/hurl-workbench.dhall.tpl`, root `hinagata.yaml` from `files/hinagata.yaml.tpl`, `tests/api/health.hurl` from a copy step, `tests/fixtures/bootstrap/fixture.sql` from `files/fixtures/bootstrap/fixture.sql`, and `scripts/keiro-test-env` from `files/scripts/keiro-test-env`. These source paths are relative to `modules/haskell/haskell-keiro-project/`. Copy literal Hurl files so their placeholders are not interpreted by Seihou. The Workbench manifest has a `base_url` parameter defaulting to `http://127.0.0.1:8080`, a `health` workflow/read-only recipe, and an external-service `smoke` suite with no managed service. The health fragment calls both `GET {{base_url}}/health/live` and `GET {{base_url}}/health/ready`, asserting HTTP 200, JSON media type, status `ok`, check `all`, and null failingSince for each. The managed acceptance service must use `/health/ready` for readiness, never the unsupported bare `/health` path.

The marker fixture creates the explicitly test-only schema `hinagata_bootstrap`, table `marker` with integer primary key and text `value`, and deterministic row `(1, 'ready')`. Use conditional DDL and an explicit conflict policy so repeated loads retain one row. Document this as a plumbing check to replace/extend with application fixtures; never put it in production migrations or load it automatically into the development database.

The YAML sets `project.id` from project name. The helper derives absolute fixture/bundle paths from the project root, creates private `.artifacts/hinagata` storage, and supplies documented `HINAGATA_*` settings from explicit dev-shell PG fields. The base exports `PGHOST` and `PGDATABASE` but not `PGUSER` or `PGPORT`: require the host/database, default the role to `id -un` and the port to 5432 when absent, and make these resolved fields explicit for children. Set endpoint host/port and maintenance, administration, setup, and application database/user pairs separately, preserving deliberate caller overrides. Default maintenance and role connection databases to the existing `postgres` database; `fixture-load` selects its separate target through the CLI. Local smoke checks may use the same local role; do not present that as the application's production privilege scheme. Do not fabricate migration hooks or reuse revisions. Hook-free marker clones are sufficient initially; absent revisions disable persistent baseline reuse. The blueprint must later wire real migration `up`/`verify` hooks before domain scenarios.

Add `test-tools`, `api-validate`, `api-render`, `api-test base_url="http://127.0.0.1:8080"`, `fixture-plan name="bootstrap"`, `fixture-load target name="bootstrap"`, and `fixture-with name="bootstrap"` to `justfile.tpl`. `test-tools` runs both versions and Workbench doctor. `fixture-load` requires a target positional argument and forwards it to `--target-database`. `fixture-with` uses `db with` to run a `psql` marker assertion and releases its clone. Invoke the environment helper with `bash scripts/keiro-test-env` so executable-bit propagation is unnecessary. Preserve existing ignore entries and add private artifacts once.

Prove one consumer path before expanding variants: render a fresh project, enter its shell, run actual Workbench validation/rendering and Hinagata configuration/fixture planning, then load the marker into a new disposable PostgreSQL database and query `ready`. This early check validates the selected tool revisions, schema, generated configuration, and local server interaction. Fix it before broadening acceptance.

### Milestone 4: Database-to-HTTP acceptance


Add `scripts/test-keiro-bootstrap.py` with a `--live` option. Reuse or factor rendering helpers from `scripts/check-keiro-bootstrap.py`, preserving that checker's normal no-live-services mode. The live harness generates a temporary project and starts its own socket-only PostgreSQL cluster, with dynamic paths/ports, explicit environment, timeouts, and finalizers. Never use an existing developer cluster.

Create a test-only Haskell HTTP consumer inside the harness's temporary project, outside the six application packages. It consumes the generated ServiceApi/server probe wiring, reads the connection supplied by `hinagata db with`, and extends the test API with a marker query. Inject a process-only liveness action and a readiness action that checks the leased database; reuse the generated builder directly for its probe conformance suite and share its probe assembly when adding the test-only route. Add a temporary Workbench suite that manages this consumer, waits at `/health/ready`, runs the generated health workflow, and verifies the marker route's HTTP status, JSON media type, and `ready` value. Invoke the actual generated wrappers/helper. Run twice under distinct leases; both must see the deterministic row, report different database names, stop their service, and release their allocation. A separate imitation of the probe routes cannot establish acceptance.

Run the generated direct-load recipe against its explicit scratch target and prove a separate sentinel database has no marker table. Run an intentionally incorrect HTTP assertion and require a nonzero outer status with service/clone cleanup. Exercise fresh generated files, not handwritten approximations of them. Build all six seed libraries with `cabal build all`. Do not expand this task into tool-level concurrency, retention, or cancellation feature work, and do not claim a production Keiro application exists.

### Milestone 5: Optional initial Mori descriptor


Add `mori.generate` as an optional Boolean variable with a prompt such as “Generate an initial mori.dhall with packages, dependencies, and the OpenAPI schema reference?”. Keep it unresolved when not supplied so interactive generation actually asks; an empty answer skips generation, an explicit false disables it, and absent noninteractive input also skips. Do not give it a resolved false default that hides the question. Add an optional `mori.namespace` text variable and a prompt conditioned on `Eq mori.generate true`, explaining that this is the Mori organization/user namespace, not `project.namespace` (the PascalCase Haskell module prefix). An enabled run must supply a nonempty valid Mori namespace; missing/invalid identity fails planning before writes. For automation support `--var mori.generate=true --var mori.namespace=example` and `--var mori.generate=false`. Mirror these declarations and conditional prompts in `blueprints/haskell-keiro-service/blueprint.dhall`, ensuring the agent path asks at most once and carries the choice into module application.

Add `modules/haskell/haskell-keiro-project/files/mori.dhall.tpl` and a managed template step targeting root `mori.dhall`, conditioned on `Eq mori.generate true`. Import the verified Mori schema at an immutable commit with a Dhall integrity hash. Project identity uses project name/description, the supplied Mori namespace, Haskell language, Application type, and Experimental lifecycle for the new seed. Do not infer a GitHub owner/URL or reuse the Haskell namespace. A local repository record can identify the current repository without inventing a remote.

Declare exactly six initial package records, with names and relative paths matching `cabal.project` and the Cabal files. Reflect actual generated components: the seed packages currently expose libraries even when their role is server or workers; the API package also contains the OpenAPI executable and test suite. Preserve the existing allowed sibling graph. Populate each package's external dependencies and native Cabal version constraints from the final scaffold, distinguishing regular dependencies from test-only ones such as servant-health:testkit and Tasty. Include the servant-health/openapi-hs/servant-openapi-hs cohort where actually used. Do not invent a fully implemented Keiro runtime dependency list before the blueprint adds that code, or claim that Hurl/Hinagata CLI tooling is linked into application libraries. List tooling separately as development metadata/documentation and canonical project references. Keep this initial inventory synchronized when the blueprint implements the domain.

Use Mori's verified dependency lookup grammar in schema-required name fields, accompanied by exact canonical package URIs in comments or documentation and typed `dependencyRefs` for external packages. Do not feed a canonical URI into a legacy dependency-name parser that treats its colon as the package separator. Local sibling names may stay local. Resolve external ownership through Mori rather than copying ambiguous package aliases. A small checked-in metadata mapping used by the template/checker is acceptable; adding a general Cabal-to-Mori synchronization engine is outside this request. An acceptance check must compare the generated descriptor's declared names, paths, scopes, and bounds with the generated Cabal components so the two representations cannot silently diverge.

Declare one API named `{{project.name}}-api` with `Schema.ApiType.OpenAPI`, `specPath = "docs/openapi.json"`, `owner = "{{project.name}}-api"`, and a typed ownerRef for that same package in the chosen Mori project identity. The referenced document remains produced by `just openapi` from Milestone 2; omit unrelated HTTP endpoints or generated-client provenance that the seed does not implement. Descriptor generation itself does not invoke the compiler or create a fake schema file. After the first build, generate the real document and verify its location agrees with Mori's API record. API ownership must be valid locally without requiring registration of this fresh project.

Extend `scripts/check-keiro-bootstrap.py` with opt-in/opt-out and missing-namespace cases, plus a pseudo-terminal or existing Seihou console fixture that proves an ordinary interactive run displays the question and honors both answers. Enabled output must pass `dhall --file mori.dhall`, `dhall-to-json --file mori.dhall`, `mori validate`, and `mori show --json`; inspect the evaluated data for exactly six packages, dependency parity, and correct API owner/path. These are scoped to temporary generated projects and do not register them. Test identical reapplication, conflict protection for an edited/existing descriptor, and disabling the option after generation without deleting the file. An opted-out run creates no descriptor, asks no namespace question, and still supports the same health/OpenAPI commands. If initial descriptor validation warns that the not-yet-generated OpenAPI file is absent, document the expected `just openapi` next step and require the post-generation check to resolve it; never fill the gap with placeholder JSON.

### Milestone 6: Publish a coherent module contract


Update `modules/haskell/haskell-keiro-project/README.md`, generated `files/README.md.tpl` and `files/bootstrap.md.tpl`, `blueprints/haskell-keiro-service/prompt.md`, and affected `blueprint.dhall` descriptions. Explain naming/context, probe assembly and policies, database-free OpenAPI generation/freshness checks, the optional Mori prompt/namespace and package/dependency/API inventory, tool acquisition, broker platform limits, database startup, direct targets versus clones, and the handoff to real service routes and migration hooks. Replace duplicated probe types/handlers in the historical `blueprints/haskell-keiro-service/files/Api.hs` reference with library imports and update its descriptor, so it does not lead agents back to a hand-written implementation. Blueprint instructions extend the generated ServiceApi, add compatible schemas for domain DTOs, keep OpenAPI derived from the complete mounted contract, preserve the generated Hurl/Hinagata assets, and update an opted-in Mori inventory when packages/dependencies/API ownership change.

Bump the Keiro module from 0.1.0 to 0.2.0 for its layout/tooling change and bump the companion blueprint when its instructions change. Update `seihou-registry.dhall`, `mori.dhall`, and the root catalog together. Regenerate `okf-docs/` through the documented extension rather than hand-editing it. Give existing projects review-first upgrade guidance; never force generation over authored workspaces or delete context-named members. Update ADR 2 with naming and test setup, and ADR 3 only if managed-module guidance needs clarification. Run final relevant checks, triage implementation friction, and record concise acceptance evidence.


## Concrete Steps


All authoring commands run from the `seihou-modules` root. Discover sources before relying on APIs, then verify released versions and tags:

```bash
mori registry list
mori registry search keiro
mori registry search servant-health
mori registry search openapi-hs
mori registry search mori-schema
mori registry show shinzui/mori-schema --full
mori registry docs shinzui/mori-schema
mori registry docs shinzui/mori
mori registry show shinzui/servant-health --full
mori registry docs shinzui/servant-health
mori registry show shinzui/openapi-hs --full
mori registry show shinzui/servant-openapi-hs --full
mori registry show shinzui/hurl-workbench --full
mori registry docs shinzui/hurl-workbench
mori registry show shinzui/hinagata --full
mori registry docs shinzui/hinagata
mori registry docs shinzui/keiro-runtime-patterns
mori path mori://shinzui/keiro-runtime-patterns/docs/architecture-service-packages
mori path mori://shinzui/keiro-runtime-patterns/docs/keiro-service-workspaces
curl -fsSL https://hackage.haskell.org/package/hinagata-cli.json
curl -fsSL https://hackage.haskell.org/package/hurl-workbench-cli.json
curl -fsSL https://hackage.haskell.org/package/servant-health.json
curl -fsSL https://hackage.haskell.org/package/openapi-hs.json
curl -fsSL https://hackage.haskell.org/package/servant-openapi-hs.json
git ls-remote --tags https://github.com/shinzui/servant-health.git
git ls-remote --tags https://github.com/shinzui/openapi-hs.git
git ls-remote --tags https://github.com/shinzui/servant-openapi-hs.git
git ls-remote --tags https://github.com/shinzui/hinagata.git
git ls-remote --tags https://github.com/shinzui/hurl-workbench.git
git ls-remote --tags https://github.com/shinzui/mori-schema.git
```

A missing unpublished package is evidence to record, not a reason to infer its version. Verify the candidate Workbench source is fetchable and matches the generated schema/CLI. If the early integration check fails, choose another verified immutable tooling commit and record why, without weakening acceptance or changing application runtime bounds.

During structural, health/schema, and tooling work, run:

```bash
seihou validate-module modules/haskell/haskell-keiro-project
seihou validate-module modules/haskell/nix-haskell-flake
seihou validate-blueprint blueprints/haskell-keiro-service
python3 scripts/check-keiro-bootstrap.py
```

Expect a PASS result for each generated fixture and registry/Mori evaluation. The checker prints a temporary fixture path. From one newly generated fixture's root, enter `nix develop` and run:

```bash
just test-tools
just api-validate
just api-render
just fixture-plan
cabal build all
cabal test sample-service-server-health
cabal test sample-service-api-openapi
just openapi
just openapi-check
```

Use the fixture's actual project name in place of `sample-service` in the test-suite command. Expect both tool versions, passing doctor/validation, rendered live/ready assertions, fixture-plan JSON with `ok: true`, six successfully built libraries, and an executed passing health suite. `just openapi` writes `docs/openapi.json`; `just openapi-check` passes immediately afterward and fails if the document is edited until regeneration restores it. Schema output must describe both probes' 200/503 responses. These checks need no running application or database. Hurl variables must survive Seihou; Workbench rendering may then supply their bindings.

For a fixture opted into Mori generation using `--var mori.generate=true --var mori.namespace=example`, run the following from that generated project's root after `just openapi`. Use the Mori CLI already installed on the authoring machine; this optional descriptor does not add a Mori daemon/runtime dependency to the application shell.

```bash
dhall --file mori.dhall
dhall-to-json --file mori.dhall
mori validate
mori show --json
test -s docs/openapi.json
```

Expect a valid descriptor and evaluated data naming all six package paths and one OpenAPI API owned by the API package, pointing at `docs/openapi.json`. The checker also compares package dependency scopes/bounds to the generated Cabal components. Repeat with the option absent/false: no descriptor is generated and `just openapi` still succeeds. Do not call `mori register` as a validation shortcut.

For a manual database demonstration, from that generated root inside its shell, start services in one terminal:

```bash
process-compose -f process-compose.yaml up
```

From a second `nix develop` shell for the same project, use a fresh scratch database:

```bash
just create-database
createdb -- keiro_bootstrap_smoke
just fixture-load keiro_bootstrap_smoke
psql -X -d keiro_bootstrap_smoke -tAc 'SELECT value FROM hinagata_bootstrap.marker WHERE id = 1'
just fixture-with
```

The query and clone check must report `ready`. If that example database name already exists, choose a fresh unique name rather than reusing unknown data. Repeated marker loading retains one row. Stop services through process-compose and remove only the scratch database created for this demonstration. Once a real application is running with its injected health checks, `just api-test http://127.0.0.1:8080` must report passing Hurl tests for `/health/live` and `/health/ready`; before then, connection failure remains visible.

Final repository acceptance runs:

```bash
python3 scripts/check-keiro-bootstrap.py
python3 scripts/test-keiro-bootstrap.py --live
seihou registry sync-versions
seihou registry validate
dhall --file mori.dhall
seihou extension run okf -- docs --dir . --out okf-docs --force
git diff --check
```

Run existing shared-runtime regression cases only if implementation changes shared Nix paths; inspect `scripts/test-haskell-runtime-bootstrap.py` for its current invocation. Required Keiro live acceptance remains separate and mandatory. The live harness must report success for real data, distinct leases, HTTP assertions, failure propagation, and cleanup. Report the platform actually executed. Broker rendering alone never proves broker startup.


## Validation and Acceptance


Use at least two valid project names, including a hyphenated name. Without `keiro.context`, domain paths, manifest service, and member context use project name. With a different explicit context, paths/service still use project name and the member honors the override. Exactly six application Cabal packages have valid sibling dependencies and matching project entries. No unresolved Seihou placeholders remain; intentional Hurl placeholders are exempt. Invalid path-like project names must fail the existing variable validation.

PostgreSQL and process-compose are enabled by default; a private broker is not. An enabled Redpanda render contains private project names, chosen ports, and console setting. Disabled output follows the base module's established omission behavior. Kafka client libraries remain independent. The existing Darwin gate must prevent Linux from forcing Apple Container packages. If Apple Container is available, manually verify private broker lifecycle; record it separately from portable render acceptance.

A fresh generated shell must execute Workbench, Hinagata, Hurl, and Hurlfmt through documented pinned selections, without developer checkout paths. Workbench validate/render and Hinagata configuration/planning pass before application implementation. The early database check must observe an inserted row, not merely valid configuration or mocked CLI arguments.

Health/schema acceptance requires the actual generated server builder to pass `servant-health:testkit` conformance under the threaded runtime. Readiness-only failure produces ready 503/live 200; liveness-only failure produces live 503/ready 200, using the package's fixed JSON wire contract. No bare `/health` endpoint is introduced. The OpenAPI generator runs without configuration, PostgreSQL, or server startup and emits parseable OpenAPI 3.1 containing both probe paths and both response statuses. The nullable timestamp and fixed probe properties must agree with the library's schema. A repeated generation is unchanged, the freshness check detects a modified artifact, and replacing the artifact through regeneration restores a pass. Preserve six application packages and normal released dependency bounds throughout.

The live harness is the required PostgreSQL-to-Hinagata-to-HTTP-to-Hurl proof. Two runs receive distinct clones and identical seeded state; the consumer stops before clone release. A wrong assertion fails the outer command, cleanup completes, and an unrelated database is unchanged. Seed compilation proves bootstrap validity; the blueprint's later domain/migration/runtime acceptance remains separate.

Repeat generation remains byte-identical, ignore entries do not duplicate, and reapplication protects edited fixtures/workspaces and the user's Nix/process-compose extensions. The canonical base lock is unchanged. Registry, Mori, module, blueprint, and generated catalog versions agree. No milestone is complete merely because templates evaluate or libraries compile.

Additional native broker evidence (2026-10-26): Apple Container was available and running. A separately rendered unique bootstrap-broker project enabled Console and five selected free ports. Its actual redpanda-local-up/status reported both containers running, the admin endpoint returned ready, the Console HTTP endpoint responded, and redpanda-local-down followed by the guarded scratch-only purge removed both containers, the volume and network. No existing broker was reused. This is Darwin/arm64 evidence; no Linux broker startup is claimed.

Mori acceptance requires the optional question to be observable in an actual interactive path and controllable through explicit noninteractive variables. Opt-in creates one typed, evaluable `mori.dhall` with exactly six real packages, accurate sibling/external dependency scopes and bounds, and an OpenAPI declaration whose owner and `docs/openapi.json` path match the generated API/schema. Opt-out skips both descriptor generation and the namespace prompt without changing OpenAPI functionality. A different valid Mori namespace must change only Mori identity/references, not the Haskell module namespace. Missing identity, existing authored files, repeated application, and opting out after a prior opt-in must not cause silent overwrite/deletion or registration side effects.


## Idempotence and Recovery


Generate checks in temporary projects containing local module copies under `.seihou/modules`, following the existing checker; do not overwrite global installed modules. Respect Seihou conflicts and never use `--force` as general recovery.

New naming applies to fresh scaffolds. For existing projects inspect domain files, ledgers, recipes, Cabal configuration, and ownership before adoption. Preserve authored workspaces and back up affected files plus the Seihou manifest together. A reviewed rename must update all references; changing a stable service identity also affects scaffold history. Automatic brownfield migration is not included.

Optional Mori generation is a seed, not an adoption or automatic synchronization command. Leave an existing authored `mori.dhall` under Seihou's conflict protection and review it rather than merging/replacing it blindly. Skipping the option never deletes an existing descriptor, even when it was generated by a previous run. No registry registration, identity minting, or repository creation is implicit. The OpenAPI artifact remains independently regenerable, and its absence before the first build is resolved by `just openapi`, not by changing the descriptor to a bogus path.

Direct fixture loading selects an existing target and never grants deletion rights. The marker fixture is repeatable; arbitrary future SQL need not be. Clone operations own only recorded allocations. Stop consumers before release; inspect retained allocations and use explicit Hinagata release rather than prefix-based database deletion. The harness tracks exact paths/resources it creates and stops its own cluster in a finalizer, retaining useful failure diagnostics.

If a tool pin cannot build, retain evidence, fix its source selection/wrapper, and retry the early integration path. Do not change application runtime bounds or the base lock to hide tool packaging issues. During implementation record provenance/friction using the bundled skill scripts. Every implementation commit includes an `ExecPlan:` trailer naming this file. No Intention trailer is active because the user selected Skip.


## Interfaces and Dependencies


The public module stays `haskell-keiro-project`. Required project name/namespace/description and existing author/package metadata remain; `keiro.context` becomes optional. Project paths and workspace service derive from name. Use existing Seihou `IsSet` conditionals instead of extending the CLI. If variable behavior needs inspection, discover `mori://shinzui/seihou` and read its `seihou-core/src/Seihou/Core/Variable.hs` and `seihou-core/src/Seihou/Composition/Resolve.hs` (artifact-level URIs pending).

The internal `mori.prompt` Boolean coordinates interactive questions: it defaults true in the module, while the blueprint forwards false after handling its own question, so an empty skip never prompts twice. It does not affect explicit generation choices.

Optional Mori inputs are `mori.generate` (Boolean; missing/false means skip) and `mori.namespace` (text; needed only when generation is enabled). The conditional root `mori.dhall` uses the pinned `Schema.Project`, `ProjectIdentity`, `Package`, `Dependency.WithAugmentation`, `MoriRef`, and `Api` interfaces. Its OpenAPI record is declaration metadata referencing the existing generated JSON, not a second schema generator. Canonical cross-project references remain explicit alongside any schema-required dependency lookup key. Additional user-specific namespace configuration is kept separate from `project.namespace`.

`nix-haskell-flake` supplies services/toolchain. The scaffold binds `nix.package-module=nix/keiro-dev-tools.nix` and `nix.builtin-package=false`, adding tools through `haskellProject.extraDevPackages`. It does not select retained runtimes, change compiler identity, or create another application package. Existing `nix.redpanda`, `nix.redpanda-console`, `redpanda.*-port`, and `nix.kafka` variables are the broker/client configuration interface.

Workbench types come from its selected `schema/package.dhall`: `Workspace`, `Parameter`, `Fragment`, `Workflow`, `Recipe`, `Suite`, `RunReference`, and `Safety.ReadOnly`. Use only actual fields in that commit and pin schema/tool together. Hurl syntax lives in copied request files.

The HTTP contract lives in `{{project.name}}-api`, with `{{project.namespace}}.Api.ServiceApi` and `{{project.namespace}}.Api.OpenApi` exporting the derived schema. The generator executable is `{{project.name}}-openapi`; recipes write/check `docs/openapi.json`. The server exports `mkApp :: ProbeCheck -> ProbeCheck -> IO Application`, delegating to `Servant.Health.healthServer`; its public probe type/codec/schema come from servant-health. `ProbeCheck` is an IO action returning `Healthy` or `Unhealthy` with a check name and failure timestamp. Production policy remains injected. `Servant.Health.TestKit.probeContractTests` belongs to the server test component only. `Data.OpenApi.OpenApi`/`ToSchema` come from openapi-hs, and `Servant.OpenApi.toOpenApi` comes from servant-openapi-hs. Keep their published compatible cohort and a Hackage index-state that actually contains it.

Hinagata's executable is `hinagata` from package `hinagata-cli`. Use `--config`, `--check-config`, `fixture plan NAME --json`, `fixture load NAME --target-database DATABASE --json`, and `db with --fixture NAME -- PROGRAM ARGS...`. Configuration requires explicit endpoint host/port, project ID, absolute fixture/bundle roots, maintenance database, and administration/setup/application user/database pairs through documented `HINAGATA_*` bindings. Ambient PG fields alone do not configure Hinagata. A leased child gets explicit PG fields, so future service wrappers must map those into service configuration rather than accidentally retain a development connection URL.

This independent follow-up builds on completed plan 3; it is not a child plan. Implement structural compatibility, shared health/schema plumbing, one real tooling/database consumer, live integration acceptance, optional Mori descriptor generation, and final validation/release documentation in that order. An immutable unpublished CLI tooling pin is explicitly allowed here and remains separate from application runtime dependencies.

Revision note (2026-10-26): Added the user's servant-health/openapi-hs/servant-openapi-hs requirements as a dedicated milestone, bringing the total to five, with generated probe assembly, database-free OpenAPI generation, published dependency verification, conformance/freshness acceptance, and corrected Hurl readiness paths. No business-domain implementation was added to the bootstrap scope.

Revision note (2026-10-26): Added an optional initial Mori descriptor prompt and a dedicated sixth milestone overall, covering project/package/dependency inventory, the generated OpenAPI artifact reference, namespace separation, actual interactive prompting, opt-out, local validation, and existing-file protection. OpenAPI generation remains available regardless of this choice.
