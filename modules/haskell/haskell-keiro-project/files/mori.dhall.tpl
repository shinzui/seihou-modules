-- Initial core dependency inventory. Excludes compiler base, test components and self edges.
-- Update core package relationships alongside Cabal when implementing the domain.
-- Tooling is separate: mori://shinzui/hurl-workbench and mori://shinzui/hinagata.
let Schema = https://raw.githubusercontent.com/shinzui/mori-schema/3522f4a51181d73c9c90fc27a7c0838bd29ae95f/package.dhall
      sha256:dcb19e2312e790bad14e622cc98a1281cd2298c5b564a2f0d0534d3c718d8803

let dep = \(name : Text) -> \(scope : Schema.DependencyScope) -> \(source : Schema.DependencySource) -> \(bounds : Text) ->
      Schema.Dependency.WithAugmentation
        { name = name, extraDocs = [] : List Schema.DocRef.Type
        , localPathOverride = None Text, kind = None Schema.DependencyKind
        , source = Some source
        , scope = Some scope, versionConstraint = Some bounds
        }

in Schema.Project::{
  , project = Schema.ProjectIdentity::{
    , name = "{{project.name}}", namespace = "{{mori.namespace}}"
    , description = Some "{{project.description}}"
    , language = Schema.Language.Haskell
    , type = Schema.PackageType.Application
    , lifecycle = Schema.Lifecycle.Experimental
    }
  , repos = [ Schema.Repo::{ name = "{{project.name}}", localPath = Some "." } ]
  , packages =
    [ Schema.Package::{
      , name = "{{project.name}}-core", path = Some "{{project.name}}-core"
      , type = Schema.PackageType.Library, language = Schema.Language.Haskell
      , dependencies =
        [ dep "ekmett/lens:lens" Schema.DependencyScope.Regular Schema.DependencySource.Hackage ">=5.3 && <5.4"
        ]
      }
    , Schema.Package::{
      , name = "{{project.name}}-api", path = Some "{{project.name}}-api"
      , type = Schema.PackageType.Library, language = Schema.Language.Haskell
      , dependencies =
        [ dep "ekmett/lens:lens" Schema.DependencyScope.Regular Schema.DependencySource.Hackage ">=5.3 && <5.4"
        , dep "haskell-servant/servant:servant" Schema.DependencyScope.Regular Schema.DependencySource.Hackage ">=0.20.2 && <0.21"
        , dep "haskell/aeson:aeson" Schema.DependencyScope.Regular Schema.DependencySource.Hackage ">=2.2 && <2.4"
        , dep "haskell/bytestring:bytestring" Schema.DependencyScope.Regular Schema.DependencySource.Hackage ">=0.12 && <0.13"
        , dep "shinzui/openapi-hs:openapi-hs" Schema.DependencyScope.Regular Schema.DependencySource.Hackage ">=5.0 && <5.1"
        , dep "shinzui/servant-health:servant-health" Schema.DependencyScope.Regular Schema.DependencySource.Hackage ">=0.1.0.0 && <0.2"
        , dep "shinzui/servant-openapi-hs:servant-openapi-hs" Schema.DependencyScope.Regular Schema.DependencySource.Hackage ">=5.1 && <5.2"
        , dep "{{project.name}}-core" Schema.DependencyScope.Regular Schema.DependencySource.Local "==0.1.0.0"
        ]
      }
    , Schema.Package::{
      , name = "{{project.name}}-workers", path = Some "{{project.name}}-workers"
      , type = Schema.PackageType.Library, language = Schema.Language.Haskell
      , dependencies =
        [ dep "{{project.name}}-core" Schema.DependencyScope.Regular Schema.DependencySource.Local "==0.1.0.0"
        ]
      }
    , Schema.Package::{
      , name = "{{project.name}}-client", path = Some "{{project.name}}-client"
      , type = Schema.PackageType.Library, language = Schema.Language.Haskell
      , dependencies =
        [ dep "{{project.name}}-api" Schema.DependencyScope.Regular Schema.DependencySource.Local "==0.1.0.0"
        ]
      }
    , Schema.Package::{
      , name = "{{project.name}}-migrations", path = Some "{{project.name}}-migrations"
      , type = Schema.PackageType.Library, language = Schema.Language.Haskell
      }
    , Schema.Package::{
      , name = "{{project.name}}-server", path = Some "{{project.name}}-server"
      , type = Schema.PackageType.Library, language = Schema.Language.Haskell
      , dependencies =
        [ dep "haskell-servant/servant:servant-server" Schema.DependencyScope.Regular Schema.DependencySource.Hackage ">=0.20.2 && <0.21"
        , dep "shinzui/servant-health:servant-health" Schema.DependencyScope.Regular Schema.DependencySource.Hackage ">=0.1.0.0 && <0.2"
        , dep "yesodweb/wai:wai" Schema.DependencyScope.Regular Schema.DependencySource.Hackage ">=3.2 && <3.3"
        , dep "{{project.name}}-api" Schema.DependencyScope.Regular Schema.DependencySource.Local "==0.1.0.0"
        , dep "{{project.name}}-core" Schema.DependencyScope.Regular Schema.DependencySource.Local "==0.1.0.0"
        ]
      }
    ]
  , dependencyRefs =
    [ Schema.MoriRef::{ namespace = "ekmett", name = "lens", kind = Some Schema.MoriArtifactKind.Package, key = Some "lens" }
    , Schema.MoriRef::{ namespace = "haskell", name = "aeson", kind = Some Schema.MoriArtifactKind.Package, key = Some "aeson" }
    , Schema.MoriRef::{ namespace = "haskell", name = "bytestring", kind = Some Schema.MoriArtifactKind.Package, key = Some "bytestring" }
    , Schema.MoriRef::{ namespace = "haskell-servant", name = "servant", kind = Some Schema.MoriArtifactKind.Package, key = Some "servant" }
    , Schema.MoriRef::{ namespace = "haskell-servant", name = "servant", kind = Some Schema.MoriArtifactKind.Package, key = Some "servant-server" }
    , Schema.MoriRef::{ namespace = "shinzui", name = "openapi-hs", kind = Some Schema.MoriArtifactKind.Package, key = Some "openapi-hs" }
    , Schema.MoriRef::{ namespace = "shinzui", name = "servant-health", kind = Some Schema.MoriArtifactKind.Package, key = Some "servant-health" }
    , Schema.MoriRef::{ namespace = "shinzui", name = "servant-openapi-hs", kind = Some Schema.MoriArtifactKind.Package, key = Some "servant-openapi-hs" }
    , Schema.MoriRef::{ namespace = "yesodweb", name = "wai", kind = Some Schema.MoriArtifactKind.Package, key = Some "wai" }
    ]
  , okfBundles = {{mori.okf-bundles}}
  , apis = [ Schema.Api::{
    , name = "{{project.name}}-api", type = Schema.ApiType.OpenAPI
    , specPath = "docs/openapi.json", owner = "{{project.name}}-api"
    , ownerRef = Some Schema.MoriRef::{
      , namespace = "{{mori.namespace}}", name = "{{project.name}}"
      , kind = Some Schema.MoriArtifactKind.Package, key = Some "{{project.name}}-api"
      }
    } ]
}
