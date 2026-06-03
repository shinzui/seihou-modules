let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/2b4035b7e720a9b30642a8a27551592175732ee5/package.dhall
        sha256:21716b4aee783d8eb8b12c754050880fa710e881ecda85925f855ef34cc34a55

-- Migration op union, matching the seihou engine's migration decoder. The pinned
-- seihou-schema (2b4035b) predates the `migrations` field, so we splice it onto
-- the completed `S.Module::{…}` record with `//` below. The engine decodes a
-- `migrations` field when present and defaults it to `[]` otherwise.
let MigrationOp =
      < MoveFile : { src : Text, dest : Text }
      | MoveDir : { src : Text, dest : Text }
      | DeleteFile : { path : Text }
      | DeleteDir : { path : Text }
      | RunCommand : { run : Text, workDir : Optional Text }
      >

in      S.Module::{
        , name = "nix-haskell-flake"
        , version = Some "0.11.0"
        , description = Some
            "Modular flake-parts Nix flake for Haskell projects, consuming the haskell-nix-dev base flake (shared nixpkgs lock, prebuilt GHC/HLS/cabal toolchains). Project wiring lives in imported nix/*.nix modules and user customizations go in an unmanaged flake.module.nix, so template upgrades migrate without conflict. Toggleable process-compose, PostgreSQL, treefmt-nix, and pre-commit-hooks."
        , vars =
          [ S.VarDecl::{
            , name = "project.name"
            , type = "text"
            , description = Some
                "Project name (used in flake description and database name)"
            , required = True
            , validation = Some "[a-z][a-z0-9-]*"
            }
          , S.VarDecl::{
            , name = "project.description"
            , type = "text"
            , description = Some "One-line project description"
            , required = True
            }
          , S.VarDecl::{
            , name = "ghc.version"
            , type = "text"
            , default = Some "ghc9124"
            , description = Some
                "Default/primary GHC for the generated project's `nix develop` shell. Must be a GHC attribute the haskell-nix-dev base flake supports (currently ghc9124 = GHC 9.12.4). Exported for dependent modules (e.g. haskell-library)."
            , required = True
            , validation = Some "ghc[0-9]+"
            }
          , S.VarDecl::{
            , name = "ghc.secondary"
            , type = "text"
            , description = Some
                "Optional second GHC attribute to expose as a named devShell (`nix develop .#<attr>`) alongside ghc.version, for cross-version testing. Must also be supported by the haskell-nix-dev base flake. Leave unset for a single-version project. (The engine has no list iteration, so exactly one extra version is supported here; use the dhall-text strategy if you need more.)"
            , required = False
            }
          , S.VarDecl::{
            , name = "nix.process-compose"
            , type = "bool"
            , description = Some
                "Include process-compose in the dev shell and generate process-compose.yaml"
            , required = True
            }
          , S.VarDecl::{
            , name = "nix.postgresql"
            , type = "bool"
            , description = Some
                "Include postgresql (and jq) in the dev shell with local DB setup in the shellHook"
            , required = True
            }
          , S.VarDecl::{
            , name = "nix.treefmt"
            , type = "bool"
            , default = Some "true"
            , description = Some
                "Include treefmt-nix and generate the nix/treefmt.nix flake-parts module (wires `nix fmt` and a formatting check)"
            , required = True
            }
          , S.VarDecl::{
            , name = "nix.pre-commit"
            , type = "bool"
            , default = Some "true"
            , description = Some
                "Include git-hooks.nix and generate the nix/pre-commit.nix flake-parts module"
            , required = True
            }
          ]
        , exports =
          [ { var = "project.name", alias = None Text }
          , { var = "ghc.version", alias = None Text }
          ]
        , prompts =
          [ S.Prompt::{
            , var = "project.name"
            , text = "What is your project name?"
            }
          , S.Prompt::{
            , var = "project.description"
            , text = "Describe your project in one line:"
            }
          , S.Prompt::{
            , var = "ghc.version"
            , text =
                "Which GHC version? (must be supported by the haskell-nix-dev base flake)"
            , choices = Some [ "ghc9124" ]
            }
          , S.Prompt::{
            , var = "nix.process-compose"
            , text = "Include process-compose for service orchestration?"
            }
          , S.Prompt::{
            , var = "nix.postgresql"
            , text = "Include PostgreSQL with local database setup?"
            }
          , S.Prompt::{
            , var = "nix.treefmt"
            , text =
                "Include treefmt-nix for code formatting (fourmolu, nixpkgs-fmt, cabal-fmt)?"
            }
          , S.Prompt::{
            , var = "nix.pre-commit"
            , text = "Include pre-commit hooks via git-hooks.nix?"
            }
          ]
        , steps =
          [ S.Step::{
            , strategy = "template"
            , src = "flake.nix.tpl"
            , dest = "flake.nix"
            }
          , S.Step::{
            , strategy = "template"
            , src = "nix/haskell.nix.tpl"
            , dest = "nix/haskell.nix"
            }
          , S.Step::{
            , strategy = "template"
            , src = "nix/treefmt.nix.tpl"
            , dest = "nix/treefmt.nix"
            , when = Some "Eq nix.treefmt true || Eq nix.treefmt \"true\""
            }
          , S.Step::{
            , strategy = "template"
            , src = "nix/pre-commit.nix.tpl"
            , dest = "nix/pre-commit.nix"
            , when = Some "Eq nix.pre-commit true || Eq nix.pre-commit \"true\""
            }
          , S.Step::{
            , strategy = "template"
            , src = "flake.module.nix.example.tpl"
            , dest = "flake.module.nix.example"
            }
          , S.Step::{
            , strategy = "copy"
            , src = "flake.lock"
            , dest = "flake.lock"
            }
          , S.Step::{
            , strategy = "template"
            , src = "process-compose.yaml.tpl"
            , dest = "process-compose.yaml"
            , when = Some
                "Eq nix.process-compose true || Eq nix.process-compose \"true\""
            }
          , S.Step::{
            , strategy = "template"
            , src = "envrc.tpl"
            , dest = ".envrc"
            }
          , S.Step::{
            , strategy = "template"
            , src = "gitignore-envrc.tpl"
            , dest = ".gitignore"
            , patch = Some "append-line-if-absent"
            }
          , S.Step::{
            , strategy = "template"
            , src = "gitignore-haskell.tpl"
            , dest = ".gitignore"
            , patch = Some "append-line-if-absent"
            }
          , S.Step::{
            , strategy = "template"
            , src = "gitignore-precommit.tpl"
            , dest = ".gitignore"
            , when = Some "Eq nix.pre-commit true || Eq nix.pre-commit \"true\""
            , patch = Some "append-line-if-absent"
            }
          ]
        }
    //  { migrations =
          [ { from = "0.10.0"
            , to = "0.11.0"
            , ops =
              -- The flake-parts rewrite (0.11.0) moves treefmt config from a
              -- top-level treefmt.nix into nix/treefmt.nix. The new files are
              -- (re)generated by `seihou run`; here we only retire the orphaned
              -- top-level treefmt.nix. DeleteFile is a no-op when it is absent
              -- (e.g. projects that never enabled treefmt).
              [ MigrationOp.DeleteFile { path = "treefmt.nix" } ]
            }
          ]
        }
