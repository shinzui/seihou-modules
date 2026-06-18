{ repoName = "seihou-modules"
, repoDescription = Some "Composable Seihou modules for bootstrapping projects"
, modules =
  [ { name = "nix-haskell-flake"
    , version = Some "0.11.3"
    , path = "modules/haskell/nix-haskell-flake"
    , description = Some "Nix flake for Haskell projects consuming the haskell-nix-dev base flake (shared nixpkgs lock, prebuilt GHC/HLS/cabal), with optional process-compose, PostgreSQL, treefmt, and pre-commit"
    , tags = [ "haskell", "nix", "flake", "devshell" ]
    }
  , { name = "haskell-cli-app"
    , version = Some "0.2.0"
    , path = "modules/haskell/haskell-cli-app"
    , description = Some "Haskell CLI app bootstrap: two cabal packages (core library + CLI exe) on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, and a nix-haskell-flake dev shell"
    , tags = [ "haskell", "cli", "bootstrap", "ghc2024" ]
    }
  , { name = "haskell-library"
    , version = Some "0.2.0"
    , path = "modules/haskell/haskell-library"
    , description = Some "Haskell library bootstrap: a single cabal package on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, an optional tasty test-suite, and a nix-haskell-flake dev shell"
    , tags = [ "haskell", "library", "bootstrap", "ghc2024" ]
    }
  , { name = "git-init"
    , version = Some "0.1.0"
    , path = "modules/git/git-init"
    , description = Some "Initialize a local git repo (default branch master), seed .gitignore with .claude/, .agents/, and .seihou/manifest.json.tmp, and optionally create a private GitHub repo via `gh` under a configured org or username"
    , tags = [ "git", "github", "bootstrap", "gitignore" ]
    }
  , { name = "nix-bun-flake"
    , version = Some "0.1.0"
    , path = "modules/typescript/nix-bun-flake"
    , description = Some "Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting (semicolon-free, sorted imports), a just task runner, and optional git-hooks.nix pre-commit checks"
    , tags = [ "typescript", "bun", "nix", "flake", "oxc", "devshell" ]
    }
  ]
, recipes =
  [ { name = "haskell-library-repo"
    , version = Some "0.1.0"
    , path = "recipes/haskell-library-repo"
    , description = Some "Bootstrap a single-package Haskell library in a fresh git repo: applies haskell-library (which pulls in nix-haskell-flake) and then git-init last so the initial commit captures the full scaffold"
    , tags = [ "haskell", "library", "git", "bootstrap" ]
    }
  , { name = "haskell-cli-app-repo"
    , version = Some "0.1.0"
    , path = "recipes/haskell-cli-app-repo"
    , description = Some "Bootstrap a two-package Haskell CLI app (core library + CLI exe) in a fresh git repo: applies haskell-cli-app (which pulls in nix-haskell-flake) and then git-init last so the initial commit captures the full scaffold"
    , tags = [ "haskell", "cli", "git", "bootstrap" ]
    }
  ]
, blueprints =
  [ { name = "upgrade-haskell-flake-parts"
    , version = Some "0.1.0"
    , path = "blueprints/upgrade-haskell-flake-parts"
    , description = Some "Agent-driven, in-place migration of a shinzui Haskell project's Nix flake to the thin flake-parts structure on the haskell-nix-dev base flake (GHC 9.12.4 via mkDevShell, wiring split into nix/{haskell,treefmt,pre-commit}.nix, package build and custom checks moved to an unmanaged flake.module.nix), preserving every custom input/overlay/dev-tool/hook/check; reviews and builds but never commits"
    , tags = [ "haskell", "nix", "flake", "flake-parts", "migration", "devshell" ]
    }
  ]
}
