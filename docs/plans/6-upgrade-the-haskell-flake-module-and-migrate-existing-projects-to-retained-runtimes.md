---
id: 6
slug: upgrade-the-haskell-flake-module-and-migrate-existing-projects-to-retained-runtimes
title: "Upgrade the Haskell flake module and migrate existing projects to retained runtimes"
kind: exec-plan
created_at: 2026-10-18T17:36:15Z
intention: "intention_01m4xq1t11ezha3http0erjxt2"
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-10-18T17:36:15Z
  revisions:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-18T19:54:20Z
      mode: "implement"
      note: "Implement the user-authorized Seihou runtime module companion after EP-18 acceptance; retain explicit selections and existing customizations."
---

# Upgrade the Haskell flake module and migrate existing projects to retained runtimes

This ExecPlan is a living document. Keep Progress, Surprises & Discoveries, Decision Log
and Outcomes & Retrospective current. This plan belongs to `mori://shinzui/seihou-modules`
and coordinates with `mori://shinzui/haskell-nix/masterplans/4-coordinate-horizon-inspired-haskell-nix-performance-and-reliability-improvements`.
That foreign plan is a coordination reference, not a project-local `master_plan` parent.


## Purpose / Big Picture


Make accepted runtime and development-shell interfaces available through normal
Seihou-generated Haskell projects, and migrate existing projects without losing their
customizations. A migrated project's ordinary `nix develop` and production outputs use
one checked dependency scope. Subsequent Seihou updates preserve that wiring, owned
packages, tools, service hooks and explicit runtime selection.

Deliver an upgraded `nix-haskell-flake` module, a validated shared input lock, and an
`upgrade-haskell-runtime` blueprint supporting both legacy adoption and ordered version
migrations. Acceptance includes real builds and reuse, not just a newer pin or a receipt.
Projects explicitly opt into runtime mode; unconfigured projects retain bare-shell behavior.
Application package splitting, compiler intermediate reuse and broader generated recipes
remain separate producer work and are not enabled automatically by this migration.


## Progress


- [x] (2026-10-18) M1: Deliver a compatible module candidate with validated pins, explicit runtime configuration, one checked shell/build scope and working legacy/new-scaffold fixtures.
- [x] (2026-10-18) M2: Deliver a discoverable adoption/migration blueprint with exact version edges, customization/ownership preservation and repeat/failure coverage.
- [x] (2026-10-18) M3: Accept an isolated real-consumer migration through ordinary builds, shell/Cabal checks, dependency identities, measured costs, cache retrieval and repeat upgrades.
- [x] (2026-10-18) M4: Prepare a coherent module/blueprint release, registry/Mori/docs updates and a validated operator workflow with rollback and explicit support limits.

Accepted M1/M2 checkpoint, 2026-10-18: module 0.32.0 and CLI scaffold 0.3.1 use
published channel `e5a7c2c50080b3364f0f0fd667240c560596d0ed`, toolchain
`21933607e80ec4660a28a125a6f4c0707e358caf` and Nixpkgs
`d5dfd8e6716dde34398bc14bc87c10dece9c8c68`. All six native bootstrap cases pass:
root/CLI bare and runtime builds, real Cabal tests and behavioral edits, old inputs lacking
both new APIs, and service/header/hook behavior including a path containing spaces. Seven
negative runtime probes fail as required. The early real Mori scope bridge retains all
311 dependency identities, all five owned recipes and its ordinary production output.
Blueprint 0.1.0 validates against published schema 7d02695f and declares exact released
0.30.0 → 0.31.0 → 0.32.0 edges. Actual CLI fixtures pass legacy adoption, both recorded
origins, genuine shared owners, customized managed-file merge, rejected conflicting merge
with unchanged metadata, interrupted provider/resume, nonzero exit without an applied edge,
repeat no-op/update and failed independent acceptance after attendance. Registry/Mori and
generated documentation include the new artifact. That checkpoint was subsequently closed by the final real-consumer acceptance below; raw terminal commands are retained outside sources under
`/private/tmp/mp4-seihou-runtime`. [Durable fixture evidence](../evidence/haskell-runtime/fixtures.json) and its raw archive
retain the terminal commands.

2026-10-18 final lock validation: upstream master moved after the release pins were
selected. Fixed the existing --check command to validate shipped immutable pins by default;
regeneration without --check may still deliberately resolve latest. The implicit final
check passes canonical generation, full-update no-op and all/minimal lock equivalence.

