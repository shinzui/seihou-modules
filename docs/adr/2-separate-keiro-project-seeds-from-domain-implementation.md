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

Fresh workspaces use project.name for manifest paths, member directories and service identity.
An optional keiro.context override changes the logical DSL context only. Existing authored
workspaces require a reviewed migration of paths, references and ownership; reapplication
does not automatically rename or delete them.

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

The scaffold owns a managed Nix tools module through the existing nix.package-module seam,
leaving flake.module.nix unmanaged and the base canonical lock/compiler unchanged. Hurl
Workbench and Hinagata execute immutable upstream flake packages; Workbench tool/schema pins
move together. Testing CLIs are development tools, separate from bounded application Cabal
dependencies. The test-only SQL marker is never a production migration or an automatic
development database load. Direct loads require an explicit existing target; leased test
consumers stop before their owned clone is released. Domain implementation supplies real
migration/verification hooks and maps leased PG fields into service configuration.

## Consequences

Both direct module users and blueprint users receive the same structure and implementation
instructions. No second copy of shared Nix templates is needed. Initial library build success
proves the seed, not runtime acceptance. Seed files become hand-owned during implementation;
Seihou conflict protection must be respected on reapplication. Nix can be updated independently,
and project-specific Nix builds belong in the unmanaged customization file.

Health tests and generated OpenAPI documentation share the typed API authority. HTTP smoke
tests use `/health/live` and `/health/ready`, and schema generation acquires no database or
server resources. [Plan 8](../plans/8-complete-the-keiro-project-bootstrap-with-api-testing-and-test-data.md)
records the scaffold extension and its real PostgreSQL-to-HTTP acceptance criteria. The
extension was decided on 2026-10-26. Released openapi-hs 5.0 generic record derivation omits
Maybe nullability; the exporter narrowly corrects the derived probe timestamp and fixed
required key until an upstream release fixes it. Probe wire types and handlers remain
library-owned. Bootstrap test success proves shared plumbing, not an implemented Keiro domain.

## Seed lifecycle implementation (2026-10-27)

The candidate `haskell-keiro-project` 0.3.0 explicitly declares 28 project-owned
starter steps: workspace/DSL, recipes/docs, Cabal/source/test files, initial
Hurl/Hinagata fixtures and optional Mori inventory. Licenses, `.gitignore`,
`nix/keiro-dev-tools.nix` and `scripts/keiro-test-env` remain managed policy/tools.
CLI 0.4.0 similarly declares 12 starters and library 0.3.0 declares seven.
All use the published schema pin supporting lifecycle and preserve managed
Nix integration. None declares shell commands, removals or migrations; the Nix
dependency's historical shell migration only removes an `.envrc` ignore line.

The lifecycle contract is implemented by
`mori://shinzui/seihou/masterplans/12-seed-files-module-outputs-created-once-and-owned-by-the-project`.
Supporting runtime release 0.11.0.0 and installed-binary acceptance must precede
producer publication: older clients ignoring lifecycle are unsafe. One ordinary
update previews release of old managed starter paths without reading/restoring
project bytes. The manifest records settlement; edits and deletion are retained,
including reruns with force. Changing the Mori namespace input does not rewrite
an existing descriptor. Authors maintain that project-owned inventory directly.
Last-claim retirement preserves disk and permits later absent reintroduction.
Shell commands are unsandboxed and must not mutate seeds.
