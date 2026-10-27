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
status: stable
generated:
  by: seihou-okf-extension/0.10.1.0
version: 0.4.0
---

# haskell-keiro-service

Agent-driven scaffold for an event-sourced Haskell service on the released Keiro runtime: a six-package vertical-slice layout with generated and hand-owned rings, Hackage-pinned dependencies, pg-migrate components, validated event streams, Settei configuration, real OpenTelemetry wiring, health and request-logging contracts, and a Keiro-DSL-first workflow.

**Version:** 0.4.0

## Base modules

- [haskell-keiro-project](/modules/haskell-keiro-project.md)

## Agent prompt

# Implement {{project.name}} as a Keiro service

```text
# Implement {{project.name}} as a Keiro service

The `haskell-keiro-project` base module has supplied six initial Cabal libraries, the
`nix-haskell-flake` environment, a workspace manifest, and `docs/bootstrap-keiro.md`.
Read that generated brief in full and carry out its workflow. It is the implementation
contract for Haskell namespace {{project.namespace}} and project-named workspace {{project.name}}.
The base also supplies injected servant-health probes, typed OpenAPI generation, Hurl Workbench
and Hinagata assets, and an optional local Mori inventory. Extend the same API/schema, preserve
test setup, and maintain an opted-in dependency inventory while implementing the domain.

Establish real domain requirements before adding aggregates. Implement the complete service,
validate it, and report evidence as required by the brief. Preserve existing implementation
when this runs on a partially bootstrapped project; inspect Git and Seihou diffs before edits.

The blueprint's `files/` contains historical reference sketches. They are not authoritative
release pins, current API signatures, or a domain specification. Read `files/standards-map.md`
and resolve the current normative documents through Mori. In particular, do not copy the old
single-file DSL workflow, index-state, package bounds, or Settei compatibility exclusions.
Reconcile every sketch with the verified released APIs and generated compilation contract.

Do not commit or push. Hand off the package tree, release evidence, build and test results,
configuration and runtime checks, and any remaining failures.
```

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project base name; creates <name>-core, -api, -migrations, -workers, -server, and -client. Shared with the Nix environment.
- `project.description` — text, required. One-line synopsis used in Cabal files, the implementation brief, and the Nix flake description.
- `project.namespace` — text, required, matching `[A-Z][A-Za-z0-9]*`. Top-level Haskell module namespace (single segment, e.g. Rei). Used both as the source-tree directory and as the module prefix in generated .hs files.
- `project.author` — text, required, default `Nadeem Bitar`. Author name written into LICENSE and .cabal files
- `project.maintainer` — text, required, default `nadeem@gmail.com`. Maintainer email written into .cabal files
- `project.copyright-year` — text, required, default `2026`, matching `[0-9]{4}`. Copyright year written into LICENSE
- `keiro.context` — text, optional, matching `[a-z][a-z0-9-]*`. Optional logical DSL context override; paths and workspace identity always use project.name.
- `mori.prompt` — boolean, optional, default `false`. Internal prompt coordination: the blueprint asks once and suppresses the baseline module question, including after an empty skip.
- `mori.generate` — boolean, optional. Generate an initial local Mori inventory (no registration). Empty input skips.
- `mori.namespace` — text, optional, matching `[a-z][a-z0-9-]*`. Mori organization/user namespace; required when mori.generate=true. Separate from Haskell project.namespace.
- `haskell.index-state` — text, required, default `2026-10-26T00:00:00Z`, matching `[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z`. Hackage index snapshot for the initial libraries; reverify the runtime cohort before adding domain dependencies.

## Prompts

- `project.name` — What is your project name? (lowercase, hyphenated; cabal packages will be <name>-core, -api, -migrations, -workers, -server, and -client)
- `project.description` — One-line project synopsis (used as cabal `synopsis:` and the flake description):
- `project.namespace` — Top-level Haskell module namespace? (single PascalCase segment, e.g. Rei)
- `project.author` — Author name?
- `project.maintainer` — Maintainer email?
- `project.copyright-year` — Copyright year?
- `mori.generate` — Generate an initial mori.dhall with packages, dependencies, and the OpenAPI schema reference? (true/false; empty skips)
- `mori.namespace` — Mori organization/user namespace? (separate from the PascalCase Haskell namespace) — when `Eq mori.generate true`
- `haskell.index-state` — Hackage index-state for this bootstrap? (UTC timestamp)

