let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/a0fba0d17b43b14bfdf6d0bf98f1b7ff7af4ebab/package.dhall
        sha256:36250d32d50cec0ea8c74926684ffb8b20f6d0b4f2152930dfa04a1ff108ef3f

in  S.Blueprint::{
    , name = "haskell-keiro-service"
    , version = Some "0.2.2"
    , description = Some
        "Agent-driven scaffold for an event-sourced Haskell service on the released Keiro runtime: a six-package vertical-slice layout with generated and hand-owned rings, Hackage-pinned dependencies, pg-migrate components, validated event streams, Settei configuration, real OpenTelemetry wiring, health and request-logging contracts, and a Keiro-DSL-first workflow."
    , prompt = ./prompt.md as Text
    , vars =
      [ S.VarDecl::{
        , name = "project.name"
        , type = "text"
        , description = Some
            "Project base name (lowercase, hyphenated). Cabal packages are named <name>-core, <name>-api, <name>-migrations, <name>-workers, <name>-server, <name>-client; executables include <name>-migrate, <name>-server, and <name>-worker. Read models live in <name>-core (there is no separate <name>-postgres package)."
        , required = True
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "project.namespace"
        , type = "text"
        , description = Some
            "Top-level Haskell module namespace (single PascalCase segment, e.g. Danwa). Modules are organized vertical-slice by domain concept: everything for one concept lives under <Namespace>.<Aggregate>.* regardless of package — the keiro-scaffolded <Namespace>.<Aggregate>.Generated.{Domain,Codec,EventStream,Projection,Harness} (a `.Generated` leaf, each carrying a `-- @generated` header, overwritten by `keiro-dsl scaffold --out <name>-core/src` because the spec declares `layout collocated`), the hand-owned <Namespace>.<Aggregate>.Holes (the keiki transducer + the read-model `apply`, create-if-absent), and that concept's <Namespace>.<Aggregate>.{Api,Worker,ReadModel,Handler}. Only cross-cutting infra keeps a technical-layer name (<Namespace>.Prelude, <Namespace>.App.Config, <Namespace>.Postgres.{Pool,Runner}, <Namespace>.Migrations, <Namespace>.Workers.{Subscription,Registry}, the <Namespace>.Api umbrella, <Namespace>.Server.{Config,App,Seam,Boot})."
        , required = True
        , validation = Some "[A-Z][A-Za-z0-9]*"
        }
      , S.VarDecl::{
        , name = "project.description"
        , type = "text"
        , description = Some
            "One-line synopsis (used as the flake description and cabal synopsis across packages)."
        , required = True
        }
      , S.VarDecl::{
        , name = "keiro.context"
        , type = "text"
        , description = Some
            "The keiro DSL context name for the domain (e.g. danwa). Names the .keiro file (domain/<context>.keiro) and the bounded context inside it."
        , required = True
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "project.author"
        , type = "text"
        , default = Some "Nadeem Bitar"
        , description = Some "Author name written into LICENSE and .cabal files."
        , required = True
        }
      , S.VarDecl::{
        , name = "project.maintainer"
        , type = "text"
        , default = Some "nadeem@gmail.com"
        , description = Some "Maintainer email written into .cabal files."
        , required = True
        }
      , S.VarDecl::{
        , name = "nix.postgresql"
        , type = "bool"
        , default = Some "true"
        , description = Some
            "Include PostgreSQL in the dev shell (the event store and read models are Postgres). Bound through to the nix-haskell-flake base module."
        , required = True
        }
      , S.VarDecl::{
        , name = "nix.process-compose"
        , type = "bool"
        , default = Some "true"
        , description = Some
            "Include process-compose for local service orchestration. Bound through to the nix-haskell-flake base module."
        , required = True
        }
      ]
    , prompts =
      [ S.Prompt::{
        , var = "project.name"
        , text =
            "Project name? (lowercase, hyphenated; cabal packages will be <name>-core, <name>-api, <name>-migrations, <name>-workers, <name>-server, <name>-client)"
        }
      , S.Prompt::{
        , var = "project.namespace"
        , text = "Top-level Haskell module namespace? (single PascalCase segment, e.g. Danwa)"
        }
      , S.Prompt::{
        , var = "project.description"
        , text = "One-line project synopsis?"
        }
      , S.Prompt::{
        , var = "keiro.context"
        , text = "keiro DSL context name for the domain? (lowercase, e.g. danwa)"
        }
      ]
    , baseModules =
      [ S.Dependency::{
        , module = "nix-haskell-flake"
        , vars =
          [ { name = "nix.postgresql", value = "true" }
          , { name = "nix.process-compose", value = "true" }
          , { name = "nix.treefmt", value = "true" }
          , { name = "nix.pre-commit", value = "true" }
          ]
        }
      ]
    , files =
      [ S.Blueprint.BlueprintFile::{
        , src = "cabal.project"
        , description = Some
            "Reference cabal.project: Hackage-only runtime cohort at the verified index-state, GHC 9.12.4, the direct settei-yaml adapter (the released settei-formats umbrella is not solvable with this bytestring cohort), and the six-package list. Adapt package names; keep the index-state and never add local paths or runtime source-repository-package pins."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "core.cabal"
        , description = Some
            "Reference <name>-core.cabal: the shared common stanzas, bounded released dependencies, and exposed modules organized by vertical slice, including generated, hand-owned, and read-model rings. Adapt names while preserving package bounds and layout."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "Prelude.hs"
        , description = Some
            "Reference <Ns>.Prelude: a thin re-export over base using {-# LANGUAGE PackageImports #-} (ONLY here), re-exporting module Control.Lens. Notes the rule that Data.Generics.Labels is NOT re-exported (its orphan IsLabel collides with keiki's); each module that uses #field lenses imports it locally."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "AppConfig.hs"
        , description = Some
            "Reference runtime dependency module: the strict AppConfig record populated only after Settei resolves Settings, plus the Eff es + Reader AppConfig + Error + IOE effect-row shape. Adapt dependencies; do not merge source resolution into this module."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "Api.hs"
        , description = Some
            "Reference Servant skeleton: NamedRoutes, wire DTOs, and the fleet liveness/readiness route shape. Adapt domain routes and keep probe semantics separate from dependency health."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "Diagrams.hs"
        , description = Some
            "Reference <Ns>.Diagrams: renders each aggregate's keiki transducer to a stateDiagram-v2 block (Keiki.Render.Mermaid.toMermaid) and splices it between HTML-comment markers in docs/diagrams/domain-lifecycles.md (Keiki.Render.Markdown.replaceMarkdownDiagramBlock). staleDiagrams/writeDiagrams back the <name>-diagrams executable (--check/--write) and the <name>-core-diagrams test suite that fails `cabal test` when a committed diagram has drifted from its transducer — the generated-artifact freshness gate."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "domain.keiro"
        , description = Some
            "Reference keiro DSL spec: a bounded context with a `layout collocated` clause, one aggregate, an id newtype with a prefix, a closed enum referenced via an explicit field:Enum annotation, a couple of commands/events, a projection, and command/query operations — the keiro-DSL-first shape to author and `keiro-dsl check` BEFORE writing any domain Haskell."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "fourmolu.yaml"
        , description = Some
            "Reference fourmolu.yaml (the fleet formatter config, also shipped by the nix-haskell-flake base module) so the generated project formats identically to the rest of the fleet."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "Migrations.hs"
        , description = Some
            "Reference pg-migrate package wiring: embedded strict manifest, application MigrationComponent, ordered complete plan, CLI command dispatch, and test-support notes. Split the module and executable sketches into their real package paths."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "manifest"
        , description = Some
            "Exact two-entry strict pg-migrate manifest format for application SQL. Copy the format, replace entries with real ordered migration files, and keep it exhaustive."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "Telemetry.hs"
        , description = Some
            "Reference production OpenTelemetry resource bracket: tracer and meter providers, flush/shutdown, W3C propagation, and Keiro metrics construction. Adapt resource attributes and thread the result into server and worker run options."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "Settings.hs"
        , description = Some
            "Reference Settei service declaration, direct YAML file loader, and canonical file, mounted-secret, then environment precedence. Adapt keys and types; preserve explicit bindings, secret sensitivity, unknown-key rejection, and diagnostic modes."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "standards-map.md"
        , description = Some
            "Topic-to-doc and Mori DocRef map for the normative Keiro runtime, architecture, configuration, migration, messaging, and HTTP standards. Read these docs before deviating from the prompt."
        }
      ]
    , allowedTools = Some
      [ "Read"
      , "Write"
      , "Edit"
      , "Glob"
      , "Grep"
      , "Bash(cabal *)"
      , "Bash(nix *)"
      , "Bash(just *)"
      , "Bash(keiro-dsl *)"
      , "Bash(fourmolu *)"
      , "Bash(mori *)"
      , "Bash(ls *)"
      , "Bash(cat *)"
      , "Bash(pwd)"
      , "Bash(find *)"
      , "Bash(mkdir *)"
      , "Bash(git status*)"
      , "Bash(git diff*)"
      , "Bash(git log*)"
      , "Bash(git rev-parse*)"
      ]
    , tags =
      [ "haskell"
      , "service"
      , "keiro"
      , "effectful"
      , "event-sourcing"
      , "bootstrap"
      ]
    }
