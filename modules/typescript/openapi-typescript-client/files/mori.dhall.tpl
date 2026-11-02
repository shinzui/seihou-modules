-- Initial client inventory; keep it aligned with package.json and the OpenAPI source.
let Schema =
      https://raw.githubusercontent.com/shinzui/mori-schema/3522f4a51181d73c9c90fc27a7c0838bd29ae95f/package.dhall
        sha256:dcb19e2312e790bad14e622cc98a1281cd2298c5b564a2f0d0534d3c718d8803

let source = Schema.MoriRef::{
      , namespace = "{{mori.source-namespace}}", name = "{{mori.source-project}}"
      }

in Schema.Project::{
  , project = Schema.ProjectIdentity::{
    , name = "{{project.name}}", namespace = "{{mori.namespace}}"
    , type = Schema.PackageType.Client, language = Schema.Language.TypeScript
    , description = Some "{{project.name}} OpenAPI TypeScript client"
    , lifecycle = Schema.Lifecycle.Experimental
    }
  , repos = [ Schema.Repo::{ name = "{{project.name}}" } ]
  , packages = [ Schema.Package::{
    , name = "{{project.name}}"
    , type = Schema.PackageType.Client, language = Schema.Language.TypeScript
    , visibility = Schema.Visibility.Private
    , runtime = { deployable = False, exposesApi = False }
    , dependencies = [ Schema.Dependency.ByName "zod" ]
    , apiSource = Some Schema.ApiSource::{
      , project = "{{mori.source-namespace}}/{{mori.source-project}}"
      , projectRef = Some source
      }
    } ]
  , dependencies = [ "{{mori.source-namespace}}/{{mori.source-project}}" ]
  , dependencyRefs = [ source ]
  , docs = [ Schema.DocRef::{
    , key = "readme", kind = Schema.DocKind.Guide, audience = Schema.DocAudience.User
    , location = Schema.DocLocation.RepoPath "README.md"
    } ]
}
