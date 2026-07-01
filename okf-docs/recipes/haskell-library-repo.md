---
type: SeihouRecipe
title: haskell-library-repo
description: 'Bootstrap a single-package Haskell library in a fresh git repo: applies
  haskell-library (which pulls in nix-haskell-flake) and then git-init last so the
  initial commit captures the full scaffold'
resource: seihou://seihou-modules/recipes/haskell-library-repo
tags:
- haskell
- library
- git
- bootstrap
version: 0.1.0
---

# haskell-library-repo

Bootstrap a single-package Haskell library in a fresh git repo: applies haskell-library (which pulls in nix-haskell-flake) and then git-init last so the initial commit captures the full scaffold

**Version:** 0.1.0

## Composes

- [haskell-library](/modules/haskell-library.md)
- [git-init](/modules/git-init.md)

