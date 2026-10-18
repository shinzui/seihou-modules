---
type: SeihouBlueprint
title: upgrade-haskell-runtime
description: Preserved Haskell runtime adoption and ordered upgrades with independent
  native acceptance
resource: seihou://seihou-modules/blueprints/upgrade-haskell-runtime
tags:
- haskell
- nix
- runtime
- migration
status: stable
generated:
  by: seihou-okf-extension/0.10.1.0
version: 0.1.0
---

# upgrade-haskell-runtime

Preserved Haskell runtime adoption and ordered upgrades with independent native acceptance

**Version:** 0.1.0

## Base modules

This blueprint declares no base modules.

## Agent prompt

Adopt the tested Haskell module while preserving the project. Read target-versions.json and this blueprint's standalone checker first. Its supported runtime configuration is a qualification boundary, not a new selection authority. Never commit, publish, activate a system, migrate an existing database, or start persistent services.

```text
Adopt the tested Haskell module while preserving the project. Read target-versions.json and this blueprint's standalone checker first. Its supported runtime configuration is a qualification boundary, not a new selection authority. Never commit, publish, activate a system, migrate an existing database, or start persistent services.

Before writing, rehearse in an independent Git clone with staged, unstaged and relevant untracked work preserved; initialize declared submodules at their exact revisions. Review existing hooks. Inventory custom inputs, nixConfig trust/cache policy, exact compiler/runtime/complementary selections, owned packages, Cabal imports and flags, production/SDK recipes, native tools/headers, HLS, checks, hooks, services, .envrc.local, process-compose overrides and Seihou applications/owners/origins. Save affected files and the entire consistent Seihou manifest/baseline set outside the checkout. Record source version BEFORE update. Capture a canonical checker inventory outside the checkout, passing --owned-package for every existing retained application recipe. Keep command logs and costs outside the source too.

Resolve the candidate module/blueprint source explicitly and inspect its real version and origin. Generate canonical target files in a separate directory using the saved feature variables. Keep all module inputs locked even for disabled features; retain custom inputs and cache trust policy. Preview recorded upgrades with `seihou update nix-haskell-flake --dry-run --json` and necessary --include-shared-owners. Apply reviewed updates with Seihou's three-way merge, never --force or fabricated IDs, hashes, origins, baselines or --mark-applied. Keep co-owning applications. Resolve only the concrete migration edits; preserve custom behavior in unmanaged flake.module.nix, .envrc.local and process-compose.override.yaml. Existing co-owned .gitignore stays live with its ordered authored patterns and owners preserved.

For genuinely unrecorded legacy Haskell files, use `seihou agent run upgrade-haskell-runtime --no-baseline`. Do not label them 0.30.0 or 0.31.0. Back up only unmanaged colliding generated paths outside the checkout, let real `seihou run nix-haskell-flake` establish canonical ownership, then merge the inventoried custom wiring into unmanaged extensions and justified custom input edits. Leave unrelated recorded applications untouched. Keep flake.module.nix unmanaged. For an already accepted project, compare actual state and rerun verification; avoid duplicate application declarations or hooks.

Retain null runtime for an unconfigured bare project. Runtime adoption is explicit: preserve the exact retained name/generation/channel/compiler/profiling/Haddock configuration and every complementary selection. If it is not qualified, stop with the concrete mismatch, rather than invent a generation, change dependencies, or silently select a new compiler. Use haskellProject.runtime plus ownPackages and applicationOverlays. Shell and production outputs must use the same checked applicationScope. Preserve full SDK output, source resources and accepted executable policy. Never inherit another compiler shell or override channel recipes. Keep native tools in extraDevPackages, native libraries/headers in extraBuildInputs, compatible inputsFrom, nullable withHls and the original hook once. Secondary unretained compilers stay bare.

Align retained Cabal import URLs with the exact channel pin only after verifying the same retained artifacts/source policy. Preserve all source/flag/configuration imports. Dependency or production identity drift is a separate upgrade requiring an explicit decision, not an adoption workaround. Pre-existing Cabal rows prove installed reuse only; run the channel owner's fresh-plan comparison separately for source completeness.

Require `python3 /absolute/blueprint/files/check-haskell-runtime-adoption.py --project /absolute/checkout --before /absolute/receipts/before.json --target /absolute/blueprint/files/target-versions.json --output /absolute/receipts/accepted.json --native`. The standalone checker must execute successfully with accepted=true after native builds/tests and applicable checks. Run full owned Nix test suites, supported HLS protocol smoke, source edit/rebuild, service/header/hook assertions, fresh-plan parity and normal repeat update as applicable; record limitations and separate migration costs. Preserve configured cache authentication; prove shared-output reuse with builders disabled without exposing secrets, and distinguish local-store from hosted-cache evidence.

A provider success or Seihou migration receipt records attendance only. Never announce adoption success without a new independent accepted report. On nonzero provider exit or interrupted merge, preserve actionable state and restore only this migration's affected paths and consistent metadata from its backup. A retry must verify actual state even when Seihou skips an attended edge. Do not reset unrelated work or remove service data. Report exact source/target versions, immutable input/runtime identities, preserved source/ownership evidence, actual command results, repeat-update behavior, costs and recovery instructions.
```

## Reference files

- `target-versions.json` - Qualified immutable release inputs and exact recorded source versions
- `flake.module.nix` - Unmanaged opt-in interface example; preserve the consumer's actual explicit selections
- `check-haskell-runtime-adoption.py` - Standalone independent before/after and native acceptance checker

## Migrations

### 0.30.0 → 0.31.0

This prerequisite crosses the actual published nix-haskell-flake 0.30.0 (3a6eebdd0c6a5b594a665dbb5e08f47f69053449) to 0.31.0 (cc1b70c70eddeec5155c1a5a723b63a4cfaba6d6). The released difference updates the generated cohort channel pin; it does not introduce the runtime module interface. Use the main adoption prompt's before-inventory, preservation and genuine ownership procedure. The saved original version must be 0.30.0; do not infer it from the already updated target. Review the pinned channel change and preserve explicit retained/source/flag policy. If a dependency change is required, report it separately. Retain the ordered edge before 0.31.0-to-0.32.0; do not treat this attendance receipt as final target acceptance. Never fabricate intermediate files, baseline hashes or a source version for legacy projects.

### 0.31.0 → 0.32.0

This edge crosses the published nix-haskell-flake 0.31.0 origin cc1b70c70eddeec5155c1a5a723b63a4cfaba6d6 to the target-versions.json candidate 0.32.0. Follow the main adoption prompt in full, including preserved custom inputs/cache policy/source and genuine Seihou three-way ownership. New runtime options are opt-in: keep bare projects bare, and adapt an existing explicitly qualified retained selection to haskellProject.runtime with declared ownPackages/applicationOverlays. Production and primary shell consume the checked applicationScope. Preserve SDK/production policy, native headers/tools, HLS, hooks and unmanaged extension. Update composed haskell-cli-app to 0.3.1 if present. Run the independent checker with --native against the inventory captured before the update, then all applicable consumer validation and normal repeat update. Receipt presence cannot substitute for accepted=true. If retry skips this attended edge, independently rerun the checker and repair only inventoried migration paths.
