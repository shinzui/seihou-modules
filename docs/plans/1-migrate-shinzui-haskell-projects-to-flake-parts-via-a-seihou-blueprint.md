---
id: 1
slug: migrate-shinzui-haskell-projects-to-flake-parts-via-a-seihou-blueprint
title: "Migrate shinzui Haskell projects to flake-parts via a seihou blueprint"
kind: exec-plan
created_at: 2026-06-03T23:15:41Z
---

# Migrate shinzui Haskell projects to flake-parts via a seihou blueprint

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.


## Purpose / Big Picture

Today the author's Haskell projects each carry a hand-written, monolithic `flake.nix`
(a Nix "flake" is the file that declares a project's build inputs and outputs). Each one
pins its own compiler and toolchain, so they drift apart, none of them share build
artifacts, and upgrading the toolchain means editing every project by hand. Three projects
(nihongo, kizamu, seihou) have already been converted to a newer, modular shape, and the
conversion turned out to require real per-project judgement rather than a mechanical edit.

After this plan is implemented, every shinzui-namespace Haskell project will use the same
thin, modular flake structure that consumes a single shared base flake
(`github:shinzui/haskell-nix-dev`), so that:

- Every project builds against the **same pinned GHC (9.12.4) and nixpkgs**, through one
  shared lock, and therefore shares one toolchain derivation and one binary cache. You can
  verify lockstep at any time by running, from
  `/Users/shinzui/Keikaku/bokuno/haskell-nix-dev`, the command `just check-toolchain`, which
  prints every consumer and a single shared revision.
- Each project's own build customizations live in an **unmanaged** `flake.module.nix`, so
  future template upgrades regenerate the managed files without ever conflicting with the
  user's edits.
- New projects and future toolchain bumps are one-liners (`just update-toolchain`) instead
  of per-repo surgery.

The user-visible outcome a reviewer can observe: in any migrated project, `nix build` and
`nix develop` work on GHC 9.12.4; `nix flake check` runs that project's checks; and
`just check-toolchain` (from the base flake repo) lists the project as sharing the one
toolchain revision with all the others.

Because converting a project is non-mechanical (every project has different custom inputs,
overlays, dev-shell tools, and checks), the vehicle for the migration is a **seihou
blueprint** — an agent-driven, repeatable upgrade that a human reviews per project — not a
deterministic template migration. Authoring that blueprint, and then running it across the
fleet, is the work of this plan.


## Progress

Use a checklist to summarize granular steps. Every stopping point must be documented here,
even if it requires splitting a partially completed task into two ("done" vs. "remaining").
This section must always reflect the actual current state of the work.

- [x] Establish and validate the target flake structure by hand on three reference projects:
  nihongo (commit 880059e), kizamu (commit 0e0208d), seihou (commit a93b7f7). Each builds on
  GHC 9.12.4 and is committed (not pushed).
- [x] Ship the `nix-haskell-flake` template at version 0.11.0 in this repo
  (`modules/haskell/nix-haskell-flake`), and a lockstep toolchain updater in the base flake
  (`/Users/shinzui/Keikaku/bokuno/haskell-nix-dev/scripts/update-haskell-toolchain.sh`,
  commit f9ca9c6).
- [x] Inventory and classify all shinzui Haskell flakes (see Context and Orientation for the
  full classification; recorded 2026-06-03).
- [x] Milestone 1 (2026-06-03): Authored the `upgrade-haskell-flake-parts` blueprint at
  `blueprints/upgrade-haskell-flake-parts/` (blueprint.dhall, prompt.md, README.md, and a
  `files/` tree mirroring the target: `flake.nix`, `nix/{haskell,treefmt,pre-commit}.nix`,
  `flake.module.nix`). Registered it in `seihou-registry.dhall` under a new `blueprints` field
  and ran `seihou registry sync-versions` (which also corrected pre-existing module version
  drift). `seihou validate-blueprint blueprints/upgrade-haskell-flake-parts` exits 0
  ("Blueprint 'upgrade-haskell-flake-parts' is valid."), `seihou registry validate` is clean,
  and `seihou agent --debug run upgrade-haskell-flake-parts` renders a coherent 256-line system
  prompt embedding the full recipe and all five reference-file descriptions. The blueprint is
  made resolvable-by-name from any project directory via a symlink into the XDG modules search
  path (see Decision Log).
- [x] Milestone 2 (2026-06-03): Proved the blueprint on notion-cli
  (`/Users/shinzui/Keikaku/bokuno/notion-cli`, committed 385f280). The conversion (emulated by
  spawning an agent with the blueprint's prompt scoped to the project — see Decision Log on how
  the blueprint is "run" given `seihou agent run` is interactive) produced a structurally
  correct result on the first pass: thin `flake.nix` stub, `nix/{haskell,treefmt,pre-commit}.nix`,
  Variant-A `flake.module.nix` (overlay graft, `notion-client-src` passed through, `gitRev`
  baked, `packages.notion-cli-exe`/`default`), `treefmt.nix` deleted, `nix/haskell-overlay.nix`
  kept, `flake-utils` dropped, `nixpkgs` follows `haskell-nix-dev`. `.#checks.aarch64-darwin` =
  `[ "pre-commit" "treefmt" ]`; `nix build .#notion-cli-exe` passed on GHC 9.12.4 (closure
  compiled from source, expected); the binary runs: `ntn v0.1.0.0 (dirty)` (baked git revision
  preserved). One prompt weakness was found and fixed: the agent must leave new files
  **intent-to-added** (`git add -N`) so both `nix eval` and the reviewer's `nix build` see them
  (flakes ignore untracked files). Blueprint re-validated after the fix.
- [~] Milestone 3 (in progress, 2026-06-03): Sweep the (mis-labeled) "Tier A" projects. All six
  are the notion-cli shape (eachDefaultSystem + nixpkgs-direct + overlay, ghc9122) — see
  Surprises. Status:
  - kiroku — converted, built (kiroku-cli + default on ghc9124), committed 8afe049 (flake files
    staged selectively; two unrelated untracked docs left alone).
  - mina — converted (mina-ui npm UI wired into overlay + as package); needed
    `nix flake update haskell-nix` (stale lock hid `baikai`); built (mina-cli + mina-ui on
    ghc9124), committed cc8c87b.
  - mori-rei-app — converted (postgres shellHook, 5 *-src), haskell-nix is *pinned* (0fbd035);
    build pending.
  - mori (on branch spike/keiro-feasibility) — converted (6 *-src, postgres shellHook, gitRev),
    haskell-nix bumped to 1e718f3. **DEFERRED — converted-but-unbuilt**: mori-core depends on
    the registry `keiro`, whose haskell-nix patch is broken (see Surprises). Conversion left in
    the working tree, uncommitted; re-run the blueprint once the registry `keiro` patch is fixed.
  - rei — converted (9 *-src, ast-grep custom pre-commit hook, postgres+pg_cron shellHook),
    haskell-nix bumped to 1e718f3; built on ghc9124 (`rei 5.0.0.0`), committed 2683d21b.
  - reiko — converted (reiko-ui npm UI + custom reiko/reiko-ui checks; previously had no
    treefmt/pre-commit wiring), haskell-nix bumped to 1e718f3; build pending.
  - notion-hub (added at user request, see Decision Log) — converted (3 packages incl custom
    notion-hub-subscriptions; 7 *-src; gogol overlay + cabal.project preserved); build in
    progress.
- [ ] Milestone 4: Sweep the Tier B projects (plain nixpkgs flakes; full migration).
- [ ] Milestone 5: Confirm fleet-wide lockstep and write the retrospective.


## Surprises & Discoveries

Document unexpected behaviors, bugs, optimizations, or insights discovered during
implementation. Provide concise evidence.

- A deterministic seihou module-migration (the `migrations` field with `MoveFile`/`DeleteFile`
  operations) cannot perform this conversion. The reference projects each diverged in ways a
  mechanical transform cannot preserve: nihongo carries a KanjiVG corpus input and binary
  wrapping; kizamu carries an aarch64 blake3 SIMD/NEON fixup and Hackage pins; seihou carries
  a custom `cli-module-placement` check wired into both pre-commit and a standalone flake
  check. This is the evidence that motivated using an agent-driven blueprint instead.

- The GHC bump is the dominant build cost, not a regression. nixpkgs' *default* Haskell set is
  GHC 9.10.3; the projects target 9.12.4, which is **not** built by Hydra, so the entire
  dependency closure compiles from source the first time. Evidence: querying cache.nixos.org
  for `servant` built against ghc9124 returns "don't know how to build these paths". Once
  built, those derivations are shared across all projects that pin the same nixpkgs, so the
  cost is paid once for the fleet, not once per project.

- A blueprint's `allowedTools` field is currently **inert** for `seihou agent run`. Evidence:
  `seihou-cli/src-exe/Seihou/CLI/AgentRun.hs:206` launches the claude-cli/codex-cli provider
  with the hard-coded `setupAllowedTools` list (`AgentLaunch.hs:93`), and `renderSystemPrompt`
  (`AgentRun.hs:408`) never references `bp.allowedTools`. So the field is validated (entries
  must be non-empty) but neither enforced as CLI permissions nor surfaced to the agent. The
  blueprint still declares a restrictive `allowedTools` as documented intent, but the
  **"never commit / never push" guarantee rests on the prompt instruction, not the tool
  allowlist** — and note `setupAllowedTools` actually grants `Bash(git *)`, which would permit
  a commit if the prompt did not forbid it.

- Blueprints are resolved **by directory name** under the three `defaultSearchPaths`
  (`Seihou/Core/Module.hs:123`): `<cwd>/.seihou/modules`, `~/.config/seihou/modules`,
  `~/.config/seihou/installed`. They are *not* discovered from a repo's local
  `seihou-registry.dhall`. Consequence: `seihou agent run <name>` and `seihou list` do not see
  a freshly authored local blueprint until it is installed (`seihou install`, which snapshots
  into `installed/`) or otherwise placed on a search path. For the authoring/sweep loop a
  symlink into `~/.config/seihou/modules/` is used instead of `install`, so prompt refinements
  in the repo are immediately live (see Decision Log). `seihou list` still does not print the
  blueprint (it lists project modules/recipes and *installed* blueprints), but `seihou agent
  run` resolves it via the symlink and `seihou validate-blueprint` validates it directly.

- notion-cli was classified Tier A in the inventory but its actual `flake.nix` does **not**
  consume `haskell-nix-dev` — it imports `nixpkgs-unstable` directly via
  `flake-utils.eachDefaultSystem` and builds the toolchain with `ghcWithPackages`. It does
  already pin `ghc9124` and carries the `haskell-nix` overlay plus a `notion-client-src` input.
  So it is really a *base-flake addition with an existing overlay* (a Tier-B-shaped conversion
  producing a Variant-A `flake.module.nix`), not the pure structural reorg the Tier A definition
  describes. The inventory fingerprint over-counted Tier A; re-confirm each project's actual
  `flake.nix` before the sweep rather than trusting the tier label. This made notion-cli a
  richer first test (it exercised both adding the base flake and the overlay graft).

- The Tier A classification is wrong for the **entire** group, not just notion-cli. Inspecting
  all seven listed Tier A projects' actual `flake.nix` files (2026-06-03): none of
  notion-cli, kiroku, mina, mori, mori-rei-app, rei, reiko consume `haskell-nix-dev`. Every one
  uses `flake-utils.eachDefaultSystem` importing `nixpkgs` directly, with a `haskell-nix`
  overlay + `nix/haskell-overlay.nix`, pinning `ghc9122` (except notion-cli, already `ghc9124`).
  So "Tier A = already on the base flake, pure structural reorg" does not describe any of them;
  they are all base-flake *additions* with an existing overlay (Variant-A `flake.module.nix`),
  and the GHC bump 9.12.2→9.12.4 applies to six of the seven. The practical consequence: Tier A
  and Tier B require the *same* conversion; the only real split is "has an overlay" (these +
  some Tier B) vs "no overlay" (the rest of Tier B). Re-confirm each project's real `flake.nix`
  rather than trusting the tier label.

- `nix flake lock` preserves the already-locked revision of every input, so a project whose old
  `flake.lock` pinned an out-of-date **unpinned** `haskell-nix` (the shared registry overlay)
  keeps that stale rev through the conversion — and then fails to build with a missing shinzui
  package the newer registry provides. Concrete evidence: mina builds `mina-cli` which
  build-depends on `baikai`/`baikai-claude`/`baikai-openai`; the registry provides those at
  `haskell-nix/overlays/registry.nix:75-77`, but mina's carried-over lock pinned `haskell-nix`
  at `4747cb8` (2026-04-24), an ancestor that predates the baikai patches, so the build failed
  with `function 'anonymous lambda' called without required argument 'baikai'`. GitHub's
  `haskell-nix` master is already at `1e718f3` (has baikai); `nix flake update haskell-nix`
  bumped mina to it and the build proceeded. The same stale lock affected mori (`4747cb8`), rei
  (`02f4cb3`), and reiko (`26f8e82`) — all bumped to `1e718f3`. This is **not** the excluded
  `haskell-nix` repo being unpushed (it is pushed); it is purely the consumer's lock being old.
  The blueprint prompt now documents bumping an *unpinned* `haskell-nix` when a build reports a
  missing registry package (and leaving a deliberately *pinned* `haskell-nix` alone).

- Some projects are blocked from building by a bug in the shared **haskell-nix registry**
  (which is explicitly excluded from this sweep, "revisit separately"). Concretely, the
  registry's `keiro` patch (`haskell-nix/patches/keiro/*.nix`) does
  `callCabal2nix "keiro" src` against the keiro repo *root* at rev `94c85e2`, but that rev has
  no root `.cabal` (keiro is multi-package: keiro-core/keiro-migrations/… in subdirs), so the
  derivation fails: `cabal2nix: Found neither a .cabal file nor package.yaml`. mori-core
  build-depends on the registry `keiro`, so mori cannot build on either the old registry lock
  (`4747cb8`, no keiro at all → "missing argument") or the new one (`1e718f3`, keiro present but
  its patch is broken). This is a registry/source concern outside the flake-restructure's scope;
  mori is left converted-but-unbuilt per the plan. Projects that vendor their own
  `keiro-src`/`*-src` and build those packages in their *local* overlay (which composes after
  the registry and overrides it) are not affected by this registry bug.

- Nix flakes evaluate only **git-tracked** files. Newly created flake files are invisible to
  `nix eval`/`nix build` until at least intent-to-added (`git add -N`); if the agent adds them
  only to run eval and then `git reset`s, the reviewer's subsequent `nix build` fails with
  "Path '…' in the repository … is not tracked by Git". Fixed by adding a step to the blueprint
  prompt instructing the agent to `git add -N` the new files and leave them that way. Evidence:
  the first notion-cli `nix build` aborted at evaluation with that exact error until the four new
  files were re-added with `git add -N`.

- The repo's `seihou-registry.dhall` had pre-existing version drift from earlier milestones:
  `nix-haskell-flake` was on disk at 0.11.0 but recorded as 0.10.0, and `haskell-cli-app` /
  `haskell-library` were at 0.2.0 on disk but 0.1.0 in the registry. `seihou registry
  sync-versions` reconciled all three (the modules genuinely are at the on-disk versions).


## Decision Log

Record every decision made while working on the plan.

- Decision: Use a seihou agent-driven blueprint, not a deterministic seihou module migration,
  to perform the conversion.
  Rationale: The conversion requires per-project judgement (custom inputs, overlays, dev-shell
  tools, custom checks, package counts all differ). Blueprints exist precisely for
  non-deterministic, agent-performed, human-reviewed scaffolding. See Surprises for evidence.
  Date: 2026-06-03

- Decision: Split the fleet into Tier A (already consuming `haskell-nix-dev` in the old
  `flake-utils.lib.eachDefaultSystem` style with a haskell-nix overlay) and Tier B (plain
  nixpkgs flakes with no base flake and no overlay), and do Tier A first.
  Rationale: Tier A is a pure structural reorganization (the base-flake plumbing already
  exists), so it is lower risk and a better shakedown for the blueprint before the larger Tier
  B set.
  Date: 2026-06-03

- Decision: Run the sweep as "blueprint + review each" — apply, review the diff and the build,
  commit, then move on — rather than a parallel multi-agent batch.
  Rationale: Each conversion changes build behavior (GHC 9.12.2 → 9.12.4) and may need
  per-project code fixes; builds are slow; non-deterministic agent output must be reviewed.
  Date: 2026-06-03

- Decision: On a compile failure caused by the GHC bump, the agent surfaces the error and
  stops; it does not silently patch the project's Haskell source.
  Rationale: Source fixes are a separate, reviewable concern from the flake restructure.
  Date: 2026-06-03

- Decision: Exclude `haskell-nix` (the overlay library itself), `dhall-grafana`, and
  `load-testing-infra` from the sweep.
  Rationale: `haskell-nix` is the registry/overlay library other projects consume (special-
  cased; revisit separately); the other two are not Haskell-package flakes.
  Date: 2026-06-03

- Decision: The blueprint converts in place and never commits or pushes; the human reviews and
  commits each project.
  Rationale: Matches the validated reference workflow and keeps the human in the loop for a
  build-behavior-changing edit.
  Date: 2026-06-03

- Decision: Make the blueprint resolvable-by-name during authoring/sweep via a symlink
  (`~/.config/seihou/modules/upgrade-haskell-flake-parts` ->
  `…/seihou-modules/blueprints/upgrade-haskell-flake-parts`) rather than `seihou install`.
  Rationale: `seihou install` snapshots the blueprint into `~/.config/seihou/installed/`, which
  would go stale every time Milestone 2 refines `prompt.md`; the symlink keeps the repo as the
  single source of truth and makes edits immediately live for re-runs. The XDG `modules/`
  directory is exactly the search path intended for locally authored artifacts. The repo is not
  yet pushed, so a remote git install is not possible anyway. When the repo is published, a
  normal `seihou install <url> --module upgrade-haskell-flake-parts` is the durable mechanism.
  Date: 2026-06-03

- Decision: Set the blueprint's `allowedTools` to a restrictive list (Read/Write/Edit/Glob/Grep,
  `Bash(nix *)`, read-only git and shell helpers) even though the field is currently inert at
  launch, and rely on the prompt's explicit "never commit/never push" and "never edit Haskell
  source" rules for the actual guardrails.
  Rationale: Records the intended permission surface for when seihou wires blueprint
  `allowedTools` into the launch, while the prompt enforces the invariants today. See Surprises
  for the evidence that the field is not yet enforced.
  Date: 2026-06-03

