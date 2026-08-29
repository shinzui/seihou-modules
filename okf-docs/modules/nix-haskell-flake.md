---
type: SeihouModule
title: nix-haskell-flake
description: Nix flake for Haskell projects consuming the haskell-nix-dev base flake
  (shared nixpkgs lock, prebuilt GHC/HLS/cabal), with optional process-compose, PostgreSQL,
  socket-only Redis, ClickHouse, treefmt, and pre-commit
resource: seihou://seihou-modules/modules/haskell/nix-haskell-flake
tags:
- haskell
- nix
- flake
- devshell
version: 0.14.0
---

# nix-haskell-flake

Nix flake for Haskell projects consuming the haskell-nix-dev base flake (shared nixpkgs lock, prebuilt GHC/HLS/cabal), with optional process-compose, PostgreSQL, socket-only Redis, ClickHouse, treefmt, and pre-commit

**Version:** 0.14.0

## Dependencies

This module has no dependencies.

## Variables

- `project.name` (required)
- `project.description` (required)
- `ghc.version` (required)
- `ghc.secondary`
- `nix.process-compose` (required)
- `nix.postgresql` (required)
- `nix.pg-database`
- `nix.redis` (required)
- `nix.clickhouse` (required)
- `nix.treefmt` (required)
- `nix.pre-commit` (required)
- `nix.builtin-package` (required)
- `nix.fourmolu-ghc-opts`


## Exports

- `project.name`
- `ghc.version`

