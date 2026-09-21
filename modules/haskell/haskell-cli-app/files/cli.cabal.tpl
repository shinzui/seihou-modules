cabal-version: 3.4
name: {{project.name}}-cli
version: 0.1.0.0
synopsis: Command-line interface for {{project.name}}
description:
  {{#if IsSet project.description-long}}{{project.description-long}}{{#else}}{{project.name}}-cli provides the command-line interface for {{project.description}}{{/if}}

category: {{project.category}}, CLI
license: BSD-3-Clause
license-file: LICENSE
author: {{project.author}}
maintainer: {{project.maintainer}}
copyright: (c) {{project.copyright-year}} {{project.author}}
build-type: Simple
extra-doc-files: CHANGELOG.md

common common-options
  ghc-options:
    -Wall
    -Wcompat
    -Widentities
    -Wincomplete-uni-patterns
    -Wincomplete-record-updates
    -Wredundant-constraints
    -fhide-source-paths
    -Wmissing-export-lists
    -Wpartial-fields
    -Wmissing-deriving-strategies
    -Wunused-packages

  default-language: GHC2024
  default-extensions:
    DeriveAnyClass
    DuplicateRecordFields
    OverloadedLabels
    OverloadedStrings

library
  import: common-options
  hs-source-dirs: src
  exposed-modules:
    {{project.namespace}}.Cli

  build-depends:
    base >=4.20 && <5,
    optparse-applicative >=0.18 && <0.20,
    text ^>=2.1,

  build-depends:
    {{project.name}}-core ^>=0.1.0.0
{{#if Eq project.tests true}}

test-suite {{project.name}}-cli-test
  import: common-options
  type: exitcode-stdio-1.0
  hs-source-dirs: test
  main-is: Spec.hs
  ghc-options:
    -threaded
    -rtsopts
    -with-rtsopts=-N

  build-depends:
    base >=4.20 && <5,
    optparse-applicative >=0.18 && <0.20,
    tasty ^>=1.5,
    tasty-hunit ^>=0.10,
    text ^>=2.1,

  build-depends:
    {{project.name}}-cli ^>=0.1.0.0,
    {{project.name}}-core ^>=0.1.0.0,
{{/if}}

executable {{project.name}}
  import: common-options
  main-is: Main.hs
  hs-source-dirs: app
  ghc-options:
    -threaded
    -rtsopts
    -with-rtsopts=-N

  build-depends:
    base >=4.20 && <5

  build-depends:
    {{project.name}}-cli ^>=0.1.0.0
