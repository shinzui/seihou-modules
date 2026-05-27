let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/b83079d377f22c77292ad5ccf88d1061a58f0c1c/package.dhall
        sha256:1d46697ed3e7ca1b0d9922020e2da034ae6e33f7b482ee454c68d94b536e8c2a

in  S.Module::{
    , name = "haskell-cli-app"
    , version = Some "0.2.0"
    , description = Some
        "Bootstrap a Haskell CLI app as two packages (core library + CLI exe) under GHC 9.12.4 / GHC2024, with lens + generic-lens, a BSD-3 license, and the project author's standard warning set. Depends on nix-haskell-flake for the dev shell."
    , vars =
      [ S.VarDecl::{
        , name = "project.name"
        , type = "text"
        , description = Some
            "Project base name; cabal packages are named <name>-core and <name>-cli, the executable is named <name>. Re-declared here so step `dest` paths validate; the value is shared with `nix-haskell-flake` via the dependency graph."
        , required = True
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "project.description"
        , type = "text"
        , description = Some
            "One-line synopsis. Re-declared here so this module's templates can interpolate it; the value is shared with `nix-haskell-flake` (which uses it as the flake description) via the dependency graph."
        , required = True
        }
      , S.VarDecl::{
        , name = "project.description-long"
        , type = "text"
        , description = Some
            "Optional longer prose description used as the `description:` paragraph in both .cabal files. When not set, the templates fall back to `project.description` (the one-line synopsis declared by nix-haskell-flake)."
        , required = False
        }
      , S.VarDecl::{
        , name = "project.namespace"
        , type = "text"
        , description = Some
            "Top-level Haskell module namespace (single segment, e.g. Rei). Used both as the source-tree directory and as the module prefix in generated .hs files."
        , required = True
        , validation = Some "[A-Z][A-Za-z0-9]*"
        }
      , S.VarDecl::{
        , name = "project.author"
        , type = "text"
        , default = Some "Nadeem Bitar"
        , description = Some "Author name written into LICENSE and .cabal files"
        , required = True
        }
      , S.VarDecl::{
        , name = "project.maintainer"
        , type = "text"
        , default = Some "nadeem@gmail.com"
        , description = Some "Maintainer email written into .cabal files"
        , required = True
        }
      , S.VarDecl::{
        , name = "project.copyright-year"
        , type = "text"
        , default = Some "2026"
        , description = Some "Copyright year written into LICENSE"
        , required = True
        , validation = Some "[0-9]{4}"
        }
      ]
    , exports =
      [ { var = "project.name", alias = None Text }
      , { var = "project.namespace", alias = None Text }
      ]
    , prompts =
      [ S.Prompt::{
        , var = "project.name"
        , text = "What is your project name? (lowercase, hyphenated; cabal packages will be <name>-core and <name>-cli)"
        }
      , S.Prompt::{
        , var = "project.description"
        , text = "One-line project synopsis (used as cabal `synopsis:` and the flake description):"
        }
      , S.Prompt::{
        , var = "project.description-long"
        , text = "Longer project description (optional; press Enter to reuse the one-line synopsis):"
        }
      , S.Prompt::{
        , var = "project.namespace"
        , text = "Top-level Haskell module namespace? (single PascalCase segment, e.g. Rei)"
        }
      , S.Prompt::{
        , var = "project.author"
        , text = "Author name?"
        }
      , S.Prompt::{
        , var = "project.maintainer"
        , text = "Maintainer email?"
        }
      , S.Prompt::{
        , var = "project.copyright-year"
        , text = "Copyright year?"
        }
      ]
    , dependencies =
      [ S.Dependency::{
        , module = "nix-haskell-flake"
        , vars = [] : List { name : Text, value : Text }
        }
      ]
    , steps =
      [ S.Step::{
        , strategy = "template"
        , src = "cabal.project.tpl"
        , dest = "cabal.project"
        }
      , S.Step::{
        , strategy = "template"
        , src = "core.cabal.tpl"
        , dest = "{{project.name}}-core/{{project.name}}-core.cabal"
        }
      , S.Step::{
        , strategy = "template"
        , src = "core/Prelude.hs.tpl"
        , dest = "{{project.name}}-core/src/{{project.namespace}}/Prelude.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "cli.cabal.tpl"
        , dest = "{{project.name}}-cli/{{project.name}}-cli.cabal"
        }
      , S.Step::{
        , strategy = "template"
        , src = "cli/Main.hs.tpl"
        , dest = "{{project.name}}-cli/app/Main.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "cli/Cli.hs.tpl"
        , dest = "{{project.name}}-cli/src/{{project.namespace}}/Cli.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "LICENSE.tpl"
        , dest = "LICENSE"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "fourmolu.yaml"
        , dest = "fourmolu.yaml"
        }
      , S.Step::{
        , strategy = "template"
        , src = "CHANGELOG.md.tpl"
        , dest = "CHANGELOG.md"
        }
      , S.Step::{
        , strategy = "template"
        , src = "README.md.tpl"
        , dest = "README.md"
        }
      ]
    }
