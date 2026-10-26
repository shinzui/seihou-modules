---
type: SeihouModule
title: nix-bun-flake
description: Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting
  (semicolon-free, sorted imports), a just task runner, optional git-hooks.nix pre-commit
  checks, and opt-in pinned bun2nix build helpers
resource: seihou://seihou-modules/modules/typescript/nix-bun-flake
tags:
- typescript
- bun
- nix
- flake
- oxc
- devshell
status: stable
generated:
  by: seihou-okf-extension/0.10.1.0
version: 0.4.0
---

# nix-bun-flake

Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting (semicolon-free, sorted imports), a just task runner, optional git-hooks.nix pre-commit checks, and opt-in pinned bun2nix build helpers

**Version:** 0.4.0

## Dependencies

This module has no dependencies.

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project name (used in flake description and package.json name)
- `project.description` — text, required. One-line project description
- `nix.bun2nix` — boolean, required, default `false`. Include the pinned bun2nix generator and build helpers (project build recipes remain user-owned)
- `nix.pre-commit` — boolean, required, default `true`. Include pre-commit-hooks (git-hooks.nix) wiring oxlint and oxfmt --check as git hooks

## Exports

- `project.name`
- `project.description`

## Prompts

- `project.name` — What is your project name?
- `project.description` — Describe your project in one line:
- `nix.bun2nix` — Include bun2nix for explicit Nix dependency generation and builds?
- `nix.pre-commit` — Include pre-commit hooks (oxlint + oxfmt) via git-hooks.nix?

## Generation steps

- `Template` `flake.nix.tpl` → `flake.nix`
- `Template` `nix/bun.nix.tpl` → `nix/bun.nix`
- `Copy` `nix/tooling.nix` → `nix/tooling.nix`
- `Copy` `nix/tooling-sources.json` → `nix/tooling-sources.json`
- `Copy` `nix/pre-commit.nix` → `nix/pre-commit.nix` — when `Eq nix.pre-commit true`
- `Copy` `nix/bun2nix-package.nix` → `nix/bun2nix-package.nix` — when `Eq nix.bun2nix true`
- `Copy` `nix/bun2nix-module.nix` → `nix/bun2nix-module.nix` — when `Eq nix.bun2nix true`
- `Copy` `flake.module.nix.example` → `flake.module.nix.example`
- `Copy` `flake.lock` → `flake.lock`
- `Template` `package.json.tpl` → `package.json`
- `Copy` `tsconfig.json` → `tsconfig.json`
- `Copy` `oxlintrc.json` → `.oxlintrc.json`
- `Copy` `oxfmtrc.json` → `.oxfmtrc.json`
- `Copy` `justfile` → `justfile`
- `Copy` `envrc` → `.envrc`
- `Template` `gitignore-bun.tpl` → `.gitignore` (appends one line to a file another module owns, if absent)
- `Template` `gitignore-precommit.tpl` → `.gitignore` (appends one line to a file another module owns, if absent) — when `Eq nix.pre-commit true`

## Removal

- delete `flake.nix`
- delete `flake.lock`
- delete `nix/bun.nix`
- delete `nix/tooling.nix`
- delete `nix/tooling-sources.json`
- delete `nix/pre-commit.nix`
- delete `nix/bun2nix-package.nix`
- delete `nix/bun2nix-module.nix`
- delete `flake.module.nix.example`
- delete `package.json`
- delete `tsconfig.json`
- delete `.oxlintrc.json`
- delete `.oxfmtrc.json`
- delete `justfile`
- delete `.envrc`
