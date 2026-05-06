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
  ]
, recipes =
  [] : List { name : Text, version : Optional Text, path : Text, description : Optional Text, tags : List Text }
}