## Reference files

- `cabal.project` - Historical cabal.project sketch for a six-package runtime cohort. Verify current releases and follow the generated bootstrap brief before choosing bounds, index-state, or adapter compatibility workarounds; never add local runtime paths.
- `core.cabal` - Reference <name>-core.cabal: the shared common stanzas, bounded released dependencies, and exposed modules organized by vertical slice, including generated, hand-owned, and read-model rings. Historical sketch only: replace bounds with the verified cohort and use the complete current generated Cabal fragment.
- `Prelude.hs` - Reference <Ns>.Prelude: a thin re-export over base using {-# LANGUAGE PackageImports #-} (ONLY here), re-exporting module Control.Lens. Notes the rule that Data.Generics.Labels is NOT re-exported (its orphan IsLabel collides with keiki's); each module that uses #field lenses imports it locally.
- `AppConfig.hs` - Reference runtime dependency module: the strict AppConfig record populated only after Settei resolves Settings, plus the Eff es + Reader AppConfig + Error + IOE effect-row shape. Adapt dependencies; do not merge source resolution into this module.
- `Api.hs` - Historical NamedRoutes/DTO sketch importing servant-health. Extend the generated ServiceApi and derived OpenAPI, retain the injected probe builder, and add domain schemas; never duplicate probe types/handlers.
- `Diagrams.hs` - Reference <Ns>.Diagrams: renders each aggregate's keiki transducer to a stateDiagram-v2 block (Keiki.Render.Mermaid.toMermaid) and splices it between HTML-comment markers in docs/diagrams/domain-lifecycles.md (Keiki.Render.Markdown.replaceMarkdownDiagramBlock). staleDiagrams/writeDiagrams back the <name>-diagrams executable (--check/--write) and the <name>-core-diagrams test suite that fails `cabal test` when a committed diagram has drifted from its transducer — the generated-artifact freshness gate.
- `domain.keiro` - Reference keiro DSL spec: a historical bare-source example with a `layout collocated` clause, one aggregate, an id newtype with a prefix, a closed enum referenced via an explicit field:Enum annotation, a couple of commands/events, a projection, and command/query operations — adapt only after reading the current workspace and language standards; the generated workspace is authoritative.
- `fourmolu.yaml` - Reference fourmolu.yaml (the fleet formatter config, also shipped by the nix-haskell-flake base module) so the generated project formats identically to the rest of the fleet.
- `Migrations.hs` - Reference pg-migrate package wiring: embedded strict manifest, application MigrationComponent, ordered complete plan, CLI command dispatch, and test-support notes. Split the module and executable sketches into their real package paths.
- `manifest` - Exact two-entry strict pg-migrate manifest format for application SQL. Copy the format, replace entries with real ordered migration files, and keep it exhaustive.
- `Telemetry.hs` - Reference production OpenTelemetry resource bracket: tracer and meter providers, flush/shutdown, W3C propagation, and Keiro metrics construction. Adapt resource attributes and thread the result into server and worker run options.
- `Settings.hs` - Reference Settei service declaration, direct YAML file loader, and canonical file, mounted-secret, then environment precedence. Adapt keys and types; preserve explicit bindings, secret sensitivity, unknown-key rejection, and diagnostic modes.
- `standards-map.md` - Topic-to-doc and Mori DocRef map for the normative Keiro runtime, architecture, configuration, migration, messaging, and HTTP standards. Read these docs before deviating from the prompt.

## Tools

- `Read`
- `Write`
- `Edit`
- `Glob`
- `Grep`
- `Bash(cabal *)`
- `Bash(nix *)`
- `Bash(just *)`
- `Bash(keiro-dsl *)`
- `Bash(fourmolu *)`
- `Bash(mori *)`
- `Bash(ls *)`
- `Bash(cat *)`
- `Bash(pwd)`
- `Bash(find *)`
- `Bash(mkdir *)`
- `Bash(git status*)`
- `Bash(git diff*)`
- `Bash(git log*)`
- `Bash(git rev-parse*)`