- Decision: Because `seihou agent run` launches `claude` **interactively** (a TUI session — see
  `AgentLaunchExec.hs:launchClaude` → `launchClaudeInteractive`), which cannot be driven from a
  non-interactive automation context, "running the blueprint" during this plan's execution is
  done by spawning a fresh agent with the blueprint's `prompt.md` (plus the reference `files/`
  on disk) scoped to the target project — the same system prompt seihou would hand the
  interactive agent — then reviewing/building/committing as the human-in-the-loop. The
  blueprint, its prompt, and its reference files are the artifact under test; the launch
  mechanism is incidental. A human can still run it the documented way (`seihou agent run
  upgrade-haskell-flake-parts`).
  Rationale: Faithfully exercises the prompt's self-sufficiency (the de-risking goal of
  Milestone 2) without requiring an interactive TTY, and keeps the review/commit gate.
  Date: 2026-06-03

- Decision: Push built-and-committed conversions to their `origin/master` (fast-forward) once
  verified, at the user's explicit request mid-sweep. First batch pushed 2026-06-04: notion-cli
  (385f280), kiroku (8afe049), mina (cc8c87b), rei (2683d21b), and the seihou-modules blueprint
  repo (5af1a0a). This supersedes the earlier "never push" stance for these reviewed projects;
  the blueprint itself still never pushes — the human does, after review and a green build.
  Date: 2026-06-04

