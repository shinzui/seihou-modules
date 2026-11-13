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
status: stable
generated:
  by: seihou-okf-extension/0.16.0.0
version: 0.1.0
---

# haskell-library-repo

Bootstrap a single-package Haskell library in a fresh git repo: applies haskell-library (which pulls in nix-haskell-flake) and then git-init last so the initial commit captures the full scaffold

**Version:** 0.1.0

## Declaration metadata

- description: ``Bootstrap a single-package Haskell library in a fresh git repository. Composes `haskell-library` (which pulls in `nix-haskell-flake` to provide the dev shell) with `git-init`; seihou's planner runs all file generation before any commands, so the resulting `git init` + initial commit captures the full scaffold in one shot. When `git.createGithub` is true, git-init will also prompt for `git.repoName` and push to GitHub via `gh repo create` — typically you'd answer with the same value as `project.name`.``

## Composes

- [haskell-library](/modules/haskell-library.md) (declaring registry)
- [git-init](/modules/git-init.md) (declaring registry)
