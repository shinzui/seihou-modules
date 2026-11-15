# Generate standard typed clients with Orval

## Status

Accepted, amended 2026-11-15. Supersedes the earlier custom validation adapter decision.

## Context

The original scaffold compensated for Orval 8.46.0 runtime-validation defects with a schema
projection, a validating fetch transport, a response registry, generated-code rewrites and
compile-time validator/model contracts. The adapter imposed a second supported OpenAPI subset.
A real Keiro service failed that subset on timestamp/cursor formats, JSON media types, integer
path parameters and defaults, although native Orval could generate its client.

The consumer explicitly chose standard typed output without automatic runtime response validation
while implementing mori://tan/tan-seihou-modules/plans/6-generate-and-publish-typescript-clients-for-tan-keiro-services-with-a-recipe-and-blueprint.

## Decision

Generate standard fetch operations and models with Orval 8.46.0 directly into one TypeScript file.
Keep only a small project-owned `make` facade supplying base URL, default headers and injected fetch.
Use Redocly for source-document checks, Orval `--outdated` for freshness, and the shared TypeScript 7+
compiler for typechecking and ESM/declaration emission. Do not rewrite schemas or generator output.

Remove the custom supported-subset validator, Zod runtime dependency, validating transport,
response registry, validator/model contracts and raw/derived output duplication. HTTP status typing
and runtime decoding follow Orval's native behavior. TypeScript types do not validate server data.
A genuine generator defect belongs upstream rather than in an expanding compatibility wrapper.

## Consequences

The native proof generates and compiles the unchanged schema from mori://tan/chapter-service-v2,
including all eight operations. Node and Bun package consumers test status narrowing and transport
configuration. Existing project-owned seeds do not migrate on update; users must review the 0.3.0
seeds, remove retired validation files and regenerate. Runtime-validation-specific errors are removed.
The former validator fidelity guarantees are intentionally retired, not claimed for native output.
Shared Nix wiring and create-once ownership remain governed by ADR 3.
