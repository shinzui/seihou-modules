{ name = "fumadocs-project"
, version = Some "0.1.0"
, description = Some
    "Container-enabled Fumadocs, technical writing skills from agent-seihou and local Mori registration"
, modules =
  [ { module = "fumadocs"
    , source = None Text
    , vars =
      [ { name = "docs.container", value = "true" }
      , { name = "nix.bun2nix", value = "true" }
      , { name = "nix.package-module", value = "nix/fumadocs-container.nix" }
      ]
    }
  , { module = "technical-docs"
    , source = Some "https://github.com/shinzui/agent-seihou.git"
    , vars = [] : List { name : Text, value : Text }
    }
  , { module = "docs-mori-bootstrap"
    , source = None Text
    , vars = [] : List { name : Text, value : Text }
    }
  ]
, vars =
    [] : List
           { name : Text
           , type : Text
           , default : Optional Text
           , description : Optional Text
           , required : Bool
           , validation : Optional Text
           }
, prompts =
    [] : List
           { var : Text
           , text : Text
           , when : Optional Text
           , choices : Optional (List Text)
           }
}
