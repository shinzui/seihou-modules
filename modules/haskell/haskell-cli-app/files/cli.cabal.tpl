cabal-version: 3.4
name: {{project.name}}-cli
version: 0.1.0.0
synopsis: Command-line interface for {{project.name}}
description:
  {{project.description-long}}

license: BSD-3-Clause
license-file: ../LICENSE
author: {{project.author}}
maintainer: {{project.maintainer}}
copyright: (c) {{project.copyright-year}} {{project.author}}
build-type: Simple
extra-doc-files: ../CHANGELOG.md

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
    {{project.name}}-core,
    generic-lens,
    lens ^>=5.3,
    optparse-applicative >=0.18,
    text ^>=2.1,

executable {{project.name}}
  import: common-options
  main-is: Main.hs
  hs-source-dirs: app
  ghc-options:
    -threaded
    -rtsopts
    -with-rtsopts=-N

  build-depends:
    base >=4.20 && <5,
    {{project.name}}-cli,
