let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/9b1d6eea8027ae57576cf0712c0b9167fccbc1a9/package.dhall
        sha256:a19f5dd9181db28ba7a6a1b77b5ab8715e81aba3e2a8f296f40973003a0b4412

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
      ]
    }
