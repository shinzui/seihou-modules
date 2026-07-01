---
type: SeihouModule
title: haskell-library
description: 'Haskell library bootstrap: a single cabal package on GHC 9.12 / GHC2024,
  with lens + generic-lens, BSD-3 license, an optional tasty test-suite, and a nix-haskell-flake
  dev shell'
resource: seihou://seihou-modules/modules/haskell/haskell-library
tags:
- haskell
- library
- bootstrap
- ghc2024
version: 0.2.0
---

# haskell-library

Haskell library bootstrap: a single cabal package on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, an optional tasty test-suite, and a nix-haskell-flake dev shell

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
- `project.cabal-version` (required)
- `project.tests` (required)


## Exports

- `project.name`
- `project.namespace`

