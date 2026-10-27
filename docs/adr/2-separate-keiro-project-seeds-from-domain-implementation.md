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

The seed does not pretend to implement an assembled application runtime, workers, migrations, or business behavior.
The implementation phase establishes domain requirements and verifies a coherent published
runtime cohort before generating domain Haskell. Migrations remain independent of sibling
libraries. Generated conformance is an auxiliary test package, outside the six application
packages. One workspace manifest explicitly owns module namespace and runtime package.

The scaffold's shared HTTP plumbing uses `mori://shinzui/servant-health/packages/servant-health`
for the probe contract and server handlers, with injected liveness/readiness checks. The API
package owns the typed route contract and a database-free OpenAPI generator using
`mori://shinzui/openapi-hs/packages/openapi-hs` and
`mori://shinzui/servant-openapi-hs/packages/servant-openapi-hs`; the server package owns
application assembly. This reusable wiring does not establish production dependency or drain
policy. The implementation blueprint supplies those policies and extends the same API/schema
with business routes. Probe conformance and schema generation must work in a fresh seed.

The seed optionally generates a local `mori.dhall` when the user selects that prompt.
It describes the actual six packages and their dependencies, and declares the generated
OpenAPI artifact owned by the API package. The Mori organization/user namespace is separate
from the Haskell module namespace. This is initial descriptor authoring, with existing-file
protection; it does not register the project or make OpenAPI generation conditional. The
implementation blueprint maintains an opted-in inventory as application code is added.

## Consequences

Both direct module users and blueprint users receive the same structure and implementation
instructions. No second copy of shared Nix templates is needed. Initial library build success
proves the seed, not runtime acceptance. Seed files become hand-owned during implementation;
Seihou conflict protection must be respected on reapplication. Nix can be updated independently,
and project-specific Nix builds belong in the unmanaged customization file.

Health tests and generated OpenAPI documentation share the typed API authority. HTTP smoke
tests use `/health/live` and `/health/ready`, and schema generation acquires no database or
server resources. [Plan 8](../plans/8-complete-the-keiro-project-bootstrap-with-api-testing-and-test-data.md)
records the planned scaffold extension and its acceptance criteria. This extension was decided
on 2026-10-26; its implementation remains tracked in that plan.
