# upgrade-haskell-runtime

Version 0.1.0 prepares nix-haskell-flake 0.32.0 and the composed CLI scaffold 0.3.1.
It preserves existing project sources, explicit retained selections, custom inputs, native
libraries/tools, HLS, hooks, services and Seihou ownership. It has no automatic base modules.
Its canonical identity is `mori://shinzui/seihou-modules/templates/upgrade-haskell-runtime`.

This is a locally prepared release. Publishing a reviewed commit and installing it are
required before remote discovery can select these versions. Do not claim the current
remote registry already contains them. Candidate tests use genuine project-local origins.
The installed Seihou 0.10.1.0 build `c3cbd9bd202e87d6fd7fc0ede1d997d2c2140e0b` is tested;
the version tag alone does not identify that build.

## Rehearse and inventory

Use an independent clone with existing staged/unstaged and relevant untracked work
preserved. Review hooks and initialize submodules. Back up affected files and the consistent
Seihou manifest/baselines outside the checkout. Keep existing co-owners and origins.
Before updating, save the actual recorded nix-haskell-flake version from the manifest.
An unrecorded legacy project has no source version.

For a local candidate, copy the blueprint directory into
`.seihou/modules/upgrade-haskell-runtime` and the candidate module directories into the
corresponding `.seihou/modules/` paths in the disposable checkout. This is project-local
discovery, not a remote install. An application with a recorded remote origin still updates
from that origin; copying a candidate does not override it. After publication, install
from the reviewed registry commit instead and retain its genuine remote origin.

Capture a baseline with the shipped standalone checker (the repository's script is a
wrapper around the same implementation):

```bash
python3 /absolute/seihou-modules/scripts/check-haskell-runtime-adoption.py \
  --project /absolute/disposable/consumer --inventory \
  --output /absolute/receipts/before.json
```

For an existing retained consumer, pass `--owned-package NAME` once per owned package.
The checker captures actual input, compiler, runtime, dependency and production identities;
authored source hashes; Cabal policy; and application/shared-owner state. Inventory is not
acceptance. It avoids reading service data and symlink targets.

## Adopt or migrate

Legacy adoption uses the run entry point:

```bash
seihou agent --debug run upgrade-haskell-runtime --no-baseline
seihou agent run upgrade-haskell-runtime --no-baseline
```

The prompt inventories and generates canonical files in isolation, backs up unmanaged
colliding files, then uses a real module run to establish baselines and merges custom
wiring. It never invents a prior version. Existing co-owned `.gitignore` remains live.
Authored source, `.envrc.local`, process overrides and unmanaged `flake.module.nix` survive.

For a recorded 0.30.0 or 0.31.0 origin, capture its version before the reviewed update:

```bash
seihou update nix-haskell-flake --dry-run --json --include-shared-owners
seihou update nix-haskell-flake --json --include-shared-owners
seihou agent --debug migrate upgrade-haskell-runtime --from 0.30.0 --to 0.32.0
seihou agent migrate upgrade-haskell-runtime --from 0.30.0 --to 0.32.0
```

Use the saved source version in `--from`. The real edges are 0.30.0 → 0.31.0 → 0.32.0;
a 0.31.0 project crosses only the last edge. The first is the released channel-pin
transition, not a retrospective runtime-interface claim. Upgrade the composed CLI module
if present. Review three-way conflicts without force; do not hand-write hashes, origins,
application IDs or baselines. A different origin/version needs a separately reviewed path.
Debug migration is read-only; debug run may record blueprint provenance without ownership.

Null runtime keeps bare behavior. Existing explicit qualified selections opt into
`haskellProject.runtime`; custom recipes declare `ownPackages` and `applicationOverlays`.
Shell and production use `applicationScope`. Preserve production/full SDK policy. Native
tools, headers, compatible inheritance and hooks use `extraDevPackages`, `extraBuildInputs`,
`inputsFrom` and `shellHook`. Do not inherit a second compiler or overwrite shared recipes.
The example is illustrative; the target manifest does not authorize changing a consumer's
runtime generation, complementary selections, source policy or compiler.

## Require independent acceptance

```bash
python3 /absolute/seihou-modules/scripts/check-haskell-runtime-adoption.py \
  --project /absolute/disposable/consumer \
  --before /absolute/receipts/before.json \
  --target /absolute/seihou-modules/blueprints/upgrade-haskell-runtime/files/target-versions.json \
  --output /absolute/receipts/accepted.json --native
```

Acceptance requires `accepted: true` and successful native ordinary Nix, scoped compiler,
Cabal build/tests, applicable overlay/parity/library-extension checks, formatting and HLS
version checks. The unchanged canonical `fourmolu.yaml` configuration may acquire module ownership during legacy adoption; its original bytes are still checked. It preserves authored source, ordered ignore patterns, co-owners, existing
application origins/variables, custom inputs, compiler and existing retained/production
identities. Migration paths intentionally permit wiring edits; review their semantic
preservation and run the consumer's full owned tests, HLS protocol smoke, native/header/
service assertions, source edit, cache proof and repeat update separately. Cabal installed
reuse is not source completeness: follow `mori://shinzui/haskell-nix` with
`docs/guides/develop-against-a-retained-runtime.md` (artifact URI pending) for the fresh-plan
owner comparison with the same pinned imports. Reports bind command results and target/before
hashes; they make no arbitrary compiler speed or hosted CI claim.

A successful provider exit or applied-edge receipt records attendance only. A failed
checker overwrites a previous accepted report with `accepted: false`. Fix only the migration's
changes and recheck on every retry, even when an attended edge is skipped. Restore only
affected paths and their consistent metadata from the external backup; preserve unrelated
work and service data. Never use `--mark-applied` to bypass validation.

Run a normal update and repeat the checker after acceptance. Maintain exact module pins and
canonical lock; custom inputs may add lock nodes. The qualification manifest currently
names only Apple Silicon, GHC 9.12.4, GitHub generation 2 with its exact complementary
selections. Other configurations need their own execution evidence. No fleet migration,
persistent-service start, system activation or remote publication is implied.

## Reproduce repository validation

```bash
bash scripts/update-nix-haskell-flake-lock.sh --check
python3 scripts/test-haskell-runtime-bootstrap.py
python3 scripts/test-haskell-runtime-adoption.py
seihou validate-blueprint blueprints/upgrade-haskell-runtime --lint
seihou registry validate
```

The adoption test launches the real CLI with a bounded deterministic provider, never a real
nested coding agent. It tests source preservation and genuine shared ownership, both
recorded windows, legacy adoption, read-only debug migration, repeat update, interrupted
provider/resume, nonzero exit without an applied edge, and failed independent acceptance
regardless of attendance.

Before offline acceptance in a fresh checkout, populate the exact pinned Cabal Git sources
and archives through an ordinary owned-package build with network access if necessary.
Record that preparation separately; do not change source pins, flags or imports to avoid it.
The checker builds/tests the explicitly declared owned package targets, falling back to
`all` for a bare project without declared ownership; it does not claim upstream dependency
suites as owned tests. Declared submodules must be initialized and clean; preserve and verify
any submodule work separately before using this inventory workflow.
