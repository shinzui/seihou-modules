# Create nix-haskell-flake Seihou Module for Haskell Projects

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

This document is maintained in accordance with `.claude/skills/exec-plan/PLANS.md`.


## Purpose / Big Picture

After this work is complete, a user can run `seihou run nix-haskell-flake` and get a fully
working `flake.nix` for a Haskell project, with optional process-compose and PostgreSQL
support. The generated flake will provide a devShell with GHC, cabal-install, HLS, and
formatters, plus optional service orchestration via process-compose and a local PostgreSQL
database — matching the patterns established in `mls-service-v2`.

This is the first module in a composable suite of Seihou modules for bootstrapping
Haskell services and libraries. Future modules (haskell-cabal, haskell-overlay,
treefmt, justfile, envrc, etc.) will compose with this one.


## Progress

- [x] Scaffold the `nix-haskell-flake` module via `seihou new-module` (2026-03-24)
- [x] Define variables in `module.dhall` (project name, description, GHC version, process-compose, postgresql toggles) (2026-03-24)
- [x] Define prompts for interactive use (2026-03-24)
- [x] Write `files/flake.nix.tpl` — the main flake template with conditional sections (2026-03-24)
- [x] Write `files/treefmt.nix.tpl` — treefmt config for Haskell formatting (2026-03-24)
- [x] Write `files/process-compose.yaml.tpl` — conditional process-compose template (2026-03-24)
- [x] Write `files/envrc.tpl` — direnv integration template (2026-03-24)
- [x] Add conditional steps in `module.dhall` for process-compose and postgresql files (2026-03-24)
- [x] Validate module with `seihou validate-module` (2026-03-24)
- [x] Test with dry-run: library mode (no process-compose, no postgresql) — 3 files generated (2026-03-24)
- [x] Test with dry-run: service mode (process-compose + postgresql) — 4 files generated (2026-03-24)
- [x] Iterate and refine based on validation and dry-run results (2026-03-24)


## Surprises & Discoveries

- The `choice` variable type requires special coercion that rejects values passed via `--var`. Switched `ghc.version` to `text` type with `ghc[0-9]+` regex validation instead. The prompt still offers choices for interactive use.
- `seihou run` resolves modules by name from search paths (`.seihou/modules`, `~/.config/seihou/modules`, `~/.config/seihou/installed`), not filesystem paths. Created a symlink in `.seihou/modules/` to make the local module discoverable during development.


## Decision Log

- Decision: Organize modules by ecosystem in subdirectories (`modules/haskell/`, `modules/elixir/`, etc.).
  Rationale: As the module count grows, a flat `modules/` directory becomes hard to navigate. Grouping by ecosystem makes it easy to find related modules.
  Date: 2026-03-24

- Decision: Name the module `nix-haskell-flake` (not `nix-flake`) since the repo will contain other non-Haskell nix modules too.
  Rationale: Clearer naming convention — prefix with the ecosystem (nix-haskell-*) to distinguish from potential nix-elixir-flake, nix-rust-flake, etc.
  Date: 2026-03-24

- Decision: Start with `nix-haskell-flake` as the foundational module rather than splitting into nix-haskell-flake + nix-haskell-devshell.
  Rationale: The flake.nix is inherently coupled to the devShell definition. Splitting would create unnecessary indirection for the common case (Haskell project). The module can be composed with future overlay and cabal modules.
  Date: 2026-03-24

- Decision: Use `process-compose` and `postgresql` as boolean toggle variables rather than separate dependency modules.
  Rationale: These are optional features within the flake itself (devShell packages, shellHook setup). Extracting them as separate modules would over-fragment the flake template. They toggle sections within a single `flake.nix` file.
  Date: 2026-03-24

- Decision: Include `treefmt.nix` as part of this module rather than a separate module.
  Rationale: The flake.nix references treefmt-nix as an input and uses it for formatting checks. The treefmt.nix file is small and tightly coupled to the flake. It can always be extracted later if needed.
  Date: 2026-03-24

- Decision: Include `.envrc` generation as part of this module.
  Rationale: Every nix flake project needs a `.envrc` with `use flake` + `eval "$shellHook"`. This is the minimal direnv integration and belongs with flake bootstrapping.
  Date: 2026-03-24

- Decision: Use `nixpkgs-unstable` as default nixpkgs channel, matching the reference project.
  Rationale: Haskell projects typically need recent GHC versions and package sets. The unstable channel provides these. Users can override via the generated flake if needed.
  Date: 2026-03-24


## Outcomes & Retrospective

