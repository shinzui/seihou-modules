# Separate Keiro project seeds from domain implementation

## Status

Accepted on 2026-09-07.

## Context

Keiro services repeat a six-package layout and Nix environment while their aggregates,
wire contracts, migrations, and integrations differ. The existing haskell-keiro-service
blueprint mixed reusable structure with reference snippets that can lag runtime releases.
The standards at `mori://shinzui/keiro-runtime-patterns/docs/architecture-service-packages`
and `mori://shinzui/keiro-runtime-patterns/docs/keiro-service-workspaces` define the shared
package boundaries and workspace authority.

## Decision

The `haskell-keiro-project` module seeds minimal compilable libraries, workspace structure,
development recipes, and a project-specific implementation brief. It depends on
`nix-haskell-flake`, with PostgreSQL/process-compose on and the root package build off.
The existing `haskell-keiro-service` blueprint consumes this module and follows the brief.
Its historical sketches do not override current standards or release verification.

The seed does not pretend to implement server, workers, migrations, or business behavior.
The implementation phase establishes domain requirements and verifies a coherent published
runtime cohort before generating domain Haskell. Migrations remain independent of sibling
libraries. Generated conformance is an auxiliary test package, outside the six application
packages. One workspace manifest explicitly owns module namespace and runtime package.

## Consequences

Both direct module users and blueprint users receive the same structure and implementation
instructions. No second copy of shared Nix templates is needed. Initial library build success
proves the seed, not runtime acceptance. Seed files become hand-owned during implementation;
Seihou conflict protection must be respected on reapplication. Nix can be updated independently,
and project-specific Nix builds belong in the unmanaged customization file.
