---
id: 7
slug: add-optional-bun2nix-support-to-the-bun-nix-module
title: "Add optional bun2nix support to the Bun Nix module"
kind: exec-plan
created_at: 2026-10-26T17:53:11Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-10-26T17:53:11Z
  revisions:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-26T18:18:21Z
      mode: "implement"
      note: "Implement the optional pinned helper, immutable verifier, native fixtures, and adoption documentation"
---

# Add optional bun2nix support to the Bun Nix module

This ExecPlan is a living document. Keep Progress, Surprises & Discoveries, Decision Log,
and Outcomes & Retrospective current during implementation. Follow the repository's
`agents/skills/exec-plan/PLANS.md`, `ADR.md`, and `FRICTION.md` for execution and durable context.


## Purpose / Big Picture


Projects adopting `nix-bun-flake` will be able to enable `nix.bun2nix=true` and receive the
pinned, compatibility-patched bun2nix generator in their Nix shell and as `packages.bun2nix`.
They can generate `bun-deps.nix` and use the helper's `hook` and `fetchBunDeps` to build a
project from its committed Bun lock without a local `node_modules`. Other projects retain
the current development-shell behavior because the option defaults to false.

The shared module will own the input pin, compatibility patch, and helper wiring. An operator
will no longer have to rediscover those pieces or the workspace-cache trap. Application
recipes, source selection, release staging, and container choices remain project-owned.
Success is an opt-in generated project whose frozen sandbox build works, alongside an
opt-out project whose existing shell and unmanaged extensions still work.


## Progress


- [x] M1 (2026-10-26): Patched bun2nix 2.1.2 built on aarch64-darwin; v1/v2 generation passed, v3 failed explicitly, and a generated registry cache fed a frozen sandbox consumer through the preserved hook/fetch APIs.
- [x] M2 (2026-10-26): Four real Seihou renders evaluate with/without the copied extension on all three systems; regenerated locks are identical and survive full update. Real enable/disable/removal preserve authored files and edited orphans; immutable verification passed without changing module files.
- [x] M3 (2026-10-26): Single-package and workspace consumers passed native sandbox builds on aarch64-darwin, aarch64-linux and x86_64-linux, including generator-byte comparison, v3 rejection, output checks, independent app/shared edits, registry-dependency invalidation and unchanged-build reuse. Fumadocs adoption passed with bun2nix disabled and its package-manager choice preserved.
- [x] M4 (2026-10-26): Version 0.4.0 agrees in module, registry, Mori, README and generated module docs. Adoption/build/patch-maintenance examples and ADR-6 are complete. Module, immutable-pin, native, ownership, Fumadocs, strict documentation and friction-profile checks passed; the global registry check retains only the pre-existing Haskell 0.34.0/0.35.0 mismatch.

Implementation and native acceptance are complete. Final code is a tested 0.4.0 release
candidate; no tags, pushes, registry publication or real consumer migration were performed.
The pre-existing unrelated Haskell registry drift is preserved. Supplemental development-shell
help checks passed on all three systems, with the translated x86 environment qualifications
recorded below. Shared Seihou ownership is established through real fixture generation.


## Surprises & Discoveries


Discovery (2026-10-26): Upstream `fetchBunDeps` is callable through a functor attribute
set; `builtins.isFunction` alone is false. Acceptance verifies the callable interface
and exercises it through real cache/build consumers.

Discovery (2026-10-26): Seihou rejects noninteractive edited-orphan dry runs before
showing the plan unless supplied a resolution. The isolated harness inspects
`--dry-run --json --force`, requires its sole resolution to be `retainTracked` for
the edited wrapper and no conflicts, then applies the identical command (FRIC-1 in
`docs/friction-log/`). Operator documentation continues to use reviewed interactive
choices instead of blanket force.

Discovery (2026-10-26): The translated x86 Linux container cannot load Nix’s seccomp
BPF filter. Its coordinator uses `filter-syscalls = false`, preserving explicit
`sandbox = true` on native builds/checks (FRIC-2 in `docs/friction-log/`).

Discovery (2026-10-26): Translated x86 Python resolves the base interpreter prefix
instead of its `withPackages` environment, so the existing Oxfmt auto-patchelf step
cannot import pyelftools. Direct Python probes reproduce this only in the translated
container. The configured native Linux builder built the unchanged tooling derivations;
Nix closure transfer then allowed the container's shell help and full native suite to
pass (FRIC-3 in `docs/friction-log/`). No tooling source or pin change was necessary.


