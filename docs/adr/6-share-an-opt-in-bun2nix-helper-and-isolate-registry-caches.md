# Share an opt-in bun2nix helper and isolate registry caches

## Status

Accepted on 2026-10-26.

## Context

The Bun development scaffold has no application entry point or production build recipe.
Native consumers need a pinned lock-to-Nix generator and its build hooks, while existing
projects own custom flake inputs, manifests, locks and unmanaged application extensions.
Released bun2nix 2.1.2 from `mori://nix-community/bun2nix` rejects Bun 1.4.2 v2 locks even though the qualified registry and
workspace package tuples retain the supported representation. Generated workspace records
also copy local sources into a dependency cache unless the caller excludes them lazily.

## Decision

`nix-bun-flake` owns the pinned bun2nix input, compatibility wrapper and optional managed
flake-parts module. `nix.bun2nix` defaults to false. Inputs stay declared across toggles to
share one canonical lock; only enabled projects import the module, expose `packages.bun2nix`
and receive that exact helper in the shell. A declared input is not an implicit build.

Preserve [ADR-3's extension boundary](3-separate-managed-scaffold-nix-wiring-from-user-extensions.md).
Projects own `flake.module.nix`, `bun.lock`, explicitly generated `bun-deps.nix`, source
selection, application outputs and deployment. The base module neither infers a default
application nor installs dependencies or rewrites project locks. Distinct managed helper
paths avoid claiming an existing custom `nix/bun2nix.nix`.

Keep the compatibility patch release-qualified, append to existing patch phases, and use
`--replace-fail`. Accept only qualified formats; never downgrade a real lock or bypass the
version gate generally. Remove the override only after a verified upstream release passes
the required generator and frozen sandbox fixtures without it. Upstream refresh must stop
for an unqualified release. Immutable pin verification remains separate from upstream
refresh and lock-only regeneration.

For workspaces, derive local package names from manifests and remove those attributes
lazily from the generated expression before calling `fetchBunDeps`. Keep explicit fetcher
arguments so `callPackage` supplies all needed fetchers. Pass current workspace sources
only to the application derivation; frozen installation creates current links. Use named,
filtered source inputs that exclude local dependency installations. A source edit rebuilds
the app while preserving the registry cache; a locked registry dependency change followed
by regeneration changes that cache.

Configure the upstream hook deliberately: explicit frozen flags preserve isolated linking
and Darwin's symlink backend; explicit build/install phases describe static outputs;
lifecycle scripts and package-script checks are chosen by the project. Evaluation across
systems is distinct from native sandbox acceptance on each system. Real Seihou updates
and removal must prove ownership preservation and retained edited-orphan behavior.

## Consequences

Consumers share a tested helper without surrendering their application architecture.
Disabling removes live feature wiring, preserving authored locks, expressions and builds.
The existing full-module removal contract for generated files remains unchanged.

The cache boundary avoids source-driven registry-cache churn; it does not promise an
installed-dependency-tree cache or a particular build speed. Explicit revision metadata
can still deliberately invalidate application builds. A narrow version patch does not
establish support for all dependency protocols or future Bun lock formats.

[Plan 7](../plans/7-add-optional-bun2nix-support-to-the-bun-nix-module.md) records release
pins, platform evidence and environment qualifications. The executable examples and
regressions live in `scripts/fixtures/nix-bun-flake/` and `scripts/test-nix-bun-flake.py`.
