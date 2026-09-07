let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/a0fba0d17b43b14bfdf6d0bf98f1b7ff7af4ebab/package.dhall
        sha256:36250d32d50cec0ea8c74926684ffb8b20f6d0b4f2152930dfa04a1ff108ef3f

in  S.Blueprint::{
    , name = "haskell-keiro-service"
    , version = Some "0.3.0"
    , description = Some
        "Agent-driven scaffold for an event-sourced Haskell service on the released Keiro runtime: a six-package vertical-slice layout with generated and hand-owned rings, Hackage-pinned dependencies, pg-migrate components, validated event streams, Settei configuration, real OpenTelemetry wiring, health and request-logging contracts, and a Keiro-DSL-first workflow."
    , prompt = ./prompt.md as Text
    , vars =
      [ S.VarDecl::{
        , name = "project.name"
        , type = "text"
        , description = Some
            "Project base name; creates <name>-core, -api, -migrations, -workers, -server, and -client. Shared with the Nix environment."
        , required = True
        , validation = Some "[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*"
        }
      , S.VarDecl::{
        , name = "project.description"
        , type = "text"
        , description = Some
            "One-line synopsis used in Cabal files, the implementation brief, and the Nix flake description."
        , required = True
        }
      , S.VarDecl::{
        , name = "project.namespace"
        , type = "text"
        , description = Some
            "Top-level Haskell module namespace (single segment, e.g. Rei). Used both as the source-tree directory and as the module prefix in generated .hs files."
        , required = True
        , validation = Some "[A-Z][A-Za-z0-9]*"
        }
      , S.VarDecl::{
        , name = "project.author"
        , type = "text"
        , default = Some "Nadeem Bitar"
        , description = Some "Author name written into LICENSE and .cabal files"
        , required = True
        }
      , S.VarDecl::{
        , name = "project.maintainer"
        , type = "text"
        , default = Some "nadeem@gmail.com"
        , description = Some "Maintainer email written into .cabal files"
        , required = True
        }
      , S.VarDecl::{
        , name = "project.copyright-year"
        , type = "text"
        , default = Some "2026"
        , description = Some "Copyright year written into LICENSE"
        , required = True
        , validation = Some "[0-9]{4}"
        }
      , S.VarDecl::{
        , name = "keiro.context"
        , type = "text"
        , description = Some
            "Stable service workspace identity and shared DSL context."
        , required = True
        , validation = Some "[a-z][a-z0-9]*(-[a-z][a-z0-9]*)*"
        }
      , S.VarDecl::{
        , name = "haskell.index-state"
        , type = "text"
        , default = Some "2026-09-07T00:00:00Z"
        , description = Some
            "Hackage index snapshot for the initial libraries; reverify the runtime cohort before adding domain dependencies."
        , required = True
        , validation = Some
            "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z"
        }
      ]
    , prompts =
      [ S.Prompt::{
        , var = "project.name"
        , text =
            "What is your project name? (lowercase, hyphenated; cabal packages will be <name>-core, -api, -migrations, -workers, -server, and -client)"
        }
      , S.Prompt::{
        , var = "project.description"
        , text =
            "One-line project synopsis (used as cabal `synopsis:` and the flake description):"
        }
      , S.Prompt::{
        , var = "project.namespace"
        , text =
            "Top-level Haskell module namespace? (single PascalCase segment, e.g. Rei)"
        }
      , S.Prompt::{ var = "project.author", text = "Author name?" }
      , S.Prompt::{ var = "project.maintainer", text = "Maintainer email?" }
      , S.Prompt::{ var = "project.copyright-year", text = "Copyright year?" }
      , S.Prompt::{
        , var = "keiro.context"
        , text = "Stable Keiro service/context name? (lowercase, e.g. contacts)"
        }
      , S.Prompt::{
        , var = "haskell.index-state"
        , text = "Hackage index-state for this bootstrap? (UTC timestamp)"
        }
      ]
    , baseModules =
      [ S.Dependency::{
        , module = "haskell-keiro-project"
        , vars = [] : List { name : Text, value : Text }
        }
      ]
    , files =
      [ S.Blueprint.BlueprintFile::{
        , src = "cabal.project"
        , description = Some
            "Historical cabal.project sketch for a six-package runtime cohort. Verify current releases and follow the generated bootstrap brief before choosing bounds, index-state, or adapter compatibility workarounds; never add local runtime paths."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "core.cabal"
        , description = Some
            "Reference <name>-core.cabal: the shared common stanzas, bounded released dependencies, and exposed modules organized by vertical slice, including generated, hand-owned, and read-model rings. Historical sketch only: replace bounds with the verified cohort and use the complete current generated Cabal fragment."
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
            "Reference keiro DSL spec: a historical bare-source example with a `layout collocated` clause, one aggregate, an id newtype with a prefix, a closed enum referenced via an explicit field:Enum annotation, a couple of commands/events, a projection, and command/query operations — adapt only after reading the current workspace and language standards; the generated workspace is authoritative."
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