- Decision: Migrate `notion-hub` (`/Users/shinzui/Keikaku/bokuno/notion-hub`,
  `github:shinzui/notion-hub`) too, at the user's request mid-sweep. It was not in the
  2026-06-03 inventory (registered in mori on 2026-06-04). It is the same overlay-CLI shape as
  the "Tier A" group (eachDefaultSystem + nixpkgs-direct + overlay, ghc9122) and is converted
  with the same blueprint. Its working tree was already dirty with the user's in-progress build
  fixes (a pinned nixpkgs to retain ghc9122 — made moot by following haskell-nix-dev/nixpkgs;
  `gogol`/`gogol-core`/`gogol-storage` jailbreaks in `nix/haskell-overlay.nix`; `cabal.project`
  allow-newer; a custom `notion-hub-subscriptions` overrideAttrs package). The conversion
  preserves all of these — the overlay file and `cabal.project` are left untouched and the
  custom package is copied verbatim into `flake.module.nix`.
  Rationale: User asked for it; it is in-scope-shaped and the blueprint applies unchanged.
  Date: 2026-06-04

- Decision: Run `seihou registry sync-versions` while registering the blueprint, correcting
  pre-existing module version drift (nix-haskell-flake 0.10.0->0.11.0, haskell-cli-app and
  haskell-library 0.1.0->0.2.0) so `seihou registry validate` is clean.
  Rationale: The registry should reflect the on-disk module versions; the drift predates this
  plan but blocks a clean `registry validate`, and `sync-versions` is the documented fix.
  Date: 2026-06-03


