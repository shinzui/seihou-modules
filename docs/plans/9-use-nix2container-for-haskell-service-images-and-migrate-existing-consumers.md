---
id: 9
slug: use-nix2container-for-haskell-service-images-and-migrate-existing-consumers
title: "Use nix2container for Haskell service images and migrate existing consumers"
kind: exec-plan
created_at: 2026-10-27T20:02:19Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-10-27T20:02:19Z
  revisions:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-27T20:03:55Z
      mode: "implement"
      note: "Implement pinned service images and preserving consumer blueprint"
---

# Use nix2container for Haskell service images and migrate existing consumers

## Purpose / Big Picture

Service consumers can build Docker-compatible images with the pinned nix2container builder,
load them with `nix run .#dockerImage.copyToDockerDaemon`, and export archives explicitly.
A Seihou blueprint upgrades existing consumers while retaining their executable, image
configuration, root files, custom inputs and unmanaged project extensions.

## Progress

- [x] (2026-10-27) Shipped 0.37.0 with the v1.1.0 builder and Linux service example. The lock check proves a full update is byte-identical and full/minimal feature sets share the same lock.
- [x] (2026-10-27) Registered upgrade-haskell-nix2container 0.1.0 with a 0.36.0 → 0.37.0 edge, reusable reference and inventory/preservation/transport guidance; blueprint and registry validation pass.
- [x] (2026-10-27) Real Seihou update and repeat-update fixture passes, preserving custom inputs, source and package derivations. Both Linux architectures evaluate, supported Darwin outputs omit the image, and x86_64-linux native archive export/inspection passes on the configured builder.

## Surprises & Discoveries

Mori has no registered nix2container corpus. The fallback source checkout is the exact
upstream v1.1.0 tag, verified against GitHub's latest release endpoint and remote tags on
2026-10-27: e503eb81630a0c5d7ec244e08e0733650235d8f1. Its buildImage API accepts
copyToRoot and config; its output is an image description with copyTo helpers rather than
a Docker archive. Docker is installed locally but its daemon is not running. The configured x86_64-linux
builder successfully builds the actual image/copy helper and executes archive acceptance.

Native export needed an explicit `--tmpdir` because Skopeo defaults to absent `/var/tmp`
in the build sandbox (FRIC-6, resolved). Archive layer inventories require resolving
root-directory symlinks from buildEnv; checking only literal file entries misses valid
TLS roots. Explicit docker-archive destinations also need the original repository/tag
suffix; without it the exported manifest has no RepoTags. The acceptance check resolves
symlinks entirely within archive metadata and checks the canonical Docker repository tag.

## Decision Log

2026-10-27: Retain image definitions in unmanaged flake.module.nix. The base module always
locks nix2container and supplies a commented service example; libraries acquire no image
output. This follows the existing ownership boundary and avoids assuming an executable.
Pin the latest released v1.1.0 commit and follow the application's nixpkgs. Keep all existing
toolchain pins unchanged. Use a blueprint rather than an automatic text replacement for
custom image definitions, since dockerTools root commands and load/push semantics differ.

## Outcomes & Retrospective

Delivered the module, blueprint, reference module, migration edge, canonical lock maintenance,
catalog/generated documentation and focused integration script. The final native run is
recorded outside the repository at
`/private/var/folders/xf/z_902qyd0dg5m6n8pjv1vk300000gn/T/seihou-nix2container-97sw9obj/receipt.json`.
Its command logs show native archive acceptance exit 0 (5.02 seconds after dependency
preparation). The fixture uses pkgs.hello to exercise the builder independently of an
unrelated Haskell build; it is bounded translation evidence, not an arbitrary consumer
migration or a coding-agent run. Both Linux architectures evaluate; only x86_64-linux
has native build/export evidence. Docker daemon smoke and registry publication were not
performed. The daemon is not running, and publication is outside this task's scope.
FRIC-6 is resolved by explicit Skopeo temporary-directory selection. Durable ownership,
transport/tagging and sandbox lessons are in
[ADR 7](../adr/7-keep-service-images-unmanaged-and-use-nix2container-transports.md).
No consumers outside the disposable fixtures were modified.

## Context and Orientation