Historical planning baseline, 2026-10-18: implementation has not started. The module and registry
currently declare 0.31.0; its README still says 0.30.0. Recheck published artifact versions
before selecting the target release. Reuse the active initiative's Intention ID.


## Surprises & Discoveries


2026-10-18: Mori has only its existing master-plan skill application recorded in Seihou;
its Haskell files are unrecorded legacy files. Adopt them through agent run and real module
generation without inventing 0.31.0 history. Keep the existing application and shared ignore
owners. Recorded-version fixtures use genuine released sources separately.

2026-10-18: Preserve formatter package choices, parser language options and generated-code
exclusions, alongside hooks and tools. A real rehearsal caught missing formatter policy and
a duplicate exclusion definition before acceptance. Restored only formatter-modified pilot
files whose original source hashes still matched the untouched producer. Existing engine
serialization adds an empty checkoutCommands list to old applications; normalize only that
documented empty default, preserving commands and every origin/variable.

2026-10-18: A fresh offline Cabal checkout needs its exact pinned Git source checkouts and
package archives populated before offline native acceptance. Source-complete comparison uses
a separate fresh bare-compiler plan. Owned build/test targets avoid accidentally testing all
upstream source-repository packages imported by the consumer's source policy.


2026-10-18: The native published retained-runtime closure retrieves all 393 paths,
including the compiler, into an initially empty matching store with builders disabled and
exact publication NAR metadata. The additional independently packaged HLS closure retrieves
680 further paths (730 in its own closure) without builds and matches all published cache
metadata. However, 427 paths differ in NAR content from independent local builds at the
same selected derivation/output paths, including the HLS root. Retain this failed local-byte
equality probe; native local HLS protocol behavior passes separately. Do not claim byte
reproducibility, cached-HLS execution or hosted CI from these observations.


2026-10-18: Cabal's test command can return zero with “No tests to run” when a mixed
package selector list includes Mori's schema-pin package, which has no test suites.
Stopped the initial native check before acceptance. The checker now reads Cabal's generated
plan and requests all five explicit owned test components, requiring executed passing-suite
output for every selected suite. No-suite projects record explicit non-applicability,
never a test pass. Threaded RTS settings are per-suite: the diagram/types runners do
not support -N4, while the threaded core/API/CLI runners use the existing bounded harness. This preserves all suites without treating an exit status alone as test evidence.
Source: `mori://haskell/cabal`, project-relative
`Cabal/cabal-install/src/Distribution/Client/CmdTest.hs` and `ProjectPlanOutput.hs`
(source artifact URIs pending).

## Decision Log

2026-10-18: In runtime mode, set the ordinary default-priority `pkgs` argument to the
same explicit pinned Nixpkgs import as the toolchain. Flake-parts' lower-priority default
uses `legacyPackages`, whose `lib.version` label differs despite identical operative
native derivations. Keep the upstream guard unchanged and preserve higher-priority caller
overrides. Null runtime mode retains the original bare package argument without forcing
new helper APIs. Source: `mori://hercules-ci/flake-parts`, project-relative
`flake-parts/modules/nixpkgs.nix` (file-level artifact URI pending).

2026-10-18: Expose an optional audited `packageSource` for the built-in root recipe;
null preserves its complete original source. Do not guess which root resources are unused.
Dependent CLI recipes retain all files within fixed-name package-local `builtins.path`
boundaries, so unrelated shell changes preserve their sources without excluding resources.



2026-10-18: Keep runtime mode explicit. Application recipes remain in the owning managed
package module or unmanaged extension. The base module supplies a shared-scope interface;
it does not infer package names, choose moving runtime defaults or own `flake.module.nix`.
This follows local ADR 3 and preserves upgrades for projects without retained runtimes.

2026-10-18: Use one blueprint with no automatic base modules for legacy adoption and
versioned upgrades. Inventory the project before merging canonical generated output.
Edges describe actual module versions, not fabricated legacy history, following ADR 4.

2026-10-18: Distinguish Seihou attendance receipts from independently validated adoption.
A provider exit or applied receipt cannot establish that builds and dependency identities
pass. Retain the existing engine semantics and gate rollout on a separate acceptance report.


