# Migrate this Haskell flake to flake-parts on the haskell-nix-dev base flake

You are converting **this** Haskell project's Nix flake — in place — from its
current monolithic shape to the thin, modular **flake-parts** structure that
consumes the shared `haskell-nix-dev` base flake. Every shinzui Haskell project
is being moved to this one structure so the whole fleet shares a single pinned
GHC (9.12.4), a single nixpkgs, one toolchain derivation, and one binary cache.

This is a blueprint, not a mechanical transform. Each project differs in its
custom inputs, overlay, dev-shell tools, formatter set, custom checks, and
package names. Your job is to **read what this project actually has** and carry
**every** customization across — losing none — while reshaping the files.

## Critical rules (read first)

- **GHC bump.** Old flakes pin `ghc9122` (GHC 9.12.2). The base flake supports
  **only `ghc9124` (GHC 9.12.4)**. Every reference to the compiler moves to
  `ghc9124`. This is the one intended behavior change.
- **Never edit Haskell source.** If the project's Haskell code fails to compile
  under GHC 9.12.4, **stop and report the exact compiler error verbatim**. Do
  not patch `.hs`/`.cabal` source to make it build — that is a separate,
  reviewable concern. The flake restructure is your only job.
- **Never commit and never push.** You convert files in place; a human reviews
  the diff and commits. Do not run `git commit`, `git push`, `git add`, or any
  history-changing git command. `git status` and `git diff` are fine.
- **Preserve every customization.** Do not drop a single custom input, overlay,
  dev-shell tool, formatter, custom hook, custom check, or package output. When
  in doubt, carry it over and note it.

## Reference material

The blueprint's `files/` directory is mounted read-only and listed under
"## Reference Files". It mirrors the **target tree**:

- `flake.nix` — the thin stub (inputs + `mkFlake` with the imports list).
- `nix/haskell.nix` — the dev shell via `mkDevShell`.
- `nix/treefmt.nix` — treefmt-nix flake module.
- `nix/pre-commit.nix` — git-hooks.nix flake module.
- `flake.module.nix` — **unmanaged** package build + custom checks (shows both
  the overlay-graft variant and the no-overlay `callCabal2nix` variant).

Treat the four managed files (`flake.nix`, `nix/haskell.nix`, `nix/treefmt.nix`,
`nix/pre-commit.nix`) as near-canonical: they are nearly identical across
projects. The only per-project edits in them are the `description`, the
`extraNativeBuildInputs` dev-tool list, the formatter set, and the custom
pre-commit hooks. `flake.module.nix` is fully project-specific — adapt it.

## The base flake's contract (what you build on)

`inputs.haskell-nix-dev.lib.${system}.mkDevShell` takes
`{ ghc ? "ghc9124", extraNativeBuildInputs ? [ ], withHls ? true, shellHook ? "" }`
and returns a dev shell that **already provides** the GHC compiler, `cabal`,
HLS (when `withHls`), `pkg-config`, `zlib`, and a `LANG=en_US.UTF-8` export. So
in `extraNativeBuildInputs` list only the tools BEYOND those (e.g. `pkgs.just`,
`pkgs.sqlite`, `pkgs.xz`). Consumers set
`inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs"` to inherit the pinned
nixpkgs.

The shared overlay library exposes
`inputs.haskell-nix.lib.haskellExtension : haskellLib -> pkgs -> overlay`, used
as `inputs.haskell-nix.lib.haskellExtension pkgs.haskell.lib.compose pkgs` and
composed with the project's local `nix/haskell-overlay.nix` via
`pkgs.lib.composeExtensions`.

## How to proceed

### 1. Inspect the existing flake

Before writing anything, read and record:

- The current `flake.nix`: its `description`, every entry in `inputs` (note
  which are project-specific: `haskell-nix`, any `*-src` non-flake inputs), and
  how `outputs` is currently structured.
- Any existing `nix/*.nix` files, especially `nix/haskell-overlay.nix` (keep it
  as-is) and any custom check scripts (e.g. `nix/*.sh`).
- A top-level `treefmt.nix` if present (its content moves into `nix/treefmt.nix`,
  then the top-level file is deleted).
- The current GHC pin (expect `ghc9122`), the dev-shell tool list, the formatter
  set, any pre-commit hooks, any custom flake `checks`, and the package
  name(s) / Haskell attribute name(s) the flake exposes as `packages.*`.
- Whether the project is **Tier A** (already imports `haskell-nix-dev` and has a
  `nix/haskell-overlay.nix`) or **Tier B** (a plain nixpkgs flake using
  `flake-utils`/`eachDefaultSystem`, no base flake, no overlay). Tier B also
  needs the `haskell-nix-dev` input added and the toolchain moved to
  `mkDevShell`.

