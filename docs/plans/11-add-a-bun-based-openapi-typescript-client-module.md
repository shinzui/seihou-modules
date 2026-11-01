---
id: 11
slug: add-a-bun-based-openapi-typescript-client-module
title: "Add a Bun-based OpenAPI TypeScript client module"
kind: exec-plan
created_at: 2026-11-01T15:39:00Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-11-01T15:39:00Z
  revisions:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-11-01T15:56:34Z
      mode: "update"
      note: "Require TypeScript 7+ throughout; remove legacy compiler fallback and gate generator compatibility before scaffolding"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-11-01T16:06:38Z
      mode: "discuss"
      note: "Propose Orval; prioritize type fidelity and status-aware validation; allow private generator TypeScript 6 while project builds and consumers require 7+"
---

# Add a Bun-based OpenAPI TypeScript client module

This ExecPlan is a living document. Keep its living sections current and follow `agents/skills/exec-plan/PLANS.md`, `agents/skills/exec-plan/ADR.md`, and `agents/skills/exec-plan/FRICTION.md`. This is a planning revision; implementation has not begun.


## Purpose / Big Picture

Create an `openapi-typescript-client` Seihou module that depends on `nix-bun-flake` and produces a reusable TypeScript client package from an OpenAPI document. OpenAPI is a JSON or YAML description of HTTP operations and their request and response shapes. Use Orval to generate operation functions, models, and validators. Use TypeScript 7+ for all project checking, JavaScript/declaration emission, and consumer tests. Strong typing and correctness are the primary selection and acceptance criteria.

A developer can validate a local schema, generate the client, make typed requests, detect stale generated output without rewriting it, and build a package for another project. Invalid arguments must fail compiler checks; malformed server responses must fail validation before being exposed as typed data. Schema validation, generated type fidelity, and runtime payload validation are three distinct checks, and all are required for the supported JSON client surface.

The reference client at `mori://tan/mls-service-v2-ts-client/packages/mls-service-v2-ts-client` supplies the use case, not the library choices. The new module keeps an explicit base URL and configurable transport, but exposes named generated operations rather than reproducing `openapi-fetch`'s path-keyed methods. Migrating that reference project, private schema fetching, releases/publication, CommonJS, framework hooks, and Nix application packaging are outside this plan. Runtime JSON response validation is now included because the user prioritized correctness.


## Progress

- [ ] Milestone 1: Qualify Orval with a schema-fidelity fixture under TypeScript 7, including status-aware runtime validation, difficult schema cases, and missing/stale output failures.
- [ ] Milestone 2: Real Seihou composition creates the client with the shared Bun/TypeScript 7 shell, supported Node runtime, and verified starter-file ownership.
- [ ] Milestone 3: The scaffold generates and validates clients, passes compiler and real HTTP tests, and builds an ESM package consumable outside its source tree.
- [ ] Milestone 4: Catalog and documentation expose the module, and ownership, packaging, and existing Bun/Fumadocs regressions pass.

Planning handoff (2026-11-01): Orval is the proposed replacement, and basic generation, TypeScript 7 checking/emission, status narrowing, and freshness behavior were probed successfully. Correctness qualification remains unfinished: a valid 404 response was rejected against the success schema by Orval's built-in runtime validation. No module files have been implemented. The planning machine has Seihou 0.10.1.0; generation acceptance requires 0.11.0.0 or newer.


## Surprises & Discoveries

The earlier compiler restriction was broader than the user's intent. The user explicitly permits Orval's private TypeScript 6 tooling dependencies while requiring project builds and consumers to use TypeScript 7+. A compiler API dependency used inside a generator is separate from the project's supported compiler. Keep that distinction observable in the final checks.

Orval 8.46.0 generated a typed JSON fetch operation and passed strict TypeScript 7.0.2 checks, including required path parameters and narrowing success/error bodies by their literal `status`. However, a probe using `schemas: { type: 'zod' }` and `override.fetch.runtimeValidation: true` generated a `Widget.parse(parsedBody)` call regardless of HTTP status. Thus valid `{ message: "Not found" }` error data was checked against the successful widget schema. Concise observed evidence:

