---
type: SeihouRecipe
title: haskell-cli-app-repo
description: 'Bootstrap a two-package Haskell CLI app (core library + CLI exe) in
  a fresh git repo: applies haskell-cli-app (which pulls in nix-haskell-flake) and
  then git-init last so the initial commit captures the full scaffold'
resource: seihou://seihou-modules/recipes/haskell-cli-app-repo
tags:
- haskell
- cli
- git
- bootstrap
version: 0.1.0
---

# haskell-cli-app-repo

Bootstrap a two-package Haskell CLI app (core library + CLI exe) in a fresh git repo: applies haskell-cli-app (which pulls in nix-haskell-flake) and then git-init last so the initial commit captures the full scaffold

**Version:** 0.1.0

## Composes

- [haskell-cli-app](/modules/haskell-cli-app.md)
- [git-init](/modules/git-init.md)

