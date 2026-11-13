---
type: SeihouModule
title: haskell-cli-app
description: Tested two-package Haskell CLI with project-owned source/Cabal/changelog
  starters (Seihou 0.11.0.0+), current GHC shells and managed Nix package/check outputs
resource: seihou://seihou-modules/modules/haskell/haskell-cli-app
tags:
- haskell
- cli
- bootstrap
- ghc2024
status: stable
generated:
  by: seihou-okf-extension/0.16.0.0
version: 0.5.0
---

# haskell-cli-app

Tested two-package Haskell CLI with project-owned source/Cabal/changelog starters (Seihou 0.11.0.0+), current GHC shells and managed Nix package/check outputs

**Version:** 0.5.0

## Declaration metadata

- description: `Bootstrap a tested two-package Haskell CLI app (reusable core library + CLI executable) under GHC2024, with GHC 9.12.4 as the HLS-backed default and GHC 9.14.1 as a secondary build shell. Generates valid package-local distribution metadata and workspace-aware Nix package/check outputs on the latest nix-haskell-flake.`

## Dependencies

- [nix-haskell-flake](/modules/nix-haskell-flake.md) (declaring registry) (with `ghc.secondary` = `ghc9141`, `nix.builtin-package` = `false`, `nix.package-module` = `nix/haskell-cli-app.nix`)

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project base name; cabal packages are named <name>-core and <name>-cli, the executable is named <name>. Re-declared here so step `dest` paths validate; the value is shared with `nix-haskell-flake` via the dependency graph.
- `project.description` — text, required. One-line synopsis. Re-declared here so this module's templates can interpolate it; the value is shared with `nix-haskell-flake` (which uses it as the flake description) via the dependency graph.
- `project.description-long` — text, optional. Optional longer prose description used as the `description:` paragraph in both .cabal files. When not set, the templates fall back to `project.description` (the one-line synopsis declared by nix-haskell-flake).
- `project.namespace` — text, required, matching `[A-Z][A-Za-z0-9]*`. Top-level Haskell module namespace (single segment, e.g. Rei). Used both as the source-tree directory and as the module prefix in generated .hs files.
- `project.category` — text, required, default `Development`. Hackage category written into both generated .cabal files
- `project.author` — text, required, default `Nadeem Bitar`. Author name written into LICENSE and .cabal files
- `project.maintainer` — text, required, default `nadeem@gmail.com`. Maintainer email written into .cabal files
- `project.copyright-year` — text, required, default `2026`, matching `[0-9]{4}`. Copyright year written into LICENSE
- `project.tests` — boolean, required, default `true`. Whether to generate the tasty suite that tests core behavior and pure CLI parsing
- `project.managed-package-module` — boolean, required, default `true`. Whether this module generates the managed nix/haskell-cli-app.nix flake-parts package module. Set false when you supply package/build wiring yourself in the unmanaged flake.module.nix; nix-haskell-flake only imports nix/haskell-cli-app.nix when nix.package-module is set, so disabling generation here is safe for that setup.

## Exports

- `project.name`
- `project.namespace`

## Prompts

- `project.name` — `What is your project name? (lowercase, hyphenated; cabal packages will be <name>-core and <name>-cli)`
- `project.description` — ``One-line project synopsis (used as cabal `synopsis:` and the flake description):``
- `project.description-long` — `Longer project description (optional; press Enter to reuse the one-line synopsis):`
- `project.namespace` — `Top-level Haskell module namespace? (single PascalCase segment, e.g. Rei)`
- `project.category` — `Hackage category?`
- `project.author` — `Author name?`
- `project.maintainer` — `Maintainer email?`
- `project.copyright-year` — `Copyright year?`
- `project.tests` — `Generate the tasty test-suite scaffold? (yes/no)`

## Generation steps

- `Template` `cabal.project.tpl` → `cabal.project` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `core.cabal.tpl` → `{{project.name}}-core/{{project.name}}-core.cabal` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `core/Prelude.hs.tpl` → `{{project.name}}-core/src/{{project.namespace}}/Prelude.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `core/Lib.hs.tpl` → `{{project.name}}-core/src/{{project.namespace}}.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `cli.cabal.tpl` → `{{project.name}}-cli/{{project.name}}-cli.cabal` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `cli/Main.hs.tpl` → `{{project.name}}-cli/app/Main.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `cli/Cli.hs.tpl` → `{{project.name}}-cli/src/{{project.namespace}}/Cli.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `cli/Spec.hs.tpl` → `{{project.name}}-cli/test/Spec.hs` — when `Eq project.tests true` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `nix/haskell-cli-app.nix.tpl` → `nix/haskell-cli-app.nix` — when `Eq project.managed-package-module true` — Managed: owned and reconciled by Seihou updates
- `Template` `LICENSE.tpl` → `LICENSE` — Managed: owned and reconciled by Seihou updates
- `Template` `LICENSE.tpl` → `{{project.name}}-core/LICENSE` — Managed: owned and reconciled by Seihou updates
- `Template` `LICENSE.tpl` → `{{project.name}}-cli/LICENSE` — Managed: owned and reconciled by Seihou updates
- `Template` `CHANGELOG.md.tpl` → `CHANGELOG.md` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `CHANGELOG.md.tpl` → `{{project.name}}-core/CHANGELOG.md` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `CHANGELOG.md.tpl` → `{{project.name}}-cli/CHANGELOG.md` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `README.md.tpl` → `README.md` — Seed: created once when absent, then project owned; updates and removal preserve it
