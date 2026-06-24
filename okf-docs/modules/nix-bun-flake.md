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
version: 0.2.0
---

# nix-bun-flake

Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting (semicolon-free, sorted imports), a just task runner, and optional git-hooks.nix pre-commit checks

**Version:** 0.2.0

## Dependencies

This module has no dependencies.

## Variables

- `project.name` (required)
- `project.description` (required)
- `nix.pre-commit` (required)


## Exports

- `project.name`
- `project.description`

