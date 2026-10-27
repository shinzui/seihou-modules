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
| `seihou update <name>` | Reconcile recorded applications and adopt starter seed ownership |

## Catalog

Versions below are the ones recorded in `seihou-registry.dhall`.

### Modules

Deterministic file generation: variables, prompts, template/copy steps,
commands, and an optional removal procedure.

| Module | Version | Purpose |
|---|---|---|
| [`gcp-kube-env`](modules/cloud/gcp-kube-env) | 0.1.1 | Checkout-local GCP project and kube context, private kubeconfig, and direnv settings in a configurable env file (default `.envrc.local`) |
| [`nix-haskell-flake`](modules/haskell/nix-haskell-flake) | 0.35.0 | flake-parts Nix dev shell on the `haskell-nix-dev` base flake, with exact managed locks, an optional managed package-module seam, and toggleable local services/formatting/hooks |
| [`haskell-library`](modules/haskell/haskell-library) | 0.3.0 | Single-package Haskell library on GHC 9.12 / GHC2024, `lens` + `generic-lens`, BSD-3, optional `tasty` suite |
| [`haskell-cli-app`](modules/haskell/haskell-cli-app) | 0.4.0 | Tested two-package CLI with real core integration, GHC 9.12.4/9.14.1 shells, valid package metadata, and working Nix package/check outputs |
| [`haskell-keiro-project`](modules/haskell/haskell-keiro-project) | 0.3.0 | Six-package Keiro seed, project-named workspace, injected probes, OpenAPI, Hurl/Hinagata testing, optional Mori inventory |
| [`git-init`](modules/git/git-init) | 0.2.0 | `git init -b master`, seed `.gitignore`, optional private GitHub repo via `gh repo create`, optional org-team access grant |
| [`repo-dir`](modules/git/repo-dir) | 0.1.0 | Create `<parentDir>/<name>` and run `git-init` inside it with a matching GitHub repo; owner from the active context's `git.githubOwner` |
| [`nix-bun-flake`](modules/typescript/nix-bun-flake) | 0.4.0 | Nix flake for Bun + TypeScript: oxlint, oxfmt, `just`, optional git-hooks.nix and pinned bun2nix builds |
| [`fumadocs`](modules/typescript/fumadocs) | 0.2.1 | Fumadocs site on TanStack Start + Vite, layered on `nix-bun-flake`, with mermaid diagrams and a zoom/pan widget |

### Recipes

Named compositions of existing modules with preset variable bindings — no new
generation logic.

| Recipe | Version | Purpose |
|---|---|---|
| [`haskell-library-repo`](recipes/haskell-library-repo) | 0.1.0 | `haskell-library` + `git-init`, so the initial commit captures the full scaffold |
| [`haskell-cli-app-repo`](recipes/haskell-cli-app-repo) | 0.1.0 | Tested two-package CLI scaffold plus `git-init`, with working Nix builds/checks in the initial commit |
| [`github-repo`](recipes/github-repo) | 0.1.0 | Prompt for a location and folder name, create it, and make it a git repo with a matching GitHub repo under the context's owner |

### Blueprints

Agent-driven scaffolds and in-place migrations: a prompt plus reference files,
for work that needs per-project judgement. They review and verify, but never
commit.

| Blueprint | Version | Purpose |
|---|---|---|
| [`haskell-keiro-service`](blueprints/haskell-keiro-service) | 0.4.0 | Extend the Keiro seed’s probes/OpenAPI/testing into an event-sourced Haskell service on the released Keiro runtime — vertical-slice packages, pg-migrate components, Settei config, OpenTelemetry wiring, Keiro-DSL-first workflow |
| [`upgrade-fumadocs`](blueprints/upgrade-fumadocs) | 0.1.0 | Upgrade a customized documentation site to current Fumadocs and the shared Bun flake-parts modules while preserving its workflows and content |
| [`upgrade-haskell-runtime`](blueprints/upgrade-haskell-runtime) | 0.1.0 | Preserve legacy projects or cross ordered 0.30.0/0.31.0 upgrades to explicit shared runtime scopes with independent native acceptance |
| [`upgrade-haskell-flake-parts`](blueprints/upgrade-haskell-flake-parts) | 0.1.0 | Migrate a monolithic `flake.nix` to the thin flake-parts structure on the base flake, preserving every custom input, overlay, tool, hook, and check |
| [`fix-nix-haskell-flake-customizations`](blueprints/fix-nix-haskell-flake-customizations) | 0.2.0 | Upgrade a repo's `nix-haskell-flake` and relocate local edits from the managed `nix/haskell.nix` into the upgrade-safe `flake.module.nix` |

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

- `scripts/test-gcp-kube-env.py` — exercises real Seihou generation, kubectl
  configuration and direnv loading against offline fixtures, including custom
  filenames, reconfiguration, credential isolation, Git protection, write failures,
  and preservation of local settings.
- `scripts/update-nix-haskell-flake-lock.sh` — the only supported way to move
  the `haskell-nix-dev` pin. Rewrites `files/flake.nix.tpl` and regenerates
  `files/flake.lock` together, then proves the pin sticks and that a minimal
  project reusing the lock resolves identical inputs. `--check` verifies without
  writing (for CI); it never commits and never bumps the module version.
- `scripts/test-keiro-bootstrap.py --live` — builds a fresh generated seed and proves real
  PostgreSQL fixtures reach HTTP/Hurl assertions under distinct leases, with failure propagation
  and service/clone cleanup. Runs in the generated Nix shell against its own private cluster.
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

Existing Haskell projects can use [upgrade-haskell-runtime](blueprints/upgrade-haskell-runtime/README.md)
for preserved legacy adoption or ordered 0.30.0/0.31.0 upgrades. The optional checked runtime
scope shares production and development identities; native acceptance remains independently
verified. This checkout prepares module 0.32.0, CLI scaffold 0.3.1 and blueprint 0.1.0;
remote discovery requires publishing the reviewed commit first.

## Seed runtime compatibility

The Haskell CLI 0.4.0, library 0.3.0 and Keiro project 0.3.0 releases declare
project-owned starter seeds. They require **Seihou 0.11.0.0+**. Update the runtime
first.
Older binaries may ignore lifecycle and overwrite starter content. The runtime
work is coordinated by
`mori://shinzui/seihou/masterplans/12-seed-files-module-outputs-created-once-and-owned-by-the-project`.

Existing projects adopt with one ordinary `seihou update haskell-cli-app` (or the
library/Keiro root). Review `release to project` and confirm once; update fetches
recorded sources/dependencies and prepares supported manifests. Commit the resulting
manifest. Saved settlement preserves edits and intentional deletion in clones,
reruns, force, status, diff, update and removal. No per-file release prompts,
prerequisite install, internal JSON changes or transitive target list are needed.
Managed Nix integration, licenses and maintained test helpers still update.
Shell commands remain unsandboxed and must never mutate project seeds.