## Outcomes & Retrospective


Completed on 2026-10-18. Module 0.32.0, composed CLI scaffold 0.3.1 and adoption
blueprint 0.1.0 are prepared together with exact published channel/toolchain pins and
canonical lock. Null runtime keeps legacy behavior; explicit retained configuration supplies
one checked production/development scope. Custom overlays declare every owned recipe;
compiler/native drift, shared overrides and incomplete selections fail. Local
[ADR 5](../adr/5-share-one-checked-runtime-scope-and-verify-managed-adoption.md) records
scope, import-priority and independent-adoption decisions.

[Final fixture receipt](../evidence/haskell-runtime/fixtures.json) covers six native bootstrap
cases and four adoption cases. Actual Seihou CLI operations preserve genuine shared owners,
authored source including tracked database SQL, custom managed-file edits and unmanaged
extensions. Both released origins follow their ordered windows. Nonzero providers create no
applied edge; conflicts preserve canonical metadata; interrupted checks revoke stale accepted
reports before external work; no-suite projects explicitly report non-applicability. A
provider/attendance receipt never substitutes for the independent checker. No real nested
model was launched: bounded deterministic providers exercise the actual supported CLI path.

[Final real Mori receipt](../evidence/haskell-runtime/native-mori.json) and its raw archive
bind the independent before/after reports, full commands and source preservation. Genuine
legacy adoption retains all 311 dependency identities, five owned recipes, compiler and
ordinary default derivation. All 4,280 owned Cabal cases pass: types 79, core 3,212,
diagrams 3, API 62 and CLI 924. Ordinary default, overlay audit, cohort parity, library
extension, formatting, pre-commit, actual HLS protocol and 392-dependency fresh source-complete
Cabal comparison pass. The checked shell exposes original native tools/headers and service
environment. Existing master-plan application/origins, ignore ordering/co-owners, custom schema
input and empty per-project cache additions survive. The real producer's original manifest
work is unchanged; all adoption operations use an independent clone.

A hook-only edit preserves production/runtime identities and passes native acceptance. A
real CLI description edit changes help behavior, preserves compiler/all retained dependencies
and all four unrelated owned recipes, passes 924 CLI cases and builds through normal Nix.
An invalid selection fails independently. Repeating the blueprint is a no-op for application
ownership; normal update and a complete second native check pass without duplicating wiring.
The candidate primary shell becomes the runtime shell; its full SDK and previously accepted
EP-18 production artifact policy remain application-owned.

The exact retained publication retrieves 393 paths, including the compiler, into an empty
matching native store with builders disabled (6,930,343,792 logical NAR bytes). The additional
HLS retrieval adds 680 paths and matches published metadata for its 730-path closure. Its
427 independent local-rebuild NAR differences are retained explicitly; do not claim local-byte
reproducibility, downloaded-HLS execution or hosted CI. Native local HLS initialization,
hover, diagnostics and clean shutdown pass separately. Existing cache trust/authentication
are preserved; nothing is published to a cache.

Costs are observations, not an asserted compilation speedup. First cold owned Cabal
preparation has an 880.80-second timestamped upper bound; the initial shell entry was observed
at approximately 11 seconds but its early per-command receipt was overwritten, so that
historical observation is explicitly approximate. Exact accepted entry/verification commands
are retained; warm shell entries are 4.92 and 4.85 seconds. First complete native acceptance
is 206.53 seconds, hook-edit acceptance 168.20 seconds, CLI edit build 15.01 seconds,
complete edited CLI tests 51.16 seconds and normal changed Nix build 37.59 seconds. The final
repeat acceptance is 179.63 seconds. Failed selector/thread-setting probes and additional
migration/maintenance commands remain visible. No per-edit speedup or amortization is inferred
from scope consistency.

Module/blueprint validation, registry version synchronization, Mori descriptor type/sealed
validation, final canonical lock/all-minimal/no-op checks, generated 17-concept OKF docs and
diff checks pass. READMEs, target manifest, exact edge prompts, old-guide pointers and operator
preview/adoption/migration/validation/retry/recovery instructions are coherent. Runtime
qualification is native Apple Silicon only; other runtime configurations need their own
acceptance. The release is prepared locally, with no Git push, consumer fleet migration,
production database/schema migration, persistent-service start or system activation. Scoped
local registry metadata may be refreshed for discovery. EP-19 remains deferred under the
user's explicit order; this standalone companion adds no ninth member to MP-4's publication
set.


