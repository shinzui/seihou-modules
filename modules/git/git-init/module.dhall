let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/b83079d377f22c77292ad5ccf88d1061a58f0c1c/package.dhall
        sha256:1d46697ed3e7ca1b0d9922020e2da034ae6e33f7b482ee454c68d94b536e8c2a

in  S.Module::{
    , name = "git-init"
    , version = Some "0.2.0"
    , description = Some
        "Initialize a local git repository (default branch master), append .claude/, .agents/, and .seihou/manifest.json.tmp to .gitignore, and optionally create a GitHub repo via `gh repo create` (defaults to private) under a configured org or username, optionally granting an organization team access to the new repo. The owner and team are read from the `git.githubOwner` and `git.githubTeam` variables, which are most useful when set per context or globally, e.g. `seihou config set git.githubOwner <org-or-user> --context <ctx>`."
    , vars =
      [ S.VarDecl::{
        , name = "git.defaultBranch"
        , type = "text"
        , default = Some "master"
        , description = Some
            "Initial branch name passed to `git init -b`. Defaults to master."
        , required = True
        , validation = Some "[A-Za-z0-9._/-]+"
        }
      , S.VarDecl::{
        , name = "git.initialCommit"
        , type = "bool"
        , default = Some "true"
        , description = Some
            "If true, stage everything currently in the project and create an `Initial commit` after `git init`."
        , required = False
        }
      , S.VarDecl::{
        , name = "git.createGithub"
        , type = "bool"
        , default = Some "false"
        , description = Some
            "If true, create a remote GitHub repository via `gh repo create` and push the initial commit. Requires the GitHub CLI (`gh`) to be installed and authenticated."
        , required = False
        }
      , S.VarDecl::{
        , name = "git.githubOwner"
        , type = "text"
        , description = Some
            "GitHub org or username under which the repo should be created. Required when `git.createGithub` is true. Recommended to set via `seihou config set git.githubOwner <value> --global` so it is reused across projects."
        , required = False
        }
      , S.VarDecl::{
        , name = "git.repoName"
        , type = "text"
        , description = Some
            "Name of the GitHub repo to create. Required when `git.createGithub` is true. Typically the same as the project name / current directory name."
        , required = False
        , validation = Some "[A-Za-z0-9._-]+"
        }
      , S.VarDecl::{
        , name = "git.githubVisibility"
        , type = "text"
        , default = Some "private"
        , description = Some
            "Visibility of the GitHub repo: `private`, `public`, or `internal`. Defaults to `private`. Only used when `git.createGithub` is true."
        , required = False
        , validation = Some "private|public|internal"
        }
      , S.VarDecl::{
        , name = "git.githubTeam"
        , type = "text"
        , description = Some
            "Slug of an organization team to grant access to the new repo (e.g. `tan-engineers`). Only valid when `git.githubOwner` is an organization. Leave unset to skip. Recommended to set per context: `seihou config set git.githubTeam <slug> --context <ctx>`."
        , required = False
        , validation = Some "[A-Za-z0-9._-]+"
        }
      , S.VarDecl::{
        , name = "git.githubTeamPermission"
        , type = "text"
        , default = Some "push"
        , description = Some
            "Permission granted to `git.githubTeam`: `pull`, `triage`, `push`, `maintain`, or `admin`. Defaults to `push`. Only used when `git.githubTeam` is set."
        , required = False
        , validation = Some "pull|triage|push|maintain|admin"
        }
      ]
    , prompts =
      [ S.Prompt::{
        , var = "git.defaultBranch"
        , text = "Initial git branch name?"
        }
      , S.Prompt::{
        , var = "git.initialCommit"
        , text = "Create an initial commit after `git init`?"
        }
      , S.Prompt::{
        , var = "git.createGithub"
        , text = "Create a GitHub repo with `gh repo create`?"
        }
      , S.Prompt::{
        , var = "git.githubOwner"
        , text =
            "GitHub org or username? (tip: set globally with `seihou config set git.githubOwner <value> --global`)"
        , when =
            Some "Eq git.createGithub true"
        }
      , S.Prompt::{
        , var = "git.repoName"
        , text = "GitHub repo name?"
        , when =
            Some "Eq git.createGithub true"
        }
      , S.Prompt::{
        , var = "git.githubVisibility"
        , text = "GitHub repo visibility?"
        , when =
            Some "Eq git.createGithub true"
        , choices = Some [ "private", "public", "internal" ]
        }
      , S.Prompt::{
        , var = "git.githubTeam"
        , text =
            "Organization team to grant access? (slug; tip: set per context with `seihou config set git.githubTeam <slug> --context <ctx>`)"
        , when =
            Some "Eq git.createGithub true"
        }
      , S.Prompt::{
        , var = "git.githubTeamPermission"
        , text = "Team permission?"
        , when =
            Some "Eq git.createGithub true && IsSet git.githubTeam"
        , choices = Some [ "pull", "triage", "push", "maintain", "admin" ]
        }
      ]
    , steps =
      [ S.Step::{
        , strategy = "template"
        , src = "gitignore.tpl"
        , dest = ".gitignore"
        , patch = Some "append-line-if-absent"
        }
      ]
    , commands =
      [ S.Command::{ run = "git init -b {{git.defaultBranch}}" }
      , S.Command::{
        , run =
            "git add -A && (git diff --cached --quiet || git -c commit.gpgsign=false commit -m 'Initial commit')"
        , when =
            Some "Eq git.initialCommit true"
        }
      , S.Command::{
        , run =
            "gh repo create {{git.githubOwner}}/{{git.repoName}} --private --source=. --remote=origin --push"
        , when =
            Some
              "Eq git.createGithub true && Eq git.githubVisibility \"private\""
        }
      , S.Command::{
        , run =
            "gh repo create {{git.githubOwner}}/{{git.repoName}} --public --source=. --remote=origin --push"
        , when =
            Some
              "Eq git.createGithub true && Eq git.githubVisibility \"public\""
        }
      , S.Command::{
        , run =
            "gh repo create {{git.githubOwner}}/{{git.repoName}} --internal --source=. --remote=origin --push"
        , when =
            Some
              "Eq git.createGithub true && Eq git.githubVisibility \"internal\""
        }
      , S.Command::{
        , run =
            "gh api -X PUT /orgs/{{git.githubOwner}}/teams/{{git.githubTeam}}/repos/{{git.githubOwner}}/{{git.repoName}} -f permission={{git.githubTeamPermission}} --silent"
        , when =
            Some "Eq git.createGithub true && IsSet git.githubTeam"
        }
      ]
    , removal = None S.Removal.Type
    }
