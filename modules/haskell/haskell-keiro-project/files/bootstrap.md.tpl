# Implement {{project.name}} on the Keiro runtime

Implement **{{project.description}}** with Haskell namespace **{{project.namespace}}** and
stable service/context **{{keiro.context}}**. The initial six libraries and Nix shell are present.
First establish the actual domain requirements with the owner: aggregates, commands, events,
queries, integrations, and lifecycle rules. A synopsis alone does not specify business behavior.
Do not invent a Widget domain, copy CRM behavior, or treat empty libraries as a finished service.

## Discover the current contracts

Use Mori before guessing APIs. Resolve and read these canonical references:

- `mori://shinzui/keiro-runtime-patterns/docs/runtime-patterns-getting-started`
- `mori://shinzui/keiro-runtime-patterns/docs/architecture-service-packages`
- `mori://shinzui/keiro-runtime-patterns/docs/architecture-vertical-slice-modules`
- `mori://shinzui/keiro-runtime-patterns/docs/architecture-generated-compilation-contract`
- `mori://shinzui/keiro-runtime-patterns/docs/keiro-service-workspaces`
- `mori://shinzui/keiro-runtime-patterns/docs/keiro-language-versions`
- `mori://shinzui/keiro-runtime-patterns/docs/architecture-test-layout`
- `mori://shinzui/keiro-runtime-patterns/docs/migrations-service-package`
- `mori://shinzui/keiro-runtime-patterns/docs/config-settei-service-standard`
- `mori://shinzui/keiro-runtime-patterns/docs/keiro-runtime-assembly`

```bash
mori registry list
mori registry docs shinzui/keiro-runtime-patterns
mori registry docs shinzui/haskell-jitsurei
mori registry show shinzui/keiro --full
mori registry show shinzui/jinmyaku --full
```

The structural example is `mori://shinzui/jinmyaku`: inspect its `cabal.project`, `justfile`,
and six package trees (artifact-level URIs pending). Its business rules are not requirements
for this service. Follow current normative docs when an example or old blueprint sketch differs.
Never traverse `/nix/store` or search the filesystem root. Use canonical Mori URIs for durable
cross-repository references.

## Verify releases before implementation

The initial `cabal.project` pins index-state `{{haskell.index-state}}` for the minimal libraries.
Before adding runtime dependencies, use `mori registry search`, `show --full`, and `docs` to locate
each dependency's sources. Verify its current Hackage release and upstream release tag, then
choose one coherent index-state and bounded runtime cohort. Record the versions and evidence.
The local corpus can be newer or older than the published APIs. Do not copy old blueprint bounds,
compatibility exclusions, or a source pin from the example. Do not add local paths or runtime
`source-repository-package` stanzas. Any necessary unpublished tooling exception needs explicit
justification and an immutable commit, separate from runtime dependencies.

Install the verified released `keiro-dsl` into the project-local `.bin` from a scratch directory
outside this Cabal workspace, with the selected index-state and GHC 9.12.4. Record the exact tool
version and reproducible install command in `just keiro-tool`; do not use an unbounded latest
install or assume the tool already on PATH matches the selected release.

## Author one workspace before domain Haskell

Use `domain/{{keiro.context}}.keiro-workspace` as the single command target. Preserve the explicit
`module {{project.namespace}}`, `layout collocated`, and `runtime-package {{project.name}}-core`.
Keep shared declarations in `domain/{{keiro.context}}/shared.keiro`; each aggregate has one complete
member in the same directory, registered once by a manifest-relative `spec` clause. All members
share the same context and explicit language contract (the seed uses stable Language 5).

Choose domain newtypes and meaningful TypeID prefixes from the standard. Specify nominal bindings,
wire values, commands, events, transitions, rejection behavior, read models, and operations using
the chosen release's syntax. Check the whole workspace before generating Haskell:

```bash
just keiro-check
just keiro-scaffold
```

The seed shared member deliberately has no business declarations; a successful seed check is not
a domain conformance result. Keep generated code disposable and Holes/bindings hand-owned.
Repaste the complete generated Cabal fragment after every regeneration, including dependencies,
extensions, all module lists, StructuralConformance, BehaviorSourceMap, and the conformance facade.
Honor the generated Haskell edition and preserve its ledger. Never hand-edit generated imports or
enable FieldSelectors to bypass the contract. Re-scaffold twice and prove unchanged output and
preservation of hand-owned files. Add the generated conformance suite to the build; the optional
package glob is already present in `cabal.project`.