## Context and Orientation


This repository is a Seihou registry. A module generates managed files; a blueprint supplies
agent instructions and references for a project-specific merge. `seihou-registry.dhall`
publishes artifacts. `mori.dhall` separately describes canonical project/template identities
and must be maintained alongside registry versions. Registry sync does not update it.

`modules/haskell/nix-haskell-flake/module.dhall` declares module variables, steps and
migrations. Its `files/flake.nix.tpl` pins the toolchain and shared Haskell channel;
`files/flake.lock` is the canonical lock seed. At authoring, those pins are respectively
`206ecd25bcb4a07581210bdae3e6f43c8fd179d8` and
`58a2c26c5be7cdf222fba6323939a67d3c62f193`. These are observed baselines, not proposed targets.
`files/nix/haskell.nix.tpl` uses the bare `mkDevShell`; its optional built-in package uses
plain Nixpkgs `callCabal2nix`. `scripts/update-nix-haskell-flake-lock.sh` updates both pins
and lock and verifies exact locking across feature configurations. Use explicit validated
revisions rather than its latest-master defaults.

A retained runtime is an immutable selection of dependency sources, flags, compiler and
build policy. `mori://shinzui/haskell-nix` owns `lib/mkProjectDevShell.nix` and the argument
reference in `docs/user/package-sets.md` (source-file artifact URIs pending). Its wrapper
constructs and audits one retained application scope, passes it to the generic shell
helper, and returns a shell with `applicationScope` and diagnostic `packageSetIdentity`.
Use that same scope for production. The generic helper belongs to
`mori://shinzui/haskell-nix-dev`, project-relative `lib/mkProjectShell.nix` (source artifact
URI pending). It selects the scoped compiler and compatible tools without rebuilding HLS
from an application dependency set.

Accepted prerequisites are
`mori://shinzui/haskell-nix/plans/20-build-project-development-shells-from-retained-runtime-package-sets`,
`mori://shinzui/haskell-nix-dev/plans/4-publish-compiler-capabilities-and-an-explicit-platform-support-matrix`
and `mori://shinzui/haskell-nix-dev/plans/5-exercise-ghc-cabal-and-hls-in-toolchain-compatibility-checks`.
Do not wait for experimental application compilation or recipe expansion to roll these
interfaces out. Choose a published matching pair that preserves the selected runtime's
compiler and Nixpkgs; a capability declaration alone is not cache/build acceptance.

`files/flake.module.nix.example.tpl` documents the unmanaged extension. The managed
`nix.package-module` import seam serves dependent scaffolds, including
`modules/haskell/haskell-cli-app/files/nix/haskell-cli-app.nix.tpl`.
`files/envrc.tpl`, `files/nix/treefmt.nix.tpl`, `files/nix/pre-commit.nix.tpl` and the
service templates retain directory watches, formatter overrides, hook installation and
project-local PostgreSQL/Redis/Redpanda/ClickHouse settings. Runtime mode must not inherit
a second bare GHC shell. Native tools and library/header inputs have distinct roles.

Existing migration precedents are `blueprints/upgrade-haskell-flake-parts/`,
`blueprints/fix-nix-haskell-flake-customizations/`, `blueprints/upgrade-fumadocs/` and
`scripts/test-fumadocs-adoption.py`. The older Haskell prompts target bare shells and
include historical force-based instructions; do not copy those as the new safety policy.
The Fumadocs blueprint shows empty base modules, a target manifest, ordered prompts,
correct origins and separate debug-run/debug-migrate behavior.

Relevant decisions are [ADR 3](../adr/3-separate-managed-scaffold-nix-wiring-from-user-extensions.md),
which assigns managed package wiring to dependent scaffolds and leaves `flake.module.nix`
unmanaged; [ADR 4](../adr/4-preserve-authored-content-during-fumadocs-adoption.md), which
requires inventory before generation, preserved authored files and honest module history;
and [ADR 1](../adr/1-use-project-local-sockets-for-redis-development-services.md), which
preserves project-local Redis socket isolation. Record new durable module/runtime
interface decisions during implementation using this repository's filesystem ADR format.

