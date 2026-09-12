let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/0e1b875efcf2b4e4b98d93595ea627290459e3ad/package.dhall
        sha256:356829d4e2b333ce157615dd7eccd0cd4765f3ef0d94ef637fa8c97398d3b92c

in  S.Blueprint::{
    , name = "fix-nix-haskell-flake-customizations"
    , version = Some "0.2.0"
    , description = Some
        "Agent-driven, in-place remediation of a repo that already consumes the nix-haskell-flake seihou module: upgrades the module to its latest version (seihou migrate + seihou run --force) and relocates every local edit made directly to a seihou-managed file into its unmanaged, upgrade-safe home — extra dev-shell tools in nix/haskell.nix move to flake.module.nix via haskellProject.extraDevPackages, custom .envrc exports move to .envrc.local, and extra process-compose processes move to process-compose.override.yaml — git-tracking the files Nix needs to see and proving dev-shell parity with nix print-dev-env. Reviews and verifies but never commits."
    , prompt = ./prompt.md as Text
    , vars = [] : List S.VarDecl.Type
    , prompts = [] : List S.Prompt.Type
    , baseModules = [] : List S.Dependency.Type
    , files =
      [ S.Blueprint.BlueprintFile::{
        , src = "flake.module.nix"
        , description = Some
            "Reference for the UNMANAGED flake.module.nix: a flake-parts module that sets haskellProject.extraDevPackages (the option declared by nix/haskell.nix) to the project's extra dev-shell tools, plus commented examples for a project-defined packages.default (when nix.builtin-package is false) and treefmt overrides. The header documents the hard requirement that this file be git-tracked, since Nix flakes ignore untracked files."
        }
      ]
    , migrations = [] : List S.BlueprintMigration.Type
    , allowedTools = Some
      [ "Read"
      , "Write"
      , "Edit"
      , "Glob"
      , "Grep"
      , "Bash(seihou *)"
      , "Bash(nix *)"
      , "Bash(ls *)"
      , "Bash(cat *)"
      , "Bash(pwd)"
      , "Bash(find *)"
      , "Bash(cp *)"
      , "Bash(mv *)"
      , "Bash(mkdir *)"
      , "Bash(git status*)"
      , "Bash(git diff*)"
      , "Bash(git log*)"
      , "Bash(git add*)"
      , "Bash(git rev-parse*)"
      ]
    , tags =
      [ "haskell"
      , "nix"
      , "flake"
      , "flake-parts"
      , "seihou"
      , "migration"
      , "devshell"
      ]
    }
