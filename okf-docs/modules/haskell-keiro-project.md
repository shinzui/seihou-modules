---
type: SeihouModule
title: haskell-keiro-project
description: Six-package Keiro bootstrap with project-owned domain/API/test starters
  (Seihou 0.11.0.0+), OpenAPI, optional Mori inventory and managed Nix/test tooling
resource: seihou://seihou-modules/modules/haskell/haskell-keiro-project
tags:
- haskell
- keiro
- service
- bootstrap
status: stable
generated:
  by: seihou-okf-extension/0.16.0.0
version: 0.4.1
---

# haskell-keiro-project

Six-package Keiro bootstrap with project-owned domain/API/test starters (Seihou 0.11.0.0+), OpenAPI, optional Mori inventory and managed Nix/test tooling

**Version:** 0.4.1

## Declaration metadata

- description: `Six-package Keiro seed with project-named domain paths, injected servant-health probes, OpenAPI generation, Hurl/Hinagata test setup, and optional initial Mori inventory on nix-haskell-flake. The blueprint implements the domain.`

## Dependencies

- [nix-haskell-flake](/modules/nix-haskell-flake.md) (declaring registry) (with `nix.builtin-package` = `false`, `nix.package-module` = `nix/keiro-dev-tools.nix`, `nix.postgresql` = `true`, `nix.process-compose` = `true`)

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project base name; creates <name>-core, -api, -migrations, -workers, -server, and -client. Shared with the Nix environment.
- `project.description` — text, required. One-line synopsis used in Cabal files, the implementation brief, and the Nix flake description.
- `project.namespace` — text, required, matching `[A-Z][A-Za-z0-9]*`. Top-level Haskell module namespace (single segment, e.g. Rei). Used both as the source-tree directory and as the module prefix in generated .hs files.
- `project.author` — text, required, default `Nadeem Bitar`. Author name written into LICENSE and .cabal files
- `project.maintainer` — text, required, default `nadeem@gmail.com`. Maintainer email written into .cabal files
- `project.copyright-year` — text, required, default `2026`, matching `[0-9]{4}`. Copyright year written into LICENSE
- `keiro.context` — text, optional, matching `[a-z][a-z0-9-]*`. Optional logical DSL context override; paths and workspace identity always use project.name.
- `mori.prompt` — boolean, optional, default `true`. Internal prompt coordination: the blueprint asks once and suppresses the baseline module question, including after an empty skip.
- `mori.generate` — boolean, optional. Generate an initial local Mori inventory (no registration). Empty input skips.
- `mori.namespace` — text, optional, matching `[a-z][a-z0-9-]*`. Mori organization/user namespace; required when mori.generate=true. Separate from Haskell project.namespace.
- `mori.okf-bundles` — text, optional, default `[] : List Schema.OkfBundle.Type`. Dhall list expression of Schema.OkfBundle values added to the initial inventory. Schema names the pinned Mori schema. Does not create bundles or rewrite an existing inventory.
- `haskell.index-state` — text, required, default `2026-10-26T00:00:00Z`, matching `[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z`. Hackage index snapshot for the initial libraries; reverify the runtime cohort before adding domain dependencies.

## Exports

- `project.name`
- `project.namespace`

## Prompts

- `project.name` — `What is your project name? (lowercase, hyphenated; cabal packages will be <name>-core, -api, -migrations, -workers, -server, and -client)`
- `project.description` — ``One-line project synopsis (used as cabal `synopsis:` and the flake description):``
- `project.namespace` — `Top-level Haskell module namespace? (single PascalCase segment, e.g. Rei)`
- `project.author` — `Author name?`
- `project.maintainer` — `Maintainer email?`
- `project.copyright-year` — `Copyright year?`
- `mori.generate` — `Generate an initial mori.dhall with packages, dependencies, and the OpenAPI schema reference? (true/false; empty skips)` — when `Eq mori.prompt true`
- `mori.namespace` — `Mori organization/user namespace? (separate from the PascalCase Haskell namespace)` — when `Eq mori.generate true`
- `haskell.index-state` — `Hackage index-state for this bootstrap? (UTC timestamp)`