Mori lookup was attempted during planning but the local database was unavailable. Owning
project descriptors, local sources and installed CLI help supplied the observed contracts.
Retry Mori for dependency discovery during implementation. The relevant engine belongs to
`mori://shinzui/seihou`, project-relative `seihou-cli/src-exe/Seihou/CLI/AgentMigrate.hs`;
the schema belongs to `mori://shinzui/seihou-schema`, project-relative `Blueprint.dhall`
and `BlueprintMigration.dhall` (source artifact URIs pending). `versionProbe` supplies the
default target version, not the previous version. Applied receipts record attendance,
not independently verified builds. Preserve those distinctions in the blueprint.


## Plan of Work


### Milestone 1: Deliver a compatible runtime-aware module


Select published immutable channel/toolchain commits exposing the accepted helpers and
matching the intended retained configuration. Verify upstream release commits/tags and
the authoritative Seihou registry before choosing the next unused module version. Record
exact compiler, Nixpkgs, runtime and publication identities. Do not change the compiler or
shared dependency policy merely to obtain a helper. Regenerate both template pins and
canonical lock with `scripts/update-nix-haskell-flake-lock.sh` using explicit revisions.

Add a per-system Nix interface in `files/nix/haskell.nix.tpl`. The option
`haskellProject.runtime` is null by default, or an explicit record containing
`runtimeSelection`, `applicationSelections`, and
any necessary application cohort/registry policy; sibling options `ownPackages` and
`applicationOverlays` declare application recipes. The owning package module or unmanaged
extension supplies this record. Expose the checked result as read-only
`haskellProject.applicationScope`. These are module options adapting the upstream library interface.

In runtime mode construct the checked wrapper once. Its result supplies default/primary
named shells and production packages. The built-in package output consumes that checked
scope instead of constructing another package set. Adapt dependent scaffold wiring where
necessary to consume the interface through `nix.package-module`, preserving its ownership
and avoiding duplicate defaults. Cover a root package and a managed two-package CLI.
Declare all application overlay packages and reject attempts to redefine shared/runtime
packages. Do not fill absent runtime/application selections from moving defaults.

Preserve `haskellProject.extraDevPackages`, caller hooks, compatible environment inheritance
and existing service behavior. Add explicit library/header input options and a nullable
HLS request that follows actual capability availability in runtime mode. Do not inherit the
legacy compiler shell into the new wrapper. Null runtime configuration retains the old
bare-shell path without forcing new helper attributes. A secondary compiler lacking the
retained configuration remains a separate bare shell, never a falsely labelled runtime
shell. Unsupported explicit compiler/HLS requests fail clearly.

Exercise one real consumer's declared runtime and owned overlay against this candidate
before expanding fixtures. Add `scripts/test-haskell-runtime-bootstrap.py` to render root
and two-package projects in both modes and verify actual Nix output identities, canonical
locks and unmanaged-file preservation. Cover all/minimal feature lock equivalence,
pre-commit-off, representative service hooks, shell-only edits, wrong compiler/HLS,
incomplete selections and shared-package override rejection. Avoid an unrelated service
feature power-set campaign. M1 passes on working shared-scope builds and preserved legacy
behavior, not a pin bump alone.


### Milestone 2: Implement adoption and ordered migration


Create `blueprints/upgrade-haskell-runtime/{blueprint.dhall,prompt.md,README.md}` and
`files/target-versions.json`, plus a minimal unmanaged extension example and per-edge
prompts under `migrations/`. The blueprint has no automatic base modules. Its target
manifest records the tested module version, immutable toolchain/channel revisions and
supported runtime configurations; it is derived from M1 rather than another solver or
selection authority. Select a compatible published schema after inspecting its current
contract; an older schema may need the explicit record-extension approach used by
`upgrade-fumadocs`.

The main prompt handles unrecorded legacy projects, existing retained-runtime consumers
and already-migrated projects. Inventory source/lock pins, Cabal imports, exact runtime
and complementary selections, package outputs, custom inputs, native tools, HLS, hooks,
services, `.envrc.local`, process-compose overrides, checks and Seihou ownership before
writing. Back up affected paths outside the checkout and generate canonical target files
in isolation. Preserve authored code/tests/assets and existing explicit selections. If
no compatible retained configuration exists, report that conflict rather than invent a
generation or silently upgrade dependency/compiler inputs. Keep unconfigured bare projects
on their supported path until runtime adoption is explicit.

