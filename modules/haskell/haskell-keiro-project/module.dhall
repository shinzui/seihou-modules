let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/7d02695f5a716384ec2174a018c20ee680ab3d13/package.dhall
        sha256:5a24b98eada6628e3e7da267f4e6c31c1e169179d2bacd5fed7254fc4cc55183

in  S.Module::{
    , name = "haskell-keiro-project"
    , version = Some "0.3.0"
    , description = Some
        "Six-package Keiro seed with project-named domain paths, injected servant-health probes, OpenAPI generation, Hurl/Hinagata test setup, and optional initial Mori inventory on nix-haskell-flake. The blueprint implements the domain."
    , vars =
      [ S.VarDecl::{
        , name = "project.name"
        , type = "text"
        , description = Some
            "Project base name; creates <name>-core, -api, -migrations, -workers, -server, and -client. Shared with the Nix environment."
        , required = True
        , validation = Some "[a-z][a-z0-9-]*"
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
            "Optional logical DSL context override; paths and workspace identity always use project.name."
        , required = False
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "mori.prompt"
        , type = "bool"
        , default = Some "true"
        , required = False
        , description = Some
            "Internal prompt coordination: the blueprint asks once and suppresses the baseline module question, including after an empty skip."
        }
      , S.VarDecl::{
        , name = "mori.generate"
        , type = "bool"
        , required = False
        , description = Some
            "Generate an initial local Mori inventory (no registration). Empty input skips."
        }
      , S.VarDecl::{
        , name = "mori.namespace"
        , type = "text"
        , required = False
        , validation = Some "[a-z][a-z0-9-]*"
        , description = Some
            "Mori organization/user namespace; required when mori.generate=true. Separate from Haskell project.namespace."
        }
      , S.VarDecl::{
        , name = "haskell.index-state"
        , type = "text"
        , default = Some "2026-10-26T00:00:00Z"
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
        , var = "mori.generate"
        , text =
            "Generate an initial mori.dhall with packages, dependencies, and the OpenAPI schema reference? (true/false; empty skips)"
        , when = Some "Eq mori.prompt true"
        }
      , S.Prompt::{
        , var = "mori.namespace"
        , text =
            "Mori organization/user namespace? (separate from the PascalCase Haskell namespace)"
        , when = Some "Eq mori.generate true"
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
          , { name = "nix.package-module", value = "nix/keiro-dev-tools.nix" }
          ]
        }
      ]
    , steps =
      [ S.Step::{
        , strategy = "template"
        , src = "cabal.project.tpl"
        , dest = "cabal.project"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "Prelude.hs.tpl"
        , dest = "{{project.name}}-core/src/{{project.namespace}}/Prelude.hs"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "workspace.tpl"
        , dest = "domain/{{project.name}}.keiro-workspace"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "shared.keiro.tpl"
        , dest = "domain/{{project.name}}/shared.keiro"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "justfile.tpl"
        , dest = "justfile"
        , lifecycle = Some "seed"
        }
      , S.Step::{ strategy = "template", src = "LICENSE.tpl", dest = "LICENSE" }
      , S.Step::{
        , strategy = "template"
        , src = "README.md.tpl"
        , dest = "README.md"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "bootstrap.md.tpl"
        , dest = "docs/bootstrap-keiro.md"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "core.cabal.tpl"
        , dest = "{{project.name}}-core/{{project.name}}-core.cabal"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "core.hs.tpl"
        , dest = "{{project.name}}-core/src/{{project.namespace}}/Bootstrap.hs"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "api.cabal.tpl"
        , dest = "{{project.name}}-api/{{project.name}}-api.cabal"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "api.hs.tpl"
        , dest = "{{project.name}}-api/src/{{project.namespace}}/Api.hs"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "openapi.hs.tpl"
        , dest = "{{project.name}}-api/src/{{project.namespace}}/Api/OpenApi.hs"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "openapi-main.hs.tpl"
        , dest = "{{project.name}}-api/app/OpenApiMain.hs"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "openapi-test.hs.tpl"
        , dest = "{{project.name}}-api/test/OpenApiTest.hs"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "health-test.hs.tpl"
        , dest = "{{project.name}}-server/test/HealthTest.hs"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "migrations.cabal.tpl"
        , dest = "{{project.name}}-migrations/{{project.name}}-migrations.cabal"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "migrations.hs.tpl"
        , dest =
            "{{project.name}}-migrations/src/{{project.namespace}}/Migrations.hs"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "workers.cabal.tpl"
        , dest = "{{project.name}}-workers/{{project.name}}-workers.cabal"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "workers.hs.tpl"
        , dest =
            "{{project.name}}-workers/src/{{project.namespace}}/Workers/Registry.hs"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "server.cabal.tpl"
        , dest = "{{project.name}}-server/{{project.name}}-server.cabal"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "server.hs.tpl"
        , dest =
            "{{project.name}}-server/src/{{project.namespace}}/Server/App.hs"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "client.cabal.tpl"
        , dest = "{{project.name}}-client/{{project.name}}-client.cabal"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "client.hs.tpl"
        , dest = "{{project.name}}-client/src/{{project.namespace}}/Client.hs"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "nix/keiro-dev-tools.nix.tpl"
        , dest = "nix/keiro-dev-tools.nix"
        }
      , S.Step::{
        , strategy = "template"
        , src = "hurl-workbench.dhall.tpl"
        , dest = "hurl-workbench.dhall"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "template"
        , src = "hinagata.yaml.tpl"
        , dest = "hinagata.yaml"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "tests/api/health.hurl"
        , dest = "tests/api/health.hurl"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "fixtures/bootstrap/fixture.sql"
        , dest = "tests/fixtures/bootstrap/fixture.sql"
        , lifecycle = Some "seed"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "scripts/keiro-test-env"
        , dest = "scripts/keiro-test-env"
        }
      , S.Step::{
        , strategy = "template"
        , src = "mori.dhall.tpl"
        , dest = "mori.dhall"
        , when = Some "Eq mori.generate true"
        , lifecycle = Some "seed"
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
