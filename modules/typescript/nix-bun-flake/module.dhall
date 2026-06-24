let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/2b4035b7e720a9b30642a8a27551592175732ee5/package.dhall
        sha256:21716b4aee783d8eb8b12c754050880fa710e881ecda85925f855ef34cc34a55

in  S.Module::{
    , name = "nix-bun-flake"
    , version = Some "0.2.0"
    , description = Some "Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting (semicolon-free, sorted imports), a just task runner, and optional git-hooks.nix pre-commit checks"
    , vars =
      [ S.VarDecl::{
        , name = "project.name"
        , type = "text"
        , description = Some "Project name (used in flake description and package.json name)"
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
        , name = "nix.pre-commit"
        , type = "bool"
        , default = Some "true"
        , description = Some "Include pre-commit-hooks (git-hooks.nix) wiring oxlint and oxfmt --check as git hooks"
        , required = True
        }
      ]
    , exports =
      [ { var = "project.name", alias = None Text }
      , { var = "project.description", alias = None Text }
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
        , var = "nix.pre-commit"
        , text = "Include pre-commit hooks (oxlint + oxfmt) via git-hooks.nix?"
        }
      ]
    , steps =
      [ S.Step::{ strategy = "template", src = "flake.nix.tpl", dest = "flake.nix" }
      , S.Step::{ strategy = "copy", src = "flake.lock", dest = "flake.lock" }
      , S.Step::{ strategy = "template", src = "package.json.tpl", dest = "package.json" }
      , S.Step::{ strategy = "copy", src = "tsconfig.json", dest = "tsconfig.json" }
      , S.Step::{ strategy = "copy", src = "oxlintrc.json", dest = ".oxlintrc.json" }
      , S.Step::{ strategy = "copy", src = "oxfmtrc.json", dest = ".oxfmtrc.json" }
      , S.Step::{ strategy = "copy", src = "justfile", dest = "justfile" }
      , S.Step::{ strategy = "copy", src = "envrc", dest = ".envrc" }
      , S.Step::{
        , strategy = "template"
        , src = "gitignore-bun.tpl"
        , dest = ".gitignore"
        , patch = Some "append-line-if-absent"
        }
      , S.Step::{
        , strategy = "template"
        , src = "gitignore-precommit.tpl"
        , dest = ".gitignore"
        , when = Some "Eq nix.pre-commit true"
        , patch = Some "append-line-if-absent"
        }
      ]
    , removal = Some S.Removal::{
      , steps =
        [ S.RemovalStep::{ action = "remove-file", dest = "flake.nix" }
        , S.RemovalStep::{ action = "remove-file", dest = "flake.lock" }
        , S.RemovalStep::{ action = "remove-file", dest = "package.json" }
        , S.RemovalStep::{ action = "remove-file", dest = "tsconfig.json" }
        , S.RemovalStep::{ action = "remove-file", dest = ".oxlintrc.json" }
        , S.RemovalStep::{ action = "remove-file", dest = ".oxfmtrc.json" }
        , S.RemovalStep::{ action = "remove-file", dest = "justfile" }
        , S.RemovalStep::{ action = "remove-file", dest = ".envrc" }
        ]
      }
    }