Declare exact ordered migration edges for the inspected 0.30.0 and 0.31.0 module origins
through the chosen target. Verify their released files before defining transformations;
use a linear chain when needed and do not skip an applicable prerequisite edge. Capture
the original module version before updating it and pass `--from`/`--to` explicitly. A
read-only `versionProbe`, if used, reads the now-selected target module version; it cannot
recover the old origin. Legacy adoption uses `agent run` and creates no fabricated source
version or `--mark-applied` shortcut.

Preview recorded upgrades with `seihou update nix-haskell-flake --dry-run --json`. Apply
reviewed updates using saved variables and necessary shared owners; preserve three-way
merge baselines and remote origins through Seihou operations. Never hand-write manifest
hashes or IDs, blindly force conflicts, delete co-owning applications or call copied files
canonically managed. Runtime Cabal imports must match the same immutable channel/source
policy. Stop on unexplained dependency drift and present the concrete separate upgrade.

Add `scripts/check-haskell-runtime-adoption.py` to compare a before-inventory and actual
migrated state against the target manifest. Its acceptance report binds input/runtime/
compiler identities, source preservation, executed commands, exit statuses and build/reuse
observations. Prompts require that checker before reporting success. A provider exit or
Seihou attendance receipt does not replace this evidence. Test that nonzero provider exit
creates no applied edge and that failed validation creates no accepted report even if an
attendance receipt already exists. Do not assume an engine post-validation transaction
hook or expand this plan into redesigning Seihou receipts. A retry must recheck acceptance.

Add `scripts/test-haskell-runtime-adoption.py` using disposable local candidates and a
controlled stub provider/direct deterministic transformation runner. Do not launch an
uncontrolled nested agent for tests. Cover legacy adoption, both supported recorded
origins, already-compliant/no-op behavior, custom managed-file edits, shared owners,
unsupported selections, validation failure and interruption/resume. Debug-run rendering
may record blueprint provenance but must not change managed file/application ownership;
debug migration is read-only. Register the blueprint in `seihou-registry.dhall` and
`mori.dhall` as `mori://shinzui/seihou-modules/templates/upgrade-haskell-runtime`.
M2 passes on both CLI entry points and executable preservation/failure tests, not prompt
text matching alone.


### Milestone 3: Validate a real consumer and repeat upgrades


Use `mori://shinzui/mori` as the primary multi-package pilot because its accepted optional
runtime-shell integration provides an actual comparison. Recheck its current state and
selections before migration. Work in an isolated copy preserving staged, unstaged and
relevant untracked work, with no feature branch by default. The root/legacy and two-package
fixtures supply the other topologies without an uncontrolled fleet sweep. Exercise the
actual blueprint path with a controlled supported provider and retain its validation
report. Prepare a canonical before-inventory using the acceptance checker's inventory
mode so its schema is shared with validation rather than hand-authored.

Compare compiler and runtime dependency derivations before and after; otherwise-equal
production recipes remain equal. Account for truthful Git revision stamps by matching
producer source references. Verify scoped `ghc`/`ghc-pkg`, representative dependency
visibility and native-library discovery, supported HLS, preserved tools/service environment,
and an actual owned Cabal build/test followed by a source edit. Run the project's ordinary
Nix outputs, applicable complete owned tests, consumer-overlay audit, cohort comparison,
formatting and pre-commit checks. Opening a shell alone does not pass this milestone.

Keep source-complete Cabal comparison separate from ordinary installed-package reuse:
`pre-existing` plan rows cannot prove source/metadata identity. Follow the owning channel's
fresh-plan procedure with the same retained imports and explicit policy. Do not disable
existing parity checks or change sources/flags to pass adoption. Enable no persistent
service, activate no system configuration and migrate no existing database during the
rehearsal; disposable test services remain owned by the existing test harness.

Record first/warm shell entry, a representative application edit, downloads, compilation,
required verification and additional migration/maintenance costs separately. A shell-only
tool/hook edit preserves production/runtime recipes; an owned-source edit invalidates
only actual dependents. Prove unchanged shared-output retrieval with builders disabled
on a matching worker through the existing channel cache mechanism. Preserve configured
public/private trust and external authentication, with no credentials in templates or
reports. Local empty-store evidence does not establish hosted CI. Exercise each newly
claimed runtime system; translated Linux correctness is qualified rather than physical
x86 performance.

