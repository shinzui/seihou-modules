let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/b83079d377f22c77292ad5ccf88d1061a58f0c1c/package.dhall
        sha256:1d46697ed3e7ca1b0d9922020e2da034ae6e33f7b482ee454c68d94b536e8c2a

in  S.Module::{
    , name = "haskell-keiro-project"
    , version = Some "0.1.0"
    , description = Some
        "Bootstrap the six-package Keiro service structure, workspace-first domain workflow, and implementation brief on nix-haskell-flake. Domain implementation is completed by the haskell-keiro-service blueprint."
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
    , exports =
      [ { var = "project.name", alias = None Text }
      , { var = "project.namespace", alias = None Text }
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
    , dependencies =
      [ S.Dependency::{
        , module = "nix-haskell-flake"
        , vars =
          [ { name = "nix.postgresql", value = "true" }
          , { name = "nix.process-compose", value = "true" }
          , { name = "nix.builtin-package", value = "false" }
          ]
        }
      ]
    , steps =
      [ S.Step::{
        , strategy = "template"
        , src = "cabal.project.tpl"
        , dest = "cabal.project"
        }
      , S.Step::{
        , strategy = "template"
        , src = "Prelude.hs.tpl"
        , dest = "{{project.name}}-core/src/{{project.namespace}}/Prelude.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "workspace.tpl"
        , dest = "domain/{{keiro.context}}.keiro-workspace"
        }
      , S.Step::{
        , strategy = "template"
        , src = "shared.keiro.tpl"
        , dest = "domain/{{keiro.context}}/shared.keiro"
        }
      , S.Step::{
        , strategy = "template"
        , src = "justfile.tpl"
        , dest = "justfile"
        }
      , S.Step::{ strategy = "template", src = "LICENSE.tpl", dest = "LICENSE" }
      , S.Step::{
        , strategy = "template"
        , src = "README.md.tpl"
        , dest = "README.md"
        }
      , S.Step::{
        , strategy = "template"
        , src = "bootstrap.md.tpl"
        , dest = "docs/bootstrap-keiro.md"
        }
      , S.Step::{
        , strategy = "template"
        , src = "core.cabal.tpl"
        , dest = "{{project.name}}-core/{{project.name}}-core.cabal"
        }
      , S.Step::{
        , strategy = "template"
        , src = "core.hs.tpl"
        , dest = "{{project.name}}-core/src/{{project.namespace}}/Bootstrap.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "api.cabal.tpl"
        , dest = "{{project.name}}-api/{{project.name}}-api.cabal"
        }
      , S.Step::{
        , strategy = "template"
        , src = "api.hs.tpl"
        , dest = "{{project.name}}-api/src/{{project.namespace}}/Api.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "migrations.cabal.tpl"
        , dest = "{{project.name}}-migrations/{{project.name}}-migrations.cabal"
        }
      , S.Step::{
        , strategy = "template"
        , src = "migrations.hs.tpl"
        , dest =
            "{{project.name}}-migrations/src/{{project.namespace}}/Migrations.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "workers.cabal.tpl"
        , dest = "{{project.name}}-workers/{{project.name}}-workers.cabal"
        }
      , S.Step::{
        , strategy = "template"
        , src = "workers.hs.tpl"
        , dest =
            "{{project.name}}-workers/src/{{project.namespace}}/Workers/Registry.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "server.cabal.tpl"
        , dest = "{{project.name}}-server/{{project.name}}-server.cabal"
        }
      , S.Step::{
        , strategy = "template"
        , src = "server.hs.tpl"
        , dest =
            "{{project.name}}-server/src/{{project.namespace}}/Server/App.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "client.cabal.tpl"
        , dest = "{{project.name}}-client/{{project.name}}-client.cabal"
        }
      , S.Step::{
        , strategy = "template"
        , src = "client.hs.tpl"
        , dest = "{{project.name}}-client/src/{{project.namespace}}/Client.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "gitignore.tpl"
        , dest = ".gitignore"
        , patch = Some "append-line-if-absent"
        }
      , S.Step::{
        , strategy = "template"
        , src = "LICENSE.tpl"
        , dest = "{{project.name}}-core/LICENSE"
        }
      , S.Step::{
        , strategy = "template"
        , src = "LICENSE.tpl"
        , dest = "{{project.name}}-api/LICENSE"
        }
      , S.Step::{
        , strategy = "template"
        , src = "LICENSE.tpl"
        , dest = "{{project.name}}-migrations/LICENSE"
        }
      , S.Step::{
        , strategy = "template"
        , src = "LICENSE.tpl"
        , dest = "{{project.name}}-workers/LICENSE"
        }
      , S.Step::{
        , strategy = "template"
        , src = "LICENSE.tpl"
        , dest = "{{project.name}}-server/LICENSE"
        }
      , S.Step::{
        , strategy = "template"
        , src = "LICENSE.tpl"
        , dest = "{{project.name}}-client/LICENSE"
        }
      ]
    }