## Outcomes & Retrospective

Summarize outcomes, gaps, and lessons learned at major milestones or at completion.
Compare the result against the original purpose.

(To be filled during and after implementation.)


## Context and Orientation

This section assumes no prior knowledge of the repositories involved. Read it fully before
starting.

**Key terms.** A *Nix flake* is a directory with a `flake.nix` file declaring `inputs`
(pinned dependencies) and `outputs` (packages, dev shells, checks). A *flake input* is locked
to an exact revision in a sibling `flake.lock` file. *flake-parts*
(`github:hercules-ci/flake-parts`) is a framework that lets a `flake.nix` be split into small
modules, each contributing to the outputs through a `perSystem` function (a function evaluated
once per CPU/OS system such as `aarch64-darwin`). A *base flake* is a flake other flakes
consume as an input; here it is `haskell-nix-dev`
(`github:shinzui/haskell-nix-dev`, checked out at
`/Users/shinzui/Keikaku/bokuno/haskell-nix-dev`), which provides the GHC/cabal/HLS toolchain
so consumers do not each pin their own. A *haskell overlay* is a function that patches the
nixpkgs Haskell package set (for example, to substitute a newer version of a dependency than
nixpkgs ships); the shared one lives at `github:shinzui/haskell-nix`
(`/Users/shinzui/Keikaku/bokuno/haskell-nix`) and is applied via
`inputs.haskell-nix.lib.haskellExtension`.

**The base flake's contract.** `haskell-nix-dev`'s `flake.nix` exposes, per system,
`lib.${system}.mkDevShell { ghc ? "ghc9124", extraNativeBuildInputs ? [], withHls ? true,
shellHook ? "" }`, which returns a dev shell containing that GHC's compiler, `cabal`,
optional HLS, plus `pkg-config` and `zlib`, and it already exports `LANG=en_US.UTF-8` in its
shell hook. Its only supported GHC is `ghc9124` (GHC 9.12.4). Consumers set
`inputs.nixpkgs.follows = "haskell-nix-dev/nixpkgs"` so they inherit the exact pinned nixpkgs.
The overlay library exposes a top-level `lib.haskellExtension : haskellLib -> pkgs -> overlay`
(call it as `inputs.haskell-nix.lib.haskellExtension pkgs.haskell.lib.compose pkgs`).

**The target structure (what every migrated project must look like).** This is the structure
already shipped by this repo's template at
`modules/haskell/nix-haskell-flake` (version 0.11.0) and validated by hand on the three
reference projects. A migrated project contains:

