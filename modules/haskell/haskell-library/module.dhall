let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/a0fba0d17b43b14bfdf6d0bf98f1b7ff7af4ebab/package.dhall
        sha256:36250d32d50cec0ea8c74926684ffb8b20f6d0b4f2152930dfa04a1ff108ef3f

in  S.Module::{
    , name = "haskell-library"
    , version = Some "0.1.0"
    , description = Some
        "Bootstrap a single-package Haskell library under GHC 9.12.4 / GHC2024, with lens + generic-lens, a BSD-3 license, the project author's standard warning set, and an optional tasty test-suite. Depends on nix-haskell-flake for the dev shell."
    , vars =
      [ S.VarDecl::{
        , name = "project.name"
        , type = "text"
        , description = Some
            "Project base name; cabal package and library are both named <name>. Re-declared here so step `dest` paths validate; the value is shared with `nix-haskell-flake` via the dependency graph."
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
            "Optional longer prose description used as the `description:` paragraph in the .cabal file. When not set, the template falls back to `project.description` (the one-line synopsis declared by nix-haskell-flake)."
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
        , description = Some "Author name written into LICENSE and the .cabal file"
        , required = True
        }
      , S.VarDecl::{
        , name = "project.maintainer"
        , type = "text"
        , default = Some "nadeem@gmail.com"
        , description = Some "Maintainer email written into the .cabal file"
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
      , S.VarDecl::{
        , name = "project.cabal-version"
        , type = "text"
        , default = Some "3.4"
        , description = Some
            "cabal-version emitted at the top of the generated .cabal file. Bump this when the template grows features that need a newer cabal."
        , required = True
        , validation = Some "[0-9]+(\\.[0-9]+)*"
        }
      , S.VarDecl::{
        , name = "project.tests"
        , type = "bool"
        , default = Some "true"
        , description = Some
            "When true, generate a tasty test-suite stanza (tasty + tasty-hunit) in the .cabal file plus a `test/Spec.hs` stub. When false, no test scaffolding is emitted and the consumer can add their own framework later."
        , required = True
        }
      ]
    , exports =
      [ { var = "project.name", alias = None Text }
      , { var = "project.namespace", alias = None Text }
      ]
    , prompts =
      [ S.Prompt::{
        , var = "project.name"
        , text = "What is your project name? (lowercase, hyphenated; the cabal package and library will both be named <name>)"
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
      , S.Prompt::{
        , var = "project.tests"
        , text = "Generate a tasty test-suite scaffold? (yes/no)"
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
        , src = "library.cabal.tpl"
        , dest = "{{project.name}}/{{project.name}}.cabal"
        }
      , S.Step::{
        , strategy = "template"
        , src = "src/Prelude.hs.tpl"
        , dest = "{{project.name}}/src/{{project.namespace}}/Prelude.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "src/Lib.hs.tpl"
        , dest = "{{project.name}}/src/{{project.namespace}}.hs"
        }
      , S.Step::{
        , strategy = "template"
        , src = "test/Spec.hs.tpl"
        , dest = "{{project.name}}/test/Spec.hs"
        , when = Some "Eq project.tests true"
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
