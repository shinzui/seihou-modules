{ repoName = "seihou-modules"
, repoDescription = Some "Composable Seihou modules for bootstrapping projects"
, modules =
  [ { name = "nix-haskell-flake"
    , path = "modules/haskell/nix-haskell-flake"
    , description = Some "Nix flake for Haskell projects with optional process-compose and PostgreSQL support"
    , tags = [ "haskell", "nix", "flake", "devshell" ]
    }
  ]
}
