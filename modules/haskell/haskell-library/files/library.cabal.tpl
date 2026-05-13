cabal-version: {{project.cabal-version}}
name: {{project.name}}
version: 0.1.0.0
synopsis: {{project.description}}
description:
  {{#if IsSet project.description-long}}{{project.description-long}}{{#else}}{{project.description}}{{/if}}

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
    {{project.namespace}}
    {{project.namespace}}.Prelude

  build-depends:
    base >=4.20 && <5,
    generic-lens,
    lens ^>=5.3,
    text ^>=2.1,
{{#if Eq project.tests true}}

test-suite {{project.name}}-test
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
    {{project.name}},
    tasty ^>=1.5,
    tasty-hunit ^>=0.10,
    text ^>=2.1,
{{/if}}
