{ name = "docs-microapp-labs"
, version = Some "0.1.0"
, description = Some "Documentation reader and protected Nagare configuration, without GitHub creation or live deployment"
, modules = [ { module = "docs-microapp", vars = [] : List { name : Text, value : Text } }, { module = "nagare-docs-config", vars = [] : List { name : Text, value : Text } } ]
, vars = [] : List { name : Text, type : Text, default : Optional Text, description : Optional Text, required : Bool, validation : Optional Text }
, prompts = [] : List { var : Text, text : Text, when : Optional Text, choices : Optional (List Text) }
}
