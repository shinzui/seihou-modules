---
type: SeihouModule
title: openapi-typescript-client
description: Reusable ESM TypeScript 7 client with Orval generation, status-specific
  Zod validation, and project-owned Bun workflows on nix-bun-flake
resource: seihou://seihou-modules/modules/typescript/openapi-typescript-client
tags:
- typescript
- bun
- openapi
- orval
- zod
- client
- nix
status: stable
generated:
  by: seihou-okf-extension/0.15.0.0
version: 0.2.1
---

# openapi-typescript-client

Reusable ESM TypeScript 7 client with Orval generation, status-specific Zod validation, and project-owned Bun workflows on nix-bun-flake

**Version:** 0.2.1

## Dependencies

- [nix-bun-flake](/modules/nix-bun-flake.md) (with `bun.starter-files` = `false`, `nix.package-module` = `nix/openapi-typescript-client.nix`, `nix.pre-commit` = `false`)

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`
- `project.description` — text, required
- `openapi.schema` — text, required, default `openapi.yaml`, matching `([A-Za-z0-9][A-Za-z0-9_-]*/)*[A-Za-z0-9][A-Za-z0-9_-]*[.](yaml|yml|json)`. Local OpenAPI document. Custom paths must already exist; only the default openapi.yaml is seeded.
- `mori.generate` — boolean, optional, default `false`. Seed an initial mori.dhall describing the client and its OpenAPI source; does not register the project.
- `mori.namespace` — text, optional, matching `[a-z][a-z0-9-]*`. Client project's Mori namespace; required when mori.generate=true.
- `mori.source-namespace` — text, optional, matching `[a-z][a-z0-9-]*`. Mori namespace of the project providing the OpenAPI schema; required when mori.generate=true.
- `mori.source-project` — text, optional, matching `[a-z][a-z0-9-]*`. Mori project name of the API provider (without its namespace); required when mori.generate=true.

## Exports

No exports declared.

## Prompts

- `mori.namespace` — Mori namespace for this client? — when `Eq mori.generate true`
- `mori.source-namespace` — Mori namespace of the OpenAPI source project? — when `Eq mori.generate true`
- `mori.source-project` — Mori project name of the OpenAPI provider (without namespace)? — when `Eq mori.generate true`

## Generation steps

- `Template` `package.json.tpl` → `package.json`
- `Copy` `tsconfig.json` → `tsconfig.json`
- `Copy` `tsconfig.build.json` → `tsconfig.build.json`
- `Copy` `justfile` → `justfile`
- `Copy` `oxlintrc.json` → `.oxlintrc.json`
- `Copy` `oxfmtrc.json` → `.oxfmtrc.json`
- `Copy` `orval.config.ts` → `orval.config.ts`
- `Copy` `redocly.yaml` → `redocly.yaml`
- `Copy` `src/index.ts` → `src/index.ts`
- `Copy` `src/client.ts` → `src/client.ts`
- `Copy` `src/transport.ts` → `src/transport.ts`
- `Copy` `scripts/compiler.ts` → `scripts/compiler.ts`
- `Copy` `scripts/schema.ts` → `scripts/schema.ts`
- `Template` `scripts/generate.ts.tpl` → `scripts/generate.ts`
- `Copy` `tests/client.test.ts` → `tests/client.test.ts` — when `Eq openapi.schema "openapi.yaml"`
- `Copy` `tests/types.ts` → `tests/types.ts` — when `Eq openapi.schema "openapi.yaml"`
- `Template` `README.md.tpl` → `README.md`
- `Template` `mori.dhall.tpl` → `mori.dhall` — when `Eq mori.generate true`
- `Copy` `openapi.yaml` → `openapi.yaml` — when `Eq openapi.schema "openapi.yaml"`
- `Copy` `nix/openapi-typescript-client.nix` → `nix/openapi-typescript-client.nix`
- `Copy` `gitignore-client` → `.gitignore` (appends one line to a file another module owns, if absent)

## Removal

- delete `nix/openapi-typescript-client.nix`
