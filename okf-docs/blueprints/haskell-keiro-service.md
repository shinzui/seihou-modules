---
type: SeihouBlueprint
title: haskell-keiro-service
description: 'Agent-driven scaffold for an event-sourced Haskell service on the keiro
  runtime (keiki/kiroku/shibuya/pgmq), shaped like danwa: a six-package <name>-<role>
  layout (core/api/migrations/workers/server/client) with read models in core, a custom
  prelude, an effectful app monad with Reader AppConfig, the keiro stack pinned via
  cabal.project, codd migrations, servant/warp HTTP, and a keiro-DSL-first domain
  workflow (author and check a .keiro spec, then keiro-dsl scaffold with collocated
  layout, before hand-filling the holes)'
resource: seihou://seihou-modules/blueprints/haskell-keiro-service
tags:
- haskell
- service
- keiro
- effectful
- event-sourcing
- bootstrap
version: 0.1.0
---

# haskell-keiro-service

Agent-driven scaffold for an event-sourced Haskell service on the keiro runtime (keiki/kiroku/shibuya/pgmq), shaped like danwa: a six-package <name>-<role> layout (core/api/migrations/workers/server/client) with read models in core, a custom prelude, an effectful app monad with Reader AppConfig, the keiro stack pinned via cabal.project, codd migrations, servant/warp HTTP, and a keiro-DSL-first domain workflow (author and check a .keiro spec, then keiro-dsl scaffold with collocated layout, before hand-filling the holes)

**Version:** 0.1.0

## Base modules

- [nix-haskell-flake](/modules/nix-haskell-flake.md)


## Agent prompt

# Scaffold an event-sourced Haskell service ({{project.name}}) on the keiro runtime

## Reference files

- `cabal.project` - Reference cabal.project: the GitHub source-repository-package pin cohort (keiki/kiroku/keiro/codd/typeid-hs/hasql-* /ephemeral-pg), the Hackage index-state, with-compiler ghc-9.12.4, the six-package list, and the constraints/allow-newer block. NEVER use file:// or corpus paths; mmzk-typeid comes from Hackage. Adapt the packages list; keep the pin cohort.
- `core.cabal` - Reference <name>-core.cabal: cabal-version 3.4, the two shared `common` stanzas (warnings + shared) with the DB-tier default-extensions, leading-comma build-depends on the keiro stack (keiki, keiki-codec-json, keiro, keiro-core, kiroku-store, mmzk-typeid, hasql, hasql-pool, hasql-transaction, contravariant-extras, effectful, generic-lens, lens, aeson, bytestring, text, time), and exposed-modules organized vertical-slice by concept: the prelude, the cross-cutting App.Config/Postgres.{Pool,Runner}, and per concept the keiro-scaffolded <Ns>.<Agg>.Generated.{Domain,Codec,EventStream,Projection,Harness} (a .Generated leaf), the hand-owned <Ns>.<Agg>.Holes, and <Ns>.<Agg>.ReadModel.
- `Prelude.hs` - Reference <Ns>.Prelude: a thin re-export over base using {-# LANGUAGE PackageImports #-} (ONLY here), re-exporting module Control.Lens. Notes the rule that Data.Generics.Labels is NOT re-exported (its orphan IsLabel collides with keiki's); each module that uses #field lenses imports it locally.
- `AppConfig.hs` - Reference effectful application-config module: the AppConfig record (hasql pool, kiroku store handle, stream categories) with every field strict (!), explicit deriving stock, and a note on the Eff es + Reader AppConfig + Error + IOE effect-row shape (peeled by Postgres.Runner).
- `Api.hs` - Reference servant skeleton: a NamedRoutes route record plus wire DTO types with deriving stock/anyclass JSON instances, illustrating the <name>-api package shape (depends only on <name>-core) and how closed-enum wire fields are carried as Text and validated in the handler.
- `Diagrams.hs` - Reference <Ns>.Diagrams: renders each aggregate's keiki transducer to a stateDiagram-v2 block (Keiki.Render.Mermaid.toMermaid) and splices it between HTML-comment markers in docs/diagrams/domain-lifecycles.md (Keiki.Render.Markdown.replaceMarkdownDiagramBlock). staleDiagrams/writeDiagrams back the <name>-diagrams executable (--check/--write) and the <name>-core-diagrams test suite that fails `cabal test` when a committed diagram has drifted from its transducer — the generated-artifact freshness gate.
- `domain.keiro` - Reference keiro DSL spec: a bounded context with a `layout collocated` clause, one aggregate, an id newtype with a prefix, a closed enum referenced via an explicit field:Enum annotation, a couple of commands/events, a projection, and command/query operations — the keiro-DSL-first shape to author and `keiro-dsl check` BEFORE writing any domain Haskell.
- `fourmolu.yaml` - Reference fourmolu.yaml (the fleet formatter config, also shipped by the nix-haskell-flake base module) so the generated project formats identically to the rest of the fleet.