- `flake.nix` — a thin "stub": it declares `inputs` (the base flake, `flake-parts`, the
  followed `nixpkgs`, `treefmt-nix`, `pre-commit-hooks`, plus any project-specific inputs),
  and an `outputs` that calls `flake-parts.lib.mkFlake` with `systems =
  nixpkgs.lib.systems.flakeExposed` and an `imports` list of the `nix/*.nix` modules, ending
  with `++ nixpkgs.lib.optional (builtins.pathExists ./flake.module.nix) ./flake.module.nix`.
- `nix/haskell.nix` — a flake-parts module providing the dev shell via the base flake's
  `mkDevShell` (GHC 9.12.4), plus the project's extra dev tools, plus a perSystem option
  `haskellProject.extraDevPackages`, and a `shellHook` of
  `${config.pre-commit.installationScript}`.
- `nix/treefmt.nix` — imports `inputs.treefmt-nix.flakeModule` and configures `perSystem`'s
  `treefmt` (this auto-wires `nix fmt` and a `treefmt` flake check).
- `nix/pre-commit.nix` — imports `inputs.pre-commit-hooks.flakeModule` and sets
  `perSystem`'s `pre-commit.settings.hooks` (at minimum the `treefmt` hook; plus any custom
  hooks the project had).
- `flake.module.nix` — **unmanaged**, project-specific: the package build (the overlaid
  `pkgs.haskell.packages.ghc9124`, `packages.<name>`/`packages.default`) and any custom
  checks. This file is imported only when present and is never regenerated, so customizations
  live here safely.
- `nix/haskell-overlay.nix` — kept as-is when the project had one.
- The old top-level `treefmt.nix` is deleted (its content moves into `nix/treefmt.nix`).
- `flake.lock` is regenerated so the root inputs follow `haskell-nix-dev`.

The exact, copyable contents of each of these files are reproduced in the Interfaces and
Dependencies section so the blueprint's reference `files/` can be authored from this plan
alone. The three committed reference projects are the ground truth; read any of their trees:
`/Users/shinzui/Keikaku/bokuno/nihongo`, `/Users/shinzui/Keikaku/bokuno/kizamu-project/kizamu`,
`/Users/shinzui/Keikaku/bokuno/seihou-project/seihou`.

**What a seihou blueprint is.** seihou (the CLI at
`/Users/shinzui/Keikaku/bokuno/seihou-project/seihou`, on PATH as `seihou`) has three kinds of
runnable: a *module* (deterministic file templating), a *recipe* (a named composition of
modules), and a *blueprint* (agent-driven, non-deterministic scaffolding). A blueprint is a
directory containing `blueprint.dhall`, `prompt.md`, and a `files/` directory of reference
material. `blueprint.dhall` (schema fields: `name`, `version`, `description`, `prompt`,
`vars`, `prompts`, `baseModules`, `files`, `allowedTools`, `tags`) is a Dhall record;
`prompt` is usually `./prompt.md as Text`. You scaffold one with `seihou new-blueprint`,
validate it with `seihou validate-blueprint <dir>`, and run it with `seihou agent run
<blueprint> [extra prompt]`. At run time seihou resolves the blueprint's `vars`/`prompts`,
substitutes `{{var.name}}` placeholders into the prompt, optionally applies any `baseModules`
deterministically first, renders a system prompt that includes the current working directory,
the project's seihou/git state, and the list of `files/` reference snippets, and then shells
out to the `claude` CLI with `--add-dir <cwd>` and the blueprint's `allowedTools`. The agent
edits the project in place; on success seihou records an `AppliedBlueprint` entry in the
project's `.seihou/manifest.json`. (Dhall is a typed configuration language; treat
`blueprint.dhall` as a strongly-typed JSON.)

**The lockstep updater.** `/Users/shinzui/Keikaku/bokuno/haskell-nix-dev/scripts/update-haskell-toolchain.sh`
scans a workspace for consumer flakes (any `flake.nix` mentioning `shinzui/haskell-nix-dev`),
reports each one's pinned `haskell-nix-dev` revision, and (with `--apply`) bumps them all to
one revision. It is dry-run by default and is exposed through the base flake's `justfile` as
`just check-toolchain` / `just update-toolchain`. After migrating projects, run
`just check-toolchain` from `/Users/shinzui/Keikaku/bokuno/haskell-nix-dev` to confirm the
fleet shares one revision.

**The fleet (classification recorded 2026-06-03).** Filtering mori
(`mori registry list --origin own --namespace shinzui --json`) and fingerprinting each
`flake.nix` yields three groups.

Already done (committed, not pushed): nihongo, kizamu, seihou.

Tier A — already consume `haskell-nix-dev` but in the old `flake-utils.lib.eachDefaultSystem`
style with a haskell-nix overlay; they need only the flake-parts reorganization (7 projects):
kiroku (`/Users/shinzui/Keikaku/bokuno/kiroku-project/kiroku`),
mina (`/Users/shinzui/Keikaku/bokuno/mina`),
mori (`/Users/shinzui/Keikaku/bokuno/mori-project/mori`),
mori-rei-app (`/Users/shinzui/Keikaku/bokuno/mori-project/mori-rei-app`),
notion-cli (`/Users/shinzui/Keikaku/bokuno/notion-cli`),
rei (`/Users/shinzui/Keikaku/bokuno/rei-project/rei`),
reiko (`/Users/shinzui/Keikaku/bokuno/rei-project/reiko`).