## Complete the six package boundaries

Use GHC 9.12.4, GHC2024, hand-written Cabal files, leading-comma dependencies, and shared warnings.
Keep extensions beyond the generated baseline local where required. Use strict data record fields,
explicit deriving strategies, and current record-dot/generic-lens conventions. Do not put strictness
annotations on newtype fields. Core's custom Prelude re-exports Control.Lens; import
Data.Generics.Labels locally where needed so its orphan instances do not leak into the Keiki DSL.
Migrations remains independently buildable and does not import core merely to reuse its Prelude.

- `{{project.name}}-core`: domain newtypes, shared Prelude, App.Config, Postgres.Pool/Runner,
  concept Generated/Holes/ReadModel modules, integration contracts, and lifecycle diagrams.
  No sibling production-library dependencies.
- `{{project.name}}-api`: NamedRoutes and wire DTOs, depending on core and servant; no server/warp.
- `{{project.name}}-server`: concept handlers, Server.Config/App/Seam/Boot, and the
  `{{project.name}}-server` executable, depending on core and API.
- `{{project.name}}-workers`: concept workers, Workers.Config/Subscription/Registry, and the
  `{{project.name}}-worker` executable, depending on core but never API/server.
- `{{project.name}}-migrations`: pg-migrate components and strict embedded application manifest,
  the `{{project.name}}-migrate` executable, and a public `test-support` sublibrary. No sibling
  production dependency. Core/server/worker tests may consume migrations:test-support.
- `{{project.name}}-client`: typed client generated from the API, never dependent on server.

Replace empty boundary modules with real typed interfaces and build all packages before deepening
any one area. Let compiler diagnostics drive focused source lookup. Keep concept code together
across packages; do not add a seventh persistence package. The generated conformance package is
an auxiliary test package, not a seventh application package.

## Wire migrations and runtime resources

Read the migration, runtime assembly, two-schema, messaging, and configuration standards. Compose
Kiroku, Keiro, any required queue component, then the application component into one complete
pg-migrate plan. Embed SQL with a strict exhaustive manifest and the required recompilation plugin.
Expose database-free `plan`, and real `up`, `status`, `verify`, and migration-authoring operations;
bare migration invocation must be a usage error. Test first apply and zero-work reapply.

The generated `create-database` recipe only creates the development database. Once the migration
executable works, extend it to apply the complete plan with explicit DATABASE_URL resolution.
Keep custom orchestration in `process-compose.override.yaml` and Nix customization in
`flake.module.nix`. Do not modify managed base Nix files. Add the project-specific Nix package build
there if required; the invalid single-root default is deliberately disabled.

Resolve Settei files, mounted secrets, and explicit environment bindings before acquiring runtime
resources. Reject unknown keys, implement --describe-config/--explain-config/--check-config through
the real resolver, preserve documented exit codes, and never log secrets. Keep Settings separate
from the strict AppConfig runtime dependency record.

Construct validated streams at startup; unchecked event streams are forbidden. Respect the separate
Keiro framework and Kiroku store schemas, ordered idempotent read-model application, and watermark
rules. Acquire real OpenTelemetry tracer and meter providers in both processes with flush/shutdown
brackets, propagate W3C context, and thread Keiro metrics into command and worker options.
Use structured request logging, NamedRoutes, and problem responses. Separate process-only liveness
from readiness, and make readiness false while draining. No no-op tracing as production wiring.

## Prove the finished service

Generate lifecycle Mermaid from the hand-owned transducers and gate freshness. Implement core domain
harness, diagram, and PostgreSQL tests; migration apply/reapply tests; real migrated handler tests;
per-concept worker tests; and generated behavioral conformance. Read each dependency's test helpers
before use, including nested Either results from migrated-database callbacks.

```bash
just keiro-check
just keiro-conformance
cabal run {{project.name}}-migrate -- plan
cabal build all
cabal test all
nix fmt
git diff --check
```

Also demonstrate configuration diagnostics without starting listeners, probe/drain behavior, a real
command/query round trip, an idempotent worker delivery, and repeated DSL generation without drift.
Report exact commands, verified releases/index-state, generated ownership, and unresolved failures.
Do not claim runtime acceptance from the initial empty-library build. Do not commit or push; hand
off the reviewable files and evidence to the owner.
