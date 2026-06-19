# nix-bun-flake

> Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting (semicolon-free, sorted imports), a `just` task runner, and optional git-hooks.nix pre-commit checks.

**Version:** `0.1.0`

## Overview

Generates a reproducible Nix development environment for a Bun + TypeScript project: a
`flake.nix` pinned via `flake.lock` providing `bun`, `oxlint`, `oxfmt`, `typescript`, and
`just` in the dev shell, plus the tooling config it expects — `tsconfig.json`,
`.oxlintrc.json`, `.oxfmtrc.json`, a `justfile` with typecheck/format/lint recipes, a
`package.json`, an `.envrc` for direnv, and a `.gitignore`. Formatting is opinionated:
oxfmt strips semicolons and sorts imports. No database or runtime services are included.

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

## Generated Files

When run, this module writes:

- `flake.nix` — strategy: `template`
- `flake.lock` — strategy: `copy`
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
`tsconfig.json`, `.oxlintrc.json`, `.oxfmtrc.json`, `justfile`, and `.envrc`. Lines
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