Run normal module update and the checker again. Repeated generation, blueprint adoption,
version migration and update preserve customizations, source hashes, explicit selections
and accepted outputs without duplicate configuration. Inject a bad selection and an
interrupted merge; recovery restores only this migration's changes and consistent managed
metadata. M3 passes on an actual working consumer and repeat-upgrade/cache results with
honest costs. This scope makes no arbitrary changed-code speedup claim from shell wiring.


### Milestone 4: Prepare the coherent release and rollout instructions


Finalize module and blueprint versions, canonical pins/lock, target manifest and all
ordered edge prompts together. Update their READMEs, the root README, registry and Mori
descriptor, then regenerate `okf-docs/` with the existing extension/profile workflow.
Document preview, source-version capture, candidate discovery, legacy adoption, versioned
migration, validation reports, repeat updates and recovery. Older Haskell upgrade and
remediation guides should point to this new path without rewriting their old edge history.

Prepare a reviewable release before publication and claim remote availability only after
actual publication. Broader project migrations use per-project validation; this plan is
not permission for an unconditional fleet rewrite. Record final supported configurations,
actual cache/build/cost observations and remaining limits. Update or create a local ADR
for durable interface/ownership decisions before marking the plan complete. Experimental
application optimizations remain separately accepted producer policy.


## Concrete Steps


Run repository commands from the `seihou-modules` root. Dependency discovery and the
current module preflight are read-only:

```bash
mori registry show shinzui/haskell-nix --full
mori registry show shinzui/haskell-nix-dev --full
mori registry show shinzui/seihou --full
seihou validate-module modules/haskell/nix-haskell-flake --lint
```

The accepted immutable published selections are:

```bash
runtime_toolchain_rev=21933607e80ec4660a28a125a6f4c0707e358caf
runtime_channel_rev=e5a7c2c50080b3364f0f0fd667240c560596d0ed
bash scripts/update-nix-haskell-flake-lock.sh \
  --rev "$runtime_toolchain_rev" --haskell-nix-rev "$runtime_channel_rev"
bash scripts/update-nix-haskell-flake-lock.sh --check
python3 scripts/test-haskell-runtime-bootstrap.py
seihou validate-blueprint blueprints/upgrade-haskell-runtime --lint
python3 scripts/test-haskell-runtime-adoption.py
```

In a disposable fixture with candidate blueprint/module discovery configured, substitute
the actual chosen target version from the target manifest:

```bash
seihou agent --debug run upgrade-haskell-runtime --no-baseline
seihou agent --debug migrate upgrade-haskell-runtime --from 0.31.0 --to 0.32.0
seihou update nix-haskell-flake --dry-run --json
```

The standalone checker and repository wrapper share the same implementation. Its inventory mode
captures canonical baseline data before migration; validation produces evidence outside
the consumer and does not mint Seihou attendance receipts:

```bash
python3 scripts/check-haskell-runtime-adoption.py \
  --project /absolute/disposable/consumer --inventory \
  --output /absolute/receipts/before.json
```

For an existing recorded module, capture its actual original version before the reviewed
update (including shared owners where required), then migrate that exact window:

```bash
seihou update nix-haskell-flake --json
seihou agent migrate upgrade-haskell-runtime \
  --from ORIGINAL_MODULE_VERSION --to 0.32.0
```

A legacy/unrecorded project instead uses the adoption entry point:

```bash
seihou agent run upgrade-haskell-runtime --no-baseline
```

Run the independent checker from this repository, then ordinary project commands from
the consumer. Adapt target names only to outputs that actually exist:

```bash
python3 scripts/check-haskell-runtime-adoption.py \
  --project /absolute/disposable/consumer \
  --before /absolute/receipts/before.json \
  --target blueprints/upgrade-haskell-runtime/files/target-versions.json \
  --output /absolute/receipts/validated-adoption.json --native
```

```bash
nix eval --raw .#devShells.aarch64-darwin.default.drvPath
nix develop -c ghc --numeric-version
nix build .#default --no-link --print-build-logs
nix build .#checks.aarch64-darwin.consumer-overlay --no-link
nix build .#checks.aarch64-darwin.cohort-parity --no-link
nix fmt -- --ci
```

