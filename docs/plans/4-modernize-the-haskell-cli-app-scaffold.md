---
id: 4
slug: modernize-the-haskell-cli-app-scaffold
title: "Modernize the Haskell CLI App Scaffold"
kind: exec-plan
created_at: 2026-09-20T23:31:53Z
---

# Modernize the Haskell CLI App Scaffold

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.


## Purpose / Big Picture

After this change, applying `haskell-cli-app` creates a real two-package Haskell workspace that
builds, tests, formats, and packages cleanly with the current `nix-haskell-flake`. The generated
CLI calls reusable logic from the generated core package, `nix build` produces the executable,
`nix flake check` runs its test suite, and both the default GHC 9.12.4 shell and the supported
GHC 9.14.1 secondary shell compile and test the project. A user can demonstrate the result by
running the generated executable's `hello` command and by observing successful Cabal and Nix
checks rather than the current root-`callCabal2nix` failure.

The modernization also removes stale and misleading output: each Cabal package gets valid local
license and changelog files, dependency bounds match the current released libraries, the CLI no
longer declares unused lens dependencies, the formatter has a single owning module, and Seihou,
Mori, registry, recipe, and generated OKF documentation all report the same module version and
file layout.


## Progress

- [x] (2026-09-20 16:31 PDT) Audit the 0.2.0 scaffold against `nix-haskell-flake` 0.24.0, GHC
  9.12.4, GHC 9.14.1, Cabal checks, Hackage releases, and current in-repository CLI projects.
- [x] (2026-09-20 16:39 PDT) Create this ExecPlan, scan the local ADR corpus, and record the
  implementation decisions and validation contract.
- [x] (2026-09-20 16:52 PDT) Implement the 0.3.0 module templates, package metadata, real
  core-to-CLI behavior, tests, multi-package Nix build module, dependency bindings, and single
  formatter ownership; add the managed package-module seam in `nix-haskell-flake` 0.25.0.
- [x] (2026-09-20 16:55 PDT) Render a fresh project and prove Cabal test/check/sdist,
  executable behavior, explicit Nix package builds and full flake checks, formatter cleanliness,
  GHC 9.12.4 and GHC 9.14.1 builds, and absence of unused-package warnings.
- [x] (2026-09-20 16:53 PDT) Exercise a real local 0.2.0-to-0.3.0 Seihou update. No destructive
  file migration is needed; reconfiguration supplies the new dependency bindings and defaulted
  variables, transfers `fourmolu.yaml` ownership, and leaves all 25 resulting files unchanged.
- [x] (2026-09-20 17:03 PDT) Synchronize module, registry, Mori, recipe, root catalog, and
  generated OKF documentation; validate the registry and inspect the final diff.
- [x] (2026-09-20 17:10 PDT) Record ADR 3 for the managed package-module seam, complete this
  plan's outcomes, and commit the implementation and documentation milestones with ExecPlan
  trailers.


## Surprises & Discoveries

- Observation: a project freshly rendered from `haskell-cli-app` 0.2.0 plus the current
  `nix-haskell-flake` 0.24.0 builds through Cabal but `nix build .#default` fails before package
  evaluation.
  Evidence: `cabal2nix: user error (*** Found neither a .cabal file nor package.yaml. Exiting.)`
  because `nix/haskell.nix` points `callCabal2nix` at the repository root while the two `.cabal`
  files live in child directories.
- Observation: `cabal check` rejects both generated packages for distribution portability even
  though `cabal sdist all` writes tarballs.
  Evidence: both packages report `relative-path-outside` and `malformed-relative-path` for
  `../LICENSE` and `../CHANGELOG.md`, ending with `Error: Hackage would reject this package.`
- Observation: the advertised package boundary is not exercised by the starter program.
  Evidence: rebuilding with `-Wunused-packages` reports `text` unused by the core package and
  the core package, `generic-lens`, and `lens` unused by the CLI package.
- Observation: the latest pinned `haskell-nix-dev` already supports `ghc9141` even though the
  `nix-haskell-flake` interactive primary-GHC choice lists only `ghc9124`.
  Evidence: a rendered project with `ghc.secondary=ghc9141` successfully completed
  `cabal build all` under GHC 9.14.1; the base flake's `supportedGhcs` is
  `[ "ghc9124" "ghc9141" ]`.
