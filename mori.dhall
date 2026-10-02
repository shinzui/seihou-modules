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
        , version = Some "0.2.0"
        , description = Some
            "Initialize a local git repository (default branch master), append .claude/, .agents/, and .seihou/manifest.json.tmp to .gitignore, and optionally create a GitHub repo via `gh repo create` (defaults to private) under a configured org or username, optionally granting an organization team access (git.githubTeam / git.githubTeamPermission)"
        , modulePath = "modules/git/git-init"
        , tags = [ "git", "github", "bootstrap" ]
        , requiredVars = [ "git.defaultBranch" ]
        }
      , Schema.SeihouTemplate::{
        , name = "repo-dir"
        , version = Some "0.1.0"
        , description = Some
            "Create <repo.parentDir>/<repo.name> and run git-init inside it to make a git repo with a matching GitHub repo; the owner comes from git.githubOwner, so per-context config selects the user or organization"
        , modulePath = "modules/git/repo-dir"
        , tags = [ "git", "github", "bootstrap" ]
        , requiredVars =
          [ "repo.parentDir"
          , "repo.name"
          , "git.githubOwner"
          , "git.githubVisibility"
          , "git.defaultBranch"
          ]
        }
      , Schema.SeihouTemplate::{
        , name = "nix-haskell-flake"
        , version = Some "0.26.0"
        , description = Some
            "Nix flake for Haskell projects with exact managed locks, a managed package-module seam for composed scaffolds, an unmanaged user extension point, and toggleable local services, treefmt-nix, and pre-commit hooks"
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
        , version = Some "0.3.0"
        , description = Some
            "Tested Haskell CLI bootstrap: reusable core plus CLI packages on GHC2024, GHC 9.12.4/9.14.1 shells, current bounded dependencies, valid package-local distribution metadata, and workspace-aware Nix package/check outputs"
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
