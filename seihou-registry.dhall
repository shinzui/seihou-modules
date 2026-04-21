{ repoName = "seihou-modules"
, repoDescription = Some "Composable Seihou modules for bootstrapping projects"
, modules =
  [ { name = "nix-haskell-flake"
    , version = Some "0.8.0"
    , path = "modules/haskell/nix-haskell-flake"
    , description = Some "Nix flake for Haskell projects with optional process-compose and PostgreSQL support"
    , tags = [ "haskell", "nix", "flake", "devshell" ]
    }
  ]
, recipes =
  [] : List { name : Text, version : Optional Text, path : Text, description : Optional Text, tags : List Text }
}
