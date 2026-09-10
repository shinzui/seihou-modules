---
type: SeihouModule
title: haskell-cli-app
description: 'Haskell CLI app bootstrap: two cabal packages (core library + CLI exe)
  on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, and a nix-haskell-flake
  dev shell'
resource: seihou://seihou-modules/modules/haskell/haskell-cli-app
tags:
- haskell
- cli
- bootstrap
- ghc2024
status: stable
generated:
  by: seihou-okf-extension/0.8.0.0
version: 0.2.0
---

# haskell-cli-app

Haskell CLI app bootstrap: two cabal packages (core library + CLI exe) on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, and a nix-haskell-flake dev shell

**Version:** 0.2.0

## Dependencies

- [nix-haskell-flake](/modules/nix-haskell-flake.md)

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project base name; cabal packages are named <name>-core and <name>-cli, the executable is named <name>. Re-declared here so step `dest` paths validate; the value is shared with `nix-haskell-flake` via the dependency graph.
- `project.description` — text, required. One-line synopsis. Re-declared here so this module's templates can interpolate it; the value is shared with `nix-haskell-flake` (which uses it as the flake description) via the dependency graph.
- `project.description-long` — text, optional. Optional longer prose description used as the `description:` paragraph in both .cabal files. When not set, the templates fall back to `project.description` (the one-line synopsis declared by nix-haskell-flake).
- `project.namespace` — text, required, matching `[A-Z][A-Za-z0-9]*`. Top-level Haskell module namespace (single segment, e.g. Rei). Used both as the source-tree directory and as the module prefix in generated .hs files.
- `project.author` — text, required, default `Nadeem Bitar`. Author name written into LICENSE and .cabal files
- `project.maintainer` — text, required, default `nadeem@gmail.com`. Maintainer email written into .cabal files
- `project.copyright-year` — text, required, default `2026`, matching `[0-9]{4}`. Copyright year written into LICENSE

## Exports

- `project.name`
- `project.namespace`

## Prompts

- `project.name` — What is your project name? (lowercase, hyphenated; cabal packages will be <name>-core and <name>-cli)
- `project.description` — One-line project synopsis (used as cabal `synopsis:` and the flake description):
- `project.description-long` — Longer project description (optional; press Enter to reuse the one-line synopsis):
- `project.namespace` — Top-level Haskell module namespace? (single PascalCase segment, e.g. Rei)
- `project.author` — Author name?
- `project.maintainer` — Maintainer email?
- `project.copyright-year` — Copyright year?

## Generation steps

- `Template` `cabal.project.tpl` → `cabal.project`
- `Template` `core.cabal.tpl` → `{{project.name}}-core/{{project.name}}-core.cabal`
- `Template` `core/Prelude.hs.tpl` → `{{project.name}}-core/src/{{project.namespace}}/Prelude.hs`
- `Template` `cli.cabal.tpl` → `{{project.name}}-cli/{{project.name}}-cli.cabal`
- `Template` `cli/Main.hs.tpl` → `{{project.name}}-cli/app/Main.hs`
- `Template` `cli/Cli.hs.tpl` → `{{project.name}}-cli/src/{{project.namespace}}/Cli.hs`
- `Template` `LICENSE.tpl` → `LICENSE`
- `Copy` `fourmolu.yaml` → `fourmolu.yaml`
- `Template` `CHANGELOG.md.tpl` → `CHANGELOG.md`
- `Template` `README.md.tpl` → `README.md`
