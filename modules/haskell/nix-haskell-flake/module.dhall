let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/2b4035b7e720a9b30642a8a27551592175732ee5/package.dhall
        sha256:21716b4aee783d8eb8b12c754050880fa710e881ecda85925f855ef34cc34a55

in  S.Module::{
    , name = "nix-haskell-flake"
    , version = Some "0.9.0"
    , description = Some "Nix flake for Haskell projects with toggleable process-compose, PostgreSQL, treefmt-nix, and pre-commit-hooks"
    , vars =
      [ S.VarDecl::{
        , name = "project.name"
        , type = "text"
        , description = Some "Project name (used in flake description and database name)"
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
        , description = Some "GHC version identifier for haskell.packages.<version> (e.g. ghc9124 pins GHC 9.12.4 exactly; ghc912 tracks the latest 9.12.x in the locked nixpkgs)"
        , required = True
        , validation = Some "ghc[0-9]+"
        }
      , S.VarDecl::{
        , name = "nix.process-compose"
        , type = "bool"
        , description = Some "Include process-compose in devShell and generate process-compose.yaml"
        , required = True
        }
      , S.VarDecl::{
        , name = "nix.postgresql"
        , type = "bool"
        , description = Some "Include postgresql in devShell with local DB setup in shellHook"
        , required = True
        }
      , S.VarDecl::{
        , name = "nix.treefmt"
        , type = "bool"
        , default = Some "true"
        , description = Some "Include treefmt-nix input and generate treefmt.nix"
        , required = True
        }
      , S.VarDecl::{
        , name = "nix.pre-commit"
        , type = "bool"
        , default = Some "true"
        , description = Some "Include pre-commit-hooks (git-hooks.nix) input and checks"
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
        , text = "Which GHC version?"
        , choices = Some [ "ghc9124", "ghc984", "ghc966" ]
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
        , text = "Include treefmt-nix for code formatting (fourmolu, nixpkgs-fmt, cabal-fmt)?"
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
        , strategy = "copy"
        , src = "flake.lock"
        , dest = "flake.lock"
        }
      , S.Step::{
        , strategy = "template"
        , src = "treefmt.nix.tpl"
        , dest = "treefmt.nix"
        , when = Some "Eq nix.treefmt true || Eq nix.treefmt \"true\""
        }
      , S.Step::{
        , strategy = "template"
        , src = "process-compose.yaml.tpl"
        , dest = "process-compose.yaml"
        , when = Some "Eq nix.process-compose true || Eq nix.process-compose \"true\""
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
