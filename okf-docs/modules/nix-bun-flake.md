---
type: SeihouModule
title: nix-bun-flake
description: Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting
  (semicolon-free, sorted imports), a just task runner, optional git-hooks.nix pre-commit
  checks, opt-in pinned bun2nix build helpers, and pinned nix2container image support
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
  by: seihou-okf-extension/0.15.0.0
version: 0.6.0
---

# nix-bun-flake

Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting (semicolon-free, sorted imports), a just task runner, optional git-hooks.nix pre-commit checks, opt-in pinned bun2nix build helpers, and pinned nix2container image support

**Version:** 0.6.0

## Dependencies

This module has no dependencies.

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project name (used in flake description and package.json name)
- `project.description` — text, required. One-line project description
- `nix.package-module` — text, optional, matching `([A-Za-z0-9][A-Za-z0-9_-]*/)*[A-Za-z0-9][A-Za-z0-9_-]*[.]nix`. Optional project-relative managed flake-parts module, imported before the unmanaged flake.module.nix extension
- `bun.starter-files` — boolean, required, default `true`. Generate the base package, TypeScript, Oxc and task-runner files; composing seed owners disable these outputs
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
- `Template` `flake.module.nix.example.tpl` → `flake.module.nix.example`
- `Copy` `flake.lock` → `flake.lock`
- `Template` `package.json.tpl` → `package.json` — when `Eq bun.starter-files true`
- `Copy` `tsconfig.json` → `tsconfig.json` — when `Eq bun.starter-files true`
- `Copy` `oxlintrc.json` → `.oxlintrc.json` — when `Eq bun.starter-files true`
- `Copy` `oxfmtrc.json` → `.oxfmtrc.json` — when `Eq bun.starter-files true`
- `Copy` `justfile` → `justfile` — when `Eq bun.starter-files true`
- `Template` `envrc.tpl` → `.envrc`
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
- delete `package.json` — when `Eq bun.starter-files true`
- delete `tsconfig.json` — when `Eq bun.starter-files true`
- delete `.oxlintrc.json` — when `Eq bun.starter-files true`
- delete `.oxfmtrc.json` — when `Eq bun.starter-files true`
- delete `justfile` — when `Eq bun.starter-files true`
- delete `.envrc`