### 2. Write the target files

Create/overwrite, modeling each on the reference but specialized to this repo:

- **`flake.nix`** — the stub. Keep the original `description`. Declare the
  standard inputs (`haskell-nix-dev`, followed `nixpkgs`, `flake-parts`,
  `treefmt-nix`, `pre-commit-hooks`) plus **every** project-specific input the
  old flake had (`haskell-nix` and any `*-src`). **Drop `flake-utils`** — it is
  no longer used. The `outputs` is the `mkFlake` call with the imports list
  exactly as in the reference.
- **`nix/haskell.nix`** — the dev shell. Put the project's extra dev tools in
  `extraNativeBuildInputs` (only those not already provided by `mkDevShell`).
- **`nix/treefmt.nix`** — the project's formatter set (default: nixpkgs-fmt +
  fourmolu + cabal-gild from the ghc9124 set; add any others the old config had).
- **`nix/pre-commit.nix`** — the `treefmt` hook plus every custom hook the old
  flake had. Move any custom hook script (e.g. a `*.sh`) under `nix/`.
- **`flake.module.nix`** — the package build and any custom checks. Use the
  overlay-graft variant when the project has `nix/haskell-overlay.nix`; use the
  `callCabal2nix` variant for a Tier B project without one. Set
  `packages.<name>` and `packages.default` to the right Haskell attribute, and
  bake the git revision (`inputs.self.shortRev or "dirty"`) if the old flake
  did. Move every custom flake `check` here too. For a pure library that exposes
  no package output, you may omit `flake.module.nix` entirely.

Then **delete the top-level `treefmt.nix`** if it existed. **Keep
`nix/haskell-overlay.nix`** unchanged.

### 3. Regenerate the lock and verify

**First make the new files visible to Nix.** Nix flakes only evaluate files
that git tracks, so the files you just created (`nix/haskell.nix`,
`nix/treefmt.nix`, `nix/pre-commit.nix`, `flake.module.nix`, and any moved hook
script) are invisible until git knows about them. Register them as
**intent-to-add** so they are seen without staging their content:

```
git add -N nix/haskell.nix nix/treefmt.nix nix/pre-commit.nix flake.module.nix
```

Do **not** `git reset` or otherwise un-add them afterward — leave them
intent-to-added so the human reviewer's `nix build` also sees them. (Adding the
file deletion of the old top-level `treefmt.nix` is not required for evaluation.)

Then run, from the project root:

```
nix flake lock
nix eval --raw ".#devShells.aarch64-darwin.default.drvPath"
nix eval ".#checks.aarch64-darwin" --apply 'builtins.attrNames'
nix build ".#<package>" -L --accept-flake-config
```

Expected: `flake.lock`'s root inputs now include `haskell-nix-dev` and
`flake-parts` and no longer include a top-level `flake-utils`; the dev shell
evaluates to a derivation path; the checks list includes at least `treefmt` and
`pre-commit` (plus any custom check); and the package builds. If the project has
a Nix-run test suite, it should pass.

The first ghc9124 build of a large dependency closure is **slow** — 9.12.4 is
not the nixpkgs default and is not on the public binary cache, so dependencies
compile from source. This is expected, not a failure. Do not mistake a slow
first build for a hang.

If the build fails because the project's **Haskell source** does not compile on
9.12.4, stop and report the exact error (see Critical rules) — do not edit
source. If it fails because of a **flake wiring mistake** (a missing input, a
wrong attribute name, an un-carried overlay), fix the wiring and re-verify.

**Stale shared-registry pin.** `nix flake lock` preserves any input revision that
was already locked, so a project whose old `flake.lock` pinned an out-of-date
`haskell-nix` (the shared registry overlay) will keep that stale rev. If the
build fails with a missing shinzui package the registry is supposed to provide
(for example `called without required argument 'baikai'`) **and** the project's
`haskell-nix` input is *unpinned* (`github:shinzui/haskell-nix` with no `/rev`),
bump just that input — `nix flake update haskell-nix` — and rebuild. Do **not**
bump a `haskell-nix` input that is deliberately pinned to a specific revision
(`github:shinzui/haskell-nix/<rev>`); a missing package there is a real pin
mismatch to report, not auto-fix.

### 4. Hand off

When the files match the target structure and (where buildable) the package
builds, summarize for the human reviewer:

- which inputs, dev tools, formatters, hooks, checks, and package outputs you
  carried over, and where each landed;
- that the GHC pin moved from 9.12.2 to 9.12.4;
- the output of the `nix eval`/`nix build` verification;
- anything you could not resolve (e.g. a source compile failure), quoted exactly.

Do **not** commit or push. The human reviews the diff and commits.
