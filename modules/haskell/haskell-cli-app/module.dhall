let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/2b4035b7e720a9b30642a8a27551592175732ee5/package.dhall
        sha256:21716b4aee783d8eb8b12c754050880fa710e881ecda85925f855ef34cc34a55

in  S.Module::{
    , name = "haskell-cli-app"
    , version = Some "0.3.0"
    , description = Some
        "Bootstrap a tested two-package Haskell CLI app (reusable core library + CLI executable) under GHC2024, with GHC 9.12.4 as the HLS-backed default and GHC 9.14.1 as a secondary build shell. Generates valid package-local distribution metadata and workspace-aware Nix package/check outputs on the latest nix-haskell-flake."
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
        , name = "project.category"
        , type = "text"
        , default = Some "Development"
        , description = Some
            "Hackage category written into both generated .cabal files"
        , required = True
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
      , S.VarDecl::{
        , name = "project.tests"
        , type = "bool"
        , default = Some "true"
        , description = Some
            "Whether to generate the tasty suite that tests core behavior and pure CLI parsing"
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
        , var = "project.category"
        , text = "Hackage category?"
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
        , text = "Generate the tasty test-suite scaffold? (yes/no)"
        }
      ]
    , dependencies =
      [ S.Dependency::{
        , module = "nix-haskell-flake"
        , vars =
          [ { name = "nix.builtin-package", value = "false" }
          , { name = "ghc.secondary", value = "ghc9141" }
          , { name = "nix.package-module", value = "nix/haskell-cli-app.nix" }
          ]
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
        , src = "core/Lib.hs.tpl"
        , dest = "{{project.name}}-core/src/{{project.namespace}}.hs"
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
        , src = "cli/Spec.hs.tpl"
        , dest = "{{project.name}}-cli/test/Spec.hs"
        , when = Some "Eq project.tests true"
        }
      , S.Step::{
        , strategy = "template"
        , src = "nix/haskell-cli-app.nix.tpl"
        , dest = "nix/haskell-cli-app.nix"
        }
      , S.Step::{
        , strategy = "template"
        , src = "LICENSE.tpl"
        , dest = "LICENSE"
        }
      , S.Step::{
        , strategy = "template"
        , src = "LICENSE.tpl"
        , dest = "{{project.name}}-core/LICENSE"
        }
      , S.Step::{
        , strategy = "template"
        , src = "LICENSE.tpl"
        , dest = "{{project.name}}-cli/LICENSE"
        }
      , S.Step::{
        , strategy = "template"
        , src = "CHANGELOG.md.tpl"
        , dest = "CHANGELOG.md"
        }
      , S.Step::{
        , strategy = "template"
        , src = "CHANGELOG.md.tpl"
        , dest = "{{project.name}}-core/CHANGELOG.md"
        }
      , S.Step::{
        , strategy = "template"
        , src = "CHANGELOG.md.tpl"
        , dest = "{{project.name}}-cli/CHANGELOG.md"
        }
      , S.Step::{
        , strategy = "template"
        , src = "README.md.tpl"
        , dest = "README.md"
        }
      ]
    }
