let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/7d02695f5a716384ec2174a018c20ee680ab3d13/package.dhall
        sha256:5a24b98eada6628e3e7da267f4e6c31c1e169179d2bacd5fed7254fc4cc55183

in S.Blueprint::{
    , name = "upgrade-haskell-nix2container"
    , version = Some "0.1.0"
    , description = Some "Migrate existing nix-haskell-flake service images from dockerTools to pinned nix2container, preserving configuration, runtime files, inputs and Seihou ownership"
    , prompt = ./prompt.md as Text
    , baseModules = [] : List S.Dependency.Type
    , files =
      [ S.Blueprint.BlueprintFile::{
        , src = "flake.module.nix"
        , description = Some "Unmanaged Linux-only nix2container service image reference; merge with the consumer's existing outputs, never overwrite its extension"
        }
      ]
    , migrations =
      [ S.BlueprintMigration::{
        , from = "0.36.0"
        , to = "0.37.0"
        , prompt = ./migrations/0.36.0-to-0.37.0.md as Text
        }
      ]
    , tags = [ "haskell", "nix", "docker", "nix2container", "migration", "seihou" ]
    }
