let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/e9f91438f081fba90f40f987de93df9f74c7117d/package.dhall
        sha256:00f822087302b53f7ffe74e6505a633c59a0c2f206d12bfadb58a2fe211c0e40

in  S.Module::{
    , name = "docs-mori-bootstrap"
    , version = Some "0.1.0"
    , description = Some
        "Seed a project-owned documentation manifest, associate its documented project and register locally with Mori"
    , vars =
      [ S.VarDecl::{
        , name = "project.name"
        , type = "text"
        , required = True
        , description = Some
            "Documentation project name (independent of the documented project)."
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "project.description"
        , type = "text"
        , required = True
        , description = Some "Description of the documentation project."
        }
      , S.VarDecl::{
        , name = "mori.namespace"
        , type = "text"
        , required = True
        , description = Some "Namespace of this documentation project."
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "mori.source-namespace"
        , type = "text"
        , required = True
        , description = Some
            "Namespace of the already registered project being documented."
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "mori.source-project"
        , type = "text"
        , required = True
        , description = Some
            "Name of the already registered project being documented."
        , validation = Some "[a-z][a-z0-9-]*"
        }
      ]
    , prompts =
      [ S.Prompt::{
        , var = "project.name"
        , text =
            "Documentation project name (independent of the documented project)."
        }
      , S.Prompt::{
        , var = "project.description"
        , text = "Description of the documentation project."
        }
      , S.Prompt::{
        , var = "mori.namespace"
        , text = "Namespace of this documentation project."
        }
      , S.Prompt::{
        , var = "mori.source-namespace"
        , text = "Namespace of the already registered project being documented."
        }
      , S.Prompt::{
        , var = "mori.source-project"
        , text = "Name of the already registered project being documented."
        }
      ]
    , steps =
      [ S.Step::{
        , strategy = "copy"
        , src = "bootstrap-docs.py"
        , dest = ".seihou/docs-mori-bootstrap/bootstrap-docs.py"
        }
      , S.Step::{
        , strategy = "template"
        , src = "project.name.conf.tpl"
        , dest = ".seihou/docs-mori-bootstrap/project.name.conf"
        }
      , S.Step::{
        , strategy = "template"
        , src = "project.description.conf.tpl"
        , dest = ".seihou/docs-mori-bootstrap/project.description.conf"
        }
      , S.Step::{
        , strategy = "template"
        , src = "mori.namespace.conf.tpl"
        , dest = ".seihou/docs-mori-bootstrap/mori.namespace.conf"
        }
      , S.Step::{
        , strategy = "template"
        , src = "mori.source-namespace.conf.tpl"
        , dest = ".seihou/docs-mori-bootstrap/mori.source-namespace.conf"
        }
      , S.Step::{
        , strategy = "template"
        , src = "mori.source-project.conf.tpl"
        , dest = ".seihou/docs-mori-bootstrap/mori.source-project.conf"
        }
      ]
    , commands =
      [ S.Command::{
        , action =
            S.Command.Action.Apply
              "python3 .seihou/docs-mori-bootstrap/bootstrap-docs.py"
        }
      ]
    , removal = Some S.Removal::{
      , steps =
        [ S.RemovalStep::{
          , action = "remove-file"
          , dest = ".seihou/docs-mori-bootstrap/bootstrap-docs.py"
          }
        , S.RemovalStep::{
          , action = "remove-file"
          , dest = ".seihou/docs-mori-bootstrap/project.name.conf"
          }
        , S.RemovalStep::{
          , action = "remove-file"
          , dest = ".seihou/docs-mori-bootstrap/project.description.conf"
          }
        , S.RemovalStep::{
          , action = "remove-file"
          , dest = ".seihou/docs-mori-bootstrap/mori.namespace.conf"
          }
        , S.RemovalStep::{
          , action = "remove-file"
          , dest = ".seihou/docs-mori-bootstrap/mori.source-namespace.conf"
          }
        , S.RemovalStep::{
          , action = "remove-file"
          , dest = ".seihou/docs-mori-bootstrap/mori.source-project.conf"
          }
        ]
      }
    }
