---
type: SeihouModule
title: haskell-library
description: 'Haskell library bootstrap: a single cabal package on GHC 9.12 / GHC2024,
  with lens + generic-lens, BSD-3 license, an optional tasty test-suite, and a nix-haskell-flake
  dev shell'
resource: seihou://seihou-modules/modules/haskell/haskell-library
tags:
- haskell
- library
- bootstrap
- ghc2024
status: stable
generated:
  by: seihou-okf-extension/0.8.0.0
version: 0.2.0
---

# haskell-library

Haskell library bootstrap: a single cabal package on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, an optional tasty test-suite, and a nix-haskell-flake dev shell

**Version:** 0.2.0

## Dependencies

- [nix-haskell-flake](/modules/nix-haskell-flake.md)

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project base name; cabal package and library are both named <name>. Re-declared here so step `dest` paths validate; the value is shared with `nix-haskell-flake` via the dependency graph.
- `project.description` — text, required. One-line synopsis. Re-declared here so this module's templates can interpolate it; the value is shared with `nix-haskell-flake` (which uses it as the flake description) via the dependency graph.
- `project.description-long` — text, optional. Optional longer prose description used as the `description:` paragraph in the .cabal file. When not set, the template falls back to `project.description` (the one-line synopsis declared by nix-haskell-flake).
- `project.namespace` — text, required, matching `[A-Z][A-Za-z0-9]*`. Top-level Haskell module namespace (single segment, e.g. Rei). Used both as the source-tree directory and as the module prefix in generated .hs files.
- `project.author` — text, required, default `Nadeem Bitar`. Author name written into LICENSE and the .cabal file
- `project.maintainer` — text, required, default `nadeem@gmail.com`. Maintainer email written into the .cabal file
- `project.copyright-year` — text, required, default `2026`, matching `[0-9]{4}`. Copyright year written into LICENSE
- `project.cabal-version` — text, required, default `3.4`, matching `[0-9]+(\.[0-9]+)*`. cabal-version emitted at the top of the generated .cabal file. Bump this when the template grows features that need a newer cabal.
- `project.tests` — boolean, required, default `true`. When true, generate a tasty test-suite stanza (tasty + tasty-hunit) in the .cabal file plus a `test/Spec.hs` stub. When false, no test scaffolding is emitted and the consumer can add their own framework later.

## Exports

- `project.name`
- `project.namespace`

## Prompts

- `project.name` — What is your project name? (lowercase, hyphenated; the cabal package and library will both be named <name>)
- `project.description` — One-line project synopsis (used as cabal `synopsis:` and the flake description):
- `project.description-long` — Longer project description (optional; press Enter to reuse the one-line synopsis):
- `project.namespace` — Top-level Haskell module namespace? (single PascalCase segment, e.g. Rei)
- `project.author` — Author name?
- `project.maintainer` — Maintainer email?
- `project.copyright-year` — Copyright year?
- `project.tests` — Generate a tasty test-suite scaffold? (yes/no)

## Generation steps

- `Template` `cabal.project.tpl` → `cabal.project`
- `Template` `library.cabal.tpl` → `{{project.name}}/{{project.name}}.cabal`
- `Template` `src/Prelude.hs.tpl` → `{{project.name}}/src/{{project.namespace}}/Prelude.hs`
- `Template` `src/Lib.hs.tpl` → `{{project.name}}/src/{{project.namespace}}.hs`
- `Template` `test/Spec.hs.tpl` → `{{project.name}}/test/Spec.hs` — when `Eq project.tests true`
- `Template` `LICENSE.tpl` → `LICENSE`
- `Copy` `fourmolu.yaml` → `fourmolu.yaml`
- `Template` `CHANGELOG.md.tpl` → `CHANGELOG.md`
- `Template` `README.md.tpl` → `README.md`
