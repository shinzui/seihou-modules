# nix-bun-flake

> Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting (semicolon-free, sorted imports), a `just` task runner, and optional git-hooks.nix pre-commit checks.

**Version:** `0.3.0`

## Overview

Generates a reproducible Nix development environment for a Bun + TypeScript project: a
a thin flake-parts `flake.nix` with revision-pinned inputs and a shared `flake.lock`, providing `bun`, `oxlint`, `oxfmt`, `typescript`, and
`just` in the dev shell, plus the tooling config it expects — `tsconfig.json`,
`.oxlintrc.json`, `.oxfmtrc.json`, a `justfile` with typecheck/format/lint recipes, a
`package.json`, an `.envrc` for direnv, and a `.gitignore`. Formatting is opinionated:
oxfmt strips semicolons and sorts imports. No database or runtime services are included.

## Shared toolchain and upgrades

This release provides Bun **1.4.2**, TypeScript **7.0.2**, Oxlint **1.87.0**,
Oxfmt **0.72.0**, and just **1.58.0**. Bun and just come from the pinned nixpkgs;
TypeScript and Oxc tools use fixed-hash upstream npm archives with native bindings,
packaged by Nix. Hooks and the shell use identical packages; no global npm install
is needed. `@types/bun` is pinned to **1.4.2** in the generated package manifest.
Commit the project's `bun.lock` after `just install` to lock its dependencies.

Supported systems are Apple Silicon macOS, ARM64 Linux, and x86-64 Linux, matching
the systems supported by Bun in the pinned nixpkgs. Intel macOS is not exposed.

The managed layout is:

```text
flake.nix                    # inputs and flake-parts imports
flake.lock                   # canonical lock seed
nix/bun.nix                  # development shell
nix/tooling.nix              # fixed-output tooling packages
nix/tooling-sources.json     # versions, archives, hashes, native bindings
nix/pre-commit.nix           # generated/imported when hooks are enabled
flake.module.nix.example     # example for unmanaged project customizations
```

All inputs are pinned by revision in `flake.nix`. The flake-parts and git-hooks
inputs follow the same nixpkgs. Hooks remain declared in the input graph when
disabled, so both feature configurations reproduce the same shipped lock.
`nix flake update` cannot move module-owned revisions. Update projects together
by installing a new module release and running:

```bash
seihou update nix-bun-flake
git add flake.nix flake.lock nix/
nix develop
```

Existing projects gain the managed `nix/` files during the update. Review conflicts
in customized `flake.nix` files and move shell/output customizations into
`flake.module.nix`. Copy `flake.module.nix.example` as a starting point; Seihou
never creates or removes `flake.module.nix`. It is imported automatically when
present. Extend shell packages with `perSystem.bunProject.extraDevPackages`, or define
additional flake-parts packages, checks, apps, and named shells. Put local environment exports in `.envrc.local`. The generated `.envrc`
watches the imported modules and sources that optional file after entering the shell.

To recover the module-owned pins in a drifted project:

```bash
nix flake lock --reference-lock-file ~/.config/seihou/installed/nix-bun-flake/files/flake.lock
```

Project-specific inputs must be added to `flake.nix`; pin them by revision and
update them by name. Projects with additional inputs have additional lock nodes.

Maintainers refresh releases and the canonical lock from this repository with:

```bash
python3 scripts/update-nix-bun-flake.py
python3 scripts/update-nix-bun-flake.py --check
```

The updater verifies registry versions against upstream release tags, checks
Bun/just in nixpkgs, compares locks with hooks on/off, and verifies a full flake
update leaves the module pins unchanged. Bump the module and registry versions
when releasing the result.

## Variables

| Name | Type | Default | Required | Validation | Description |
|------|------|---------|----------|------------|-------------|
| `project.name` | `text` | — | yes | `[a-z][a-z0-9-]*` | Project name (used in flake description and `package.json` name) |
| `project.description` | `text` | — | yes | — | One-line project description |
| `nix.pre-commit` | `bool` | `true` | yes | — | Include pre-commit-hooks (git-hooks.nix) wiring `oxlint` and `oxfmt --check` as git hooks |

## Prompts

The following values are asked interactively (unless supplied via `--var`):

- **`project.name`** — What is your project name?
- **`project.description`** — Describe your project in one line:
- **`nix.pre-commit`** — Include pre-commit hooks (oxlint + oxfmt) via git-hooks.nix?

## Exports

Variables this module exposes to parent modules:

- `project.name`
- `project.description`

## Generated Files

When run, this module writes:

- `flake.nix` — strategy: `template`
- `flake.lock` — strategy: `copy`
- `nix/bun.nix` — strategy: `template`
- `nix/tooling.nix` and `nix/tooling-sources.json` — strategy: `copy`
- `nix/pre-commit.nix` — strategy: `copy`, when hooks are enabled
- `flake.module.nix.example` — strategy: `copy`
- `package.json` — strategy: `template`
- `tsconfig.json` — strategy: `copy`
- `.oxlintrc.json` — strategy: `copy`
- `.oxfmtrc.json` — strategy: `copy`
- `justfile` — strategy: `copy`
- `.envrc` — strategy: `copy`
- `.gitignore` — strategy: `template`, patch mode: `append-line-if-absent`
- `.gitignore` — strategy: `template`, patch mode: `append-line-if-absent`
  - Applied when: `Eq nix.pre-commit true`

## Removal

This module supports removal via:

```bash
seihou remove nix-bun-flake
```

Removal steps remove the files it created: `flake.nix`, `flake.lock`, `package.json`,
`tsconfig.json`, `.oxlintrc.json`, `.oxfmtrc.json`, `justfile`, `.envrc`, the managed
`nix/` files, and `flake.module.nix.example`. User `flake.module.nix` is preserved. Lines
appended to `.gitignore` are left in place.

## Usage

Apply the module:

```bash
seihou run nix-bun-flake
```

With variable overrides:

```bash
seihou run nix-bun-flake --var project.name=acme-api --var project.description="Acme HTTP API" --var nix.pre-commit=true
```

Preview without writing files:

```bash
seihou run nix-bun-flake --dry-run
```

Once generated, enter the dev shell (`direnv allow` or `nix develop`) and:

```bash
just install      # bun install
just typecheck    # tsc --noEmit
just format       # oxfmt --write . (strips semicolons, sorts imports)
just lint         # oxlint
just check        # typecheck + lint + format-check
```

## See Also

- `module.dhall` — full module definition and authoritative source
- `files/` — template sources
