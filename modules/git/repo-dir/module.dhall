let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/b83079d377f22c77292ad5ccf88d1061a58f0c1c/package.dhall
        sha256:1d46697ed3e7ca1b0d9922020e2da034ae6e33f7b482ee454c68d94b536e8c2a

in  S.Module::{
    , name = "repo-dir"
    , version = Some "0.2.0"
    , description = Some
        "Create a new directory, optionally apply a scaffold there, then delegate initial commit and GitHub creation to git-init"
    , vars =
      [ S.VarDecl::{
        , default = Some "."
        , description = Some
            "Directory in which the new repo folder is created. Relative paths resolve against the directory `seihou run` is invoked from; a leading `~` expands to `\$HOME`. Created if missing. Can be set per context, e.g. `seihou config set repo.parentDir ~/Work --context work`."
        , name = "repo.parentDir"
        , required = True
        , type = "text"
        }
      , S.VarDecl::{
        , description = Some
            "Name of the new folder, which is also used as the GitHub repo name. Letters, digits, `.`, `_`, and `-` only."
        , name = "repo.name"
        , required = True
        , type = "text"
        , validation = Some "[A-Za-z0-9._-]+"
        }
      , S.VarDecl::{
        , description = Some
            "GitHub user or organization that will own the repo. Resolved through the normal config chain, so set it per context (`seihou config set git.githubOwner <value> --context <ctx>`) or globally (`--global`) and select the context with `--context`, `SEIHOU_CONTEXT`, `.seihou/context`, or `seihou context default`."
        , name = "git.githubOwner"
        , required = True
        , type = "text"
        , validation = Some "[A-Za-z0-9-]+"
        }
      , S.VarDecl::{
        , default = Some "private"
        , description = Some
            "Visibility of the GitHub repo: `private`, `public`, or `internal`. Defaults to `private`."
        , name = "git.githubVisibility"
        , required = True
        , type = "text"
        , validation = Some "private|public|internal"
        }
      , S.VarDecl::{
        , default = Some "master"
        , description = Some
            "Initial branch name forwarded to git-init. Not prompted; override with `--var` or config."
        , name = "git.defaultBranch"
        , required = True
        , type = "text"
        , validation = Some "[A-Za-z0-9._/-]+"
        }
      , S.VarDecl::{
        , description = Some
            "Slug of an organization team to grant access to the new repo (forwarded to git-init). Leave unset to skip. Best set per context: `seihou config set git.githubTeam <slug> --context <ctx>`."
        , name = "git.githubTeam"
        , required = False
        , type = "text"
        , validation = Some "[A-Za-z0-9._-]+"
        }
      , S.VarDecl::{
        , default = Some "push"
        , description = Some
            "Permission granted to `git.githubTeam`: `pull`, `triage`, `push`, `maintain`, or `admin`. Defaults to `push`."
        , name = "git.githubTeamPermission"
        , required = False
        , type = "text"
        , validation = Some "pull|triage|push|maintain|admin"
        }
      , S.VarDecl::{
        , name = "repo.scaffold"
        , type = "text"
        , required = False
        , default = None Text
        , description = Some
            "Optional module or recipe applied inside the new directory before git-init."
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "repo.source"
        , type = "text"
        , required = True
        , default = Some "https://github.com/shinzui/seihou-modules.git"
        , description = Some
            "Registry source used to acquire git-init and the optional child scaffold."
        , validation = None Text
        }
      , S.VarDecl::{
        , name = "repo.scaffoldBindings"
        , type = "text"
        , required = True
        , default = Some "{}"
        , description = Some
            "JSON object mapping omitted child inputs to resolved outer input names."
        }
      ]
    , prompts =
      [ S.Prompt::{
        , text = "Directory to create the repo in?"
        , var = "repo.parentDir"
        }
      , S.Prompt::{ text = "Folder / GitHub repo name?", var = "repo.name" }
      , S.Prompt::{
        , text =
            "GitHub user or organization? (tip: set per context with `seihou config set git.githubOwner <value> --context <ctx>`)"
        , var = "git.githubOwner"
        }
      , S.Prompt::{
        , choices = Some [ "private", "public", "internal" ]
        , text = "GitHub repo visibility?"
        , var = "git.githubVisibility"
        }
      , S.Prompt::{
        , text =
            "Organization team to grant access? (slug; tip: set per context with `seihou config set git.githubTeam <slug> --context <ctx>`)"
        , var = "git.githubTeam"
        }
      , S.Prompt::{
        , choices = Some [ "pull", "triage", "push", "maintain", "admin" ]
        , text = "Team permission?"
        , var = "git.githubTeamPermission"
        , when = Some "IsSet git.githubTeam"
        }
      ]
    , steps =
      [ S.Step::{
        , strategy = "copy"
        , src = "create-repo.py"
        , dest = ".seihou/repo-dir/create-repo.py"
        }
      ]
    , removal = Some S.Removal::{
      , steps =
        [ S.RemovalStep::{
          , action = "remove-file"
          , dest = ".seihou/repo-dir/create-repo.py"
          }
        ]
      }
    , commands =
      [ S.Command::{ run = "python3 .seihou/repo-dir/create-repo.py" } ]
    }
