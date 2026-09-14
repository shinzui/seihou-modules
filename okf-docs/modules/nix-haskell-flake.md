---
type: SeihouModule
title: nix-haskell-flake
description: Nix flake for Haskell projects consuming the haskell-nix-dev base flake
  (prebuilt GHC/HLS/cabal); one rev-pinned base-flake URL that every other input follows,
  so a module version locks identically everywhere. Optional process-compose, PostgreSQL,
  socket-only Redis, ClickHouse, treefmt, pre-commit, and the paired haskell-nix patch
  registry
resource: seihou://seihou-modules/modules/haskell/nix-haskell-flake
tags:
- haskell
- nix
- flake
- devshell
status: stable
generated:
  by: seihou-okf-extension/0.8.0.0
version: 0.21.0
---

# nix-haskell-flake

Nix flake for Haskell projects consuming the haskell-nix-dev base flake (prebuilt GHC/HLS/cabal); one rev-pinned base-flake URL that every other input follows, so a module version locks identically everywhere. Optional process-compose, PostgreSQL, socket-only Redis, ClickHouse, treefmt, pre-commit, and the paired haskell-nix patch registry

**Version:** 0.21.0

## Dependencies

This module has no dependencies.

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project name (used in flake description and database name)
- `project.description` — text, required. One-line project description
- `ghc.version` — text, required, default `ghc9124`, matching `ghc[0-9]+`. Default/primary GHC for the generated project's `nix develop` shell. Must be a GHC attribute the haskell-nix-dev base flake supports (currently ghc9124 = GHC 9.12.4). Exported for dependent modules (e.g. haskell-library).
- `ghc.secondary` — text, optional. Optional second GHC attribute to expose as a named devShell (`nix develop .#<attr>`) alongside ghc.version, for cross-version testing. Must also be supported by the haskell-nix-dev base flake. Leave unset for a single-version project. (The engine has no list iteration, so exactly one extra version is supported here; use the dhall-text strategy if you need more.)
- `nix.process-compose` — boolean, required. Include process-compose in the dev shell and generate process-compose.yaml
- `nix.postgresql` — boolean, required. Include postgresql (and jq) in the dev shell with local DB setup in the shellHook. The postgresql package/major version is chosen by nix.pg-package (default `postgresql`).
- `nix.pg-database` — text, optional. Postgres database name used in the dev-shell shellHook (PGDATABASE and the derived PG_CONNECTION_STRING). Defaults to project.name when unset. Set it when the database name must differ from the (possibly hyphenated) project name — e.g. an underscore name like `notion_hub`, since unquoted hyphenated identifiers are invalid in Postgres. Only used when nix.postgresql is enabled.
- `nix.pg-package` — text, optional, default `postgresql`. nixpkgs attribute for the PostgreSQL package used in the dev shell — the server, client (initdb/pg_ctl/psql), and libpq `.dev` all come from it. Defaults to `postgresql` (nixpkgs' default major version). Set it to pin a specific major version, e.g. `postgresql_18`, so an existing local `./db` cluster keeps working across nixpkgs bumps that move the default. `nix.pg-extensions` builds against this same package, so headers and extensions stay on one major version. Only used when nix.postgresql is enabled.
- `nix.pg-extensions` — text, optional. Optional space-separated PostgreSQL extension attributes to build into the dev-shell postgresql via `withPackages`, e.g. `pgp.pg_partman pgp.postgis`. Each item is spliced verbatim into `pkgs.<nix.pg-package>.withPackages (pgp: [ … ])`, so include the `pgp.` prefix. Leave unset for a plain postgres. The extension-bearing server shares the same major version as `pkgs.<nix.pg-package>.dev`, so libpq headers still resolve. Only used when nix.postgresql is enabled.
- `nix.redis` — boolean, required, default `false`. Include Redis in the dev shell. The shellHook exports REDIS_SOCKET and REDIS_LOG beneath the project's local redis/ directory and, when nix.process-compose is enabled, process-compose.yaml gains a socket-only `redis` process with TCP disabled.
- `nix.clickhouse` — boolean, required, default `false`. Include clickhouse in the dev shell with a local, rootless server. The shellHook exports CLICKHOUSE_HOME (a per-project data dir) plus CLICKHOUSE_TCP_PORT/CLICKHOUSE_HTTP_PORT, and — when nix.process-compose is enabled — process-compose.yaml gains a `clickhouse` process that runs `clickhouse-server` against that data dir with a `SELECT 1` readiness probe. The server uses clickhouse's embedded default config; override ports via the env vars if two projects clash.
- `nix.kafka` — boolean, required, default `false`. Include librdkafka (rdkafka + rdkafka.dev) in the dev shell for hw-kafka-client-based projects. The shellHook exports CPATH, LIBRARY_PATH, and PKG_CONFIG_PATH so GHC's linker, the C preprocessor, and pkg-config resolve `-lrdkafka`. This adds the client library only; run your own Kafka-compatible broker (e.g. redpanda) as needed.
- `nix.redpanda` — boolean, required, default `false`. Generate nix/redpanda.nix: opt-in, macOS-only lifecycle scripts (redpanda-local-{up,down,status,logs,purge}) for a PRIVATE Redpanda cluster on Apple Container, whose names and host ports do not collide with the shared machine-wide cluster or other projects' private clusters. The default dev flow still targets the shared cluster; use this only when a test needs its own broker. Reuses the redpanda-container flake (added as a module-owned input) — on non-Darwin systems the module contributes nothing. Independent of nix.kafka (which only adds the librdkafka client library).
- `nix.redpanda-console` — boolean, required, default `false`. Also run Redpanda Console for the project-local cluster (adds a second container, bound to redpanda.console-port). Only used when nix.redpanda is enabled.
- `redpanda.kafka-port` — integer, optional, default `39092`. Host port for the project-local Redpanda Kafka API. Defaults to a high block (39092) distinct from the shared cluster's 9092. Change it when running two private clusters at once, or when it clashes with something else on the host. Only used when nix.redpanda is enabled.
- `redpanda.admin-port` — integer, optional, default `39644`. Host port for the project-local Redpanda Admin API (readiness probe). Defaults to 39644 (vs the shared cluster's 9644). Only used when nix.redpanda is enabled.
- `redpanda.schema-registry-port` — integer, optional, default `38081`. Host port for the project-local Redpanda Schema Registry. Defaults to 38081 (vs the shared cluster's 8081). Only used when nix.redpanda is enabled.
- `redpanda.proxy-port` — integer, optional, default `38082`. Host port for the project-local Redpanda HTTP (pandaproxy) endpoint. Defaults to 38082 (vs the shared cluster's 8082). Only used when nix.redpanda is enabled.
- `redpanda.console-port` — integer, optional, default `38080`. Host port for the project-local Redpanda Console. Defaults to 38080 (vs the shared cluster's 8080). Only used when nix.redpanda and nix.redpanda-console are enabled.
- `nix.treefmt` — boolean, required, default `true`. Include treefmt-nix and generate the nix/treefmt.nix flake-parts module (wires `nix fmt` and a formatting check)
- `nix.pre-commit` — boolean, required, default `true`. Include git-hooks.nix and generate the nix/pre-commit.nix flake-parts module
- `nix.haskell-nix` — boolean, required, default `false`. Add the shared haskell-nix patch registry (github:shinzui/haskell-nix) as a module-owned flake input, paired with this flake's haskell-nix-dev (`inputs.haskell-nix-dev.follows`, `inputs.nixpkgs.follows`) so the lock carries one haskell-nix-dev and one nixpkgs. Consume it from the unmanaged flake.module.nix via `inputs.haskell-nix.lib.haskellExtension` (see flake.module.nix.example), typically with nix.builtin-package = false. Its revision is pinned by the module next to haskell-nix-dev and moves with nix-haskell-flake releases.
- `nix.builtin-package` — boolean, required, default `true`. Emit a `packages.default = callCabal2nix project.name self` build in nix/haskell.nix. Set False for projects that define their own package build in the unmanaged flake.module.nix (e.g. a haskell-nix overlay supplying patched private dependencies); leaving it True there produces a duplicate `packages.default` and a flake-parts evaluation error.
- `nix.fourmolu-ghc-opts` — text, optional. Optional override for fourmolu's GHC options (the language extensions it must be told about, since it cannot auto-detect "manual" extensions). Leave unset to use treefmt-nix's defaults (BangPatterns, PatternSynonyms, TypeApplications). Set it when those defaults don't fit — e.g. a project that uses `pattern` as an identifier (lens-generated fields) must drop PatternSynonyms, or one using CPP must add it. Value is the space-separated, double-quoted, bare extension names spliced into a Nix list, e.g. `"BangPatterns" "TypeApplications" "CPP"` (no -X prefix; treefmt-nix adds it). Only used when nix.treefmt is enabled.

## Exports

- `project.name`
- `ghc.version`

## Prompts

- `project.name` — What is your project name?
- `project.description` — Describe your project in one line:
- `ghc.version` — Which GHC version? (must be supported by the haskell-nix-dev base flake) (choices: `ghc9124`)
- `nix.process-compose` — Include process-compose for service orchestration?
- `nix.postgresql` — Include PostgreSQL with local database setup?
- `nix.redis` — Include Redis with a local socket-only server?
- `nix.clickhouse` — Include ClickHouse with a local server?
- `nix.kafka` — Include Kafka client support (librdkafka for hw-kafka-client)?
- `nix.redpanda` — Add project-local Redpanda scripts on Apple Container (macOS only)?
- `nix.redpanda-console` — Also run Redpanda Console for the project-local cluster? — when `Eq nix.redpanda true`
- `nix.haskell-nix` — Include the shared haskell-nix patch registry as a flake input?
- `nix.treefmt` — Include treefmt-nix for code formatting (fourmolu, nixpkgs-fmt, cabal-gild)?
- `nix.pre-commit` — Include pre-commit hooks via git-hooks.nix?

## Generation steps

- `Template` `flake.nix.tpl` → `flake.nix`
- `Template` `nix/haskell.nix.tpl` → `nix/haskell.nix`
- `Template` `nix/treefmt.nix.tpl` → `nix/treefmt.nix` — when `Eq nix.treefmt true`
- `Template` `nix/pre-commit.nix.tpl` → `nix/pre-commit.nix` — when `Eq nix.pre-commit true`
- `Template` `nix/redpanda.nix.tpl` → `nix/redpanda.nix` — when `Eq nix.redpanda true`
- `Template` `flake.module.nix.example.tpl` → `flake.module.nix.example`
- `Copy` `flake.lock` → `flake.lock`
- `Copy` `fourmolu.yaml` → `fourmolu.yaml`
- `Template` `process-compose.yaml.tpl` → `process-compose.yaml` — when `Eq nix.process-compose true`
- `Template` `process-compose.override.yaml.example.tpl` → `process-compose.override.yaml.example` — when `Eq nix.process-compose true`
- `Template` `envrc.tpl` → `.envrc`
- `Template` `gitignore-envrc.tpl` → `.gitignore` (appends one line to a file another module owns, if absent)
- `Template` `gitignore-haskell.tpl` → `.gitignore` (appends one line to a file another module owns, if absent)
- `Template` `gitignore-precommit.tpl` → `.gitignore` (appends one line to a file another module owns, if absent) — when `Eq nix.pre-commit true`
- `Template` `gitignore-redis.tpl` → `.gitignore` (appends one line to a file another module owns, if absent) — when `Eq nix.redis true`
- `Template` `gitignore-clickhouse.tpl` → `.gitignore` (appends one line to a file another module owns, if absent) — when `Eq nix.clickhouse true`

## Migrations

### 0.10.0 → 0.11.0

- delete `treefmt.nix`
