# Qualify OpenAPI client types and validate responses by status

## Status

Accepted on 2026-11-01, with published/installed ownership acceptance verified
against `mori://shinzui/seihou` 0.15.0.0. Plan 11 records the delivery evidence.

## Context

A typed HTTP client can expose incorrect data if a server returns a different
shape, or if its generator validates every status against a success schema.
Orval 8.46.0's built-in runtime validation failed a valid-404 regression. Raw
Orval output also needed qualified compatibility repairs for TypeScript exact
optional properties, recursive input annotations, Node imports and empty bodies.

## Decision

Use pinned Orval for named operation factories, model types and separate Zod
validators. Keep project checking, declaration/JavaScript emission and independent
consumers on the shared TypeScript 7+ compiler. Private generator TypeScript 6
API dependencies are allowed and cannot select the project compiler.

Each client instance owns its base URL, headers and injected fetch. A project-owned
fetch adapter resolves a unique generated method/path registry and validates the
actual declared status and JSON media/payload before generated operations decode it.
Custom fetch injection preserves this validation. Declared HTTP errors are ordinary
status-discriminated results; transport, JSON, shape, status and media failures
remain distinct. Empty responses expose undefined data; dates stay wire strings.

Preserve raw output for Orval's read-only outdated check. Deterministically derive
Node-compatible copies, response registry and bidirectional validator/model type
contracts. Freshness compares complete path sets and bytes, including obsolete files,
against isolated expectations without repairing output. Generation validates supported
schema semantics and type-checks staged contracts before replacing existing output.

Support a bounded, tested OpenAPI 3.0/3.1 JSON subset. Required semantic fixtures
include object openness, exact optional/nullability, unions and exclusivity,
disjoint open-object allOf, recursive/local references, directional properties,
and status-specific responses. Diagnose unimplemented constraints, remote refs,
range/default statuses, other media and ambiguous routes before output replacement.
Do not silently drop constraints or substitute global strictness for object openness.
Component keys follow OpenAPI's naming rules. Preserve their spelling and references
through directional projection; let Orval choose TypeScript identifiers and resolve
identifier collisions rather than imposing TypeScript casing on the source schema.

## Consequences

The package ships ESM, declarations and Zod runtime validation; it exposes no Bun
or generator types. Both Node and Bun consumers import it by package name. A
compiler version gate downloads nothing and excludes dependency executable paths.
Compatibility rewrites are version-specific maintenance obligations, enforced by
behavioral/type/consumer fixtures rather than snapshots alone.

Project configs, schema, source, recipes and maintained helpers are create-once
seeds. Generated trees, dist and Bun locks are explicit command products. Shared
Nix wiring stays managed under [ADR 3](3-separate-managed-scaffold-nix-wiring-from-user-extensions.md).
[Plan 11](../plans/11-add-a-bun-based-openapi-typescript-client-module.md) records the
qualification evidence, release prerequisites and friction triage.
