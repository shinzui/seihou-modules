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
    , okfBundles =
      [ Schema.OkfBundle::{
        , name = "friction-log"
        , path = "docs/friction-log"
        , okfVersion = "0.2"
        , profile = Some "docs/friction-log/profile.dhall"
        , description = Some "Friction met while implementing plans, before triage into bug reports and requests"
        }
      ]
    , templates =
      [ Schema.SeihouTemplate::{ name = "fumadocs-project", version = Some "0.2.0", description = Some "Create a directory and Git/GitHub repository with container-enabled Fumadocs, writing skills and local Mori registration", modulePath = "recipes/fumadocs-project", tags = [ "docs", "fumadocs", "container", "mori", "recipe" ], requiredVars = [ "repo.parentDir", "repo.name", "git.githubOwner", "project.name", "project.description", "docs.site-name", "mori.namespace", "mori.source-namespace", "mori.source-project" ], dependencies = [ "repo-dir", "fumadocs-site", "git-init" ] }
      , Schema.SeihouTemplate::{ name = "fumadocs-site", version = Some "0.1.0", description = Some "Container-enabled Fumadocs with technical writing skills from agent-seihou and local Mori registration", modulePath = "recipes/fumadocs-site", tags = [ "docs", "fumadocs", "container", "mori", "recipe" ], requiredVars = [ "project.name", "project.description", "docs.site-name", "docs.github-user", "mori.namespace", "mori.source-namespace", "mori.source-project" ], dependencies = [ "fumadocs", "mori://shinzui/agent-seihou/templates/technical-docs", "docs-mori-bootstrap" ] }
      , Schema.SeihouTemplate::{ name = "docs-mori-bootstrap", version = Some "0.1.0", description = Some "Seed a documentation manifest, associate its documented project and register locally with Mori", modulePath = "modules/mori/docs-mori-bootstrap", tags = [ "docs", "mori", "bootstrap" ], requiredVars = [ "project.name", "project.description", "mori.namespace", "mori.source-namespace", "mori.source-project" ] }
      , Schema.SeihouTemplate::{ name = "docs-microapp-labs", version = Some "0.1.0", description = Some "Documentation reader and protected Nagare configuration with a native image and two-review deployment workflow", modulePath = "recipes/docs-microapp-labs", tags = [ "docs", "nagare", "labs", "recipe" ], requiredVars = [ "project.name", "project.description", "docs.site-name", "nagare.service-name", "nagare.domain", "nagare.namespace" ], dependencies = [ "docs-microapp", "nagare-docs-config" ] }
      , Schema.SeihouTemplate::{ name = "nagare-docs-config", version = Some "0.1.0", description = Some "Project-owned protected Nagare Application config with independent service, hostname and image values", modulePath = "modules/cloud/nagare-docs-config", tags = [ "nagare", "docs", "deployment" ], requiredVars = [ "project.name", "nagare.service-name", "nagare.domain", "nagare.namespace" ] }
      , Schema.SeihouTemplate::{ name = "docs-microapp", version = Some "0.1.0", description = Some "Documentation reader with TanStack Start, React Aria, Highlights, local fonts and immutable content images", modulePath = "modules/typescript/docs-microapp", tags = [ "typescript", "docs", "bun", "tanstack", "nix" ], requiredVars = [ "project.name", "project.description", "docs.site-name" ], dependencies = [ "nix-bun-flake" ] }
      , Schema.SeihouTemplate::{
        , name = "openapi-typescript-client-dir"
        , version = Some "0.1.0"
        , description = Some "Create a new client directory and run openapi-typescript-client with git-init inside it under a configurable GitHub owner"
        , modulePath = "modules/typescript/openapi-typescript-client-dir"
        , tags = [ "typescript", "openapi", "client", "git", "github", "bootstrap" ]
        , requiredVars = [ "repo.parentDir", "project.name", "project.description", "git.githubOwner", "git.githubVisibility", "git.defaultBranch", "nix.bun2nix" ]
        }
      , Schema.SeihouTemplate::{
        , name = "openapi-typescript-client-repo"
        , version = Some "0.1.0"
        , description = Some "Create a folder and scaffold an OpenAPI TypeScript client with an initial commit and a matching GitHub repository under git.githubOwner"
        , modulePath = "recipes/openapi-typescript-client-repo"
        , tags = [ "typescript", "openapi", "client", "git", "github", "bootstrap", "context" ]
        , dependencies = [ "openapi-typescript-client-dir" ]
        , requiredVars = [ "project.name", "project.description", "git.githubOwner" ]
        }
      , Schema.SeihouTemplate::{
        , name = "gcp-kube-env"
        , version = Some "0.1.1"
        , description = Some "Checkout-local GCP project and Kubernetes context through direnv, with a private kubeconfig and a configurable env filename defaulting to .envrc.local"
        , modulePath = "modules/cloud/gcp-kube-env"
        , tags = [ "gcp", "kubernetes", "direnv", "environment" ]
        , requiredVars = [ "gcp.project", "k8s.context", "env.file" ]
        }
      , Schema.SeihouTemplate::{
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
        , version = Some "0.2.0"
        , description = Some
            "Create a directory, acquire/apply an optional child scaffold, then delegate initial commit and Git/GitHub creation to git-init"
        , modulePath = "modules/git/repo-dir"
        , tags = [ "git", "github", "bootstrap" ]
        , requiredVars =
          [ "repo.source"
          , "repo.parentDir"
          , "repo.name"
          , "git.githubOwner"
          , "git.githubVisibility"
          , "git.defaultBranch"
          ]
        }
      , Schema.SeihouTemplate::{
        , name = "nix-haskell-flake"
        , version = Some "0.37.1"
        , description = Some
            "Nix flake for Haskell projects with optional explicit checked runtime scopes, exact managed locks, a managed package-module seam for composed scaffolds, an unmanaged user extension point, pinned nix2container service image support, and toggleable local services, treefmt-nix, and pre-commit hooks"
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
        , version = Some "0.3.0"
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
        , version = Some "0.4.0"
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
        , version = Some "0.4.1"
        , description = Some
            "Six-package Keiro seed with project-named workspace, injected probes, derived OpenAPI, Hurl/Hinagata testing, and optional initial Mori inventory"
        , modulePath = "modules/haskell/haskell-keiro-project"
        , tags = [ "haskell", "keiro", "service", "bootstrap" ]
        , dependencies = [ "nix-haskell-flake" ]
        , requiredVars = [ "project.name", "project.namespace", "project.description" ]
        }
      , Schema.SeihouTemplate::{
        , name = "nix-bun-flake"
        , version = Some "0.6.1"
        , description = Some "Shared Bun/TypeScript/Oxc flake-parts environment with revision-pinned locks, optional bun2nix builds, pinned nix2container image support, and an unmanaged project extension"
        , modulePath = "modules/typescript/nix-bun-flake"
        , tags = [ "typescript", "bun", "nix", "flake-parts" ]
        , requiredVars = [ "project.name", "project.description" ]
        }
      , Schema.SeihouTemplate::{
        , name = "openapi-typescript-client"
        , version = Some "0.2.2"
        , description = Some "Reusable ESM TypeScript 7 client with Orval generation, status-specific Zod validation, and project-owned Bun workflows"
        , modulePath = "modules/typescript/openapi-typescript-client"
        , tags = [ "typescript", "bun", "openapi", "orval", "zod", "client" ]
        , dependencies = [ "nix-bun-flake" ]
        , requiredVars = [ "project.name", "project.description", "openapi.schema" ]
        }
      , Schema.SeihouTemplate::{
        , name = "fumadocs"
        , version = Some "0.6.0"
        , description = Some "Current Fumadocs static documentation site on the shared Bun environment, with optional starter content for existing-site adoption, optional OpenAPI reference pages, and an optional Caddy container image"
        , modulePath = "modules/typescript/fumadocs"
        , tags = [ "typescript", "fumadocs", "docs" ]
        , dependencies = [ "nix-bun-flake" ]
        , requiredVars = [ "project.name", "project.description", "docs.site-name", "docs.github-user" ]
        }
      , Schema.SeihouTemplate::{
        , name = "upgrade-haskell-nix2container"
        , version = Some "0.1.0"
        , description = Some "Migrate customized Haskell service images to pinned nix2container and explicit load/export workflows while preserving managed ownership"
        , modulePath = "blueprints/upgrade-haskell-nix2container"
        , tags = [ "haskell", "nix", "docker", "migration" ]
        }
      , Schema.SeihouTemplate::{
        , name = "upgrade-haskell-runtime"
        , version = Some "0.1.0"
        , description = Some "Preserved legacy Haskell adoption and ordered module upgrades with independent native acceptance"
        , modulePath = "blueprints/upgrade-haskell-runtime"
        , tags = [ "haskell", "nix", "runtime", "migration" ]
        }
      , Schema.SeihouTemplate::{
        , name = "upgrade-fumadocs"
        , version = Some "0.3.0"
        , description = Some "Migrate customized Fumadocs sites to the current shared Bun flake-parts modules with content preservation and static-output validation"
        , modulePath = "blueprints/upgrade-fumadocs"
        , tags = [ "typescript", "fumadocs", "nix", "migration" ]
        }
      , Schema.SeihouTemplate::{
        , name = "relaunch-fumadocs-docs"
        , version = Some "0.1.0"
        , description = Some "Relaunch legacy Fumadocs sites: platform upgrade, writing skills, Mori registration, diagrams, source pin, release gates and a content assessment"
        , modulePath = "blueprints/relaunch-fumadocs-docs"
        , tags = [ "typescript", "fumadocs", "docs", "migration" ]
        }
      , Schema.SeihouTemplate::{
        , name = "haskell-keiro-service"
        , version = Some "0.4.0"
        , description = Some
            "Implement a six-package Keiro domain while extending the seed probes/OpenAPI, retaining Hurl/Hinagata setup, and maintaining an opted-in Mori inventory"
        , modulePath = "blueprints/haskell-keiro-service"
        , tags = [ "haskell", "service", "keiro", "bootstrap" ]
        , dependencies = [ "haskell-keiro-project" ]
        , requiredVars = [ "project.name", "project.namespace", "project.description" ]
        }
      ]
    }
