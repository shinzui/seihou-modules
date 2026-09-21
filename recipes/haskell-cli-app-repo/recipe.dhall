{ name = "haskell-cli-app-repo"
, version = Some "0.1.0"
, description = Some
    "Bootstrap a tested two-package Haskell CLI app (reusable core library + CLI executable) in a fresh git repository. Composes `haskell-cli-app` (which pulls in the latest `nix-haskell-flake` for GHC 9.12.4/9.14.1 shells and workspace package/check outputs) with `git-init`; seihou's planner runs all file generation before any commands, so the resulting `git init` + initial commit captures the full scaffold in one shot. When `git.createGithub` is true, git-init will also prompt for `git.repoName` and push to GitHub via `gh repo create` — typically you'd answer with the same value as `project.name`."
, modules =
  [ { module = "haskell-cli-app", vars = [] : List { name : Text, value : Text } }
  , { module = "git-init", vars = [] : List { name : Text, value : Text } }
  ]
, vars = [] : List { name : Text, type : Text, default : Optional Text, description : Optional Text, required : Bool, validation : Optional Text }
, prompts = [] : List { var : Text, text : Text, when : Optional Text, choices : Optional (List Text) }
}
