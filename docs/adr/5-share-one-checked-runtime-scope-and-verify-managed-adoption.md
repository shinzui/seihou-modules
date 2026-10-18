# Share one checked runtime scope and verify managed adoption

## Status

Accepted on 2026-10-18.

## Context

A bare toolchain shell and an independently composed application can expose different
package databases even with the same compiler version. Existing projects also carry
custom Nix inputs, native libraries, formatter policies, services and shared Seihou owners.
Replacing their files without those facts risks changing behavior or inventing ownership.

## Decision

The Haskell module defaults to its compatible bare-shell path. An explicit runtime
configuration supplies the exact retained selection and complementary application selections.
Declared application overlays build one checked scope for production packages and the primary
shell. Root and CLI scaffolds declare their recipes; custom compositions declare all owned
packages. Shared overrides, undeclared packages, native-input drift and a second compiler fail.
The secondary compiler remains bare. HLS follows actual capability unless explicitly requested.

Keep native tools, library/header inputs, compatible inheritance and project hooks distinct.
Use the toolchain's direct Nixpkgs import by default in runtime mode; flake-parts legacyPackages
has a different library version label despite identical native recipes. Explicit caller package
sets retain higher priority and must pass the original strict guard. Never disguise metadata
or weaken the upstream compiler/native identity checks.

The adoption blueprint has no automatic base modules. Inventory and back up before writing;
use real module generation/update to establish baselines, preserving authored sources,
co-owners, custom inputs and trust policy. Legacy projects have no fabricated source version.
Recorded 0.30.0 and 0.31.0 upgrades follow their actual ordered edges. Keep custom wiring
in unmanaged extensions and preserve independently accepted production/full SDK policy.
Unchanged canonical formatter configuration can acquire genuine module ownership during
legacy adoption while its original bytes remain checked.

Seihou receipts record provider attendance. An independent checker compares actual identities,
source hashes, ordered ignore patterns, application records and shared owners, then executes
native builds/tests and applicable gates. A new validation attempt revokes a prior accepted report before its first external command;
failures and interruptions leave it unaccepted. Cabal tests use explicit components from
the generated plan, requiring every selected suite to report execution and PASS. A package
without suites can otherwise short-circuit a mixed test command with exit zero. No-suite
projects report explicit non-applicability. Owner-supported threaded-runtime arguments are
scoped per suite, preserving non-threaded runners and all test cases.
Normalize only documented equivalent engine serialization, including absent versus empty
checkoutCommands; preserve real commands, origins and variables. Recovery restores only the
migration's affected paths and consistent metadata, leaving unrelated work and service data.

## Consequences

The interface provides consistent development and production dependencies. It does not
establish arbitrary compilation speedups or equal Cabal unit IDs. Fresh source-complete Cabal
comparison, full consumer suites, HLS protocol and cache retrieval require separate evidence.
Runtime qualification is limited to configurations actually executed. Local candidates and
independent stores do not imply remote release availability or hosted CI. Compare cache
retrieval against its published metadata: independent local HLS builds can have different
NAR content at identical derivation/output paths. The pilot retains that distinction;
local protocol behavior and downloaded published bytes are separate observations.

[Plan 6](../plans/6-upgrade-the-haskell-flake-module-and-migrate-existing-projects-to-retained-runtimes.md)
records release pins, executable fixtures, real Mori adoption, costs and qualifications.
The upstream interface is owned by
`mori://shinzui/haskell-nix/plans/20-build-project-development-shells-from-retained-runtime-package-sets`
and `mori://shinzui/haskell-nix-dev/plans/4-publish-compiler-capabilities-and-an-explicit-platform-support-matrix`.