- Observation: no existing ADR governs the generic Haskell CLI scaffold. The two local ADRs
  concern Redis development sockets and separation of Keiro project seeds from domain
  implementation, so neither constrains this work.
- Observation: the base module's canonical lock was a superset of conditional inputs, so a first
  Nix command pruned disabled `haskell-nix` and Redpanda nodes and modified a file described as
  deterministic and managed.
  Evidence: the first generated project emitted a lock update removing the entire `haskell-nix`
  subtree. After making module-owned inputs unconditional, `nix flake lock` preserves SHA-256
  `bfa08ebe5903ceeb1cd5e820cca40167906b74f8de602f99f0764bdb7b231cce` for both the default and
  all-feature-disabled renders.
- Observation: the generated `cabal.project`, core prelude, new core module, CLI source, and test
  source needed formatter normalization.
  Evidence: an initial `nix fmt -- --ci .` changed six managed source/config files; a fresh render
  after template corrections reports 13 files formatted with zero changes.
- Observation: Seihou's local-origin upgrade fixture required `--reconfigure` after the dependency
  edge gained three bindings; the non-interactive test also required `--json` to accept the plan.
  Evidence: a plain local `seihou update --dry-run` reported missing dependency variables, while
  `seihou update --reconfigure --force --json ...` applied 0.2.0 -> 0.3.0 with seven files created,
  nine updated, zero conflicts, and formatter ownership transferred to `nix-haskell-flake`.
- Observation: formatter cleanliness initially depended on the generated project name and
  namespace. A-leading names happened to place local imports/dependencies where Fourmolu and
  cabal-gild wanted them, while R-leading names were rewritten.
  Evidence: `audit-cli` formatted cleanly while a fresh `readme-cli` render changed three files.
  Separating variable Cabal dependencies into repeated (Cabal-valid) `build-depends` fields and
  setting Fourmolu `import-grouping: preserve` made both fresh renders report zero changes; the
  final Nix flake check rebuilt and tested the R-leading fixture successfully.
- Observation: making `haskell-nix` an unconditional module-owned input left the historical
  `nix.haskell-nix` toggle without an effect.
  Evidence: source search found no remaining template condition using the variable. It is now an
  optional, deprecated compatibility input with no prompt so saved configurations still update
  without implying that new projects must enable the already-available input.


## Decision Log

- Decision: retain the two-package shape instead of collapsing the scaffold into one package.
  Rationale: the module's public purpose is a reusable core plus a thin CLI. The defect is that
  the generated example does not honor the boundary, so the core will gain a small public
  greeting function and the CLI will call it.
  Date: 2026-09-20
- Decision: consume `nix-haskell-flake` 0.25.0 through the existing dependency name, bind
  `nix.builtin-package=false`, and bind `ghc.secondary=ghc9141` while retaining `ghc9124` as the
  primary editor shell.
  Rationale: the generic root package output cannot build a Cabal workspace. GHC 9.14.1 is the
  latest stable compiler supported by the pinned base flake but currently has no HLS there, so
  making it secondary provides current-compiler validation without degrading the default editor
  experience. CLI and config overrides remain higher priority than dependency bindings.
  Date: 2026-09-20
- Decision: keep every module-owned flake input in the generated `inputs` set regardless of
  feature toggles; toggles control generated files and imports rather than lock membership.
  Rationale: the shipped lock already carries the full graph, and unused inputs are neither
  evaluated nor built. Unconditional membership makes the advertised canonical lock exact for
  every configuration and prevents the first Nix command from dirtying generated projects.
  Date: 2026-09-20
- Decision: add an optional `nix.package-module` import seam to `nix-haskell-flake` 0.25.0 and let
  `haskell-cli-app` generate `nix/haskell-cli-app.nix` through that seam.
  Rationale: the latest base module intentionally disables its single-root output when
  `nix.builtin-package=false`. A working scaffold must provide the package-specific replacement,
  but generating `flake.module.nix` would take over the base module's deliberately unmanaged user
  extension point. A separate managed import lets composed modules own build wiring while users
  retain conflict-free `flake.module.nix` customizations.
  Date: 2026-09-20
- Decision: add a default-on Tasty test suite in the CLI package and expose parser data plus
  `parserInfo` for pure `execParserPure` tests.
  Rationale: this proves both the package boundary and argument parsing without invoking process
  global `argv`, while preserving `runCli :: IO ()` as the executable entry point.
  Date: 2026-09-20