Use the consumer's declared Cabal package/test and comparator commands. Missing checks
are not invented or silently counted as passing. Repeat actual supported Linux checks
on a matching worker when claiming that configuration. Finish release metadata locally:

```bash
seihou registry sync-versions
seihou registry validate
seihou extension run okf -- docs --dir . --out okf-docs --force
dhall type --file mori.dhall
git diff --check
```

Expected results are valid module/blueprint declarations, explicit passing fixture
summaries, a canonical lock with no drift, and a real adoption report with passing build,
identity and source-preservation checks. Revise these commands with verified target
versions and accepted CLI details during implementation.


## Validation and Acceptance


A legacy fixture retains its configured bare-shell behavior. Runtime-mode root and
multi-package fixtures build from the exact scope supplying their shell. Wrong compiler,
shared/runtime override, incomplete selection, undeclared owned package and unsupported
explicit HLS fail clearly. Both blueprint entry points resolve the intended source and
version window; legacy adoption invents no old version. Debug migration is read-only.

Migration tests exercise actual managed ownership and output behavior. Repeats preserve
customizations and lock bytes; interruption/failure leaves a recoverable project. A
nonzero provider failure produces no applied edge. Failed independent checks never yield
an accepted adoption report, regardless of attendance receipts. No engine redesign or
manifest fabrication is used to manufacture acceptance.

The real pilot preserves authored code, tests, resources, source/flag policy and relevant
custom inputs. Necessary new Nix paths are tracked in the isolated copy so flakes see them.
Compiler/dependency visibility, normal builds and applicable complete suites pass. Shell-only
edits preserve runtime/production identities, and shared outputs substitute without builds
in the declared verification environment. Each new support claim names its execution system
and limits. The second normal update retains all accepted behavior and Seihou ownership.

The release is coherent across artifact versions, exact pins/lock, blueprint target/edges,
registry, Mori descriptor and generated docs. Rollback restores only this migration's
changes. Record entry/build/edit and additional migration costs without treating consistency
as a demonstrated compilation speedup. Existing immutable generations and unaccepted
application experiments are never promoted as a side effect.


## Idempotence and Recovery


Before writing, inventory/back up affected files and Seihou metadata outside the consumer.
Preserve staged/unstaged and relevant untracked work and prefer isolated rehearsals.
Restore only this migration's paths, including a consistent manifest/baseline set. Do not
reset the index, blanket-clean a checkout, overwrite unrelated edits or delete service data.

Preview updates without force and preserve actionable conflicts. Exact versions, input pins
and target manifests make retries reproducible. An attendance receipt does not suppress the
independent acceptance checker, and `--mark-applied` is not a failed-validation workaround.
If origin, source version, shared ownership or runtime identity is ambiguous, stop before
writing misleading history. Successful repeated operations are no-ops apart from external
validation evidence.


## Interfaces and Dependencies


The upstream channel wrapper takes `runtimeSelection`, `applicationSelections`,
`ownPackages`, `pkgs`, `toolchainLib`, `applicationOverrides`, optional application cohort/
registry, nullable `withHls`, native/library extra inputs, compatible `inputsFrom` and
`shellHook`. `runtimeSelection` has exactly `name`, `generation`, `channel` and
`configuration`; configuration has `compiler`, `disableProfiling` and `disableHaddock`.
Its result exposes checked `applicationScope` and diagnostic `packageSetIdentity`.
The module options adapt this interface without another solver or selection lock.

Seihou supplies module updates, blueprint discovery, ordered agent migrations, debug
rendering and artifact-owned attendance receipts. `BlueprintMigration` has dotted numeric
`from`/`to` values and an edge prompt; gaps are allowed, but required transformations cannot
be skipped. A read-only version probe supplies the target, never inferred old history.
Automated fixtures use a controlled stub provider; the real pilot explicitly exercises a
bounded actual provider path. Creating this plan launches no agent or project migration.

This is a standalone local plan linked to the canonical MP-4 URI above. Source artifacts
without URI coverage use their canonical owning project plus a relative path and an explicit
pending-artifact statement. Experimental work under
`mori://shinzui/haskell-nix/plans/18-accelerate-application-code-compilation-in-nix-builds`
and `mori://shinzui/haskell-nix/plans/19-pre-generate-complete-locked-nix-haskell-dependency-recipes`
is not a prerequisite for shipping the accepted shell/runtime interfaces.
