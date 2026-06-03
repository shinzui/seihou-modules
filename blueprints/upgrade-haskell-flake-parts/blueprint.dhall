let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/a0fba0d17b43b14bfdf6d0bf98f1b7ff7af4ebab/package.dhall
        sha256:36250d32d50cec0ea8c74926684ffb8b20f6d0b4f2152930dfa04a1ff108ef3f

in  S.Blueprint::{
    , name = "upgrade-haskell-flake-parts"
    , version = Some "0.1.0"
    , description = Some
        "Agent-driven, in-place migration of a shinzui Haskell project's Nix flake to the thin flake-parts structure on the haskell-nix-dev base flake: moves the toolchain to mkDevShell (GHC 9.12.4), splits wiring into nix/{haskell,treefmt,pre-commit}.nix, relocates the package build and custom checks into an unmanaged flake.module.nix, preserving every custom input/overlay/dev-tool/hook/check. Reviews and builds but never commits."
    , prompt = ./prompt.md as Text
    , vars = [] : List S.VarDecl.Type
    , prompts = [] : List S.Prompt.Type
    , baseModules = [] : List S.Dependency.Type
    , files =
      [ S.Blueprint.BlueprintFile::{
        , src = "flake.nix"
        , description = Some
            "Reference for the thin top-level flake.nix stub: standard inputs (haskell-nix-dev, followed nixpkgs, flake-parts, treefmt-nix, pre-commit-hooks) plus a commented PROJECT-SPECIFIC INPUTS section, and the mkFlake outputs with the nix/* imports and the optional flake.module.nix import. Keep the project's description and project-specific inputs; drop flake-utils."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "nix/haskell.nix"
        , description = Some
            "Reference for nix/haskell.nix: the dev shell via the base flake's mkDevShell on ghc9124, the haskellProject.extraDevPackages perSystem option, and the pre-commit installationScript shellHook. Put the project's extra dev tools (only those beyond cabal/HLS/pkg-config/zlib) in extraNativeBuildInputs."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "nix/treefmt.nix"
        , description = Some
            "Reference for nix/treefmt.nix: treefmt-nix as a flake-parts module wiring `nix fmt` and a treefmt check, with nixpkgs-fmt + fourmolu + cabal-gild (the latter two from the ghc9124 set). Preserve the project's existing formatter set."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "nix/pre-commit.nix"
        , description = Some
            "Reference for nix/pre-commit.nix: git-hooks.nix as a flake-parts module with the treefmt hook plus a commented example of a custom system-language hook. Carry over every custom hook the old flake had, moving any hook script under nix/."
        }
      , S.Blueprint.BlueprintFile::{
        , src = "flake.module.nix"
        , description = Some
            "Reference for the UNMANAGED flake.module.nix: the project-specific package build and custom checks. Shows Variant A (compose the shared haskell-nix overlay with the project's nix/haskell-overlay.nix and graft onto pkgs.haskell.packages.ghc9124) and Variant B (a no-overlay Tier B project building directly with callCabal2nix)."
        }
      ]
    , allowedTools = Some
      [ "Read"
      , "Write"
      , "Edit"
      , "Glob"
      , "Grep"
      , "Bash(nix *)"
      , "Bash(ls *)"
      , "Bash(cat *)"
      , "Bash(pwd)"
      , "Bash(find *)"
      , "Bash(rm *)"
      , "Bash(mv *)"
      , "Bash(mkdir *)"
      , "Bash(git status*)"
      , "Bash(git diff*)"
      , "Bash(git log*)"
      , "Bash(git rev-parse*)"
      ]
    , tags = [ "haskell", "nix", "flake", "flake-parts", "migration", "devshell" ]
    }