- Decision: copy `LICENSE` and `CHANGELOG.md` into each package directory as well as keeping the
  repository-level copies.
  Rationale: Cabal package source distributions cannot portably reference parent paths. Local
  copies make each package independently checkable and distributable without changing the
  workspace layout.
  Date: 2026-09-20
- Decision: remove the CLI module's `fourmolu.yaml` step and leave ownership with
  `nix-haskell-flake`.
  Rationale: both sources are byte-identical today, and duplicate ownership produces a Seihou
  overwrite warning. The environment module already owns formatter installation and config.
  Date: 2026-09-20
- Decision: record an ADR for the managed package-module seam during the documentation milestone.
  Rationale: preserving `flake.module.nix` as an unmanaged user extension while allowing composed
  Seihou modules to own package outputs is now a durable cross-module contract, not merely an
  internal CLI implementation detail.
  Date: 2026-09-20
- Decision: preserve explicit Haskell import groups in the shared formatter configuration and
  isolate generated internal Cabal dependencies from alphabetically sorted external dependencies.
  Rationale: template placeholders cannot choose a fixed position that is sorted for every valid
  project name or namespace. Stable groups make formatting idempotent without weakening dependency
  bounds or requiring a post-generation formatter mutation.
  Date: 2026-09-20


## Outcomes & Retrospective

`haskell-cli-app` 0.3.0 now produces the two-package project it previously described but did not
actually exercise. The generated CLI calls its core package, exports a pure parser, and ships a
default-on three-case Tasty suite. Both Cabal packages pass `cabal check`, their source archives
contain package-local `LICENSE` and `CHANGELOG.md` files with no parent traversal, and the declared
dependencies are bounded to verified releases without unused-package warnings.

`nix-haskell-flake` 0.25.0 supplies the missing composition seam. The CLI module owns a managed
workspace package module while `flake.module.nix` remains user-owned, as recorded by
[ADR 3](../adr/3-separate-managed-scaffold-nix-wiring-from-user-extensions.md). The default Nix
package now builds the executable, both named package outputs evaluate/build, and `nix flake check`
runs the suite plus treefmt and pre-commit. Module-owned inputs are unconditional and the canonical
lock remains SHA-256 `bfa08ebe5903ceeb1cd5e820cca40167906b74f8de602f99f0764bdb7b231cce`
under default and feature-disabled configurations. The obsolete `nix.haskell-nix` toggle remains
only as a non-prompted compatibility input.

Fresh A-leading and R-leading fixtures both report zero formatter changes, avoiding the earlier
name-dependent import/dependency ordering. The final fixture passes under GHC 9.12.4 through the
full Nix check and under GHC 9.14.1 through the secondary shell. A real local 0.2.0 project updated
to 0.3.0 with `--reconfigure`, adding seven files and updating nine with zero conflicts; no
destructive migration operation was needed, and shared formatter ownership transferred cleanly.

The registry reports seven modules, two recipes, and three blueprints with every version in sync.
Mori resolves the CLI and Nix templates as 0.3.0 and 0.25.0, respectively, and the regenerated OKF
bundle exposes the new variables, dependency bindings, and generation steps. The modernization
also corrected the stale root catalog, stale Mori CLI version, duplicate formatter ownership,
invalid Cabal metadata paths, missing tests, broken root Nix build, unstable generated formatting,
and first-run lock rewrites found during the audit.


## Context and Orientation

This repository is a Seihou registry. A Seihou module is a Dhall declaration that lists variables,
dependencies, and file-generation steps. `modules/haskell/haskell-cli-app/module.dhall` is the
authoritative 0.2.0 declaration. Its templates live under
`modules/haskell/haskell-cli-app/files/`; applying the module currently produces a repository-level
`cabal.project`, one `-core` library package, one `-cli` library-plus-executable package, and common
metadata. `recipes/haskell-cli-app-repo/recipe.dhall` combines it with `git-init` but owns no
generation logic.

The module depends on `modules/haskell/nix-haskell-flake/module.dhall`, currently version 0.24.0.
That dependency generates the flake-parts shell in `flake.nix` and `nix/*.nix`. Its Boolean
`nix.builtin-package` defaults to true and emits a single
`callCabal2nix project.name inputs.self` expression, which only works when a `.cabal` file exists
at the repository root. Its optional `ghc.secondary` adds a second named shell. Dependency-edge
bindings act as low-priority values: an explicit CLI or saved config value can override them.

