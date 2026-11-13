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
  by: seihou-okf-extension/0.16.0.0
version: 0.1.1
---

# haskell-cli-app-repo

Bootstrap a tested two-package Haskell CLI app in a fresh git repo: real core-to-CLI behavior, parser tests, GHC 9.12.4/9.14.1 shells, working Nix package/check outputs, then git-init last so the initial commit captures the full scaffold

**Version:** 0.1.1

## Declaration metadata

- description: ``Reusable base for single-recipe specializations; extending recipes retain haskell-cli-app as primary and inherit git-init. Bootstrap a tested two-package Haskell CLI app (reusable core library + CLI executable) in a fresh git repository. Composes `haskell-cli-app` (which pulls in the latest `nix-haskell-flake` for GHC 9.12.4/9.14.1 shells and workspace package/check outputs) with `git-init`; seihou's planner runs all file generation before any commands, so the resulting `git init` + initial commit captures the full scaffold in one shot. When `git.createGithub` is true, git-init will also prompt for `git.repoName` and push to GitHub via `gh repo create` — typically you'd answer with the same value as `project.name`.``

## Composes

- [haskell-cli-app](/modules/haskell-cli-app.md) (declaring registry)
- [git-init](/modules/git-init.md) (declaring registry)
