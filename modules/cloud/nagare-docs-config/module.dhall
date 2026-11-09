let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/e9f91438f081fba90f40f987de93df9f74c7117d/package.dhall
        sha256:00f822087302b53f7ffe74e6505a633c59a0c2f206d12bfadb58a2fe211c0e40

in S.Module::{
  , name = "nagare-docs-config"
  , version = Some "0.1.0"
  , description = Some "Project-owned protected Nagare Application config for an immutable documentation image; independent full domain and service name (Nagare 0.16.2)"
  , vars = [ S.VarDecl::{ name = "project.name", type = "text", required = True, validation = Some "[a-z][a-z0-9-]*" }
    , S.VarDecl::{ name = "nagare.service-name", type = "text", required = True, validation = Some "[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?" }
    , S.VarDecl::{ name = "nagare.namespace", type = "text", required = True, default = Some "personal", validation = Some "[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?" }
    , S.VarDecl::{ name = "nagare.domain", type = "text", required = True, validation = Some "[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?([.][a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+" }
  ]
  , steps = [ S.Step::{ strategy = "template", src = "nagare/Config.hs.tpl", dest = "nagare/Config.hs", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "nagare/README.md.tpl", dest = "nagare/README.md", lifecycle = Some "seed" }
  ]
}
