let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/a0fba0d17b43b14bfdf6d0bf98f1b7ff7af4ebab/package.dhall
        sha256:36250d32d50cec0ea8c74926684ffb8b20f6d0b4f2152930dfa04a1ff108ef3f

in S.Blueprint::{
    , name = "upgrade-fumadocs"
    , version = Some "0.1.0"
    , description = Some "Upgrade an existing Fumadocs site to the current fumadocs and nix-bun-flake modules, preserving content, custom components, package-manager workflows, fonts, CI gates, and Seihou ownership; validates the production static site and never commits"
    , prompt = ./prompt.md as Text
    , baseModules = [] : List S.Dependency.Type
    , files =
      [ S.Blueprint.BlueprintFile::{ src = "target-versions.json", description = Some "Tested target cohort; refresh alongside the modules, never guess versions from an old reference" }
      , S.Blueprint.BlueprintFile::{ src = "flake.module.nix", description = Some "Unmanaged extension example retaining a pnpm/Node workflow beside the shared Bun toolchain" }
      ]
    , tags = [ "typescript", "fumadocs", "nix", "flake-parts", "migration", "docs" ]
    } // { migrations = [ { from = "0.1.2", to = "0.2.1", prompt = ./migration-0.1.2-to-0.2.1.md as Text } ] }
