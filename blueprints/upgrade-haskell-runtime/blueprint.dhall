let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/7d02695f5a716384ec2174a018c20ee680ab3d13/package.dhall
        sha256:5a24b98eada6628e3e7da267f4e6c31c1e169179d2bacd5fed7254fc4cc55183

in S.Blueprint::{
    , name = "upgrade-haskell-runtime"
    , version = Some "0.1.0"
    , description = Some "Adopt the checked Haskell runtime module, preserving explicit selections, authored sources and genuine Seihou ownership; require independent native acceptance"
    , prompt = ./prompt.md as Text
    , baseModules = [] : List S.Dependency.Type
    , files =
      [ S.Blueprint.BlueprintFile::{ src = "target-versions.json", description = Some "Qualified immutable release inputs and exact recorded source versions" }
      , S.Blueprint.BlueprintFile::{ src = "flake.module.nix", description = Some "Unmanaged opt-in interface example; preserve the consumer's actual explicit selections" }
      , S.Blueprint.BlueprintFile::{ src = "check-haskell-runtime-adoption.py", description = Some "Standalone independent before/after and native acceptance checker" }
      ]
    , migrations =
      [ S.BlueprintMigration::{ from = "0.30.0", to = "0.31.0", prompt = ./migrations/0.30.0-to-0.31.0.md as Text }
      , S.BlueprintMigration::{ from = "0.31.0", to = "0.32.0", prompt = ./migrations/0.31.0-to-0.32.0.md as Text }
      ]
    , tags = [ "haskell", "nix", "runtime", "migration", "seihou" ]
    }