```text
TypeScript 7.0.2 required-parameter and status-narrowing assertions: PASS
valid-200: accepted
invalid-200: rejected with ZodError
valid-404: rejected with ZodError
unchanged orval --outdated: exit 0
changed schema, orval --outdated: exit 1; generated client unchanged
```

The same probe's component schema declared `additionalProperties: false`, while default generated Zod output used `zod.object` rather than a rejecting object validator. Do not assume default generation preserves every constraint. Test closed versus open objects explicitly; global strictness is not a substitute because it could reject properties allowed by an open schema.


## Decision Log

2026-11-01: Replace the proposed `openapi-typescript`/`openapi-fetch` stack with Orval, initially 8.46.0. The user favors Orval and prioritizes strong typing/correctness. The former project's maintainer announced no further updates, including security fixes, on 2026-09-19. Retire the earlier plan to wait for or adapt its legacy compiler API.

2026-11-01: Project compilation and consumers support TypeScript 7+ only, initially the shared Nix compiler 7.0.2. The user explicitly allows Orval's private TypeScript 6 generator dependencies. Do not use that private executable for project builds, add a supported TypeScript 6 build path, or override the generator's dependencies to force a different API version. Future TypeScript 7+ releases require explicit qualification; they are not already tested.

2026-11-01: Use a framework-independent fetch client, generated status-specific JSON validators, and Redocly CLI 2.72.1 for source-document validation. Zod 4.6.7 is the initially researched runtime-validator baseline. Compiler checking alone cannot establish that a server returned the declared shape. Built-in validation is not accepted until it passes the status/shape tests; a small maintained transport adapter may select the proper generated validator for each declared status/media type. Do not publish unsound data behind an unchecked generic assertion.

2026-11-01: Keep the module's published name `openapi-typescript-client`; it describes the resulting TypeScript client, not a dependency on the old generator package. Generate into `src/generated/`, expose a small project-owned `make` facade with named operations, and build ESM using the shared TypeScript 7 compiler. Project starters remain seeds, while shared Nix imports remain managed.

2026-11-01: Extend the Bun base with an optional managed `nix.package-module` seam, preserving the unmanaged `flake.module.nix` extension and canonical lock. The client contributes a supported Node 22 package through `bunProject.extraDevPackages`. It does not create a second Bun/TypeScript toolchain or enable bun2nix implicitly.


## Outcomes & Retrospective

(To be filled during implementation.)


## Context and Orientation

Seihou modules consist of `module.dhall` descriptors and `files/` templates. Dhall is the typed configuration language for those descriptors. `seihou-registry.dhall` catalogs artifacts; `mori.dhall` independently exposes discovery metadata; `README.md` lists them. `okf-docs/` is generated documentation.

`modules/typescript/nix-bun-flake/module.dhall`, currently 0.4.0, creates the Bun/Nix development environment, package metadata, TypeScript configuration, and `justfile` recipes. A Nix flake fixes tool inputs and describes development shells. Its `files/flake.nix.tpl` imports managed Nix modules and optional unmanaged `flake.module.nix`. `files/nix/bun.nix.tpl` exposes `bunProject.extraDevPackages` for extra development tools. The base has no managed project-module import variable, and `files/envrc` is currently copied rather than templated. The tool manifest `files/nix/tooling-sources.json` pins TypeScript 7.0.2, oxlint 1.87.0, and oxfmt 0.72.0. Preserve those pins and the byte-identical `files/flake.lock`.

`modules/typescript/fumadocs/module.dhall` demonstrates dependent-module overrides for package metadata, TypeScript config, and recipes. `scripts/test-fumadocs-bootstrap.py` uses temporary project-local module copies and real Seihou generation. `scripts/test-nix-bun-flake.py` and `scripts/update-nix-bun-flake.py --check` cover base rendering, update/removal, optional features, and immutable pins. Use those patterns instead of changing the user's personal module cache or fabricating manifests.