Tier B — plain nixpkgs Haskell flakes (`flake-utils` + `eachDefaultSystem`, no base flake, no
overlay); they need the full migration (18 projects):
baikai (`/Users/shinzui/Keikaku/bokuno/baikai`),
ephemeral-pg (`/Users/shinzui/Keikaku/bokuno/ephemeral-pg-project/ephemeral-pg`),
hasql-migration (`/Users/shinzui/Keikaku/hub/haskell/hasql-migration`),
hasql-opentelemetry (`/Users/shinzui/Keikaku/bokuno/hasql-opentelemetry`),
hw-kafka-streamly (`/Users/shinzui/Keikaku/bokuno/hw-kafka-streamly`),
kafka-effectful (`/Users/shinzui/Keikaku/bokuno/kafka-effectful`),
keiki (`/Users/shinzui/Keikaku/bokuno/keiki`),
keiro (`/Users/shinzui/Keikaku/bokuno/keiro`),
kizashi (`/Users/shinzui/Keikaku/bokuno/kizashi`),
nagare (`/Users/shinzui/Keikaku/bokuno/nagare`),
notion-client (`/Users/shinzui/Keikaku/bokuno/libraries/haskell/notion-client`),
pgmq-hs (`/Users/shinzui/Keikaku/bokuno/libraries/pgmq-hs-project/pgmq-hs`),
shibuya (`/Users/shinzui/Keikaku/bokuno/shibuya-project/shibuya`),
shibuya-kafka-adapter (`/Users/shinzui/Keikaku/bokuno/shibuya-project/shibuya-kafka-adapter`),
shibuya-message-db-adapter (`/Users/shinzui/Keikaku/work/libraries/haskell/shibuya-message-db-adapter`),
shibuya-pgmq-adapter (`/Users/shinzui/Keikaku/bokuno/shibuya-project/shibuya-pgmq-adapter`),
shiki (`/Users/shinzui/Keikaku/bokuno/shiki`),
typeid-hs (`/Users/shinzui/Keikaku/work/libraries/haskell/typeid-hs`).

Excluded: haskell-nix (`/Users/shinzui/Keikaku/bokuno/haskell-nix`, the overlay library
itself), dhall-grafana, load-testing-infra (non-Haskell). The classification was produced by a
throwaway Python fingerprint over each `flake.nix`; re-run the inventory if the fleet has
changed since the date above.


## Plan of Work

The work proceeds in five milestones. Milestone 1 produces the reusable artifact; Milestones
2–4 use it; Milestone 5 verifies the whole-fleet property and records lessons. Each milestone
is independently verifiable.

**Milestone 1 — Author the blueprint.** Scope: create a seihou blueprint named
`upgrade-haskell-flake-parts` under this repository, whose `prompt.md` encodes the per-project
recipe and judgement learned from the three reference conversions, and whose `files/` holds the
canonical reference versions of `flake.nix`, `nix/haskell.nix`, `nix/treefmt.nix`,
`nix/pre-commit.nix`, and an example `flake.module.nix`. At the end of this milestone the
command `seihou validate-blueprint <blueprint-dir>` exits zero and prints that the blueprint is
valid, and `seihou list` shows the blueprint. Author the blueprint by running `seihou
new-blueprint` to scaffold the standard layout, then replace the generated `prompt.md` and
populate `files/` with the contents reproduced in Interfaces and Dependencies, then register it
in the repo's registry the same way recipes are registered (inspect
`recipes/` and any `seihou-registry.dhall` to mirror the convention). The blueprint declares no
`baseModules` (applying the template module to an existing custom flake would conflict); its
`allowedTools` permit reading and writing files, running `nix`, and running `git` for status
and diff but not commit or push. Acceptance: `seihou validate-blueprint` passes; a `--debug`
dry run (`seihou agent run upgrade-haskell-flake-parts --debug` from a scratch directory)
prints a coherent system prompt that contains the recipe.

**Milestone 2 — Prove the blueprint on one Tier A project.** Scope: pick the smallest Tier A
project (suggested: notion-cli, a single application already on `haskell-nix-dev`), run the
blueprint against it, and review the result against the reference structure. At the end, that
one project builds on GHC 9.12.4 and matches the target structure, and any prompt weaknesses
exposed by the run are fixed back in Milestone 1's blueprint. This milestone exists to
de-risk: it is a prototyping milestone in the sense of PLANS.md. Commands and acceptance are in
Concrete Steps and Validation. If the run produces a wrong or partial conversion, do not hand-
fix the project and move on — fix the prompt, `git checkout` the project, and re-run, so the
blueprint itself improves. Commit the project (with the `ExecPlan:` trailer) only once it
matches the reference structure and builds.

**Milestone 3 — Tier A sweep.** Scope: run the blueprint across the remaining Tier A projects
(kiroku, mina, mori, mori-rei-app, rei, reiko). Because Tier A already consumes the base flake,
each conversion is a structural reorganization; expect few code surprises. Order does not
matter much within Tier A, but do `mori` and `mori-rei-app` together (same `mori-project`
parent) and `rei`/`reiko` together (same `rei-project` parent). After each project: review,
build, commit. Acceptance: each project builds on 9.12.4 and `just check-toolchain` shows it in
lockstep.

**Milestone 4 — Tier B sweep.** Scope: run the blueprint across the 18 Tier B projects. These
do not yet consume the base flake, so the blueprint also adds the `haskell-nix-dev` input and
moves the toolchain to `mkDevShell`; this is the larger change and is the most likely to expose
GHC 9.12.4 compile differences. Order to maximize cache reuse: do the project with the largest
dependency closure first (libraries that everything else depends on — for example the
`shibuya` family and `pgmq-hs` — and otherwise an application like `kizashi`), so the shared
ghc9124 dependency derivations are built and cached early; later projects then reuse them. For
any project whose Haskell source does not compile on 9.12.4, record the error in Surprises &
Discoveries, leave that project converted-but-unbuilt with a note, and continue; source fixes
are out of scope for this plan (see Decision Log). After each buildable project: review, build,
commit.

**Milestone 5 — Fleet lockstep and retrospective.** Scope: from
`/Users/shinzui/Keikaku/bokuno/haskell-nix-dev`, run `just check-toolchain` and confirm every
migrated project reports the same `haskell-nix-dev` revision and the same nixpkgs revision.
Record the final count of migrated/built/deferred projects in Outcomes & Retrospective, along
with any projects left for follow-up (source fixes, the excluded `haskell-nix` library).


## Concrete Steps

All commands assume the macOS shell with `nix` (Determinate Nix), `seihou`, `just`, and `git`
available, and the current system `aarch64-darwin`.

Author the blueprint (Milestone 1), run from this repo
(`/Users/shinzui/Keikaku/bokuno/seihou-modules`):

    seihou new-blueprint blueprints/upgrade-haskell-flake-parts
    # then edit blueprints/upgrade-haskell-flake-parts/{blueprint.dhall,prompt.md}
    # and populate blueprints/upgrade-haskell-flake-parts/files/ per Interfaces and Dependencies
    seihou validate-blueprint blueprints/upgrade-haskell-flake-parts

