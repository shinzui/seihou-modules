let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/b83079d377f22c77292ad5ccf88d1061a58f0c1c/package.dhall
        sha256:1d46697ed3e7ca1b0d9922020e2da034ae6e33f7b482ee454c68d94b536e8c2a

let target =
      ''
      set -eu
      parent='{{repo.parentDir}}'
      name='{{repo.name}}'
      owner='{{git.githubOwner}}'
      case "$name" in
        ""|.|..|*[!A-Za-z0-9._-]*) echo "repo-dir: invalid repo.name '$name' (use letters, digits, '.', '_', '-')" >&2; exit 1 ;;
      esac
      case "$owner" in
        ""|*[!A-Za-z0-9-]*) echo "repo-dir: invalid git.githubOwner '$owner'" >&2; exit 1 ;;
      esac
      case "$parent" in
        "~") parent="$HOME" ;;
        "~/"*) parent="$HOME/''${parent#"~/"}" ;;
      esac
      target="$parent/$name"
      ''

let prepare =
          target
      ++  ''
          if [ -e "$target" ] && [ -n "$(ls -A "$target" 2>/dev/null || echo x)" ]; then
            echo "repo-dir: $target already exists and is not an empty directory" >&2
            exit 1
          fi
          mkdir -p "$target"
          ''

let gitInit =
      \(extraVars : Text) ->
            target
        ++  ''
            cd "$target"
            seihou run git-init --no-save-prompted \
              --var git.defaultBranch='{{git.defaultBranch}}' \
              --var git.initialCommit=true \
              --var git.createGithub=true \
              --var git.githubOwner="$owner" \
              --var git.repoName="$name" \
              --var git.githubVisibility='{{git.githubVisibility}}'${extraVars}
            echo "repo-dir: created $(pwd) -> https://github.com/$owner/$name"
            ''

in  S.Module::{
    , name = "repo-dir"
    , version = Some "0.1.0"
    , description = Some
        "Create a new directory `<repo.parentDir>/<repo.name>` and bootstrap it as a git repository with a matching GitHub repo by running `seihou run git-init` inside it (so git-init's manifest, .gitignore, and initial commit live in the new repo, not the directory you ran from). The GitHub owner is resolved from `git.githubOwner`, so per-context config (`seihou config set git.githubOwner <org-or-user> --context <ctx>`) picks the user or organization for the active context."
    , vars =
      [ S.VarDecl::{
        , name = "repo.parentDir"
        , type = "text"
        , default = Some "."
        , description = Some
            "Directory in which the new repo folder is created. Relative paths resolve against the directory `seihou run` is invoked from; a leading `~` expands to `\$HOME`. Created if missing. Can be set per context, e.g. `seihou config set repo.parentDir ~/Work --context work`."
        , required = True
        }
      , S.VarDecl::{
        , name = "repo.name"
        , type = "text"
        , description = Some
            "Name of the new folder, which is also used as the GitHub repo name. Letters, digits, `.`, `_`, and `-` only."
        , required = True
        , validation = Some "[A-Za-z0-9._-]+"
        }
      , S.VarDecl::{
        , name = "git.githubOwner"
        , type = "text"
        , description = Some
            "GitHub user or organization that will own the repo. Resolved through the normal config chain, so set it per context (`seihou config set git.githubOwner <value> --context <ctx>`) or globally (`--global`) and select the context with `--context`, `SEIHOU_CONTEXT`, `.seihou/context`, or `seihou context default`."
        , required = True
        , validation = Some "[A-Za-z0-9-]+"
        }
      , S.VarDecl::{
        , name = "git.githubVisibility"
        , type = "text"
        , default = Some "private"
        , description = Some
            "Visibility of the GitHub repo: `private`, `public`, or `internal`. Defaults to `private`."
        , required = True
        , validation = Some "private|public|internal"
        }
      , S.VarDecl::{
        , name = "git.defaultBranch"
        , type = "text"
        , default = Some "master"
        , description = Some
            "Initial branch name forwarded to git-init. Not prompted; override with `--var` or config."
        , required = True
        , validation = Some "[A-Za-z0-9._/-]+"
        }
      , S.VarDecl::{
        , name = "git.githubTeam"
        , type = "text"
        , description = Some
            "Slug of an organization team to grant access to the new repo (forwarded to git-init). Leave unset to skip. Best set per context: `seihou config set git.githubTeam <slug> --context <ctx>`."
        , required = False
        , validation = Some "[A-Za-z0-9._-]+"
        }
      , S.VarDecl::{
        , name = "git.githubTeamPermission"
        , type = "text"
        , default = Some "push"
        , description = Some
            "Permission granted to `git.githubTeam`: `pull`, `triage`, `push`, `maintain`, or `admin`. Defaults to `push`."
        , required = False
        , validation = Some "pull|triage|push|maintain|admin"
        }
      ]
    , prompts =
      [ S.Prompt::{
        , var = "repo.parentDir"
        , text = "Directory to create the repo in?"
        }
      , S.Prompt::{ var = "repo.name", text = "Folder / GitHub repo name?" }
      , S.Prompt::{
        , var = "git.githubOwner"
        , text =
            "GitHub user or organization? (tip: set per context with `seihou config set git.githubOwner <value> --context <ctx>`)"
        }
      , S.Prompt::{
        , var = "git.githubVisibility"
        , text = "GitHub repo visibility?"
        , choices = Some [ "private", "public", "internal" ]
        }
      , S.Prompt::{
        , var = "git.githubTeam"
        , text =
            "Organization team to grant access? (slug; tip: set per context with `seihou config set git.githubTeam <slug> --context <ctx>`)"
        }
      , S.Prompt::{
        , var = "git.githubTeamPermission"
        , text = "Team permission?"
        , when = Some "IsSet git.githubTeam"
        , choices = Some [ "pull", "triage", "push", "maintain", "admin" ]
        }
      ]
    , commands =
      [ S.Command::{ run = prepare }
      , S.Command::{ run = gitInit "", when = Some "!IsSet git.githubTeam" }
      , S.Command::{
        , run =
            gitInit
              " --var git.githubTeam='{{git.githubTeam}}' --var git.githubTeamPermission='{{git.githubTeamPermission}}'"
        , when = Some "IsSet git.githubTeam"
        }
      ]
    }