## Decision Log


Decision (2026-10-26): Add the boolean `nix.bun2nix`, default false, using the existing
feature-toggle conventions. Declare the released helper input across all combinations so
one canonical lock remains shareable, but import its managed feature module, expose its
package, and add it to the shell only when enabled. Optional support therefore does not
mean an optional lock node; disabled users must not build or receive the helper implicitly.

Decision (2026-10-26): Share the generator and hook integration rather than inventing a generic
application output. Preserve the unmanaged `flake.module.nix` boundary in ADR-3. Do not add
nix2container, a web server, or deployment-specific files to the Bun module. No automatic
migration of the console or other real repositories is part of this plan.

Decision (2026-10-26): Initially pin bun2nix 2.1.2 at
`0f2a1f0b6f42cebe3b149bf62d38754c5e0e9729`, following the existing nixpkgs and flake-parts inputs.
Retain Bun 1.4.2 and the module's current toolchain pins for this change. Apply only the
verified v1/v2 generator version-gate patch. Unknown lock formats, including v3 scoped-override
locks, remain unsupported until separately inspected and tested. Do not downgrade project locks.

Decision (2026-10-26): Separate immutable pin validation from upstream refresh in the Bun
updater. `--check` must verify committed inputs; a new `--write-lock` mode regenerates only
the canonical lock from the committed template. Keep the existing no-argument upstream
refresh explicit in documentation, and do not invoke it merely to enable this feature.


## Outcomes & Retrospective


The opt-in helper, canonical input graph, immutable verifier, real ownership tests and
registry-backed native recipes are implemented. All required platforms have independent
native application-build evidence. The helper preserves upstream hook/fetch APIs and its
narrow gate patch accepts v1/v2 while rejecting v3. The default development-only path and
Fumadocs composition remain disabled. Application recipes and dependency expressions stay
project-owned; no consumer migration or publication was performed.

The final acceptance commands were `python3 scripts/update-nix-bun-flake.py --check`,
`python3 scripts/test-nix-bun-flake.py --native`, `python3 scripts/test-fumadocs-adoption.py`,
module validation, strict `okf-docs`/friction profile validation and `git diff --check`.
Linux coordinators used temporary projects rendered by the same `prepare_native` function
through actual Seihou operations, transferred with the harness/fixtures and executed with
its portable `native` function. The host used Determinate Nix 3.23.2 / Nix 2.35.3;
both Linux coordinators used Nix 2.35.2 and the committed Bun 1.4.2/tooling pins.

```text
Native aarch64-darwin / single: passed
Native aarch64-darwin / workspace: passed
Native aarch64-linux / single: passed
Native aarch64-linux / workspace: passed
Native x86_64-linux / single: passed
Native x86_64-linux / workspace: passed
```

Each native case compared generated bytes, built with `sandbox=true` and frozen install
without checkout dependencies, ran the output, proved unchanged-build reuse and compared
app/cache derivation identities after edits. The single-package case additionally changed
the locked registry version from 7.0.0 to 6.0.0, regenerated and observed a changed cache.
The workspace case independently edited both app and shared source at fixed version 1.0.0.
The supplemental shell help check was also executed on each system. The x86 coordinator
retained `filter-syscalls = false`; the application derivations themselves built in its
sandbox. Its unchanged TypeScript/Oxc tooling was built by the already configured native
`ssh://builder@nix-gcp-builder` Nix builder and copied through a temporary Nix binary cache
using `nix copy`; no store-source traversal or toolchain override was used.

`seihou registry sync-versions --dry-run` now proposes only the baseline unrelated Haskell
change. `seihou registry validate` still reports that its registry is 0.34.0 and module is
0.35.0; this is not a passing release-wide check. Generated docs were regenerated with
the documented extension, and its unrelated Haskell migration-page change was restored
to the pre-generation baseline. The house documentation profile is unchanged.

FRIC-1 in `docs/friction-log/` is **accepted**: noninteractive edited-orphan preview needs
a resolution; the isolated harness verifies its sole retainTracked choice before applying.
FRIC-2 is **accepted**: translated x86 builds use the environment-only syscall-filter
override while retaining `sandbox=true`. FRIC-3 is **accepted**: unchanged tooling built
on the configured native x86 builder and imported into the container avoids its Python
prefix limitation. All three are triaged, with no remaining logged entries for this plan.

