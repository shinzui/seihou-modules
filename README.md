# seihou-modules

> Composable [Seihou](https://github.com/shinzui/seihou) modules, recipes, and blueprints for bootstrapping projects.

This repository is a **Seihou registry**: a multi-artifact repo whose
`seihou-registry.dhall` publishes every scaffolding artifact used to start and
maintain shinzui projects — Haskell libraries, CLI apps and Keiro services,
Bun/TypeScript flakes, Fumadocs sites, and the agent-driven migrations that keep
existing repos on the current conventions.

Nothing here is a library you depend on at build time. Artifacts are *applied*
to a project by the `seihou` CLI, which generates files, records what it wrote
in `.seihou/manifest.json`, and can later upgrade or remove them without
clobbering local edits.

## Requirements

- The `seihou` CLI on `PATH` (`seihou --version`).
- `nix` (with flakes) for the Nix-based modules, `gh` for `git-init`'s optional
  GitHub repo creation, `dhall` / `dhall-to-json` for authoring work.

## Quick start

Install everything this registry publishes into `~/.config/seihou/installed/`:

```bash
seihou install https://github.com/shinzui/seihou-modules.git --all
```

…or pick individual artifacts:

```bash
seihou install https://github.com/shinzui/seihou-modules.git \
  --module haskell-library --module git-init
```

Then, from an empty directory, apply one:

```bash
mkdir my-lib && cd my-lib
seihou run haskell-library-repo     # prompts for project.name, namespace, …
```

Useful follow-ups in a project that already has a `.seihou/manifest.json`:

| Command | What it does |
|---|---|
| `seihou status` | What is applied, at which version |
| `seihou diff` | Local edits since the last generation |
| `seihou outdated` | Installed artifacts with newer versions upstream |
| `seihou migrate` | Apply module-declared migrations to this project |
| `seihou run <name> --force` | Regenerate after an upgrade |

## Catalog

Versions below are the ones recorded in `seihou-registry.dhall`.

### Modules

Deterministic file generation: variables, prompts, template/copy steps,
commands, and an optional removal procedure.

| Module | Version | Purpose |
|---|---|---|
| [`nix-haskell-flake`](modules/haskell/nix-haskell-flake) | 0.17.0 | flake-parts Nix dev shell on the `haskell-nix-dev` base flake (prebuilt GHC/HLS/cabal), with optional process-compose, PostgreSQL, socket-only Redis, ClickHouse, Kafka, treefmt, and pre-commit |
| [`haskell-library`](modules/haskell/haskell-library) | 0.2.0 | Single-package Haskell library on GHC 9.12 / GHC2024, `lens` + `generic-lens`, BSD-3, optional `tasty` suite |
| [`haskell-cli-app`](modules/haskell/haskell-cli-app) | 0.2.0 | Two-package Haskell CLI app (core library + CLI exe) on the same baseline |
| [`haskell-keiro-project`](modules/haskell/haskell-keiro-project) | 0.1.0 | Six-package Keiro service bootstrap: Nix shell, workspace manifest, `just` recipes, implementation brief |
| [`git-init`](modules/git/git-init) | 0.1.0 | `git init -b master`, seed `.gitignore`, optional private GitHub repo via `gh repo create` |
| [`nix-bun-flake`](modules/typescript/nix-bun-flake) | 0.2.0 | Nix flake for Bun + TypeScript: oxlint, oxfmt, `just`, optional git-hooks.nix |
| [`fumadocs`](modules/typescript/fumadocs) | 0.1.2 | Fumadocs site on TanStack Start + Vite, layered on `nix-bun-flake`, with mermaid diagrams and a zoom/pan widget |

### Recipes

Named compositions of existing modules with preset variable bindings — no new
generation logic.

| Recipe | Version | Purpose |
|---|---|---|
| [`haskell-library-repo`](recipes/haskell-library-repo) | 0.1.0 | `haskell-library` + `git-init`, so the initial commit captures the full scaffold |
| [`haskell-cli-app-repo`](recipes/haskell-cli-app-repo) | 0.1.0 | Same, for the two-package CLI layout |

### Blueprints

Agent-driven scaffolds and in-place migrations: a prompt plus reference files,
for work that needs per-project judgement. They review and verify, but never
commit.

| Blueprint | Version | Purpose |
|---|---|---|
| [`haskell-keiro-service`](blueprints/haskell-keiro-service) | 0.3.0 | Implement an event-sourced Haskell service on the released Keiro runtime — vertical-slice packages, pg-migrate components, Settei config, OpenTelemetry wiring, Keiro-DSL-first workflow |
| [`upgrade-haskell-flake-parts`](blueprints/upgrade-haskell-flake-parts) | 0.1.0 | Migrate a monolithic `flake.nix` to the thin flake-parts structure on the base flake, preserving every custom input, overlay, tool, hook, and check |
| [`fix-nix-haskell-flake-customizations`](blueprints/fix-nix-haskell-flake-customizations) | 0.1.0 | Upgrade a repo's `nix-haskell-flake` and relocate local edits from the managed `nix/haskell.nix` into the upgrade-safe `flake.module.nix` |

## Repository layout

```
seihou-registry.dhall   Catalog of everything published here (the registry)
mori.dhall              Mori project descriptor (cross-repo discovery)
modules/<lang>/<name>/  module.dhall + files/ + README.md
recipes/<name>/         recipe.dhall + README.md
blueprints/<name>/      blueprint.dhall + prompt.md + files/ + README.md
okf-docs/               GENERATED OKF bundle — one concept per registry entry
docs/adr/               Architecture decision records
docs/plans/             ExecPlans for work done in this repo
scripts/                Authoring and verification scripts
agents/, claude/        Shared agent skills (applied from agent-seihou)
```

Each module directory holds `module.dhall` (the schema-typed declaration of
variables, prompts, steps, commands, dependencies) and a `files/` tree of
templates and copied assets. `README.md` in each directory documents the
variables, prompts, and generated files in detail.

## Authoring

Scaffold a new artifact, then validate and register it:

```bash
seihou new-module <name>          # or new-recipe / new-blueprint / new-prompt
seihou validate-module modules/<lang>/<name>
seihou registry sync-versions     # copy artifact versions into the registry
seihou registry validate          # registry entries match on-disk artifacts
```

Bump the artifact's own `version` in its `*.dhall` whenever its output changes,
then re-run `sync-versions` — the registry, the generated docs, and
`seihou outdated` in consuming projects all read that value.

### Regenerating `okf-docs/`

`okf-docs/` is generated, never hand-edited. Run `sync-versions` first, or the
docs record stale versions:

```bash
seihou registry sync-versions
seihou extension run okf -- docs --dir . --out okf-docs --force
```

`okf-docs/profile.dhall` is the house profile describing what those bundles
promise; the bundle itself stays OKF-conformant regardless.

### Scripts

- `scripts/update-nix-haskell-flake-lock.sh` — the only supported way to move
  the `haskell-nix-dev` pin. Rewrites `files/flake.nix.tpl` and regenerates
  `files/flake.lock` together, then proves the pin sticks and that a minimal
  project reusing the lock resolves identical inputs. `--check` verifies without
  writing (for CI); it never commits and never bumps the module version.
- `scripts/check-keiro-bootstrap.py` — renders `haskell-keiro-project` into
  throwaway directories and asserts the six-package layout, idempotent
  regeneration, user-edit protection, and that the registry and Mori descriptors
  still evaluate.

## Conventions

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/),
  scoped by artifact (`feat(nix-haskell-flake): …`, `docs(okf-docs): …`).
- Cross-repository references use canonical `mori://` URIs — e.g.
  `mori://shinzui/seihou-modules/templates/nix-haskell-flake` — rather than bare
  paths or names. Repo-local references stay relative paths. Verify one with
  `mori path <uri>`.
- `mori.dhall` is a separate descriptor from `seihou-registry.dhall`: it feeds
  Mori's cross-repo discovery, exposes artifacts under the `templates/` kind,
  and is maintained by hand — `seihou registry sync-versions` does not touch it,
  so update it in the same commit when you add an artifact or bump a version.
