---
type: SeihouBlueprint
title: upgrade-haskell-flake-parts
description: Agent-driven, in-place migration of a shinzui Haskell project's Nix flake
  to the thin flake-parts structure on the haskell-nix-dev base flake (GHC 9.12.4
  via mkDevShell, wiring split into nix/{haskell,treefmt,pre-commit}.nix, package
  build and custom checks moved to an unmanaged flake.module.nix), preserving every
  custom input/overlay/dev-tool/hook/check; reviews and builds but never commits
resource: seihou://seihou-modules/blueprints/upgrade-haskell-flake-parts
tags:
- haskell
- nix
- flake
- flake-parts
- migration
- devshell
version: 0.1.0
---

# upgrade-haskell-flake-parts

Agent-driven, in-place migration of a shinzui Haskell project's Nix flake to the thin flake-parts structure on the haskell-nix-dev base flake (GHC 9.12.4 via mkDevShell, wiring split into nix/{haskell,treefmt,pre-commit}.nix, package build and custom checks moved to an unmanaged flake.module.nix), preserving every custom input/overlay/dev-tool/hook/check; reviews and builds but never commits

**Version:** 0.1.0

## Base modules

This blueprint declares no base modules.

## Agent prompt

# Migrate this Haskell flake to flake-parts on the haskell-nix-dev base flake

## Reference files

- `flake.nix` - Reference for the thin top-level flake.nix stub: standard inputs (haskell-nix-dev, followed nixpkgs, flake-parts, treefmt-nix, pre-commit-hooks) plus a commented PROJECT-SPECIFIC INPUTS section, and the mkFlake outputs with the nix/* imports and the optional flake.module.nix import. Keep the project's description and project-specific inputs; drop flake-utils.
- `nix/haskell.nix` - Reference for nix/haskell.nix: the dev shell via the base flake's mkDevShell on ghc9124, the haskellProject.extraDevPackages perSystem option, and the pre-commit installationScript shellHook. Put the project's extra dev tools (only those beyond cabal/HLS/pkg-config/zlib) in extraNativeBuildInputs.
- `nix/treefmt.nix` - Reference for nix/treefmt.nix: treefmt-nix as a flake-parts module wiring `nix fmt` and a treefmt check, with nixpkgs-fmt + fourmolu + cabal-gild (the latter two from the ghc9124 set). Preserve the project's existing formatter set.
- `nix/pre-commit.nix` - Reference for nix/pre-commit.nix: git-hooks.nix as a flake-parts module with the treefmt hook plus a commented example of a custom system-language hook. Carry over every custom hook the old flake had, moving any hook script under nix/.
- `flake.module.nix` - Reference for the UNMANAGED flake.module.nix: the project-specific package build and custom checks. Shows Variant A (compose the shared haskell-nix overlay with the project's nix/haskell-overlay.nix and graft onto pkgs.haskell.packages.ghc9124) and Variant B (a no-overlay Tier B project building directly with callCabal2nix).

