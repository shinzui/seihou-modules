---
type: SeihouModule
title: haskell-keiro-project
description: Six-package Keiro bootstrap with a Nix development shell, workspace manifest,
  development recipes, and a project-specific implementation brief
resource: seihou://seihou-modules/modules/haskell/haskell-keiro-project
tags:
- haskell
- keiro
- service
- bootstrap
status: stable
generated:
  by: seihou-okf-extension/0.8.0.0
version: 0.1.0
---

# haskell-keiro-project

Six-package Keiro bootstrap with a Nix development shell, workspace manifest, development recipes, and a project-specific implementation brief

**Version:** 0.1.0

## Dependencies

- [nix-haskell-flake](/modules/nix-haskell-flake.md) (with `nix.builtin-package` = `false`, `nix.postgresql` = `true`, `nix.process-compose` = `true`)

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*`. Project base name; creates <name>-core, -api, -migrations, -workers, -server, and -client. Shared with the Nix environment.
- `project.description` — text, required. One-line synopsis used in Cabal files, the implementation brief, and the Nix flake description.
- `project.namespace` — text, required, matching `[A-Z][A-Za-z0-9]*`. Top-level Haskell module namespace (single segment, e.g. Rei). Used both as the source-tree directory and as the module prefix in generated .hs files.
- `project.author` — text, required, default `Nadeem Bitar`. Author name written into LICENSE and .cabal files
- `project.maintainer` — text, required, default `nadeem@gmail.com`. Maintainer email written into .cabal files
- `project.copyright-year` — text, required, default `2026`, matching `[0-9]{4}`. Copyright year written into LICENSE
- `keiro.context` — text, required, matching `[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*`. Stable service workspace identity and shared DSL context.
- `haskell.index-state` — text, required, default `2026-09-07T00:00:00Z`, matching `[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z`. Hackage index snapshot for the initial libraries; reverify the runtime cohort before adding domain dependencies.

## Exports

- `project.name`
- `project.namespace`

## Prompts

- `project.name` — What is your project name? (lowercase, hyphenated; cabal packages will be <name>-core, -api, -migrations, -workers, -server, and -client)
- `project.description` — One-line project synopsis (used as cabal `synopsis:` and the flake description):
- `project.namespace` — Top-level Haskell module namespace? (single PascalCase segment, e.g. Rei)
- `project.author` — Author name?
- `project.maintainer` — Maintainer email?
- `project.copyright-year` — Copyright year?
- `keiro.context` — Stable Keiro service/context name? (lowercase, e.g. contacts)
- `haskell.index-state` — Hackage index-state for this bootstrap? (UTC timestamp)

## Generation steps

- `Template` `cabal.project.tpl` → `cabal.project`
- `Template` `Prelude.hs.tpl` → `{{project.name}}-core/src/{{project.namespace}}/Prelude.hs`
- `Template` `workspace.tpl` → `domain/{{keiro.context}}.keiro-workspace`
- `Template` `shared.keiro.tpl` → `domain/{{keiro.context}}/shared.keiro`
- `Template` `justfile.tpl` → `justfile`
- `Template` `LICENSE.tpl` → `LICENSE`
- `Template` `README.md.tpl` → `README.md`
- `Template` `bootstrap.md.tpl` → `docs/bootstrap-keiro.md`
- `Template` `core.cabal.tpl` → `{{project.name}}-core/{{project.name}}-core.cabal`
- `Template` `core.hs.tpl` → `{{project.name}}-core/src/{{project.namespace}}/Bootstrap.hs`
- `Template` `api.cabal.tpl` → `{{project.name}}-api/{{project.name}}-api.cabal`
- `Template` `api.hs.tpl` → `{{project.name}}-api/src/{{project.namespace}}/Api.hs`
- `Template` `migrations.cabal.tpl` → `{{project.name}}-migrations/{{project.name}}-migrations.cabal`
- `Template` `migrations.hs.tpl` → `{{project.name}}-migrations/src/{{project.namespace}}/Migrations.hs`
- `Template` `workers.cabal.tpl` → `{{project.name}}-workers/{{project.name}}-workers.cabal`
- `Template` `workers.hs.tpl` → `{{project.name}}-workers/src/{{project.namespace}}/Workers/Registry.hs`
- `Template` `server.cabal.tpl` → `{{project.name}}-server/{{project.name}}-server.cabal`
- `Template` `server.hs.tpl` → `{{project.name}}-server/src/{{project.namespace}}/Server/App.hs`
- `Template` `client.cabal.tpl` → `{{project.name}}-client/{{project.name}}-client.cabal`
- `Template` `client.hs.tpl` → `{{project.name}}-client/src/{{project.namespace}}/Client.hs`
- `Template` `gitignore.tpl` → `.gitignore` (appends one line to a file another module owns, if absent)
- `Template` `LICENSE.tpl` → `{{project.name}}-core/LICENSE`
- `Template` `LICENSE.tpl` → `{{project.name}}-api/LICENSE`
- `Template` `LICENSE.tpl` → `{{project.name}}-migrations/LICENSE`
- `Template` `LICENSE.tpl` → `{{project.name}}-workers/LICENSE`
- `Template` `LICENSE.tpl` → `{{project.name}}-server/LICENSE`
- `Template` `LICENSE.tpl` → `{{project.name}}-client/LICENSE`