`seihou-registry.dhall` publishes artifact versions to Seihou. `mori.dhall` publishes the same
module as `mori://shinzui/seihou-modules/templates/haskell-cli-app`; it is currently stale at
0.1.0. The human module documentation is
`modules/haskell/haskell-cli-app/README.md`, while `okf-docs/` is generated and must only be
updated through `seihou extension run okf -- docs`.

The local ADR corpus uses simple Markdown files under `docs/adr/` and is not a profiled OKF bundle.
[ADR 1](../adr/1-use-project-local-sockets-for-redis-development-services.md) governs Redis socket
isolation in `nix-haskell-flake`, and
[ADR 2](../adr/2-separate-keiro-project-seeds-from-domain-implementation.md) governs the Keiro
service seed. Neither record addresses generic CLI package layout, Cabal distribution metadata,
or multi-package Nix outputs.


## Plan of Work

Milestone 1 replaces the broken starter internals while preserving its public two-package shape.
Update `nix-haskell-flake` to 0.25.0 with an optional managed package-module import, then update
the CLI `module.dhall` to version 0.3.0 and bind the Nix module for a workspace build and the
GHC 9.14.1 secondary shell, add category and test variables, remove duplicate formatter ownership,
and generate all new source, test, package-local metadata, and Nix files. Update `core.cabal.tpl`
and `cli.cabal.tpl` with PVP-style upper bounds, local metadata paths, a category, the real
inter-package dependency, and a default-on test suite. Add a root core module exporting
`greet :: Maybe Text -> Text`; simplify `Cli.hs.tpl` to call it; expose `Command`, `Options`, and
`parserInfo`; and add a Tasty test driver that verifies default and explicit greeting subjects plus
pure argument parsing. Add `nix/haskell-cli-app.nix.tpl` that recursively defines the two local packages
in the selected GHC package set, exposes both package outputs, chooses the CLI package as default,
and runs its tests as a flake check. This milestone is accepted when a direct template render has
the intended files and `seihou validate-module` succeeds.

Milestone 2 proves the generated artifact rather than only validating Dhall. Render a fresh project
with `seihou run haskell-cli-app`, then run Cabal build, tests, package checks, source distributions,
and the executable under GHC 9.12.4. Rebuild with `-Wunused-packages` and require no unused package
diagnostics. Run the tests under GHC 9.14.1. Run `nix build .#default`, both named package outputs,
`nix flake check`, and the formatter check. Inspect source-distribution members to ensure they stay
inside their package roots. Then simulate or exercise an upgrade from 0.2.0 and record whether
ordinary Seihou conflict handling is sufficient or a migration operation is required.

Milestone 3 synchronizes every public description. Update module and recipe READMEs, the root
catalog, `mori.dhall`, and any recipe file inventories. Run `seihou registry sync-versions`, validate
the registry, regenerate `okf-docs/`, and run the repository's available checks. Finish by reviewing
the diff, performing ADR distillation, completing this plan, and committing with conventional
messages carrying `ExecPlan: docs/plans/4-modernize-the-haskell-cli-app-scaffold.md` trailers.


## Concrete Steps

Run all commands from `/Users/shinzui/Keikaku/bokuno/seihou-modules` unless another directory is
stated. Edit tracked files only through `apply_patch`.

First validate the declaration after the Milestone 1 edits:

```bash
seihou validate-module modules/haskell/haskell-cli-app
```

The command must end with `Module 'haskell-cli-app' is valid.` and list every new template source
as present.

Create a throwaway directory with `mktemp -d`, render the project using the working-tree artifact,
and supply deterministic variables. If Seihou's installed cache cannot consume the working tree
directly, install the checkout into an isolated temporary Seihou configuration or render through a
temporary registry clone; do not replace the user's persistent installed module silently. The
render must show `nix-haskell-flake` 0.25.0 and `haskell-cli-app` 0.3.0, no warning that
`fourmolu.yaml` was overwritten, `nix.builtin-package=false`, and `ghc.secondary=ghc9141`.

In the generated project run:

```bash
nix develop .#ghc9124 --command cabal build all
nix develop .#ghc9124 --command cabal test all
nix develop .#ghc9124 --command cabal build all --ghc-option=-Wunused-packages
nix develop .#ghc9141 --command cabal test all
nix develop .#ghc9124 --command cabal sdist all
nix build .#default --no-link
nix build .#audit-cli-core --no-link
nix build .#audit-cli-cli --no-link
nix flake check
nix fmt -- --ci .
nix develop .#ghc9124 --command cabal run audit-cli -- hello --name world
```