## Generation steps

- `Template` `cabal.project.tpl` → `cabal.project` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `Prelude.hs.tpl` → `{{project.name}}-core/src/{{project.namespace}}/Prelude.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `workspace.tpl` → `domain/{{project.name}}.keiro-workspace` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `shared.keiro.tpl` → `domain/{{project.name}}/shared.keiro` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `justfile.tpl` → `justfile` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `LICENSE.tpl` → `LICENSE` — Managed: owned and reconciled by Seihou updates
- `Template` `README.md.tpl` → `README.md` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `bootstrap.md.tpl` → `docs/bootstrap-keiro.md` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `core.cabal.tpl` → `{{project.name}}-core/{{project.name}}-core.cabal` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `core.hs.tpl` → `{{project.name}}-core/src/{{project.namespace}}/Bootstrap.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `api.cabal.tpl` → `{{project.name}}-api/{{project.name}}-api.cabal` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `api.hs.tpl` → `{{project.name}}-api/src/{{project.namespace}}/Api.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `openapi.hs.tpl` → `{{project.name}}-api/src/{{project.namespace}}/Api/OpenApi.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `openapi-main.hs.tpl` → `{{project.name}}-api/app/OpenApiMain.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `openapi-test.hs.tpl` → `{{project.name}}-api/test/OpenApiTest.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `health-test.hs.tpl` → `{{project.name}}-server/test/HealthTest.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `migrations.cabal.tpl` → `{{project.name}}-migrations/{{project.name}}-migrations.cabal` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `migrations.hs.tpl` → `{{project.name}}-migrations/src/{{project.namespace}}/Migrations.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `workers.cabal.tpl` → `{{project.name}}-workers/{{project.name}}-workers.cabal` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `workers.hs.tpl` → `{{project.name}}-workers/src/{{project.namespace}}/Workers/Registry.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `server.cabal.tpl` → `{{project.name}}-server/{{project.name}}-server.cabal` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `server.hs.tpl` → `{{project.name}}-server/src/{{project.namespace}}/Server/App.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `client.cabal.tpl` → `{{project.name}}-client/{{project.name}}-client.cabal` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `client.hs.tpl` → `{{project.name}}-client/src/{{project.namespace}}/Client.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `nix/keiro-dev-tools.nix.tpl` → `nix/keiro-dev-tools.nix` — Managed: owned and reconciled by Seihou updates
- `Template` `hurl-workbench.dhall.tpl` → `hurl-workbench.dhall` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `hinagata.yaml.tpl` → `hinagata.yaml` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `tests/api/health.hurl` → `tests/api/health.hurl` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `fixtures/bootstrap/fixture.sql` → `tests/fixtures/bootstrap/fixture.sql` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `scripts/keiro-test-env` → `scripts/keiro-test-env` — Managed: owned and reconciled by Seihou updates
- `Template` `mori.dhall.tpl` → `mori.dhall` — when `Eq mori.generate true` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `gitignore.tpl` → `.gitignore` (appends one line to a file another module owns, if absent) — Managed: owned and reconciled by Seihou updates
- `Template` `LICENSE.tpl` → `{{project.name}}-core/LICENSE` — Managed: owned and reconciled by Seihou updates
- `Template` `LICENSE.tpl` → `{{project.name}}-api/LICENSE` — Managed: owned and reconciled by Seihou updates
- `Template` `LICENSE.tpl` → `{{project.name}}-migrations/LICENSE` — Managed: owned and reconciled by Seihou updates
- `Template` `LICENSE.tpl` → `{{project.name}}-workers/LICENSE` — Managed: owned and reconciled by Seihou updates
- `Template` `LICENSE.tpl` → `{{project.name}}-server/LICENSE` — Managed: owned and reconciled by Seihou updates
- `Template` `LICENSE.tpl` → `{{project.name}}-client/LICENSE` — Managed: owned and reconciled by Seihou updates
