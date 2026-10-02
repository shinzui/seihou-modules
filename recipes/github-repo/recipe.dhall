{ name = "github-repo"
, version = Some "0.1.0"
, description = Some
    "Create a new, empty project directory and turn it into a git repository with a matching GitHub repo. Prompts for the parent directory and the folder name, creates `<repo.parentDir>/<repo.name>`, and runs `git-init` inside it with `git.createGithub=true` and `git.repoName` bound to the folder name. The GitHub user or organization comes from `git.githubOwner`, so per-context config (`seihou config set git.githubOwner <org-or-user> --context <ctx>`) together with `--context` / `SEIHOU_CONTEXT` / `seihou context default` decides where the repo is created."
, modules =
  [ { module = "repo-dir", vars = [] : List { name : Text, value : Text } }
  ]
, vars = [] : List { name : Text, type : Text, default : Optional Text, description : Optional Text, required : Bool, validation : Optional Text }
, prompts = [] : List { var : Text, text : Text, when : Optional Text, choices : Optional (List Text) }
}