Expected final line:

    Blueprint 'upgrade-haskell-flake-parts' is valid.

Run the blueprint against one project (Milestones 2–4). From the project directory, e.g.:

    cd /Users/shinzui/Keikaku/bokuno/notion-cli
    git status --short            # confirm a clean tree first (so the diff is reviewable)
    seihou agent run upgrade-haskell-flake-parts

After the agent finishes, review and build (the per-project verification recipe used on the
three reference projects):

    git status --short            # see what changed
    nix flake lock                # regenerate the lock for the new inputs if the agent did not
    nix eval --raw ".#devShells.aarch64-darwin.default.drvPath"
    nix eval ".#checks.aarch64-darwin" --apply 'builtins.attrNames'
    nix build ".#<package>" -L --accept-flake-config    # <package> is the project's package name

Commit each converted project from its own directory, including the plan trailer:

    git add -A
    git commit -m "build(nix): migrate flake to flake-parts on the haskell-nix-dev base flake

    <one-paragraph summary of what moved where and the GHC 9.12.2 -> 9.12.4 bump>

    ExecPlan: docs/plans/1-migrate-shinzui-haskell-projects-to-flake-parts-via-a-seihou-blueprint.md"

Confirm fleet lockstep (Milestone 5), from the base flake repo:

    cd /Users/shinzui/Keikaku/bokuno/haskell-nix-dev
    just check-toolchain

Expected: a table listing every migrated project with one shared `haskell-nix-dev` revision and
the line `lockstep: all <N> consumers pin <rev>`.


## Validation and Acceptance

The plan is validated per project and once for the fleet.

Per project, the conversion is accepted when all of the following hold (these mirror exactly how
the three reference projects were verified):

- The project tree matches the target structure: a thin `flake.nix` stub, `nix/haskell.nix`,
  `nix/treefmt.nix`, `nix/pre-commit.nix`, a `flake.module.nix` (when the project has a package
  build or custom checks), no top-level `treefmt.nix`, and a regenerated `flake.lock` whose root
  inputs include `haskell-nix-dev` and `flake-parts` and no longer include a top-level
  `flake-utils`.
- `nix eval ".#checks.aarch64-darwin" --apply 'builtins.attrNames'` lists at least `treefmt` and
  `pre-commit` (plus any project-specific check such as `cli-module-placement` for seihou-like
  projects).
- `nix build ".#<package>"` completes and, for projects whose Haskell test suites run under the
  Nix build, the test suite passes. Example evidence from the seihou reference build:

      seihou-cli> All 226 tests passed (1.49s)
      seihou-cli> Test suite seihou-cli-test: PASS

- The built binary runs and preserves any custom behavior (for example a baked-in git revision):

      $ ./result/bin/seihou --version
      seihou v0.2.0.0 (dirty)

- A human has reviewed the diff and confirmed every custom input, overlay, dev-shell tool, and
  check from the old flake is preserved (in `flake.module.nix` or the `nix/` modules), and that
  the GHC version moved to 9.12.4.

For the fleet, acceptance is that `just check-toolchain` from the base flake repo reports every
migrated project on a single shared `haskell-nix-dev` revision, proving they share one toolchain
and one cache.

Note on build time: the first GHC 9.12.4 build of a large dependency closure is slow because
9.12.4 is not the nixpkgs default and is not on the public binary cache, so dependencies build
from source. This is expected (see Surprises & Discoveries) and is a one-time, fleet-shared
cost; do not mistake a slow first build for a failure.


## Idempotence and Recovery

Every step is safe to repeat. Each project is a clean git working tree before conversion, so the
recovery for any bad or partial conversion is `git checkout -- .` (and `git clean -fd nix
flake.module.nix` to drop newly created files) in that project, after which the blueprint can be
re-run. Because review-and-commit happens per project, a failure in one project never affects
the others.

The target structure is itself re-run-safe. The `flake.nix` stub imports `flake.module.nix`
only via `nixpkgs.lib.optional (builtins.pathExists ./flake.module.nix)`, so a missing
customization file is not an error. Re-running `nix flake lock` is idempotent. Re-running the
blueprint on an already-migrated project should be a near no-op; if in doubt, inspect the diff
before committing.

The lockstep updater is dry-run by default and never commits; running `just check-toolchain`
only reports, and `just update-toolchain` only rewrites `flake.lock` files (review and commit
those per repo). If a toolchain bump goes wrong, `git checkout -- flake.lock` in the affected
project restores the previous pin.

If the blueprint authored in Milestone 1 proves wrong mid-sweep, fix `prompt.md` and/or the
`files/` references, re-validate, and continue; already-committed projects are unaffected, and
any in-flight project can be reset with `git checkout` and re-run.


## Interfaces and Dependencies

This section reproduces the exact, copyable contents the blueprint's `files/` must contain and
the signatures the conversion depends on, so Milestone 1 can be completed from this plan alone.
These are distilled from the three committed reference projects; when in doubt, the reference
trees are authoritative.

**Dependency: the base flake contract.** From
`/Users/shinzui/Keikaku/bokuno/haskell-nix-dev/flake.nix`:
`lib.${system}.mkDevShell { ghc ? "ghc9124", extraNativeBuildInputs ? [ ], withHls ? true,
shellHook ? "" }` returns a `pkgs.mkShell` with the GHC compiler, `cabal`, optional HLS,
`pkg-config`, `zlib`, and a `LANG=en_US.UTF-8` export. The only supported GHC attribute is
`ghc9124`.

**Dependency: the overlay contract.** From `/Users/shinzui/Keikaku/bokuno/haskell-nix/flake.nix`:
`lib.haskellExtension : haskellLib -> pkgs -> overlay`, used as
`inputs.haskell-nix.lib.haskellExtension pkgs.haskell.lib.compose pkgs` and composed with a
project's local `nix/haskell-overlay.nix` via `pkgs.lib.composeExtensions`.