All milestones complete. The module validates, and both library-mode and service-mode dry-runs produce the expected file sets. The flake template uses Nix-level `lib.optional` and `lib.optionalString` conditionals controlled by `withProcessCompose` and `withPostgresql` let-bindings, which are templated from the boolean variables. This keeps the generated flake clean regardless of which features are enabled.


## Context and Orientation

### Repository Layout

This work happens in `/Users/shinzui/Keikaku/bokuno/seihou-modules`, a seihou-managed
repository that will contain composable modules. Currently it has:

    .seihou/manifest.json   — tracks installed modules (exec-plan, claude-gitignore, claude-skill-link)
    claude/skills/exec-plan/ — the ExecPlan Claude skill
    .gitignore              — generated by claude-gitignore module

Modules are organized by ecosystem under `modules/`. Haskell modules live in `modules/haskell/`:

    modules/haskell/<name>/
    ├── module.dhall    — module definition (variables, steps, prompts, dependencies)
    └── files/          — template and static files

This keeps the repo navigable as non-Haskell modules (e.g., `modules/elixir/`, `modules/common/`)
are added later.

### Seihou Schema

All `module.dhall` files import the seihou schema package:

    let S =
          https://raw.githubusercontent.com/shinzui/seihou-schema/2b4035b/package.dhall
            sha256:21716b4aee783d8eb8b12c754050880fa710e881ecda85925f855ef34cc34a55

And use record completion: `S.Module::{ name = "...", ... }`.

### Reference Project

The `mls-service-v2` project at `/Users/shinzui/Keikaku/work/microtan/mls-service-v2-master`
serves as the reference for what a mature Haskell service flake looks like. Key characteristics:

- **Inputs**: nixpkgs (unstable), pre-commit-hooks (git-hooks.nix), flake-utils, treefmt-nix
- **GHC**: 9.12.2 via `ghcVersion` variable
- **devShell packages**: zlib, xz, just, cabal-install, process-compose, postgresql, pkg-config, hurl, viddy, ast-grep, rsync, GHC with HLS
- **shellHook**: sets PGHOST, PGDATA, PGLOG, PGDATABASE, PG_CONNECTION_STRING; runs `initdb` if needed
- **treefmt.nix**: enables nixpkgs-fmt, fourmolu, cabal-fmt
- **process-compose.yaml**: orchestrates postgres startup, sanity checks, schema creation
- **.envrc**: `use flake` + `eval "$shellHook"`

### Template Variables to Define

