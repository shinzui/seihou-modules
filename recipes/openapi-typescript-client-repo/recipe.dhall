{ name = "openapi-typescript-client-repo"
, version = Some "0.1.1"
, description = Some
    "Create <repo.parentDir>/<project.name>, generate an OpenAPI TypeScript client there, and initialize and push a matching GitHub repository under git.githubOwner. The initial commit includes the client and Nix scaffold."
, modules =
  [ { module = "openapi-typescript-client-dir", vars = [] : List { name : Text, value : Text } }
  ]
, vars = [] : List { name : Text, type : Text, default : Optional Text, description : Optional Text, required : Bool, validation : Optional Text }
, prompts = [] : List { var : Text, text : Text, when : Optional Text, choices : Optional (List Text) }
}
