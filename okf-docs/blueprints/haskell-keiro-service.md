---
type: SeihouBlueprint
title: haskell-keiro-service
description: 'Agent-driven scaffold for an event-sourced Haskell service on the released
  Keiro runtime: a six-package vertical-slice layout with generated and hand-owned
  rings, Hackage-pinned dependencies, pg-migrate components, validated event streams,
  Settei configuration, real OpenTelemetry wiring, health and request-logging contracts,
  and a Keiro-DSL-first workflow.'
resource: seihou://seihou-modules/blueprints/haskell-keiro-service
tags:
- haskell
- service
- keiro
- effectful
- event-sourcing
- bootstrap
version: 0.2.2
---

# haskell-keiro-service

Agent-driven scaffold for an event-sourced Haskell service on the released Keiro runtime: a six-package vertical-slice layout with generated and hand-owned rings, Hackage-pinned dependencies, pg-migrate components, validated event streams, Settei configuration, real OpenTelemetry wiring, health and request-logging contracts, and a Keiro-DSL-first workflow.

**Version:** 0.2.2

## Base modules

- [nix-haskell-flake](/modules/nix-haskell-flake.md)


## Agent prompt

# Scaffold an event-sourced Haskell service ({{project.name}}) on the Keiro runtime

## Reference files

- `cabal.project` - Reference cabal.project: Hackage-only runtime cohort at the verified index-state, GHC 9.12.4, the direct settei-yaml adapter (the released settei-formats umbrella is not solvable with this bytestring cohort), and the six-package list. Adapt package names; keep the index-state and never add local paths or runtime source-repository-package pins.
- `core.cabal` - Reference <name>-core.cabal: the shared common stanzas, bounded released dependencies, and exposed modules organized by vertical slice, including generated, hand-owned, and read-model rings. Adapt names while preserving package bounds and layout.
- `Prelude.hs` - Reference <Ns>.Prelude: a thin re-export over base using {-# LANGUAGE PackageImports #-} (ONLY here), re-exporting module Control.Lens. Notes the rule that Data.Generics.Labels is NOT re-exported (its orphan IsLabel collides with keiki's); each module that uses #field lenses imports it locally.
- `AppConfig.hs` - Reference runtime dependency module: the strict AppConfig record populated only after Settei resolves Settings, plus the Eff es + Reader AppConfig + Error + IOE effect-row shape. Adapt dependencies; do not merge source resolution into this module.
- `Api.hs` - Reference Servant skeleton: NamedRoutes, wire DTOs, and the fleet liveness/readiness route shape. Adapt domain routes and keep probe semantics separate from dependency health.
- `Diagrams.hs` - Reference <Ns>.Diagrams: renders each aggregate's keiki transducer to a stateDiagram-v2 block (Keiki.Render.Mermaid.toMermaid) and splices it between HTML-comment markers in docs/diagrams/domain-lifecycles.md (Keiki.Render.Markdown.replaceMarkdownDiagramBlock). staleDiagrams/writeDiagrams back the <name>-diagrams executable (--check/--write) and the <name>-core-diagrams test suite that fails `cabal test` when a committed diagram has drifted from its transducer — the generated-artifact freshness gate.
- `domain.keiro` - Reference keiro DSL spec: a bounded context with a `layout collocated` clause, one aggregate, an id newtype with a prefix, a closed enum referenced via an explicit field:Enum annotation, a couple of commands/events, a projection, and command/query operations — the keiro-DSL-first shape to author and `keiro-dsl check` BEFORE writing any domain Haskell.
- `fourmolu.yaml` - Reference fourmolu.yaml (the fleet formatter config, also shipped by the nix-haskell-flake base module) so the generated project formats identically to the rest of the fleet.
- `Migrations.hs` - Reference pg-migrate package wiring: embedded strict manifest, application MigrationComponent, ordered complete plan, CLI command dispatch, and test-support notes. Split the module and executable sketches into their real package paths.
- `manifest` - Exact two-entry strict pg-migrate manifest format for application SQL. Copy the format, replace entries with real ordered migration files, and keep it exhaustive.
- `Telemetry.hs` - Reference production OpenTelemetry resource bracket: tracer and meter providers, flush/shutdown, W3C propagation, and Keiro metrics construction. Adapt resource attributes and thread the result into server and worker run options.
- `Settings.hs` - Reference Settei service declaration, direct YAML file loader, and canonical file, mounted-secret, then environment precedence. Adapt keys and types; preserve explicit bindings, secret sensitivity, unknown-key rejection, and diagnostic modes.
- `standards-map.md` - Topic-to-doc and Mori DocRef map for the normative Keiro runtime, architecture, configuration, migration, messaging, and HTTP standards. Read these docs before deviating from the prompt.

