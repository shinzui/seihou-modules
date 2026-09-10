let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/3522f4a51181d73c9c90fc27a7c0838bd29ae95f/package.dhall
        sha256:dcb19e2312e790bad14e622cc98a1281cd2298c5b564a2f0d0534d3c718d8803

in  Schema.Project::{
    , project = Schema.ProjectIdentity::{
      , name = "seihou-modules"
      , namespace = "shinzui"
      , type = Schema.PackageType.Other "SeihouRegistry"
      , language = Schema.Language.Dhall
      , lifecycle = Schema.Lifecycle.Active
      , description = Some "Composable Seihou modules for bootstrapping projects"
      }
    , repos =
      [ Schema.Repo::{
        , name = "seihou-modules"
        , github = Some "shinzui/seihou-modules"
        }
      ]
    , templates =
      [ Schema.SeihouTemplate::{
        , name = "git-init"
        , version = Some "0.1.0"
        , description = Some
            "Initialize a local git repository (default branch master), append .claude/, .agents/, and .seihou/manifest.json.tmp to .gitignore, and optionally create a GitHub repo via `gh repo create` (defaults to private) under a configured org or username"
        , modulePath = "modules/git/git-init"
        , tags = [ "git", "github", "bootstrap" ]
        , requiredVars = [ "git.defaultBranch" ]
        }
      , Schema.SeihouTemplate::{
        , name = "nix-haskell-flake"
        , version = Some "0.14.0"
        , description = Some
            "Nix flake for Haskell projects with toggleable process-compose, PostgreSQL, socket-only Redis, ClickHouse, treefmt-nix, and pre-commit-hooks"
        , modulePath = "modules/haskell/nix-haskell-flake"
        , tags = [ "haskell", "nix", "flake", "devshell" ]
        , requiredVars =
          [ "project.name"
          , "project.description"
          , "nix.process-compose"
          , "nix.postgresql"
          ]
        }
      , Schema.SeihouTemplate::{
        , name = "haskell-library"
        , version = Some "0.1.0"
        , description = Some
            "Haskell library bootstrap: single cabal package on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, the project author's standard warning set, and an optional tasty test-suite; pulls in nix-haskell-flake for the dev shell"
        , modulePath = "modules/haskell/haskell-library"
        , tags = [ "haskell", "library", "bootstrap", "ghc2024" ]
        , dependencies = [ "nix-haskell-flake" ]
        , requiredVars =
          [ "project.name"
          , "project.description"
          , "project.namespace"
          ]
        }
      , Schema.SeihouTemplate::{
        , name = "haskell-cli-app"
        , version = Some "0.1.0"
        , description = Some
            "Haskell CLI app bootstrap: two cabal packages (core library + CLI exe) on GHC 9.12.4 / GHC2024, with lens + generic-lens, BSD-3 license, and a nix-haskell-flake dev shell"
        , modulePath = "modules/haskell/haskell-cli-app"
        , tags = [ "haskell", "cli", "bootstrap", "ghc2024" ]
        , dependencies = [ "nix-haskell-flake" ]
        , requiredVars =
          [ "project.name"
          , "project.description"
          , "project.namespace"
          ]
        }
      , Schema.SeihouTemplate::{
        , name = "haskell-keiro-project"
        , version = Some "0.1.0"
        , description = Some
            "Six-package Keiro bootstrap with a Nix shell, workspace-first domain structure, and implementation brief"
        , modulePath = "modules/haskell/haskell-keiro-project"
        , tags = [ "haskell", "keiro", "service", "bootstrap" ]
        , dependencies = [ "nix-haskell-flake" ]
        , requiredVars = [ "project.name", "project.namespace", "project.description", "keiro.context" ]
        }
      , Schema.SeihouTemplate::{
        , name = "haskell-keiro-service"
        , version = Some "0.3.0"
        , description = Some
            "Agent implementation of a six-package service using the haskell-keiro-project scaffold and current Keiro runtime patterns"
        , modulePath = "blueprints/haskell-keiro-service"
        , tags = [ "haskell", "service", "keiro", "bootstrap" ]
        , dependencies = [ "haskell-keiro-project" ]
        , requiredVars = [ "project.name", "project.namespace", "project.description", "keiro.context" ]
        }
      ]
    }