`modules/haskell/nix-haskell-flake/files/flake.nix.tpl` owns the input graph and imports;
`files/flake.module.nix.example.tpl` is the managed example of an unmanaged extension.
`files/flake.lock` seeds every feature combination. The baseline module published 0.36.0; this change prepares 0.37.0.
`seihou-registry.dhall`, `mori.dhall` and the root README enumerate artifacts.
`blueprints/upgrade-haskell-runtime/blueprint.dhall` demonstrates agent run and ordered
migration edges. A blueprint is instructions plus reference files executed by a coding
agent through Seihou; it does not automatically own the consumer's custom files.
[ADR 3](../adr/3-separate-managed-scaffold-nix-wiring-from-user-extensions.md) keeps user
extensions unmanaged while scaffold-specific modules own generated package wiring.
The new ADR 7 records image transport and tagging. Upstream dependency identity is
`mori://nlewo/nix2container`; artifact URI coverage is pending for README.md and default.nix.
The Seihou engine and schema were located via Mori at `mori://shinzui/seihou` and
`mori://shinzui/seihou-schema` before inspecting their local sources and CLI help.

## Plan of Work

First add the immutable nix2container input with nixpkgs follows and replace the commented
image example. Preserve the Linux-only guard, packages.default seam, TLS roots and runtime
tools; build a root tree with buildEnv, preserving /bin and /etc. Extend the lock maintenance
script with an explicit nix2container revision override that otherwise preserves its pin.
Regenerate using the existing Haskell revisions, bump the module to 0.37.0 and synchronize
catalogs. Acceptance is identical full/minimal locks and an immovable full update.

Then add blueprints/upgrade-haskell-nix2container with an inventory-first prompt, a
0.36.0 to 0.37.0 edge and a reusable reference module. Require genuine Seihou three-way
updates, preserve custom inputs and ownership, and translate root trees, permissions and
archive consumers explicitly. Run handles older recorded versions without inventing edges;
legacy unrecorded projects must establish ownership separately. Repeated runs detect an
already migrated image. No remote publishing or fleet migration is included.

Finally add a focused script using actual Seihou generation/update and Nix evaluation. It
must prove the checked-in example evaluates for both Linux architectures, exposes real
copy helpers, omits Darwin images and preserves unmanaged customizations across repeat
updates. Native Linux image build/export and runtime commands are documented and must be
reported as unverified if no Linux builder/daemon is available. Update documentation and
record the durable image transport/ownership decision in docs/adr.

## Concrete Steps

Run from the repository root:

```bash
bash scripts/update-nix-haskell-flake-lock.sh --rev 21933607e80ec4660a28a125a6f4c0707e358caf --haskell-nix-rev dedd4d81589e99d97137eb36f88423c70c7d69f5
bash scripts/update-nix-haskell-flake-lock.sh --check
seihou validate-module modules/haskell/nix-haskell-flake
seihou validate-blueprint blueprints/upgrade-haskell-nix2container --lint
seihou registry sync-versions
seihou registry validate
python3 scripts/test-haskell-nix2container.py
seihou extension run okf -- docs --dir . --out okf-docs --force
git diff --check
```

## Validation and Acceptance

The lock check must report that full update is a no-op and feature toggles reproduce the
canonical lock. Blueprint validation must resolve every reference and migration prompt.
The integration test renders current files through Seihou, upgrades a genuine 0.36.0 local
application, preserves the unmanaged image extension and custom input, and repeats the
update without drift. Nix evaluation resolves Linux image and helper derivations and excludes
Darwin images. A separate optional --native-linux mode builds/exports and inspects a real
image archive using the copy helper; this requires a matching Linux builder and is distinct
from local evaluation evidence. A daemon smoke requires Linux binaries and Docker.

## Idempotence and Recovery

The lock script writes only after its invariants pass; --check writes nothing. Test projects
and receipts live in temporary directories outside the repository. Consumer instructions
back up affected files and consistent Seihou metadata externally, preview three-way updates,
resolve conflicts without force and preserve unrelated work. Revert only migration-owned
changes on failure. Never hand-edit manifest hashes, origin metadata or baselines.

## Interfaces and Dependencies

nix2container v1.1.0 provides inputs.nix2container.packages.${system}.nix2container.buildImage.
Arguments include name, tag, config, copyToRoot, layers and perms. buildImage does not accept
extraCommands/fakeRootCommands. config preserves OCI command/environment/port/user/workdir
settings. The derivation has copyToDockerDaemon, copyToRegistry and copyTo executables.
Linux outputs use Linux packages; Darwin evaluation excludes image definitions lazily.
