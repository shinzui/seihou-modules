# nix-haskell-flake

> Modular [flake-parts](https://flake.parts) Nix flake for Haskell projects, consuming the `haskell-nix-dev` base flake (prebuilt GHC/HLS/cabal toolchains). Every module-owned input is decided by one rev-pinned `haskell-nix-dev` URL that the rest `follows`, so each module version locks to byte-identical pins across projects and `nix flake update` cannot drift them. Project wiring lives in imported `nix/*.nix` modules and user customizations go in an unmanaged `flake.module.nix`, so template upgrades migrate without conflict. Toggleable process-compose, PostgreSQL, socket-only Redis, ClickHouse, treefmt-nix, and pre-commit-hooks.

**Version:** `0.17.0`

## Overview

Generates a reproducible Nix development environment for a Haskell project, structured as a
[flake-parts](https://flake.parts) flake so the seihou-managed surface stays small and
regenerates cleanly across upgrades.

The generated `flake.nix` is a thin, stable **stub**: it declares inputs, calls
`flake-parts.lib.mkFlake`, and imports a handful of modules. All real wiring lives in
`nix/*.nix` modules, and the toolchain itself lives in the `haskell-nix-dev` base flake
(`github:shinzui/haskell-nix-dev`) — so:

- The generated flake has **exactly one pin of its own** — a rev-pinned `haskell-nix-dev`
  URL — and every other module-owned input (`nixpkgs`, `flake-parts`, `treefmt-nix`,
  `pre-commit-hooks`) `follows` it. The whole locked graph is therefore a pure function of
  that one rev, so two projects on the same module version get **byte-identical pins and one
  shared store closure**. See [Reproducible locks](#reproducible-locks).
- Each devShell is built from the base flake's `lib.${system}.mkDevShell` (GHC + `cabal` + HLS;
  HLS prebuilt from the base flake's cache once published, rather than compiled from source).
- The project's own package is built with `callCabal2nix` against the followed nixpkgs.

### Generated layout

```
flake.nix                  # seihou-managed stub: inputs + mkFlake + imports
flake.lock                 # seihou-managed seed; derivable from flake.nix (see below)
nix/
  haskell.nix              # seihou-managed: devShells (mkDevShell) + package (callCabal2nix)
  treefmt.nix              # seihou-managed: treefmt-nix flake-parts module   (nix.treefmt)
  pre-commit.nix           # seihou-managed: git-hooks flake-parts module     (nix.pre-commit)
flake.module.nix.example   # template you copy to flake.module.nix (see "Extending")
process-compose.yaml       # (nix.process-compose)
.envrc                     # watches imported modules, then loads the dev shell
.gitignore
```

The generated `.envrc` explicitly watches `nix/haskell.nix`, the optional
treefmt and pre-commit modules, and the optional unmanaged `flake.module.nix`
before `use flake`. This prevents nix-direnv from retaining an obsolete dev
shell or pre-commit wrapper after an imported module changes.

## Reproducible locks

The point of this module is that every project it generates resolves to the **same** GHC,
HLS, cabal and nixpkgs — one store closure, one warm cache — while still letting each project
add inputs of its own.

### One pin, everything else follows

```nix
inputs = {
  haskell-nix-dev.url = "github:shinzui/haskell-nix-dev/<rev>";   # the only pin
  nixpkgs.follows          = "haskell-nix-dev/nixpkgs";
  flake-parts.follows      = "haskell-nix-dev/flake-parts";
  treefmt-nix.follows      = "haskell-nix-dev/treefmt-nix";       # (nix.treefmt)
  pre-commit-hooks.follows = "haskell-nix-dev/pre-commit-hooks";  # (nix.pre-commit)
};
```

Two properties fall out of this, and together they are the whole guarantee:

- **The rev is in `flake.nix`, not only in `flake.lock`.** A rev-pinned input is already
  fully resolved, so `nix flake update` — the command that updates *everything* — cannot move
  it. Run it in a generated project and `git diff flake.lock` comes back empty. A branch ref
  (`github:shinzui/haskell-nix-dev`) has the opposite behaviour: it is re-resolved to whatever
  `master` is that day, silently moving one project off the shared toolchain.
- **Nothing else is pinned here at all.** The remaining inputs `follows` the base flake, so
  their revs are read out of *that* flake's `flake.lock` at the pinned rev. There is no second
  place for them to drift and no per-input bump to keep in sync — see the base flake's
  "Re-exported inputs" section.

The shipped `flake.lock` is therefore a **seed, not the source of truth**: it saves the first
`nix flake lock` a network round trip, and `nix flake lock` would reproduce it from `flake.nix`
alone. It is generated with every optional input switched on, so a project with any
combination of `nix.treefmt` / `nix.pre-commit` finds its nodes already present.

### `git add flake.lock` — immediately

Inside a git work tree, **Nix cannot see a `flake.lock` that git does not track.** A freshly
generated project whose lock is still untracked gets its inputs re-resolved from scratch on
the first `nix develop` or direnv load, which is exactly the "why did this project build its
own GHC?" failure. The generated `.envrc` checks for this and logs an error, but the fix is
simply to stage the lock with the rest of the scaffold:

```bash
git add flake.nix flake.lock nix/
```

### Adding inputs of your own

You can, and it costs you nothing: `nix flake lock` only *appends* nodes for inputs that are
missing, leaving every existing pin alone. Two rules keep it that way:

- **Pin your extra inputs by rev too** (`github:owner/repo/<rev>`). A rev-pinned extra is
  immune to everything below; a branch-ref extra can be re-resolved by a full update or by
  the recovery command in the next section.
- **Never run bare `nix flake update`.** It cannot touch the module-owned inputs, but it will
  bump every branch-ref input you added. Update yours by name: `nix flake update my-input`.

Note that adding an input means editing the managed `flake.nix`, which is a conflict at the
next `seihou run` (resolve with **accept new** and re-apply). Everything that does *not*
require a new input belongs in the unmanaged `flake.module.nix` instead.

### Moving the toolchain

The pinned rev ships in the module template, so the module version **is** the toolchain
generation. Move a project by moving it to a newer module version:

```bash
seihou update nix-haskell-flake     # or: seihou run nix-haskell-flake --with-migrations
git add flake.nix flake.lock && nix develop
```

Do not edit the rev in the generated `flake.nix`: it will be overwritten at the next run, and
in the meantime that project is alone on its toolchain. If a project genuinely needs a
different base-flake rev, override it in the lock instead, which leaves the managed file
untouched:

```bash
nix flake lock --override-input haskell-nix-dev github:shinzui/haskell-nix-dev/<rev>
```

### Recovering a drifted project

If a project's lock has already wandered off (someone ran `nix flake update`, or it was
generated before this module rev-pinned its inputs), snap the module-owned inputs back to the
canonical pins without disturbing your own:

```bash
nix flake lock \
  --reference-lock-file ~/.config/seihou/installed/nix-haskell-flake/files/flake.lock \
  --output-lock-file flake.lock
```

Inputs present in the reference take its pins; anything else is re-resolved — which is why
extra inputs should carry their own rev. Check the result with
`nix flake metadata --json | jq '.locks.nodes["haskell-nix-dev"].locked.rev'`.

## Extending your project (without migration conflicts)

`flake.nix` and everything under `nix/` are **seihou-managed**: they are regenerated by
`seihou run` and by module migrations. Editing them means accepting a conflict the next time
this module upgrades.

To customize **without conflicts**, copy the example to an unmanaged module:

```bash
cp flake.module.nix.example flake.module.nix
```

`flake.nix` imports it automatically when present:

```nix
imports = [ ./nix/haskell.nix … ]
  ++ nixpkgs.lib.optional (builtins.pathExists ./flake.module.nix) ./flake.module.nix;
```

seihou **never generates, touches, or migrates** `flake.module.nix`, so anything you put there
survives template upgrades untouched. It is an ordinary flake-parts module. Common extensions:

- **Dev-shell tools** (conflict-free, via the option declared in `nix/haskell.nix`):
  ```nix
  perSystem.haskellProject.extraDevPackages = [ pkgs.ghciwatch pkgs.haskellPackages.hpack ];
  ```
- **Extra outputs** — `perSystem.packages.*`, `perSystem.apps.*`, `perSystem.checks.*`, or an
  extra named `perSystem.devShells.<name>`.

**The one exception:** adding a brand-new flake **input** must be done in `flake.nix`'s
top-level `inputs` (a Nix requirement — inputs cannot be declared from an imported module).
That single edit will conflict on the next migration; resolve it with **accept new** and re-add
your input line. Everything else stays clean.

## Variables

| Name | Type | Default | Required | Validation | Description |
|------|------|---------|----------|------------|-------------|
| `project.name` | `text` | — | yes | `[a-z][a-z0-9-]*` | Project name (used in flake description and database name) |
| `project.description` | `text` | — | yes | — | One-line project description |
| `ghc.version` | `text` | `ghc9124` | yes | `ghc[0-9]+` | Default/primary GHC for the project's `nix develop` shell. Must be a GHC attribute the `haskell-nix-dev` base flake supports (currently `ghc9124` = GHC 9.12.4). Exported for dependent modules. |
| `ghc.secondary` | `text` | — | no | — | Optional second GHC attribute exposed as `nix develop .#<attr>` for cross-version testing. Must also be base-flake-supported. Leave unset for a single-version project. (Exactly one extra version is supported.) |
| `nix.process-compose` | `bool` | — | yes | — | Include process-compose in the dev shell and generate `process-compose.yaml` |
| `nix.postgresql` | `bool` | — | yes | — | Include postgresql (and `jq`) in the dev shell with local DB setup in the shellHook |
| `nix.redis` | `bool` | `false` | yes | — | Include `redis-server` and `redis-cli` in the dev shell. The shellHook exports `REDIS_SOCKET` and `REDIS_LOG` beneath the project-local `redis/` directory; when `nix.process-compose` is on, `process-compose.yaml` gains a socket-only `redis` process with TCP disabled. |
| `nix.clickhouse` | `bool` | `false` | yes | — | Include `clickhouse` in the dev shell with a local, rootless server. The shellHook exports `CLICKHOUSE_HOME` (per-project data dir) and `CLICKHOUSE_TCP_PORT`/`CLICKHOUSE_HTTP_PORT`; when `nix.process-compose` is on, `process-compose.yaml` gains a `clickhouse` process running `clickhouse-server` with a `SELECT 1` readiness probe. Uses clickhouse's embedded default config; override the ports if two projects clash. |
| `nix.treefmt` | `bool` | `true` | yes | — | Include treefmt-nix and generate the `nix/treefmt.nix` flake-parts module (wires `nix fmt` and a formatting check) |
| `nix.pre-commit` | `bool` | `true` | yes | — | Include git-hooks.nix and generate the `nix/pre-commit.nix` flake-parts module |
| `nix.fourmolu-ghc-opts` | `text` | — | no | — | Optional override for fourmolu's GHC options (the language extensions it must be told about, since it can't auto-detect "manual" ones). Leave unset to use treefmt-nix's defaults (`BangPatterns`, `PatternSynonyms`, `TypeApplications`). Set it when those don't fit — e.g. a project that uses `pattern` as an identifier (lens-generated fields) must drop `PatternSynonyms`, or one using CPP must add it. Value is the space-separated, double-quoted, bare extension names spliced into a Nix list, e.g. `"BangPatterns" "TypeApplications" "CPP"` (no `-X` prefix; treefmt-nix adds it). Only used when `nix.treefmt` is enabled. |

## Prompts

The following values are asked interactively (unless supplied via `--var`):

- **`project.name`** — What is your project name?
- **`project.description`** — Describe your project in one line:
- **`ghc.version`** — Which GHC version? (must be supported by the haskell-nix-dev base flake)
  - Choices: `ghc9124`
- **`nix.process-compose`** — Include process-compose for service orchestration?
- **`nix.postgresql`** — Include PostgreSQL with local database setup?
- **`nix.redis`** — Include Redis with a local socket-only server?
- **`nix.clickhouse`** — Include ClickHouse with a local server?
- **`nix.treefmt`** — Include treefmt-nix for code formatting (fourmolu, nixpkgs-fmt, cabal-gild)?
- **`nix.pre-commit`** — Include pre-commit hooks via git-hooks.nix?

`ghc.secondary` has no prompt — supply it with `--var ghc.secondary=<attr>` when you want a
second devShell. Likewise `nix.fourmolu-ghc-opts` has no prompt — supply it with
`--var nix.fourmolu-ghc-opts='"BangPatterns" "TypeApplications" "CPP"'` when the default
fourmolu extensions don't suit the project.

## Exports

Variables this module exposes to parent modules:

- `project.name`
- `ghc.version`

## Generated Files

When run, this module writes:

- `flake.nix` — strategy: `template` (flake-parts stub)
- `nix/haskell.nix` — strategy: `template` (devShells via `mkDevShell`, package via `callCabal2nix`)
- `nix/treefmt.nix` — strategy: `template`
  - Applied when: `Eq nix.treefmt true`
- `nix/pre-commit.nix` — strategy: `template`
  - Applied when: `Eq nix.pre-commit true`
- `flake.module.nix.example` — strategy: `template` (copy to `flake.module.nix` to customize)
- `flake.lock` — strategy: `copy`; the canonical seed lock, generated with every optional
  input on so any toggle combination finds its nodes. Derivable from `flake.nix` — see
  [Reproducible locks](#reproducible-locks)
- `process-compose.yaml` — strategy: `template`
  - Applied when: `Eq nix.process-compose true`
  - Emits a `postgres` (+ `create_schema`) process when `nix.postgresql`, a socket-only `redis`
    process when `nix.redis`, and a `clickhouse` process when `nix.clickhouse`
- `.envrc` — strategy: `template`; watches every local module imported by
  `flake.nix` before loading the dev shell, and errors if `flake.lock` is untracked (Nix
  ignores an untracked lock and would re-resolve every input)
- `.gitignore` — strategy: `template`, patch `append-line-if-absent`
  - Appends `.envrc`, Haskell build artifacts (`dist`, `dist-*`, `cabal-dev`, `.direnv`,
    `cabal.project.local`, `result`, `result-*`), (when `nix.pre-commit`)
    `.pre-commit-config.yaml`, (when `nix.redis`) `redis/`, and (when `nix.clickhouse`)
    `clickhouse/`

## Redis socket interface

With `nix.redis=true`, entering the generated development shell creates the local `redis/`
directory and exports:

```bash
REDIS_SOCKET="$PWD/redis/redis.sock"
REDIS_LOG="$PWD/redis/redis.log"
```

When `nix.process-compose=true` as well, the generated `redis` process starts Redis in the
foreground with TCP port `0`, owner-only UNIX-socket permissions, and snapshot persistence
disabled. Applications and health checks connect through `REDIS_SOCKET`; no TCP host or port
is exported. UNIX-domain socket paths have platform limits; Redis 8.8.0 on macOS requires the
full path to be under 104 bytes, so use a shorter checkout path if `redis/redis.log` reports
that the socket path is too long.

## Migrations

| From | To | Effect |
|------|----|--------|
| `0.10.0` | `0.11.0` | Retire the top-level `treefmt.nix` (its config moved into `nix/treefmt.nix`). |
| `0.15.0` | `0.16.0` | `nix/treefmt.nix` switches the `.cabal` formatter from `cabal-fmt` to [`cabal-gild`](https://github.com/tfausak/cabal-gild). No migration ops — regenerating the file is enough. |
| `0.16.0` | `0.17.0` | `flake.nix` pins `haskell-nix-dev` by rev and `follows` it for `flake-parts` and `pre-commit-hooks` (previously their own branch-ref `url`s). `.envrc` gains an untracked-`flake.lock` guard. No migration ops — regenerating both files is enough. |

The `0.16.0` formatter swap needs no `seihou migrate` step: `seihou run nix-haskell-flake --force`
regenerates `nix/treefmt.nix` with `programs.cabal-gild.enable`. Expect a one-time reformat of every
`.cabal` file on the next `nix fmt` — cabal-gild's output differs from cabal-fmt's, and it also
formats `cabal.project` and `cabal.project.local`, which cabal-fmt left alone. Commit that reformat
on its own so it does not muddy later diffs.

The `0.17.0` pin change needs no `seihou migrate` step either: `seihou update
nix-haskell-flake` regenerates `flake.nix` and `.envrc`, and the copied `flake.lock` carries the
canonical pins. What to expect per project:

- **Default projects** (`nix.treefmt` and `nix.pre-commit` both on, the defaults) get the
  canonical lock verbatim. `nixpkgs` does not move in this release, so the GHC/HLS/cabal
  closure is untouched — no rebuild.
- **Projects with a toggle off** will have `nix flake lock` prune the unused nodes from the
  superset lock on the next `nix develop`, showing `flake.lock` as locally modified. Harmless;
  commit it.
- **Projects with inputs of their own** in `flake.nix`: the regenerated stub drops them, so
  re-add them (rev-pinned) after the update and re-lock. See
  [Adding inputs of your own](#adding-inputs-of-your-own).

Afterwards, verify the guarantee holds — this should print no diff:

```bash
nix flake update && git diff --exit-code flake.lock && echo "pins are immovable"
```

The `0.11.0` rewrite restructures the flake into flake-parts modules. The new `flake.nix` and
`nix/*.nix` files are (re)generated by `seihou run`; the migration only removes the orphaned
top-level `treefmt.nix` (a no-op for projects that never enabled treefmt).

```bash
seihou migrate nix-haskell-flake --dry-run   # preview
seihou migrate nix-haskell-flake             # apply, then regenerate with `seihou run`
# or, to do both in one step:
seihou run nix-haskell-flake --with-migrations
```

**Note on existing customized projects:** `flake.nix` and `nix/*.nix` are regenerated, so any
hand edits to those files become conflicts (resolve with **accept new** and move customizations
into `flake.module.nix`, or **keep current** to stay on the old structure). This is a one-time
cost; afterward, customizations living in `flake.module.nix` migrate without conflict. The
migration refuses to delete a hand-edited `treefmt.nix` without `--force`.

## Maintaining the pin (module maintainers)

`files/flake.nix.tpl` and `files/flake.lock` must move together — the lock is the render of
the template's pin, and a mismatch would hand new projects a lock that Nix immediately
rewrites. `scripts/update-nix-haskell-flake-lock.sh` in this repo is the only supported way to
move them:

```bash
./scripts/update-nix-haskell-flake-lock.sh              # bump to latest haskell-nix-dev master
./scripts/update-nix-haskell-flake-lock.sh --rev <rev>  # or pin a specific rev
./scripts/update-nix-haskell-flake-lock.sh --check      # CI: is the shipped pair current?
```

It rewrites the rev in the template, renders the **superset** flake (every optional input on),
locks it, and only then writes both files — after asserting two things that the whole
guarantee rests on:

1. `nix flake update` against the freshly generated lock is a **no-op**, i.e. every
   module-owned input really is decided by the one rev.
2. A **minimal** project (both toggles off) reusing that lock keeps the identical
   `haskell-nix-dev` and `nixpkgs` pins, i.e. pruning the optional nodes does not disturb the
   shared closure.

The script does not bump the module version or commit. After running it: bump `version` in
`module.dhall` and in `seihou-registry.dhall`, add a row to the Migrations table above saying
what moved (and whether `nixpkgs` moved, since that is what decides a toolchain rebuild), then
commit both files together.

To bump `flake-parts` or `pre-commit-hooks` rather than the toolchain, update them in the
`haskell-nix-dev` repo first — it owns those pins now — and then run this script against the
resulting rev.

## Removal

This module is **not removable** — `seihou remove nix-haskell-flake` will refuse. File
additions made by this module will have to be reverted manually.

## Usage

Apply the module:

```bash
seihou run nix-haskell-flake
```

With variable overrides:

```bash
seihou run nix-haskell-flake --var project.name=my-app --var nix.postgresql=true
```

Enable the project-local, socket-only Redis server:

```bash
seihou run nix-haskell-flake \
  --var project.name=my-app \
  --var nix.process-compose=true \
  --var nix.postgresql=false \
  --var nix.redis=true
```

Preview without writing files:

```bash
seihou run nix-haskell-flake --dry-run
```

## See Also

- `module.dhall` — full module definition and authoritative source
- `files/` — template sources (`flake.nix.tpl`, `nix/*.tpl`, `flake.module.nix.example.tpl`, …)