The reference client is `mori://tan/mls-service-v2-ts-client/packages/mls-service-v2-ts-client`. Resolve it with `mori path`. Its project-relative `package.json`, `src/client.ts`, `src/index.ts`, `src/validate.ts`, `build.ts`, and `Justfile` supplied the inspected example; artifact-level source-file URIs are pending. Its base-URL wrapper and reusable package matter here; its old generator, Swagger Parser wrapper, declaration plugin, formatting, and release automation are not required compatibility surfaces.

ADR discovery scanned local filenames and headings. [ADR 2](../adr/2-separate-keiro-project-seeds-from-domain-implementation.md) establishes project-owned seed files and Seihou 0.11.0.0 as the minimum runtime. A seed is created once and then belongs to the project, including intentional deletion. [ADR 3](../adr/3-separate-managed-scaffold-nix-wiring-from-user-extensions.md) separates dependent managed Nix wiring from the user's extension. [ADR 6](../adr/6-share-an-opt-in-bun2nix-helper-and-isolate-registry-caches.md) preserves shared locks and keeps project build artifacts outside base ownership. No existing ADR chooses Orval or this client's validation contract. There is no profiled ADR bundle in this repository, so preserve ordinary Markdown ADR conventions.

### Research and qualification evidence

Mori was queried for OpenAPI projects and for Orval, Hey API, Kubb, and Zod. The old generator is available at `mori://openapi-ts/openapi-typescript`, but the replacement projects are not currently registered in this local corpus. Their authoritative package metadata, release tags, documentation, and published source archives were therefore used. Intended project identities are `mori://orval-labs/orval`, `mori://hey-api/hey-api`, `mori://kubb-labs/kubb`, and `mori://colinhacks/zod`; artifact-level URIs and local registration are pending. Use those identities with project-relative paths for durable source references.