The last command must print `Hello, world!`. Run `cabal check` from each package directory; neither
invocation may say Hackage would reject the package. Inspect both source tarballs with `tar -tzf`;
no member may contain a `/../` component.

After documentation edits run:

```bash
seihou registry sync-versions
seihou registry validate
seihou extension run okf -- docs --dir . --out okf-docs --force
git diff --check
git status --short
```

The registry must report all versions synchronized, generated docs must advertise 0.3.0, and
`git diff --check` must produce no output.


## Validation and Acceptance

Acceptance requires observable success from a newly generated project, not merely template
inspection. `seihou run` must complete without duplicate destination warnings. `cabal test all`
must run the generated tests and report all passing. The same source must compile under GHC 9.12.4
and GHC 9.14.1. `cabal check` must no longer reject either package, `cabal sdist all` must create
two self-contained archives, and the unused-package build must not name any redundant dependency.

The Nix acceptance gate is that `nix build .#default`, `.#<name>-core`, and `.#<name>-cli` all build
instead of reporting that the repository root has no `.cabal` file. `nix flake check` must execute
the CLI test suite, and the generated executable must print exactly `Hello, world!` for
`hello --name world` and use the project name when `--name` is omitted.

Repository acceptance requires module validation, synchronized registry versions, regenerated OKF
documentation, accurate Mori metadata, no stale 0.2.0 claims in the CLI module documentation, and
a clean whitespace check. Any failure caused by unrelated pre-existing repository state must be
recorded with evidence rather than hidden.


## Idempotence and Recovery

All generation and validation commands are safe to repeat. Use a newly created `/tmp` directory for
each end-to-end render so failed builds cannot contaminate later evidence. Cabal and Nix may leave
build caches inside that temporary directory; they can be left for the operating system's temporary
file cleanup rather than recursively deleting an ambiguous path.

Seihou's manifest protects hand-edited generated files. A 0.2.0 consumer may already contain a
user-authored `flake.module.nix`; the 0.3.0 module must leave it untouched and install its workspace
build under `nix/haskell-cli-app.nix` instead. If testing proves a migration is needed, add only
operations whose targets are exact and recoverable; never delete a user's existing custom Nix
module. Removing `fourmolu.yaml` from the CLI module must transfer fresh-project ownership to
`nix-haskell-flake` without deleting the physical file.

If a milestone fails, inspect the generated files and command output, patch the source templates,
create a fresh render, and rerun the milestone. Do not edit the generated test project as the final
fix; changes belong in the templates.


## Interfaces and Dependencies

The generated core module at `<name>-core/src/<Namespace>.hs` must export:

```haskell
greet :: Maybe Text -> Text
```

It returns `Hello, <subject>!`, using the project name when the argument is `Nothing`. The generated
CLI module must export `Command(..)`, `Options(..)`, `parserInfo`, and `runCli`. `runCli` keeps type
`IO ()`; `parserInfo :: ParserInfo Options` is the pure parser description consumed by both
`execParser` and test-side `execParserPure`.

The CLI package depends directly on the core package, `optparse-applicative`, and `text`; it must not
depend directly on `lens` or `generic-lens` unless its source imports those packages. The core
package depends on `generic-lens >=2.2 && <2.4`, `lens ^>=5.3`, and `text ^>=2.1`. The test suite
uses `tasty ^>=1.5`, `tasty-hunit ^>=0.10`, and `optparse-applicative >=0.18 && <0.20`.

The generated `nix/haskell-cli-app.nix` uses the flake-parts `perSystem` interface supplied by
`nix-haskell-flake`. It must build the two local package directories through a recursive override
of `pkgs.haskell.packages."{{ghc.version}}"`, expose `packages.<name>-core`,
`packages.<name>-cli`, and `packages.default`, and expose a `checks.<name>-cli-test` derivation made
with `pkgs.haskell.lib.doCheck`. The dependency edge supplies `nix.builtin-package=false` so this
workspace output does not collide with the base module's single-root output,
`nix.package-module=nix/haskell-cli-app.nix` so the managed file is imported, and
`ghc.secondary=ghc9141` so the second compiler shell exists by default.
