---
type: SeihouRecipe
title: haskell-cli-app-repo
description: 'Bootstrap a tested two-package Haskell CLI app in a fresh git repo:
  real core-to-CLI behavior, parser tests, GHC 9.12.4/9.14.1 shells, working Nix package/check
  outputs, then git-init last so the initial commit captures the full scaffold'
resource: seihou://seihou-modules/recipes/haskell-cli-app-repo
tags:
- haskell
- cli
- git
- bootstrap
status: stable
generated:
  by: seihou-okf-extension/0.9.0.0
version: 0.1.0
---

# haskell-cli-app-repo

Bootstrap a tested two-package Haskell CLI app in a fresh git repo: real core-to-CLI behavior, parser tests, GHC 9.12.4/9.14.1 shells, working Nix package/check outputs, then git-init last so the initial commit captures the full scaffold

**Version:** 0.1.0

## Composes

- [haskell-cli-app](/modules/haskell-cli-app.md)
- [git-init](/modules/git-init.md)
