---
type: SeihouModule
title: haskell-cli-app
description: 'Tested Haskell CLI bootstrap: reusable core plus CLI packages on GHC2024,
  GHC 9.12.4/9.14.1 shells, current bounded dependencies, valid package-local distribution
  metadata, and workspace-aware Nix package/check outputs'
resource: seihou://seihou-modules/modules/haskell/haskell-cli-app
tags:
- haskell
- cli
- bootstrap
- ghc2024
status: stable
generated:
  by: seihou-okf-extension/0.9.0.0
version: 0.3.0
---

# haskell-cli-app

Tested Haskell CLI bootstrap: reusable core plus CLI packages on GHC2024, GHC 9.12.4/9.14.1 shells, current bounded dependencies, valid package-local distribution metadata, and workspace-aware Nix package/check outputs

**Version:** 0.3.0

## Dependencies

- [nix-haskell-flake](/modules/nix-haskell-flake.md) (with `ghc.secondary` = `ghc9141`, `nix.builtin-package` = `false`, `nix.package-module` = `nix/haskell-cli-app.nix`)

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

## Exports

- `project.name`
- `project.namespace`

## Prompts

- `project.name` — What is your project name? (lowercase, hyphenated; cabal packages will be <name>-core and <name>-cli)
- `project.description` — One-line project synopsis (used as cabal `synopsis:` and the flake description):
- `project.description-long` — Longer project description (optional; press Enter to reuse the one-line synopsis):
- `project.namespace` — Top-level Haskell module namespace? (single PascalCase segment, e.g. Rei)
- `project.category` — Hackage category?
- `project.author` — Author name?
- `project.maintainer` — Maintainer email?
- `project.copyright-year` — Copyright year?
- `project.tests` — Generate the tasty test-suite scaffold? (yes/no)

## Generation steps

- `Template` `cabal.project.tpl` → `cabal.project`
- `Template` `core.cabal.tpl` → `{{project.name}}-core/{{project.name}}-core.cabal`
- `Template` `core/Prelude.hs.tpl` → `{{project.name}}-core/src/{{project.namespace}}/Prelude.hs`
- `Template` `core/Lib.hs.tpl` → `{{project.name}}-core/src/{{project.namespace}}.hs`
- `Template` `cli.cabal.tpl` → `{{project.name}}-cli/{{project.name}}-cli.cabal`
- `Template` `cli/Main.hs.tpl` → `{{project.name}}-cli/app/Main.hs`
- `Template` `cli/Cli.hs.tpl` → `{{project.name}}-cli/src/{{project.namespace}}/Cli.hs`
- `Template` `cli/Spec.hs.tpl` → `{{project.name}}-cli/test/Spec.hs` — when `Eq project.tests true`
- `Template` `nix/haskell-cli-app.nix.tpl` → `nix/haskell-cli-app.nix`
- `Template` `LICENSE.tpl` → `LICENSE`
- `Template` `LICENSE.tpl` → `{{project.name}}-core/LICENSE`
- `Template` `LICENSE.tpl` → `{{project.name}}-cli/LICENSE`
- `Template` `CHANGELOG.md.tpl` → `CHANGELOG.md`
- `Template` `CHANGELOG.md.tpl` → `{{project.name}}-core/CHANGELOG.md`
- `Template` `CHANGELOG.md.tpl` → `{{project.name}}-cli/CHANGELOG.md`
- `Template` `README.md.tpl` → `README.md`
