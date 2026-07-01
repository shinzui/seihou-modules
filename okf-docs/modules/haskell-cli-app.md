---
type: SeihouModule
title: haskell-cli-app
description: 'Haskell CLI app bootstrap: two cabal packages (core library + CLI exe)
  on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, and a nix-haskell-flake
  dev shell'
resource: seihou://seihou-modules/modules/haskell/haskell-cli-app
tags:
- haskell
- cli
- bootstrap
- ghc2024
version: 0.2.0
---

# haskell-cli-app

Haskell CLI app bootstrap: two cabal packages (core library + CLI exe) on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, and a nix-haskell-flake dev shell

**Version:** 0.2.0

## Dependencies

- [nix-haskell-flake](/modules/nix-haskell-flake.md)


## Variables

- `project.name` (required)
- `project.description` (required)
- `project.description-long`
- `project.namespace` (required)
- `project.author` (required)
- `project.maintainer` (required)
- `project.copyright-year` (required)


## Exports

- `project.name`
- `project.namespace`