Durable helper ownership, patch qualification, immutable maintenance modes and workspace
cache boundaries are distilled in
[ADR-6](../adr/6-share-an-opt-in-bun2nix-helper-and-isolate-registry-caches.md).


## Context and Orientation


This repository publishes Seihou scaffolding artifacts. `seihou-registry.dhall` lists their
versions, while `mori.dhall` supplies independent discovery metadata. A module is applied by
the `seihou` CLI, which records generated-file ownership and variables in a consumer's
`.seihou/manifest.json`. The module in scope is `modules/typescript/nix-bun-flake/module.dhall`,
currently version 0.3.0. Its canonical identity is
`mori://shinzui/seihou-modules/templates/nix-bun-flake`.

`modules/typescript/nix-bun-flake/files/flake.nix.tpl` declares fixed nixpkgs, flake-parts,
and git-hooks inputs, imports `nix/bun.nix`, conditionally imports `nix/pre-commit.nix`, and
then imports a user-authored `flake.module.nix` when present. All inputs are declared even
with hooks disabled. The generated `nix/bun.nix` offers `bunProject.extraDevPackages` and
provides Bun, just, TypeScript, Oxlint, and Oxfmt. The three systems are `aarch64-darwin`,
`aarch64-linux`, and `x86_64-linux`. `files/flake.module.nix.example` is safe to copy with
features disabled. `files/envrc` watches managed Nix files and loads `.envrc.local`.

The module also generates development `package.json`, tsconfig, and task files. Its default
package has no production build script or source entrypoint supplied by this module, so
merely enabling bun2nix cannot correctly infer `packages.default`. The new feature must not
run installation, rewrite manifests, generate a dependency expression automatically, or
select an application build strategy.

`scripts/update-nix-bun-flake.py` refreshes pins and npm tooling, regenerates a shared lock,
and checks hooks-on/off renders. Today `--check` still queries newest releases and rejects
any differences before validating the committed graph. Adding the helper must not require
an unrelated Bun/nixpkgs/Oxc upgrade. The expanded verifier must cover both booleans, all
three systems, and a copied unmanaged extension. Use the existing temporary-project module
installation pattern in `scripts/test-fumadocs-bootstrap.py` and
`scripts/test-fumadocs-adoption.py`; do not replace globally installed modules during tests.

Local ADR filenames and headings were scanned. Relevant decisions are
[ADR-3](../adr/3-separate-managed-scaffold-nix-wiring-from-user-extensions.md), which separates
managed scaffold wiring from user extensions, and
[ADR-5](../adr/5-share-one-checked-runtime-scope-and-verify-managed-adoption.md), which requires
explicit opt-in behavior, genuine Seihou ownership, preserved customizations, and independent
native acceptance. ADR-5's checked-runtime mechanism is Haskell-specific; this plan uses its
ownership and validation principles without introducing that mechanism into Bun. `mori.dhall`
currently declares no profiled ADR bundle, so preserve the existing local Markdown convention.

The working implementation motivating this extraction is
`mori://shinzui/keiro-ui/plans/21-add-native-nix-builds-and-fast-docker-images-for-the-console`.
Its reusable patch is in project `mori://shinzui/keiro-ui`, project-relative
`nix/bun2nix.nix`; registry-only workspace filtering is in `nix/console-deps.nix`, and hook
usage is in `nix/console.nix` (source-file artifact URIs pending). These references are
background evidence; all required patch and integration behavior is described below.

