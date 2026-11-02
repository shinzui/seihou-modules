let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/7d02695f5a716384ec2174a018c20ee680ab3d13/package.dhall
        sha256:5a24b98eada6628e3e7da267f4e6c31c1e169179d2bacd5fed7254fc4cc55183

in S.Module::{
    , name = "openapi-typescript-client"
    , version = Some "0.2.1"
    , description = Some "Generate a reusable ESM TypeScript 7 client with Orval, status-specific Zod response validation, strict schema qualification, and project-owned Bun workflows"
    , vars =
      [ S.VarDecl::{ name = "project.name", type = "text", required = True, validation = Some "[a-z][a-z0-9-]*" }
      , S.VarDecl::{ name = "project.description", type = "text", required = True }
      , S.VarDecl::{
        , name = "openapi.schema"
        , type = "text"
        , default = Some "openapi.yaml"
        , required = True
        , validation = Some "([A-Za-z0-9][A-Za-z0-9_-]*/)*[A-Za-z0-9][A-Za-z0-9_-]*[.](yaml|yml|json)"
        , description = Some "Local OpenAPI document. Custom paths must already exist; only the default openapi.yaml is seeded."
        }
      , S.VarDecl::{
        , name = "mori.generate", type = "bool", default = Some "false"
        , description = Some "Seed an initial mori.dhall describing the client and its OpenAPI source; does not register the project."
        }
      , S.VarDecl::{
        , name = "mori.namespace", type = "text"
        , validation = Some "[a-z][a-z0-9-]*"
        , description = Some "Client project's Mori namespace; required when mori.generate=true."
        }
      , S.VarDecl::{
        , name = "mori.source-namespace", type = "text"
        , validation = Some "[a-z][a-z0-9-]*"
        , description = Some "Mori namespace of the project providing the OpenAPI schema; required when mori.generate=true."
        }
      , S.VarDecl::{
        , name = "mori.source-project", type = "text"
        , validation = Some "[a-z][a-z0-9-]*"
        , description = Some "Mori project name of the API provider (without its namespace); required when mori.generate=true."
        }
      ]
    , prompts =
      [ S.Prompt::{ var = "mori.namespace", text = "Mori namespace for this client?", when = Some "Eq mori.generate true" }
      , S.Prompt::{ var = "mori.source-namespace", text = "Mori namespace of the OpenAPI source project?", when = Some "Eq mori.generate true" }
      , S.Prompt::{ var = "mori.source-project", text = "Mori project name of the OpenAPI provider (without namespace)?", when = Some "Eq mori.generate true" }
      ]
    , dependencies = [ S.Dependency::{
        , module = "nix-bun-flake"
        , vars = [ { name = "nix.package-module", value = "nix/openapi-typescript-client.nix" }
                 , { name = "nix.pre-commit", value = "false" }
                 , { name = "bun.starter-files", value = "false" }
                 ]
        } ]
    , steps = [ S.Step::{ strategy = "template", src = "package.json.tpl", dest = "package.json", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "tsconfig.json", dest = "tsconfig.json", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "tsconfig.build.json", dest = "tsconfig.build.json", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "justfile", dest = "justfile", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "oxlintrc.json", dest = ".oxlintrc.json", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "oxfmtrc.json", dest = ".oxfmtrc.json", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "orval.config.ts", dest = "orval.config.ts", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "redocly.yaml", dest = "redocly.yaml", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "src/index.ts", dest = "src/index.ts", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "src/client.ts", dest = "src/client.ts", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "src/transport.ts", dest = "src/transport.ts", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "scripts/compiler.ts", dest = "scripts/compiler.ts", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "scripts/schema.ts", dest = "scripts/schema.ts", lifecycle = Some "seed" }
      , S.Step::{ strategy = "template", src = "scripts/generate.ts.tpl", dest = "scripts/generate.ts", lifecycle = Some "seed" }
      , S.Step::{ strategy = "copy", src = "tests/client.test.ts", dest = "tests/client.test.ts", lifecycle = Some "seed", when = Some "Eq openapi.schema openapi.yaml" }
      , S.Step::{ strategy = "copy", src = "tests/types.ts", dest = "tests/types.ts", lifecycle = Some "seed", when = Some "Eq openapi.schema openapi.yaml" }
      , S.Step::{ strategy = "template", src = "README.md.tpl", dest = "README.md", lifecycle = Some "seed" }
      , S.Step::{ strategy = "template", src = "mori.dhall.tpl", dest = "mori.dhall", lifecycle = Some "seed", when = Some "Eq mori.generate true" }
      , S.Step::{ strategy = "copy", src = "openapi.yaml", dest = "openapi.yaml", lifecycle = Some "seed", when = Some "Eq openapi.schema openapi.yaml" }
      , S.Step::{ strategy = "copy", src = "nix/openapi-typescript-client.nix", dest = "nix/openapi-typescript-client.nix" }
      , S.Step::{ strategy = "copy", src = "gitignore-client", dest = ".gitignore", patch = Some "append-line-if-absent" } ]
    , removal = Some S.Removal::{ steps = [ S.RemovalStep::{ action = "remove-file", dest = "nix/openapi-typescript-client.nix" } ] }
    }
