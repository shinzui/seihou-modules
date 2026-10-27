cabal-version: 3.4
name: {{project.name}}-server
version: 0.1.0.0
synopsis: {{project.description}}
description: Initial server package for {{project.name}}; see docs/bootstrap-keiro.md.
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
    {{project.namespace}}.Server.App
  build-depends:
      base >=4.21 && <4.22
    , {{project.name}}-core ==0.1.0.0
    , {{project.name}}-api ==0.1.0.0
    , servant-health >=0.1.0.0 && <0.2
    , servant-server >=0.20.2 && <0.21
    , wai >=3.2 && <3.3

test-suite {{project.name}}-server-health
  import: warnings, shared
  type: exitcode-stdio-1.0
  hs-source-dirs: test
  main-is: HealthTest.hs
  ghc-options: -threaded -rtsopts -with-rtsopts=-N
  build-depends:
      base >=4.21 && <4.22
    , {{project.name}}-server ==0.1.0.0
    , servant-health:testkit >=0.1.0.0 && <0.2
    , tasty >=1.4 && <1.6