**Reference file `flake.nix` (the stub).** Project-specific inputs (the `haskell-nix` overlay,
any `*-src` non-flake inputs) are added in the `inputs` block as needed; the skeleton is:

    {
      description = "<project description>";

      inputs = {
        haskell-nix-dev.url = "github:shinzui/haskell-nix-dev";
        nixpkgs.follows = "haskell-nix-dev/nixpkgs";

        flake-parts.url = "github:hercules-ci/flake-parts";
        flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

        treefmt-nix.follows = "haskell-nix-dev/treefmt-nix";

        pre-commit-hooks.url = "github:cachix/git-hooks.nix";
        pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

        # project-specific (keep what the old flake had), e.g.:
        # haskell-nix.url = "github:shinzui/haskell-nix";
        # haskell-nix.inputs.nixpkgs.follows = "nixpkgs";
      };

      nixConfig = {
        extra-substituters = [ ];
        extra-trusted-public-keys = [ ];
      };

      outputs = inputs@{ flake-parts, nixpkgs, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } {
          systems = nixpkgs.lib.systems.flakeExposed;
          imports =
            [
              ./nix/haskell.nix
              ./nix/treefmt.nix
              ./nix/pre-commit.nix
            ]
            ++ nixpkgs.lib.optional (builtins.pathExists ./flake.module.nix) ./flake.module.nix;
        };
    }

**Reference file `nix/haskell.nix` (dev shell).** The `extraNativeBuildInputs` list carries the
project's old dev-shell tools that `mkDevShell` does not already provide (cabal, HLS, pkg-config,
zlib are already provided):

    { inputs, lib, flake-parts-lib, ... }:
    {
      options.perSystem = flake-parts-lib.mkPerSystemOption ({ ... }: {
        options.haskellProject.extraDevPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "Extra packages to add to the dev shell.";
        };
      });

      config.perSystem = { system, pkgs, config, ... }:
        let
          hsdev = inputs.haskell-nix-dev.lib.${system};
          mkProjectShell = ghc: hsdev.mkDevShell {
            inherit ghc;
            withHls = true;
            extraNativeBuildInputs = [ /* project tools, e.g. pkgs.just */ ]
              ++ config.haskellProject.extraDevPackages;
            shellHook = ''
              ${config.pre-commit.installationScript}
            '';
          };
        in
        {
          devShells.default = mkProjectShell "ghc9124";
          devShells.ghc9124 = mkProjectShell "ghc9124";
        };
    }

**Reference file `nix/treefmt.nix`.** Use the project's old formatter set (the reference
projects use nixpkgs-fmt + fourmolu + cabal-gild, the last two from the ghc9124 set):

    { inputs, ... }:
    {
      imports = [ inputs.treefmt-nix.flakeModule ];
      perSystem = { pkgs, ... }:
        let haskellPkgs = pkgs.haskell.packages.ghc9124;
        in {
          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixpkgs-fmt.enable = true;
            programs.fourmolu.enable = true;
            programs.fourmolu.package = haskellPkgs.fourmolu;
            programs.cabal-gild.enable = true;
            programs.cabal-gild.package = haskellPkgs.cabal-gild;
          };
        };
    }

**Reference file `nix/pre-commit.nix`.** Custom hooks the project had (such as seihou's
`cli-module-placement`) are added alongside `treefmt`:

    { inputs, ... }:
    {
      imports = [ inputs.pre-commit-hooks.flakeModule ];
      perSystem = { config, pkgs, ... }: {
        pre-commit.settings.hooks = {
          treefmt = {
            enable = true;
            package = config.treefmt.build.wrapper;
          };
          # custom hooks here, e.g.:
          # my-check = { enable = true; name = "my-check"; language = "system";
          #   entry = "${pkgs.bash}/bin/bash ${./my-check.sh}"; pass_filenames = false; };
        };
      };
    }

**Reference file `flake.module.nix` (example/unmanaged).** This is where the package build and
custom checks live; it is the file a project owner edits. The overlay graft pattern:

    { inputs, ... }:
    {
      perSystem = { system, pkgs, ... }:
        let
          gitRev = inputs.self.shortRev or "dirty";
          haskellPackages = pkgs.haskell.packages.ghc9124.override {
            overrides = pkgs.lib.composeExtensions
              (inputs.haskell-nix.lib.haskellExtension pkgs.haskell.lib.compose pkgs)
              (import ./nix/haskell-overlay.nix { inherit pkgs gitRev; /* + project *-src inputs */ });
          };
        in
        {
          packages.<name> = haskellPackages.<name>;
          packages.default = haskellPackages.<name>;
          # custom checks (e.g. a runCommand) go here too
        };
    }

For Tier B projects without an existing overlay, `flake.module.nix` instead builds the package
directly, for example `packages.default = (pkgs.haskell.packages.ghc9124.callCabal2nix "<name>"
inputs.self { });`, and may be omitted entirely for a pure library that needs no package output
beyond what `nix flake check` exercises.

**The blueprint's `prompt.md` (content outline).** The prompt instructs the agent to: read the
existing `flake.nix` and any `nix/` files and `treefmt.nix`; identify the project's custom
inputs, overlay, dev-shell tools, formatter set, custom checks, and package name(s); write the
five target files above preserving every customization, moving the toolchain to `mkDevShell`
(ghc9124) and the package build/overlay/custom checks into `flake.module.nix`; delete the
top-level `treefmt.nix`; keep `nix/haskell-overlay.nix`; run `nix flake lock`; verify with `nix
eval` of the dev shell and checks and `nix build` of the package; if Haskell source fails to
compile under 9.12.4, stop and report the exact error rather than editing source; and never
commit or push. The prompt must state the GHC bump explicitly (old flakes pin `ghc9122`; the
base flake supports only `ghc9124`).

**Tooling dependencies.** `seihou` (blueprint run/validate), `nix` (build/eval/lock), `just`
(lockstep recipes in the base flake), `git` (status/diff/commit), and the `claude` CLI (the
agent backend seihou shells out to). The base flake, the overlay library, and this repo's
`nix-haskell-flake` template (version 0.11.0, at `modules/haskell/nix-haskell-flake`) are the
upstream artifacts the conversion targets.
