---
type: SeihouModule
title: nix-bun-flake
description: Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting
  (semicolon-free, sorted imports), a just task runner, and optional git-hooks.nix
  pre-commit checks
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
  by: seihou-okf-extension/0.8.0.0
version: 0.2.0
---

# nix-bun-flake

Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting (semicolon-free, sorted imports), a just task runner, and optional git-hooks.nix pre-commit checks

**Version:** 0.2.0

## Dependencies

This module has no dependencies.

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project name (used in flake description and package.json name)
- `project.description` — text, required. One-line project description
- `nix.pre-commit` — boolean, required, default `true`. Include pre-commit-hooks (git-hooks.nix) wiring oxlint and oxfmt --check as git hooks

## Exports

- `project.name`
- `project.description`

## Prompts

- `project.name` — What is your project name?
- `project.description` — Describe your project in one line:
- `nix.pre-commit` — Include pre-commit hooks (oxlint + oxfmt) via git-hooks.nix?

## Generation steps

- `Template` `flake.nix.tpl` → `flake.nix`
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
- delete `package.json`
- delete `tsconfig.json`
- delete `.oxlintrc.json`
- delete `.oxfmtrc.json`
- delete `justfile`
- delete `.envrc`