Research on 2026-10-26 found npm and the authoritative upstream release/tag both at bun2nix
2.1.2, with the commit recorded above. Mori had no registered Bun or bun2nix source corpus.
Use intended source identity `mori://nix-community/bun2nix` with project-relative
`programs/bun2nix/src/lib.rs`, `nix/bun2nix.nix`, `nix/fetch-bun-deps.nix`, and
`nix/mk-derivation/hook.sh` (source-file artifact URIs pending). The release's package is
`inputs.bun2nix.packages.${system}.default`; its passthrough values include `hook` and
`fetchBunDeps`. The [released source](https://github.com/nix-community/bun2nix/tree/2.1.2)
and [hook guide](https://nix-community.github.io/bun2nix/building-packages/hook.html) are
primary references; exact pinned source takes precedence over moving documentation.

A Nix derivation is a build recipe. A registry cache contains hash-verified downloaded
packages; Bun still installs dependencies from it during an application build. A sandbox
prevents ordinary build phases from reaching the network. A generated `bun-deps.nix`
describes fetches and is different from the managed development module `nix/bun.nix`.
Workspace entries are local packages linked into the current source tree, not registry
packages to download.

Baseline validation: `seihou validate-module modules/typescript/nix-bun-flake` passes.
`seihou registry validate` currently fails because the unrelated `nix-haskell-flake` registry
entry is 0.34.0 while its module is 0.35.0. Preserve and report this pre-existing difference;
do not silently repair or roll it into the Bun feature. Registry-wide synchronization rewrites
all entries and can include that unrelated change, so inspect its dry run and scope updates.


## Plan of Work


### M1: Package the verified compatibility patch


Add `modules/typescript/nix-bun-flake/files/nix/bun2nix-package.nix`, a small Nix function taking
`{ bun2nix }` and returning the patched upstream package via `overrideAttrs`. Preserve the old
`postPatch` and append a `substituteInPlace --replace-fail` that changes precisely this gate
in `src/lib.rs` relative to the package source root:

```diff
-    if lockfile.lockfile_version != 1 {
+    if !matches!(lockfile.lockfile_version, 1 | 2) {
```

The upstream repository path is `programs/bun2nix/src/lib.rs`; the derivation already selects
`programs/bun2nix` as its source. The error without this patch is
`Unsupported lockfile version: '2'.` Bun 1.4.2's upstream source, project
`mori://oven-sh/bun`, project-relative `src/install/lockfile/bun.lock.rs` (artifact URI pending),
defines v2 as stronger parse-time validation of the same package tuples rather than a new
registry/workspace encoding. This is the reason for the narrow patch, not permission to
accept every later version or every untested package protocol.

Add checked-in compact v1, v2, and unsupported-v3 fixtures under
`scripts/fixtures/nix-bun-flake/`, with pinned registry package hashes and local workspace
entries representative of the supported examples. A synthetic negative fixture may change
only a test fixture's format field; production lockfiles must never be rewritten to pass
the generator. Select any fixture dependency using registry/release evidence, not a floating
`latest` version in the committed fixture. The reference workspace contains one app and one
shared package with a visible exported message.

Introduce `scripts/test-nix-bun-flake.py` with a `--native` mode. Its first native integration
check builds this helper against the existing pinned toolchain, converts the v2 fixture,
and successfully consumes the generated result in a minimal frozen sandbox build. Also prove
v1 generation works, v3 fails clearly, and `hook`/`fetchBunDeps` remain accessible. This early
producer/consumer test must pass before expanding the toggle matrix. No copied `bun-deps.nix`
from another project or local package cache may stand in for generator output.


### M2: Add optional managed wiring and immutable lock validation


Add the boolean variable/prompt `nix.bun2nix`, default `false`, to
`modules/typescript/nix-bun-flake/module.dhall`. Add conditional copy steps and matching removal
entries for `nix/bun2nix-package.nix` and `nix/bun2nix-module.nix`. Using distinct new paths
avoids colliding with a consumer's pre-existing custom `nix/bun2nix.nix` wrapper.

The new `files/nix/bun2nix-module.nix` is a flake-parts module. It selects the helper from the
input for the current system, imports the pure patch wrapper, defines `packages.bun2nix`,
and adds that exact package through `bunProject.extraDevPackages`. The generated
`flake.nix.tpl` imports it only under `{{#if Eq nix.bun2nix true}}`. It declares the pinned
`bun2nix` input unconditionally, following existing `nixpkgs` and `flake-parts`. Add the new
managed paths to `files/envrc` watch entries. Disabled generation exposes no bun2nix package,
adds no generator to the shell, and does not import files that were not generated.

Keep `files/flake.module.nix.example` usable when bun2nix is disabled. Put any enabled-only
build example in the README or a separate explicitly named example; do not make copying the
standard extension example fail. Do not change the user's `flake.module.nix`, package scripts,
package manager, app output, `bun.lock`, or `bun-deps.nix` as a side effect of the toggle.

Refactor `scripts/update-nix-bun-flake.py` into reusable render/lock verification and explicit
refresh paths. `--check` validates committed pins and fixed-output metadata without comparing
them against moving latest releases or modifying the checkout. Add mutually exclusive
`--write-lock` to regenerate only `files/flake.lock` from the current committed template;
the existing no-argument refresh may continue discovering newest upstream tool releases.
Refresh mode must verify bun2nix against npm and the upstream release/tag before choosing a
new pin. Keep the patch version-qualified and require its fixtures to pass before an upgrade.

Render hooks/bun2nix false/false, false/true, true/false, and true/true. Every combination must
produce the same canonical lock, survive `nix flake update` without pin movement, and evaluate
shells for all three systems. Regeneration must preserve an existing unmanaged extension
byte-for-byte. Check enabling/disabling and removal through real Seihou operations: remove
managed feature files only according to Seihou's ownership rules, preserve edited orphans
on reconfiguration, and leave user-owned dependency/build files alone. Full module removal
retains its existing contract for generated files such as `package.json`; do not expand this
feature into a change to all module-removal semantics. A disabled reconfiguration must not retain
a live import or generator output even when an edited former managed file is retained as an
orphan. Do not manufacture receipts or recommend blanket `--force` for adoption.


### M3: Verify useful native builds and workspace cache reuse


Complete the single-package and two-workspace fixtures in `scripts/test-nix-bun-flake.py`.
The default command runs rendering, ownership, schema, and evaluation checks; `--native`
additionally builds the helper and real registry-backed consumers on the host system. Print
a concise summary distinguishing evaluation from actual native builds.

Application recipes belong in a fixture-owned `flake.module.nix`, as they will in a real
consumer. Obtain the shared helper through `config.packages.bun2nix`. Use
`stdenvNoCC.mkDerivation`, explicit Bun and any genuinely required build interpreter,
`strictDeps = true`, `bun2nix.hook`, and explicit build/install phases. Frozen install flags
must preserve upstream platform defaults: isolated linking, plus `--backend=symlink` on
Darwin. Disable the redundant lifecycle phase with `dontRunLifecycleScripts = true` when
fixtures build without it. Do not invent an `--offline` flag, enable network access, or use
the hook's executable/check defaults for a static build. Distinguish `bun run test` from
Bun's unrelated built-in `bun test` runner in documentation.

The single-package example calls `fetchBunDeps { bunNix = ./bun-deps.nix; }`. The workspace
example evaluates the generated expression lazily and removes local names before handing
it to `fetchBunDeps`. Use an explicit fetcher argument signature so `callPackage` can supply
all fetchers required by the generated file:

```nix
registryOnly = { copyPathToStore, fetchFromGitHub, fetchgit, fetchurl, ... }@args:
  builtins.removeAttrs (import ./bun-deps.nix args) workspaceNames;
bunDeps = bun2nix.fetchBunDeps { bunNix = registryOnly; };
```

Derive `workspaceNames` from the fixture workspace manifests, not from assumed `@scope`
spelling. Do not remove workspace records from the real lock or hand-edit the generated
expression. Current sources enter the application derivation and Bun creates current
workspace links. Use named `builtins.path` filtering or `lib.fileset.toSource` to include
only build inputs; never import local `node_modules` or rely on the checkout's original
source hash surviving plain `filterSource`.

Build from temporary trees with no local dependency installation, using `--option sandbox
true`. Run the built fixture output and assert the registry-backed value and shared message.
Edit the app and shared message independently, hold any explicit revision fixed, and require
changed output with identical registry-cache derivations. Regenerate after changing one valid
locked registry dependency and require the cache identity to change. Repeated unchanged builds
must do no application work. Compare generation bytes with the pinned helper. These are
correctness/cache-identity checks; no arbitrary build-speed claim or installed-dependency-tree
optimization is required.

Run actual native acceptance on aarch64-darwin, aarch64-linux, and x86_64-linux, or leave the
missing platforms explicit in Progress. Linux coordinators may run in Apple containers;
remote evaluation alone does not prove a native build. Run the existing Fumadocs adoption
regression and verify a rendered Fumadocs composition remains bun2nix-disabled by default,
retains its package-manager choice, and uses the same expanded canonical lock. Do not turn
bun2nix into an automatic dependency of ordinary Fumadocs build/test commands.


### M4: Document adoption, qualify the patch, and prepare the module release


Update `modules/typescript/nix-bun-flake/README.md` with fresh-project and existing-project
commands, the new option, optional generated paths, and complete examples for both layouts.
Document `bun-deps.nix` generation with the exact pinned generator, frozen sandbox builds,
manifest/lock/expression update order, workspace cache filtering, and why the option does
not create `packages.default`. Include platform defaults and lifecycle guidance, source
filtering, and honest revision-driven rebuild costs. Keep containers out of the base module.

Document the exact patch, affected release/commit, source path, error, evidence, supported
v1/v2 scenarios, unsupported v3/scoped-override limit, `--replace-fail` guard, and removal
criteria. Retire the override only when a verified released upstream version supports the
required formats and all generator/frozen-install fixtures pass without the patch. Do not
make an unrestricted version-gate bypass, hide a failed substitution, or publish a private
compatibility fork without a separate decision.

For adoption, show `seihou update nix-bun-flake --var nix.bun2nix=true --dry-run`, then the
corresponding reviewed update. Preserve other recorded variables, shared owners, custom flake
inputs, unmanaged builds, and package-manager settings. An existing custom helper is removed
only after callers are switched to the shared package and checks pass. Show how to disable the
feature without deleting authored locks or dependency expressions. No real consumer migration
is required in this plan.

Prepare module version 0.4.0 in `module.dhall`, its entry in `seihou-registry.dhall`, the
`nix-bun-flake` template descriptor in `mori.dhall`, and the root README catalog. Inspect
`seihou registry sync-versions --dry-run` before any write; do not absorb unrelated registry
drift. Regenerate `okf-docs/` using the documented extension rather than editing its generated
module page. Review the diff for unrelated metadata changes and preserve its house profile.
Distill any new durable helper ownership/patch policy into an appropriate local ADR, preserving
ADR-3's existing extension boundary. This is a tested release candidate; tagging, pushing,
registry publication, upstream pull requests, and broad consumer migration are separate work.


## Concrete Steps


Run from the seihou-modules repository root. Discover dependency sources with Mori before
inspecting APIs. Never traverse `/nix/store` or the filesystem root for source lookup.

```bash
mori registry list
mori registry search bun2nix
mori registry show shinzui/seihou-modules --full
mori registry docs shinzui/seihou-modules
mori path mori://shinzui/seihou-modules/templates/nix-bun-flake
curl -fsSL https://registry.npmjs.org/bun2nix/latest
curl -fsSL https://api.github.com/repos/nix-community/bun2nix/releases/latest
git ls-remote https://github.com/nix-community/bun2nix.git refs/tags/2.1.2
seihou validate-module modules/typescript/nix-bun-flake
seihou registry validate
```

After implementing the new modes and fixture script, run the following target interfaces.
These new script flags are deliverables, not commands claimed to exist at plan creation.

```bash
python3 scripts/update-nix-bun-flake.py --write-lock
python3 scripts/update-nix-bun-flake.py --check
python3 scripts/test-nix-bun-flake.py
python3 scripts/test-nix-bun-flake.py --native
python3 scripts/test-fumadocs-adoption.py
```

Repeat `--native` on each declared system, saving system/version and build evidence. Generated
fixtures may use `path:` flakes; any Git-flake fixture must make new files visible to Git
before evaluation. Verification must leave committed module files and pins unchanged.

The expected adoption interface from a consumer with the candidate installed is:

```bash
seihou update nix-bun-flake --var nix.bun2nix=true --dry-run
seihou update nix-bun-flake --var nix.bun2nix=true --json
nix run .#bun2nix -- --lock-file bun.lock --output-file bun-deps.nix
nix develop -c bun2nix --help
# After adding the documented application recipe in flake.module.nix:
nix build --option sandbox true
nix flake check --option sandbox true
```

`--json` is the CLI's noninteractive apply interface; use it only after examining the dry-run
plan. For unpublished tests, copy the candidate module into each fixture's own
`.seihou/modules/nix-bun-flake` as the existing test scripts do. Do not replace a user's
installed module or update a real project just to run the fixture.

Final metadata/documentation checks are:

```bash
seihou validate-module modules/typescript/nix-bun-flake
seihou registry sync-versions --dry-run
seihou registry validate
seihou extension run okf -- docs --dir . --out okf-docs --force
okf validate okf-docs --strict --profile okf-docs/profile.dhall --profile-enforce
python3 scripts/update-nix-bun-flake.py --check
git diff --check
```

Keep generated docs changes scoped to this feature. If the recorded unrelated Haskell version
mismatch still prevents global registry validation, report that exact baseline failure and
independently check the Bun module/registry/Mori/docs versions agree at 0.4.0; do not claim the
global check passed or fix unrelated artifacts. Resolve release-wide baseline issues separately
before publishing a registry release.


## Validation and Acceptance


With the flag omitted or false, existing shells and the copied default extension evaluate on
all three systems; `packages.bun2nix` and generated feature imports are absent, and the helper
is not in the shell's dependency graph. With true, `nix run .#bun2nix -- --help` and the shell
resolve the same patched helper, and its hook/fetch passthrough APIs work in a real recipe.
The four flag combinations have byte-identical locks; full flake update preserves managed
pins, and immutable verification does not write files or demand a newer unrelated toolchain.

v1 and v2 generation succeed, v3 fails with an explicit unsupported-version error, and the
original lock bytes are unchanged. Single-package and workspace recipes build without local
`node_modules` in network-isolated ordinary phases. Frozen installation succeeds, the built
program includes current shared-source values, regeneration matches committed fixture output,
and app/shared edits preserve the registry cache while changing the appropriate artifact.
Locked dependency changes invalidate the cache after regeneration. Hook lifecycle/check
behavior is configured deliberately rather than inherited accidentally.

Real Seihou regeneration, update, and disabling preserve authored extensions, custom manifest
content, locks, dependency expressions, and edited orphans. Full module removal deletes the
feature's managed files under the existing removal contract while preserving unmanaged
`flake.module.nix`, `bun.lock`, `bun-deps.nix`, and app sources; generated files already owned
by the base module retain their existing removal behavior. Default Fumadocs composition
remains compatible. Record native builds separately from evaluation and mark milestones only
when their required platform evidence exists. Module/registry/Mori/docs versions and operator
commands agree; any global pre-existing registry failure remains explicitly qualified.


## Idempotence and Recovery


Work in temporary fixtures for generation, lock comparison, and adoption experiments. Do not
use broad `--force`, manual manifest reconstruction, Git resets, or global package-cache
pruning. Snapshot managed candidate files before generating a lock; rerun `--write-lock` when
only the intended pinned input graph has changed. `--check` must be read-only. A patch mismatch
is a stop-and-investigate signal: inspect the new released source and qualify it, rather than
using an optional substitution or changing the real lock's version.

The generated dependency expression is user-owned and regenerated explicitly with the pinned
helper; it is committed with deliberate dependency changes. Disabling bun2nix removes only
managed feature wiring and does not erase this expression or a user's recipe. Preserve normal
Seihou conflict/orphan handling. Keep the current branch, use Conventional Commits, and include
an `ExecPlan:` trailer pointing to this file on implementation commits. No intention trailer
is required for this plan.


## Interfaces and Dependencies


`nix.bun2nix` is the default-false Seihou boolean. New managed consumer files are
`nix/bun2nix-module.nix` (flake-parts wiring) and `nix/bun2nix-package.nix` (a pure
`{ bun2nix }: <patched package>` wrapper). The enabled public package is `packages.bun2nix`,
with unchanged upstream `hook` and `fetchBunDeps` APIs. No generic default app or generated
project dependency expression is added.

The initial helper is bun2nix 2.1.2 at the verified commit above, with nixpkgs/flake-parts
following existing inputs. Maintain the current nixpkgs revision
`39ad350a0602fa0a58a544344e3e9187526ea45c` and Bun 1.4.2 unless an actual reproduced
compatibility failure requires a separate toolchain decision. The helper's released transitive
input graph becomes part of the canonical lock; do not rely on evaluation-time downloads or
import-from-derivation to generate dependency files.

`python3 scripts/test-nix-bun-flake.py` is the fast generation/evaluation/ownership harness;
`--native` adds real current-platform builds. The updater provides immutable `--check`,
lock-only `--write-lock`, and its explicit documented no-argument upstream refresh. The
planned module release is 0.4.0. No parent MasterPlan is assigned.
