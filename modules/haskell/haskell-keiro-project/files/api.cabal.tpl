cabal-version: 3.4
name: {{project.name}}-api
version: 0.1.0.0
synopsis: {{project.description}}
description: Initial api package for {{project.name}}; see docs/bootstrap-keiro.md.
license: BSD-3-Clause
license-file: LICENSE
category: Web
author: {{project.author}}
maintainer: {{project.maintainer}}
copyright: {{project.copyright-year}} {{project.author}}
build-type: Simple

common warnings
  ghc-options:
    -Wall -Wcompat -Widentities -Wincomplete-record-updates
    -Wincomplete-uni-patterns -Wpartial-fields -Wredundant-constraints

common shared
  default-language: GHC2024
  default-extensions: DuplicateRecordFields NoFieldSelectors OverloadedRecordDot OverloadedStrings

library
  import: warnings, shared
  hs-source-dirs: src
  exposed-modules:
    {{project.namespace}}.Api
  build-depends:
      base >=4.21 && <4.22
    , {{project.name}}-core ==0.1.0.0