The [maintenance announcement](https://github.com/openapi-ts/openapi-typescript/issues/2874) supersedes that project's older roadmap. npm and upstream tag `v8.46.0` verify Orval 8.46.0, released 2026-10-30 at commit `46aaf2a177d39c60bfa92d70edb713f24f221e03`. Node must be at least 22.18.0. The [release notes](https://github.com/orval-labs/orval/releases/tag/v8.46.0) include the new read-only freshness check and TypeScript 7-related work. npm and tag `v4.6.7` verify Zod 4.6.7 at commit `b500a2ee95134f81d74da7911d7378dd2853d042`. Redocly CLI 2.72.1 was verified against npm and annotated tag `@redocly/cli@2.72.1`, resolving to `d402413a1cba14680e5d7cc5038337b1b4cdc8bf`.

The [Orval fetch guide](https://orval.dev/docs/guides/fetch/) describes generated operation functions. Its [CLI reference](https://orval.dev/docs/reference/cli/) documents `--outdated`, which compares generated files without writing; external formatting/hooks can make that mode inapplicable. The [Zod guide](https://orval.dev/docs/guides/zod/) documents that conversion is not a complete JSON Schema implementation: exclusivity, compositions, and unsupported constraints need deliberate treatment. These limitations motivate qualification tests rather than a claim of universal fidelity.

An isolated probe installed Orval 8.46.0 using Bun 1.4.2 under Node 22.23.2. Strict checking and declaration/JavaScript emission with the shared TypeScript 7.0.2 worked for a simple generated JSON client. Further compiler assertions with Zod models passed under `strict`, `exactOptionalPropertyTypes`, and `noUncheckedIndexedAccess`. The resolved `@orval/zod` and `@orval/hono` packages depend internally on TypeScript 6.0.3; that dependency is now explicitly allowed, while the compiler command remained 7.0.2. Probe outputs were temporary research artifacts, not implementation or full module acceptance.

Alternatives were investigated. Kubb 5.15.3 has recent releases and a modular generation architecture, but was not qualified against the client's fidelity fixtures. Hey API's current stable `@hey-api/openapi-ts` 0.99.0 still has the legacy compiler API problem; its [TypeScript 7 issue](https://github.com/hey-api/hey-api/issues/4235) describes a fix on the `next` channel, currently `0.0.0-next-20260930190945`. Orval is preferred over relying on that prerelease or maintaining a fork of the retired generator.


## Plan of Work

### Milestone 1: Qualify schema fidelity and transport correctness

Create `scripts/fixtures/openapi-typescript-client/` and `scripts/test-openapi-typescript-client.py --toolchain-only`. Work from temporary copies. Pin Orval 8.46.0 as a development dependency, Zod 4.6.7 as a runtime dependency, and Redocly CLI 2.72.1 as a development dependency. Use the shared TypeScript 7.0.2 compiler, not a local compiler executable. Record a qualified fixture Bun lock separately from consumer locks.

The primary fixture is OpenAPI 3.1 with `GET /widgets/{id}` and `POST /widgets`, explicit success/error JSON bodies, a required path parameter, required body fields, and a local referenced component. Include an OpenAPI 3.0 equivalent. Additional fixtures must exercise required versus optional versus nullable fields; explicit `undefined` with exact optional properties; closed and open objects; enum/literal values; tagged unions; overlapping `oneOf` versus inclusive `anyOf`; `allOf`; recursive/local references; request read-only and response write-only exclusions; and separate response shapes for 200, 201, 404, and 422. A tagged union uses a literal field to distinguish the possible object shapes. Keep dates as wire strings and disable coercion/renaming that would claim a different shape without transforming the actual value.

Use `redocly.yaml` extending `spec` and explicit operation/parameter uniqueness errors. Independently test malformed structure, unresolved references, missing required path declarations, and duplicate operation IDs. Orval config must emit operation functions/types and per-operation/per-status validators into `src/generated/`. Inspect its installed public option types before selecting configuration. Initial codegen can use `client: 'fetch'`, Zod model output, `override.fetch.useRuntimeFetcher`, and factory injection; `override.title` is a function, not a string. Keep formatter hooks disabled for deterministic `--outdated` behavior.

Reproduce the valid-404 failure from Surprises & Discoveries, then qualify the transport fix before accepting this milestone. Prefer ordinary generated Zod operation/status schemas plus a small owned dispatcher, using an explicit generated registry keyed by operation, method/path, status, and content type. Select the actual response schema, validate untrusted data, and only then return the declared response union. A custom fetch/mutator must retain validation; injecting a transport must never bypass it. Generate registry entries deterministically from the same document/configuration, with compiler-checked references to generated validators. Avoid global mutable base URLs. If a different public Orval configuration resolves the failure, prove the same acceptance before preferring it over custom glue. An upstream patch or broader custom generator needs a recorded design decision.

Test valid success and error bodies, malformed success and error bodies, unsupported statuses/media types, empty responses, and declared JSON primitive/array responses. Handle a declared empty response without inventing a JSON body; reject an undeclared status or unsupported typed media path clearly. Do not silently turn unsupported schema constraints into accepting validators. Document the supported subset and produce a generation diagnostic for constraints whose semantics are not preserved. For `oneOf`, accepting an input that matches two branches is a failure. For `additionalProperties: false`, silently stripping forbidden properties is not sufficient. Validation of an open object must retain its allowed properties.

Use positive and negative TypeScript assertions that prove actual type safety, not snapshots alone. Missing required parameters, wrong body fields, invalid enum values, improper nullability, and access to the wrong status branch must fail checking. Generated validators' input/output types must agree with exported client models in both assignability directions for the supported cases. Verify declarations and a valid response at runtime, so an `any` or broad cast cannot make a weak type test pass. Record limitations rather than calling a generator universally correct.

Generate twice with byte-identical output. `orval --config orval.config.ts --outdated` must return zero unchanged and nonzero for missing/stale output, leaving existing bytes unchanged. The harness prints `OpenAPI client toolchain passed.` only when schema, type, transport, and freshness criteria pass. Stop before template expansion if they do not; record the concrete failure and remedy. This milestone explicitly permits prototyping a small adapter, not changing the supported TypeScript floor or weakening correctness.

### Milestone 2: Compose with the shared Bun shell

Add optional `nix.package-module` to `modules/typescript/nix-bun-flake/module.dhall`, following the existing Haskell base's validated relative `.nix` path convention. Add the conditional import to `files/flake.nix.tpl` before the unmanaged extension. Rename `files/envrc` to `files/envrc.tpl`, change the step to `template`, and watch the configured import while preserving all existing environment behavior. Bump the base from 0.4.0 to 0.5.0 without refreshing inputs, archives, or its canonical lock.

Add `modules/typescript/openapi-typescript-client/module.dhall` at 0.1.0 using the published seed-capable schema hash in `modules/haskell/haskell-library/module.dhall`. Re-declare `project.name` and `project.description`. Add local `openapi.schema`, default `openapi.yaml`, accepting validated project-relative YAML/YML/JSON paths. Reject absolute paths, traversal, spaces, and shell metacharacters before interpolation. Seed an example only for the default path; a custom-path user supplies that file. No schema fetching is implicit.

Depend on `nix-bun-flake` with `nix.package-module=nix/openapi-typescript-client.nix` and `nix.pre-commit=false`; keep bun2nix false. The new managed Nix module contributes a Node 22 package meeting Orval's >=22.18.0 requirement through `bunProject.extraDevPackages`. Preserve the shared TypeScript compiler and leave `flake.module.nix` unmanaged.

Seed package metadata, `tsconfig.json`, `tsconfig.build.json`, `justfile`, Oxc configuration, `orval.config.ts`, `redocly.yaml`, example schema/tests, `src/index.ts`, `src/client.ts`, maintained project transport/registry-generation helpers, and the generated project's README. Seeds are project-owned after creation. Generated `src/generated/`, `dist/`, and `bun.lock` are command products, not template outputs. Base-overlapping seeds such as package metadata must retain the child seed lifecycle on repeated root generation, updates, and force; verify using released Seihou instead of assuming overwrite order settles ownership. No destructive removal steps for seeds.

Implement `--render-only` to prove real generation and ownership behavior without npm installation. Preserve the exact lock and a sentinel unmanaged extension. Evaluate the optional import unset/set and all three base-supported systems; native execution is required only on the host. Print `OpenAPI client rendering passed.` when accepted.

### Milestone 3: Deliver the typed package workflow

Templates live in `modules/typescript/openapi-typescript-client/files/`. The package is initially private, named from `project.name`, version 0.1.0, and `type: module`. Declare `types: ./dist/index.d.ts`, a `.` export with `types` before `import`, and publishable files restricted to `dist`. Keep Zod as a runtime dependency and Orval/Redocly as development dependencies. Do not retain `openapi-typescript` or `openapi-fetch` dependencies.

Expose project-owned `make({ baseUrl, fetch?, headers? })`, returning an instance with named generated operations. `Api` is its inferred client type. Export generated models and operation request/response types; retire `paths`, `components`, and `Schema` exports tied to the old generator. Use the factory/adapter qualified in milestone 1, keeping per-instance configuration isolated. Operations return the qualified status-discriminated envelope. Transport errors, invalid JSON, invalid payloads, and unsupported statuses are distinguishable from a valid declared HTTP error response.

Use the shared TypeScript 7 compiler with `strict`, `exactOptionalPropertyTypes`, and `noUncheckedIndexedAccess`. Include source/tests in checking and source only in emission to `dist/`. A compiler-version check used by typecheck/build must reject versions below 7, print the selected executable/version, and download nothing. Private generator TypeScript 6 packages are allowed but must not shadow this compiler when package scripts prepend `node_modules/.bin`. Prefer direct shell `tsc` through the task runner or a Nix-owned named wrapper when needed. The independent consumer must also use 7.0.2. Do not expose a supported older-compiler path.

Qualify emitted ESM under Node, not only Bun's more permissive module resolver. Orval's multi-file probe emitted extensionless directory imports; solve this with supported generator configuration or deterministic generation-time module-specifier handling covered by freshness checks. Authored source uses explicit `.js` imports. Never ship output that passes Bundler resolution but cannot load in the promised Node runtime. No declaration bundling plugin is required.

Provide package scripts for schema validation, generation, freshness, typecheck, tests, emission/build, lint, format, and format-check, with corresponding `just` tasks `install`, `validate-schema`, `generate`, `generated-check`, `typecheck`, `test`, `build`, `lint`, `format`, `format-check`, and `check`. Validate the schema before generation. `generated-check` validates and invokes `--outdated`, never regenerating first. `check` runs freshness before any build that could repair output. If a registry/import-normalization helper follows Orval, its read-only comparison is part of freshness too; skip no generated files. Exclude generated files from independent Oxc rewrites and check only authored formatting. Never configure hooks/formatting that make `--outdated` inapplicable and then bypass freshness.

Run generated operations against a loopback Bun server on an allocated port and close it in `finally`. Prove URL/path/query/header/body serialization, success/error typing and decoding, invalid response rejection, and isolation between two client configurations. Exercise encoded path values and query array/object styles present in the fixture rather than assuming template interpolation is correct. Include negative compiler assertions, each required to fail if its expected error disappears.

Build and pack with `npm pack --ignore-scripts` into a temporary consumer. Import by package name under Node and Bun, compile positive/negative consumer examples with shared TypeScript 7.0.2, and execute a typed request. Public declarations must require neither Bun types nor generator dependencies. Repeat with a schema change and deterministic regeneration. Print `OpenAPI client bootstrap passed.` after the complete harness succeeds.

### Milestone 4: Publish catalog metadata and durable documentation

Update `seihou-registry.dhall`, `mori.dhall`, `README.md`, and the new module README with matching dependency relationships and versions. Explain supported schema behavior, task commands, project ownership, TypeScript 7+ support, permitted private generator API dependencies, named operations, validation errors, and packaging. Explicitly distinguish source-schema linting from payload validation, and document unsupported schema/media features as diagnosed limitations.

Extend the harness to default YAML and nested JSON/local references, both OpenAPI versions, invalid schema/path inputs, missing/stale output, edited/deleted seeds, repeated updates/force/removal, an unmanaged extension, and independent package consumption. Removing the client preserves seeds and generated project artifacts and keeps a base still required by another module. Use actual CLI previews/operations and inspect current help before choosing update/removal flags.

Run the existing Bun/Fumadocs regressions after the base change, synchronize registry versions, and regenerate `okf-docs/`. Inspect incidental registry drift instead of releasing unrelated changes. Distill the managed Bun import seam and client correctness/ownership contract into ordinary Markdown ADRs at completion, updating ADR 3 where appropriate. Keep provisional findings in this plan until they become accepted architecture.


## Concrete Steps

Use the repository root, `/Users/shinzui/Keikaku/bokuno/seihou-modules` on the planning machine. Required tools are Git, Mori, Python 3, Bun, Nix with flakes, the shared TypeScript 7.0.2 compiler, Node >=22.18.0, and Seihou >=0.11.0.0. Upgrade an older Seihou through the repository's normal installation process before seed acceptance. Copy the existing published seed-capable schema pin/hash from `modules/haskell/haskell-library/module.dhall`. Never traverse the filesystem root or `/nix/store` for sources.

Discover dependencies before guessing APIs. Current replacement projects are absent from Mori, so inspect their authoritative sources when lookup has no match:

```bash
seihou --version
tsc --version
mori registry search orval
mori registry search zod
mori registry search openapi
mori path mori://tan/mls-service-v2-ts-client/packages/mls-service-v2-ts-client
npm view orval@8.46.0 version engines dependencies peerDependencies --json
npm view zod@4.6.7 version --json
npm view @redocly/cli@2.72.1 version engines --json
git ls-remote --tags https://github.com/orval-labs/orval.git 'refs/tags/v8.46.0'
git ls-remote --tags https://github.com/colinhacks/zod.git 'refs/tags/v4.6.7'
git ls-remote --tags https://github.com/Redocly/redocly-cli.git 'refs/tags/@redocly/cli@2.72.1*'
```

Recheck current registry releases before selecting newer pins; qualify any intentional update against upstream tags and the fidelity fixture. Existing pins are not permission to use moving `latest` or `next` in generated projects. During milestone 1 the ordinary commands in the temporary fixture are:

```bash
bun install
bun run orval --config orval.config.ts
bun run orval --config orval.config.ts --outdated
tsc --version
```

The final fixture/task runner supplies exact compiler options and checks that PATH selects 7.0.2. The incompatible built-in validation probe is expected to fail its valid-error-response criterion until fixed; do not treat that transcript as acceptance.

After implementing the harness and module, from the repository root run:

```bash
python3 scripts/test-openapi-typescript-client.py --toolchain-only
python3 scripts/test-openapi-typescript-client.py --render-only
python3 scripts/test-openapi-typescript-client.py
seihou validate-module modules/typescript/openapi-typescript-client
seihou validate-module modules/typescript/nix-bun-flake
python3 scripts/test-nix-bun-flake.py
python3 scripts/update-nix-bun-flake.py --check
python3 scripts/test-fumadocs-bootstrap.py
python3 scripts/test-fumadocs-openapi.py
seihou registry sync-versions
seihou registry validate
mori show --full
seihou extension run okf -- docs --dir . --out okf-docs --force
git diff --check
```

All acceptance checks exit zero and the new harness prints its milestone-specific success summaries. Generated docs must show the new module and base versions. For a manual demonstration, create an empty temporary project with copies of both local modules:

```bash
repo_dir="$PWD"
client_demo_dir=$(mktemp -d -t openapi-client-demo)
mkdir -p "$client_demo_dir/.seihou/modules"
cp -R "$repo_dir/modules/typescript/nix-bun-flake" "$client_demo_dir/.seihou/modules/nix-bun-flake"
cp -R "$repo_dir/modules/typescript/openapi-typescript-client" "$client_demo_dir/.seihou/modules/openapi-typescript-client"
cd "$client_demo_dir"
seihou run openapi-typescript-client --no-save-prompted --no-commands \
  --var project.name=example-api-client \
  --var 'project.description=Example typed API client'
nix develop --command just install
nix develop --command just generate
nix develop --command just check
nix develop --command just build
nix develop --command npm pack --ignore-scripts
```

The package contains loadable ESM, declarations, validators, and declared runtime dependencies. Edit the schema without regenerating: `nix develop --command just generated-check` must fail without changing output. Regenerate and the same check passes. A custom input is selected on initial creation with `--var openapi.schema=spec/api.json`; supply that local file before generation. Developer-facing README examples must show a valid named operation call and explicit status narrowing.


## Validation and Acceptance

The first release is gated by schema fidelity and transport behavior, not a compilation-only smoke test. The primary 3.0/3.1 fixtures must pass all required/optional/nullability, union/composition, object openness, directional-property, local-reference, and status-specific cases. TypeScript positive/negative assertions must remain strict under 7.0.2. Compare supported validator semantics against the source schema, including deliberately invalid counterexamples; unsupported semantics require diagnostics instead of silent widening. This is a defined supported subset, not a guarantee of arbitrary OpenAPI/JSON Schema equivalence.

Valid 200 and 404 JSON responses both succeed with their own validators; malformed bodies of either status are rejected before typed data reaches the caller. Undeclared statuses, invalid JSON, empty responses, and content-type selection have explicit tested behavior. Custom transport injection preserves validation and per-client configuration. Test the valid-404 case that failed the research probe as a regression. Primitive/array and error validation must not disappear behind the built-in client's documented bypasses. Avoid numeric/date coercion that accepts a payload of the wrong wire type.

Project compilation, declaration emission, and independent consumers use the Nix TypeScript 7+ compiler. Report its actual path/version at each boundary and prove a selected compiler below 7 is rejected. Private TypeScript 6.0.3 under Orval's generator graph is allowed by the user; it must not become the supported project compiler, leak into public declarations, or become a client runtime requirement.

Freshness checks detect missing/stale files and never repair them. Package checks verify actual Node/Bun imports by package name and strict consumer typing, including invalid-call rejection. Generated multi-file ESM imports resolve in Node. HTTP tests verify serialization and runtime validation, not simply generated text snapshots. The status envelope and validator output agree with public types.

Real Seihou generation preserves the canonical lock and unmanaged extension. Edited/deleted starters remain project-owned through ordinary updates and forced reruns, including base-overlapping paths. Generated sources, consumer locks, and build artifacts are never module-owned and survive client removal. Evaluate all three supported shell systems and record native execution only where actually run. Existing Bun/Fumadocs checks remain passing.


## Idempotence and Recovery

Use temporary project-local module copies and consumers for automated checks. Installation and generation are explicit commands, not Nix shell hooks or module side effects. A fixture lock is separate from the consuming project's own `bun.lock`; frozen installation is demonstrated after the project creates its lock. Apply any needed Bun release-age override only to the temporary invocation, never global settings.

`generated-check`, compiler checks, and style checks do not mutate source. Regeneration only changes `src/generated/` and any explicitly declared generated registry artifact; preserve project transport/facade code. If cleanup is needed, restrict it to owned generated output or `dist/`, with source inputs loaded before cleaning. Keep generated files out of unrelated formatter rewrites. Tests close local servers in `finally` and allocate free ports.

Do not edit manifests to invent ownership acceptance or force copies over authored conflicts. Revert only this work when abandoning a prototype, preserving unrelated changes. Implementation commits use Conventional Commits and include `ExecPlan: docs/plans/11-add-a-bun-based-openapi-typescript-client-module.md`. No Intention trailer is active because the user selected Skip. Triage implementation friction and distill accepted durable decisions into ADRs at completion.


## Interfaces and Dependencies

The module is `modules/typescript/openapi-typescript-client/` with `module.dhall`, `README.md`, and the described `files/` templates. It depends on base 0.5.0 prepared here, binding optional `nix.package-module` to `nix/openapi-typescript-client.nix`. Share `project.name` and `project.description`; accept a validated local `openapi.schema`, default `openapi.yaml`. Generate source/validators under `src/generated/`.

Baseline dependencies are Orval 8.46.0 (development generator), Redocly CLI 2.72.1 (development schema validator), Zod 4.6.7 (runtime payload validation), and `@types/bun` 1.4.2 (development tests). The shared environment supplies Bun, Oxc, TypeScript 7.0.2, and a Node 22 runtime satisfying Orval's engine. Orval's private TypeScript 6 API dependencies are explicitly allowed. Do not downgrade or replace the base compiler and canonical lock to accommodate them.

The source facade provides `make(options)` with a required base URL and optional injected fetch/default headers, and exports its inferred `Api` type plus generated operation/model types. Each returned instance exposes schema-derived named operations; callers narrow the response by literal HTTP status. The operation surface is generated rather than a handwritten list. `make` must delegate to the factory/adapter qualified in milestone 1, whose precise configuration and registry-generation contract must be recorded here before template expansion. The transport fix is currently an open qualification item; do not represent the basic research probe as a complete client implementation.

Seihou >=0.11.0.0 is a prerequisite for seed ownership. Its owner is `mori://shinzui/seihou`; the descriptor schema owner is `mori://shinzui/seihou-schema/packages/seihou-schema`. Use the existing library scaffold's published schema hash. This plan has no parent MasterPlan and no prerequisite feature plan.

Revision note (2026-11-01): Replaced the original generator stack with proposed Orval after maintenance research and the user's preference. Prioritized type/schema fidelity and runtime response correctness; retained the observed valid-404 failure as an explicit qualification gate. The user clarified that private generator TypeScript 6 dependencies are allowed while project builds and consumers support TypeScript 7+ only. Earlier proposed legacy project compiler fallbacks and a blanket ban on private older APIs are superseded.
