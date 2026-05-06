let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/1f70781427426c09673d46f8e6733b7e7d0abedc/package.dhall
        sha256:3b79aae9216456678300441ca8616b64a4b4fa520a1286dfcc418f60899d5d4a

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
          , "project.description-long"
          , "project.namespace"
          ]
        }
      ]
    }
