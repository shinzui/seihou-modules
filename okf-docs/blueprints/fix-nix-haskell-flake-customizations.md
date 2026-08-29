---
type: SeihouBlueprint
title: fix-nix-haskell-flake-customizations
description: 'Agent-driven, in-place remediation of a repo that already consumes the
  nix-haskell-flake seihou module: upgrades the module to its latest version (seihou
  migrate + seihou run --force) and relocates every local edit made directly to the
  seihou-managed nix/haskell.nix (extra dev-shell packages, etc.) into the unmanaged,
  upgrade-safe flake.module.nix via haskellProject.extraDevPackages, git-tracking
  that file so Nix actually sees it, and proving dev-shell parity with nix print-dev-env;
  reviews and verifies but never commits'
resource: seihou://seihou-modules/blueprints/fix-nix-haskell-flake-customizations
tags:
- haskell
- nix
- flake
- flake-parts
- seihou
- migration
- devshell
version: 0.1.0
---

# fix-nix-haskell-flake-customizations

Agent-driven, in-place remediation of a repo that already consumes the nix-haskell-flake seihou module: upgrades the module to its latest version (seihou migrate + seihou run --force) and relocates every local edit made directly to the seihou-managed nix/haskell.nix (extra dev-shell packages, etc.) into the unmanaged, upgrade-safe flake.module.nix via haskellProject.extraDevPackages, git-tracking that file so Nix actually sees it, and proving dev-shell parity with nix print-dev-env; reviews and verifies but never commits

**Version:** 0.1.0

## Base modules

This blueprint declares no base modules.

## Agent prompt

# Fix this repo's nix-haskell-flake customizations and upgrade the module

## Reference files

- `flake.module.nix` - Reference for the UNMANAGED flake.module.nix: a flake-parts module that sets haskellProject.extraDevPackages (the option declared by nix/haskell.nix) to the project's extra dev-shell tools, plus commented examples for a project-defined packages.default (when nix.builtin-package is false) and treefmt overrides. The header documents the hard requirement that this file be git-tracked, since Nix flakes ignore untracked files.
