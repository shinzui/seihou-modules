---
type: SeihouBlueprint
title: haskell-keiro-service
description: 'Agent-driven scaffold for an event-sourced Haskell service on the released Keiro runtime: a six-package vertical-slice layout with generated and hand-owned rings, Hackage-pinned dependencies, pg-migrate components, validated event streams, Settei configuration, real OpenTelemetry wiring, health and request-logging contracts, and a Keiro-DSL-first workflow.'
resource: seihou://seihou-modules/blueprints/haskell-keiro-service
tags: [haskell, keiro, service, bootstrap]
version: 0.3.0
---

# haskell-keiro-service

Agent-driven scaffold for an event-sourced Haskell service on the released Keiro runtime: a six-package vertical-slice layout with generated and hand-owned rings, Hackage-pinned dependencies, pg-migrate components, validated event streams, Settei configuration, real OpenTelemetry wiring, health and request-logging contracts, and a Keiro-DSL-first workflow.

**Version:** 0.3.0

## Base modules

- [haskell-keiro-project](/modules/haskell-keiro-project.md)

## Usage

```bash
seihou agent run haskell-keiro-service
```

Applies the reusable project module, then follows its generated `docs/bootstrap-keiro.md`.
The brief discovers current standards through Mori, establishes domain requirements, verifies
published dependencies, and implements the complete service with runtime acceptance checks.
Reference sketches are historical and must be reconciled against the chosen released cohort.

## Reference files

- `cabal.project` — Historical cabal.project sketch for a six-package runtime cohort. Verify current releases and follow the generated bootstrap brief before choosing bounds, index-state, or adapter compatibility workarounds; never add local runtime paths.
- `core.cabal` — Reference <name>-core.cabal: the shared common stanzas, bounded released dependencies, and exposed modules organized by vertical slice, including generated, hand-owned, and read-model rings. Historical sketch only: replace bounds with the verified cohort and use the complete current generated Cabal fragment.
- `Prelude.hs` — Reference <Ns>.Prelude: a thin re-export over base using {-# LANGUAGE PackageImports #-} (ONLY here), re-exporting module Control.Lens. Notes the rule that Data.Generics.Labels is NOT re-exported (its orphan IsLabel collides with keiki's); each module that uses #field lenses imports it locally.
- `AppConfig.hs` — Reference runtime dependency module: the strict AppConfig record populated only after Settei resolves Settings, plus the Eff es + Reader AppConfig + Error + IOE effect-row shape. Adapt dependencies; do not merge source resolution into this module.
- `Api.hs` — Reference Servant skeleton: NamedRoutes, wire DTOs, and the fleet liveness/readiness route shape. Adapt domain routes and keep probe semantics separate from dependency health.
- `Diagrams.hs` — Reference <Ns>.Diagrams: renders each aggregate's keiki transducer to a stateDiagram-v2 block (Keiki.Render.Mermaid.toMermaid) and splices it between HTML-comment markers in docs/diagrams/domain-lifecycles.md (Keiki.Render.Markdown.replaceMarkdownDiagramBlock). staleDiagrams/writeDiagrams back the <name>-diagrams executable (--check/--write) and the <name>-core-diagrams test suite that fails `cabal test` when a committed diagram has drifted from its transducer — the generated-artifact freshness gate.
- `domain.keiro` — Reference keiro DSL spec: a historical bare-source example with a `layout collocated` clause, one aggregate, an id newtype with a prefix, a closed enum referenced via an explicit field:Enum annotation, a couple of commands/events, a projection, and command/query operations — adapt only after reading the current workspace and language standards; the generated workspace is authoritative.
- `fourmolu.yaml` — Reference fourmolu.yaml (the fleet formatter config, also shipped by the nix-haskell-flake base module) so the generated project formats identically to the rest of the fleet.
- `Migrations.hs` — Reference pg-migrate package wiring: embedded strict manifest, application MigrationComponent, ordered complete plan, CLI command dispatch, and test-support notes. Split the module and executable sketches into their real package paths.
- `manifest` — Exact two-entry strict pg-migrate manifest format for application SQL. Copy the format, replace entries with real ordered migration files, and keep it exhaustive.
- `Telemetry.hs` — Reference production OpenTelemetry resource bracket: tracer and meter providers, flush/shutdown, W3C propagation, and Keiro metrics construction. Adapt resource attributes and thread the result into server and worker run options.
- `Settings.hs` — Reference Settei service declaration, direct YAML file loader, and canonical file, mounted-secret, then environment precedence. Adapt keys and types; preserve explicit bindings, secret sensitivity, unknown-key rejection, and diagnostic modes.
- `standards-map.md` — Topic-to-doc and Mori DocRef map for the normative Keiro runtime, architecture, configuration, migration, messaging, and HTTP standards. Read these docs before deviating from the prompt.
