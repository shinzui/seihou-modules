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
    {{project.namespace}}.Api.OpenApi
  build-depends:
      base >=4.21 && <4.22
    , {{project.name}}-core ==0.1.0.0
    , servant >=0.20.2 && <0.21
    , servant-health >=0.1.0.0 && <0.2
    , openapi-hs >=5.0 && <5.1
    , servant-openapi-hs >=5.1 && <5.2
    , lens >=5.3 && <5.4

executable {{project.name}}-openapi
  import: warnings, shared
  hs-source-dirs: app
  main-is: OpenApiMain.hs
  build-depends:
      base >=4.21 && <4.22
    , {{project.name}}-api ==0.1.0.0
    , aeson >=2.2 && <2.4
    , bytestring >=0.12 && <0.13

test-suite {{project.name}}-api-openapi
  import: warnings, shared
  type: exitcode-stdio-1.0
  hs-source-dirs: test
  main-is: OpenApiTest.hs
  build-depends:
      base >=4.21 && <4.22
    , {{project.name}}-api ==0.1.0.0
    , aeson >=2.2 && <2.4
    , openapi-hs >=5.0 && <5.1
    , tasty >=1.4 && <1.6
    , tasty-hunit >=0.10 && <0.11
