{ repoName = "seihou-modules"
, repoDescription = Some "Composable Seihou modules for bootstrapping projects"
, modules =
  [ { name = "nix-haskell-flake"
    , version = Some "0.8.0"
    , path = "modules/haskell/nix-haskell-flake"
    , description = Some "Nix flake for Haskell projects with optional process-compose and PostgreSQL support"
    , tags = [ "haskell", "nix", "flake", "devshell" ]
    }
  , { name = "haskell-cli-app"
    , version = Some "0.1.0"
    , path = "modules/haskell/haskell-cli-app"
    , description = Some "Haskell CLI app bootstrap: two cabal packages (core library + CLI exe) on GHC 9.12 / GHC2024, with lens + generic-lens, BSD-3 license, and a nix-haskell-flake dev shell"
    , tags = [ "haskell", "cli", "bootstrap", "ghc2024" ]
    }
  , { name = "haskell-library"
    , version = Some "0.1.0"
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
}
