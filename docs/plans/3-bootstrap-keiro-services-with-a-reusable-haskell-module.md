---
id: 3
slug: bootstrap-keiro-services-with-a-reusable-haskell-module
title: "Bootstrap Keiro services with a reusable Haskell module"
kind: exec-plan
created_at: 2026-09-07T19:52:13Z
---

# Bootstrap Keiro services with a reusable Haskell module

## Purpose / Big Picture

Create `haskell-keiro-project`, a deterministic Seihou module that supplies the six-package Cabal workspace and Nix development environment. The existing `haskell-keiro-service` agent blueprint will consume it and implement the domain using current runtime patterns. Running the module alone produces a compilable starting structure and a project-specific implementation brief, not a functioning backend.

## Progress

- [x] (2026-09-07) Inspect module composition, the existing blueprint, Jinmyaku, and current runtime standards through Mori.
- [x] (2026-09-07) Implement the module and integrate blueprint version 0.3.0.
- [x] (2026-09-07) Validate descriptors, render two configurations, test rerun/edit protection and database recipes, and build all six libraries under GHC 9.12.4.
- [x] (2026-09-07) Document usage and record the ownership decision in docs/adr/2-separate-keiro-project-seeds-from-domain-implementation.md.

## Surprises & Discoveries

Cabal check rejected the existing CLI module's `../LICENSE` convention when reused. Each new package now receives a local license file so all six pass distribution checks. The default PATH has GHC 9.10.3 and an older DSL that rejects `--min-language`; the generated Nix shell supplied GHC 9.12.4, and the reference project's project-local DSL accepted the Language 5 workspace. Hackage and upstream tags confirmed keiro-dsl 0.15.0.0 as the current release during this work. The initial Prelude produced a redundant-import warning; NoImplicitPrelude makes its explicit base re-export warning-free.

The blueprint already exists, but has no reusable package scaffold and uses an old bare-source workflow. Current standards default to a workspace manifest and generated conformance package. The Nix module defaults to a root `callCabal2nix` package, which cannot represent six child packages; disable `nix.builtin-package` in the new module.

## Decision Log

On 2026-09-07, choose a distinct module name (`haskell-keiro-project`) to avoid colliding with the existing blueprint in Seihou discovery. Keep domain-specific implementation in the blueprint and generated brief. Seed minimal libraries without pretending that placeholder server or migration executables implement production behavior. Runtime dependencies and DSL tool releases must be verified at implementation time, not copied from the older reference cohort.

## Outcomes & Retrospective

Delivered the module, generated implementation brief, blueprint integration, registry/Mori entries, catalog docs, and ADR. Module lint and registry validation pass. The smoke script passes for two distinct names, namespaces, and contexts, including all twelve Cabal package checks, blueprint prompt rendering without contacting an agent, mocked database creation/no-op behavior, byte-stable reruns, and preservation of hand edits. `nix develop --command cabal build all` built all six initial libraries with GHC 9.12.4. The workspace seed passed a Language 5 check using the reference project's local DSL executable. These are scaffold checks; no generated business service or production runtime is claimed.

## Context and Orientation

`modules/haskell/nix-haskell-flake/module.dhall` owns the shared development environment. `modules/haskell/haskell-cli-app/module.dhall` demonstrates variable prompts, dependencies, and template steps. `blueprints/haskell-keiro-service/blueprint.dhall` describes the existing agent prompt and reference files. `seihou-registry.dhall` indexes runnable artifacts; `mori.dhall` exposes templates to Mori. No relevant existing local ADR was found (the current ADR concerns Redis sockets).

The reference project is `mori://shinzui/jinmyaku`; inspect its `cabal.project`, `justfile`, and `domain/jinmyaku.keiro-workspace` (artifact-level URIs pending). Normative references are `mori://shinzui/keiro-runtime-patterns/docs/architecture-service-packages`, `mori://shinzui/keiro-runtime-patterns/docs/keiro-service-workspaces`, and `mori://shinzui/keiro-runtime-patterns/docs/architecture-generated-compilation-contract`. Six packages separate domain/core, HTTP types/api, execution/server, workers, migrations, and client. Migrations have no sibling library dependency; workers do not depend on HTTP packages. A workspace is a manifest composing independently owned DSL source members into one service contract.

