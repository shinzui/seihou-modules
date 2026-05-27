# nix-haskell-flake

> Nix flake for Haskell projects with toggleable process-compose, PostgreSQL, treefmt-nix, and pre-commit-hooks.

**Version:** `0.9.0`

## Overview

Generates a reproducible Nix development environment for a Haskell project: a `flake.nix`
pinned via `flake.lock`, an `.envrc` for direnv, and opt-in integrations for service
orchestration (process-compose), a local PostgreSQL instance, code formatting
(treefmt-nix), and Git pre-commit hooks.

## Variables

| Name | Type | Default | Required | Validation | Description |
|------|------|---------|----------|------------|-------------|
| `project.name` | `text` | — | yes | `[a-z][a-z0-9-]*` | Project name (used in flake description and database name) |
| `project.description` | `text` | — | yes | — | One-line project description |
| `ghc.version` | `text` | `ghc9124` | yes | `ghc[0-9]+` | GHC version identifier for `haskell.packages.<version>` (e.g. `ghc9124` pins GHC 9.12.4 exactly; `ghc912` tracks the latest 9.12.x in the locked nixpkgs) |
| `nix.process-compose` | `bool` | — | yes | — | Include process-compose in devShell and generate `process-compose.yaml` |
| `nix.postgresql` | `bool` | — | yes | — | Include postgresql in devShell with local DB setup in shellHook |
| `nix.treefmt` | `bool` | `true` | yes | — | Include treefmt-nix input and generate `treefmt.nix` |
| `nix.pre-commit` | `bool` | `true` | yes | — | Include pre-commit-hooks (`git-hooks.nix`) input and checks |

## Prompts

The following values are asked interactively (unless supplied via `--var`):

- **`project.name`** — What is your project name?
- **`project.description`** — Describe your project in one line:
- **`ghc.version`** — Which GHC version?
  - Choices: `ghc9124`, `ghc984`, `ghc966`
- **`nix.process-compose`** — Include process-compose for service orchestration?
- **`nix.postgresql`** — Include PostgreSQL with local database setup?
- **`nix.treefmt`** — Include treefmt-nix for code formatting (fourmolu, nixpkgs-fmt, cabal-fmt)?
- **`nix.pre-commit`** — Include pre-commit hooks via git-hooks.nix?

## Exports

Variables this module exposes to parent modules:

- `project.name`
- `ghc.version`

## Generated Files

When run, this module writes:

- `flake.nix` — strategy: `template`
- `flake.lock` — strategy: `copy`
- `treefmt.nix` — strategy: `template`
  - Applied when: `Eq nix.treefmt true || Eq nix.treefmt "true"`
- `process-compose.yaml` — strategy: `template`
  - Applied when: `Eq nix.process-compose true || Eq nix.process-compose "true"`
- `.envrc` — strategy: `template`
- `.gitignore` — strategy: `template`
  - Patch mode: `append-line-if-absent`
  - Appends: `.envrc`
- `.gitignore` — strategy: `template`
  - Patch mode: `append-line-if-absent`
  - Appends Haskell build artifacts: `dist`, `dist-*`, `cabal-dev`, `.direnv`, `cabal.project.local`
- `.gitignore` — strategy: `template`
  - Applied when: `Eq nix.pre-commit true || Eq nix.pre-commit "true"`
  - Patch mode: `append-line-if-absent`
  - Appends: `.pre-commit-config.yaml`

## Removal

This module is **not removable** — `seihou remove nix-haskell-flake` will refuse. File
additions made by this module will have to be reverted manually.

## Usage

Apply the module:

```bash
seihou run nix-haskell-flake
```

With variable overrides:

```bash
seihou run nix-haskell-flake --var project.name=my-app --var nix.postgresql=true
```

Preview without writing files:

```bash
seihou run nix-haskell-flake --dry-run
```

## See Also

- `module.dhall` — full module definition and authoritative source
- `files/` — template sources
