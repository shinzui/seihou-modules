let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/a3c59033a08c2eaef2cfba4a3c99fc9c192ca6d7/package.dhall
        sha256:18258ef583580a897f4af3e7c86db0342afb42fb40efc535b217ba1089230141

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
        , name = "nix-haskell-flake"
        , version = Some "0.8.0"
        , description = Some
            "Nix flake for Haskell projects with toggleable process-compose, PostgreSQL, treefmt-nix, and pre-commit-hooks"
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
        , name = "haskell-cli-app"
        , version = Some "0.1.0"
        , description = Some
            "Haskell CLI app bootstrap: two cabal packages (core library + CLI exe) on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, and a nix-haskell-flake dev shell"
        , modulePath = "modules/haskell/haskell-cli-app"
        , tags = [ "haskell", "cli", "bootstrap", "ghc2024" ]
        , requiredVars =
          [ "project.name"
          , "project.description"
          , "project.namespace"
          ]
        }
      ]
    }