## Plan of Work

Milestone one adds `modules/haskell/haskell-keiro-project/module.dhall`, templates under its `files/`, and a README. Prompt for project name, namespace, synopsis, context, author, maintainer, copyright year, and index state. Generate six minimal library packages, a custom core prelude, a workspace manifest with a shared member, a justfile, license, README, and `docs/bootstrap-keiro.md`. Compose the existing Nix module with PostgreSQL/process-compose enabled and its root package build disabled. Validate the module descriptor.

Milestone two changes the blueprint base module and prompt to extend the generated structure. Replace obsolete pinned workflow instructions with release verification and workspace-first instructions; preserve runtime invariants. Update registry metadata and the standards map with canonical references. Validate the blueprint.

Milestone three exercises the actual Seihou CLI in temporary directories with project-local module copies. Generate different names and namespaces, validate Cabal files and just recipes, repeat generation, and check conflict protection after an intentional edit. Build all six libraries using the available GHC toolchain. Record any environmental limits accurately. Add a durable ADR explaining scaffold versus domain ownership.

## Concrete Steps

Run from this repository root:

```bash
seihou validate-module modules/haskell/haskell-keiro-project --lint
python3 scripts/check-keiro-bootstrap.py
git diff --check
```

The standalone blueprint validator needs the new base module in its search path; the smoke script validates it with isolated project-local copies. The smoke script creates a temporary project, copies local modules into `.seihou/modules`, supplies variables noninteractively, and runs Seihou. Success means rendered files contain the selected identifiers, package dependency boundaries hold, a second run changes no generated content, and edits are protected. It prints its temporary path for inspecting/building the generated project.

## Validation and Acceptance

A fresh `sample-service` / `SampleService` scaffold contains exactly six application Cabal packages and optional discovery of a future generated conformance package. The Nix environment includes PostgreSQL and process-compose; it does not emit a broken default root package. The justfile includes the `create-database` recipe expected by process-compose, and all DSL recipes target one workspace. Module and blueprint validation pass. `cabal build all` builds the initial libraries; domain implementation and runtime tests remain the explicitly documented responsibility of the bootstrap prompt.

## Idempotence and Recovery

Use temporary directories for acceptance. Do not run this bootstrap module with `--force` on an implemented service. Seihou records generated files and protects later hand edits as conflicts. Nix remains independently updatable. No domain-specific generated Haskell is owned by this module; Keiro scaffolding owns its generated ring and preserves create-once files. No target reference project is changed.

## Interfaces and Dependencies

Use existing Seihou Dhall types and template interpolation, preserving the established pinned schema imports. Dependency discovery used `mori://shinzui/seihou/packages/seihou-core` and `mori://shinzui/seihou-schema/packages/seihou-schema`. The initial core prelude re-exports base and Control.Lens; lens 5.3.6 was verified against Hackage and upstream v5.3.6, permitting the existing 5.3 series bound. Do not pin a runtime cohort in minimal placeholder libraries. The implementation prompt must verify Hackage and upstream tags, select a coherent index-state, and reconcile the complete generated Cabal fragment before building the real service.

## Validation evidence

```text
PASS sample-service: six packages, workspace, Nix composition, just recipes, rerun, edit protection
PASS other: six packages, workspace, Nix composition, just recipes, rerun, edit protection
PASS registry and Mori descriptors
OK: 7 modules, 2 recipes, 3 blueprints, 0 prompts, all versions in sync.
Build profile: -w ghc-9.12.4 -O1
```

For build reproduction, use either build fixture printed by the smoke script and run `nix develop --command cabal build all` there. The build performed here used the sample-service fixture, then rebuilt after correcting its Prelude template. No Nix store paths were traversed or read directly. The seed check used the executable under `.bin/keiro-dsl` in `mori://shinzui/jinmyaku` (artifact-level URI pending); it printed `OK` with `--min-language 5 --deny-warnings`.

Revision 2026-09-07: completed implementation and acceptance, recorded distribution and toolchain findings, and distilled ownership into the new ADR. No intention was linked; the optional prompt received no ID.