The module needs these configurable variables:

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project.name` | text | (required) | Project name, used in flake description and PGDATABASE |
| `project.description` | text | (required) | One-line project description |
| `ghc.version` | choice | "ghc912" | GHC version identifier (e.g., ghc912, ghc966, ghc984) |
| `nix.process-compose` | bool | false | Include process-compose in devShell and generate process-compose.yaml |
| `nix.postgresql` | bool | false | Include postgresql in devShell, add shellHook for local DB setup |
| `nix.treefmt` | bool | true | Include treefmt-nix input and generate treefmt.nix |
| `nix.pre-commit` | bool | true | Include pre-commit-hooks input and checks |

### Template Syntax

Seihou templates use `\{{variable.name}}` for substitution. Conditional sections within
templates are not natively supported — instead, use separate template files with `when`
conditions on steps, or use the dhall-text strategy for computed output.

Since flake.nix has conditional sections (process-compose, postgresql), the approach will be:

1. A **base flake.nix.tpl** with placeholders for the project name and GHC version
2. Conditional sections handled via **dhall-text** strategy or by having a few flake variants, OR
3. Use **append-section** patch strategy to inject optional sections

The cleanest approach: use a single `flake.nix.tpl` template that includes all sections,
with Nix-level conditionals (using `lib.optionalAttrs` and `lib.optional`) controlled by
a simple boolean pattern. Since this is Nix, the conditionals can live in the generated
Nix code itself — we template the booleans in.


## Plan of Work

### Milestone 1: Scaffold and Define Module

Scaffold the module directory with `seihou new-module nix-haskell-flake`, then replace the
generated `module.dhall` with the full variable and step definitions.

The module will have 7 variables, 7 prompts, and up to 4 steps (flake.nix always,
treefmt.nix conditional, process-compose.yaml conditional, .envrc always).

At the end of this milestone, `seihou validate-module modules/haskell/nix-haskell-flake` passes all checks.

### Milestone 2: Write Template Files

Create the template files in `modules/haskell/nix-haskell-flake/files/`:

1. **flake.nix.tpl** — The main flake. Uses `\{{project.name}}`, `\{{project.description}}`,
   `\{{ghc.version}}`. Includes conditional Nix code for process-compose and postgresql
   controlled by `\{{nix.process-compose}}` and `\{{nix.postgresql}}` booleans embedded
   as Nix `let` bindings, so the generated flake has clean `if` branches.

2. **treefmt.nix.tpl** — Small file enabling nixpkgs-fmt, fourmolu, cabal-fmt.

3. **process-compose.yaml.tpl** — Service orchestration using `\{{project.name}}` for
   the database name. Only generated when `nix.process-compose` is true.

4. **envrc.tpl** — Minimal `.envrc` with `use flake` and `eval "$shellHook"`.

### Milestone 3: Validate and Test

Run `seihou validate-module` to ensure the module is well-formed. Then run dry-runs
with different variable combinations:

- Library mode: `--var nix.process-compose=false --var nix.postgresql=false`
- Service mode: `--var nix.process-compose=true --var nix.postgresql=true`

Verify the generated output looks correct for both scenarios.


## Concrete Steps

All commands run from the repository root: `/Users/shinzui/Keikaku/bokuno/seihou-modules`.

### Milestone 1

    seihou new-module nix-haskell-flake

Expected output: creates `modules/haskell/nix-haskell-flake/module.dhall` and `modules/haskell/nix-haskell-flake/files/`.

Then edit `modules/haskell/nix-haskell-flake/module.dhall` to define all variables, prompts, and steps.

    seihou validate-module modules/haskell/nix-haskell-flake

Expected: all 9 checks pass.

### Milestone 2

Create template files:

    modules/haskell/nix-haskell-flake/files/flake.nix.tpl
    modules/haskell/nix-haskell-flake/files/treefmt.nix.tpl
    modules/haskell/nix-haskell-flake/files/process-compose.yaml.tpl
    modules/haskell/nix-haskell-flake/files/envrc.tpl

### Milestone 3

    seihou run nix-haskell-flake --dry-run \
      --var project.name=my-service \
      --var project.description="My Haskell service" \
      --var ghc.version=ghc912 \
      --var nix.process-compose=false \
      --var nix.postgresql=false \
      --var nix.treefmt=true \
      --var nix.pre-commit=true

Expected: shows flake.nix, treefmt.nix, .envrc (no process-compose.yaml).

    seihou run nix-haskell-flake --dry-run \
      --var project.name=my-service \
      --var project.description="My Haskell service" \
      --var ghc.version=ghc912 \
      --var nix.process-compose=true \
      --var nix.postgresql=true \
      --var nix.treefmt=true \
      --var nix.pre-commit=true

Expected: shows flake.nix (with pg + process-compose sections), treefmt.nix,
process-compose.yaml, .envrc.


## Validation and Acceptance

1. `seihou validate-module modules/haskell/nix-haskell-flake` passes all checks.

2. Dry-run in library mode produces a `flake.nix` that:
   - Has correct project name in description
   - Imports nixpkgs, flake-utils, treefmt-nix, pre-commit-hooks
   - Defines a devShell with GHC, cabal-install, HLS, and formatters
   - Does NOT include process-compose or postgresql packages
   - Does NOT have postgresql shellHook setup

3. Dry-run in service mode produces a `flake.nix` that:
   - Includes process-compose and postgresql in devShell nativeBuildInputs
   - Has shellHook setting up PGHOST, PGDATA, PGLOG, and running initdb
   - Also generates `process-compose.yaml` with postgres and create_schema processes

4. The generated `treefmt.nix` enables fourmolu, nixpkgs-fmt, and cabal-fmt.

5. The generated `.envrc` contains `use flake` and `eval "$shellHook"`.


## Idempotence and Recovery

All steps are idempotent. `seihou new-module` will fail if the directory already exists,
but the template files can be overwritten freely. `seihou validate-module` and
`seihou run --dry-run` are read-only operations.

If a template has errors, edit the file and re-run validation. No cleanup needed.


## Interfaces and Dependencies

**Seihou CLI**: Used for scaffolding (`new-module`), validation (`validate-module`),
and testing (`run --dry-run`).

**Seihou Schema** (Dhall): Imported at the pinned URL:

    https://raw.githubusercontent.com/shinzui/seihou-schema/2b4035b/package.dhall
      sha256:21716b4aee783d8eb8b12c754050880fa710e881ecda85925f855ef34cc34a55

Types used: `S.Module`, `S.Step`, `S.VarDecl`, `S.Prompt`.

**Module exports**: The module exports `project.name` so downstream modules (e.g.,
haskell-cabal, haskell-overlay) can reference it.

**No runtime dependencies**: This module generates static files only. No commands are
executed during application.
