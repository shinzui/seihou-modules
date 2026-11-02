let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/b83079d377f22c77292ad5ccf88d1061a58f0c1c/package.dhall
        sha256:1d46697ed3e7ca1b0d9922020e2da034ae6e33f7b482ee454c68d94b536e8c2a

in S.Module::{
    , name = "openapi-typescript-client-dir"
    , version = Some "0.1.1"
    , description = Some "Create a new client folder and run openapi-typescript-client with git-init inside it, including GitHub creation under a configurable owner."
    , vars =
      [ S.VarDecl::{
        , name = "repo.postCreateScript", type = "text", required = False
        , description = Some "Optional Python script in the invocation directory, run after successful repository creation."
        }
      , S.VarDecl::{
        , name = "repo.parentDir", type = "text", required = True
        , description = Some "Parent directory for the new client folder; a leading ~ is expanded."
        , default = Some "."
        }
      , S.VarDecl::{
        , name = "project.name", type = "text", required = True
        , description = Some "Client package, folder and GitHub repository name."
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "project.description", type = "text", required = True
        , description = Some "One-line client description."
        }
      , S.VarDecl::{
        , name = "git.githubOwner", type = "text", required = True
        , description = Some "GitHub user or organization; may be set with --var or context/global config."
        , validation = Some "[A-Za-z0-9-]+"
        }
      , S.VarDecl::{
        , name = "git.githubVisibility", type = "text", required = True
        , description = Some "GitHub repository visibility."
        , default = Some "private"
        , validation = Some "private|public|internal"
        }
      , S.VarDecl::{
        , name = "git.defaultBranch", type = "text", required = True
        , description = Some "Initial branch name forwarded to git-init."
        , default = Some "master"
        , validation = Some "[A-Za-z0-9._/-]+"
        }
      , S.VarDecl::{
        , name = "git.githubTeam", type = "text", required = False
        , description = Some "Optional organization team to grant repository access."
        , validation = Some "[A-Za-z0-9._-]+"
        }
      , S.VarDecl::{
        , name = "git.githubTeamPermission", type = "text", required = False
        , description = Some "Permission for the optional organization team."
        , default = Some "push"
        , validation = Some "pull|triage|push|maintain|admin"
        }
      , S.VarDecl::{
        , name = "nix.bun2nix", type = "bool", required = True
        , description = Some "Include optional bun2nix helpers."
        , default = Some "false"
        }
      , S.VarDecl::{
        , name = "mori.generate", type = "bool", required = False
        , description = Some "Seed optional client Mori inventory."
        , default = Some "false"
        }
      , S.VarDecl::{
        , name = "mori.namespace", type = "text", required = False
        , description = Some "Client Mori namespace when mori.generate=true."
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "mori.source-namespace", type = "text", required = False
        , description = Some "Mori namespace of the API provider."
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "mori.source-project", type = "text", required = False
        , description = Some "Mori project name of the API provider."
        , validation = Some "[a-z][a-z0-9-]*"
        }
      ]
    , prompts =
      [ S.Prompt::{ var = "repo.parentDir", text = "Directory to create the client repo in?" }
      , S.Prompt::{ var = "project.name", text = "Client project name?" }
      , S.Prompt::{ var = "project.description", text = "Describe the client in one line:" }
      , S.Prompt::{ var = "git.githubOwner", text = "GitHub user or organization?" }
      , S.Prompt::{ var = "git.githubVisibility", text = "GitHub repo visibility?" }
      , S.Prompt::{ var = "git.githubTeam", text = "Organization team to grant access? (leave empty to skip)" }
      , S.Prompt::{ var = "git.githubTeamPermission", text = "Team permission?", when = Some "IsSet git.githubTeam" }
      , S.Prompt::{ var = "mori.namespace", text = "Mori namespace for this client?", when = Some "Eq mori.generate true" }
      , S.Prompt::{ var = "mori.source-namespace", text = "Mori namespace of the OpenAPI provider?", when = Some "Eq mori.generate true" }
      , S.Prompt::{ var = "mori.source-project", text = "Mori project name of the OpenAPI provider?", when = Some "Eq mori.generate true" }
      ]
    , steps =
      [ S.Step::{ strategy = "copy", src = "create-client-repo.py", dest = ".seihou/openapi-typescript-client-dir/create-client-repo.py" }
      , S.Step::{ strategy = "template", src = "repo.postCreateScript.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/repo.postCreateScript.conf" }
      , S.Step::{ strategy = "template", src = "repo.parentDir.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/repo.parentDir.conf" }
      , S.Step::{ strategy = "template", src = "project.name.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/project.name.conf" }
      , S.Step::{ strategy = "template", src = "project.description.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/project.description.conf" }
      , S.Step::{ strategy = "template", src = "git.githubOwner.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/git.githubOwner.conf" }
      , S.Step::{ strategy = "template", src = "git.githubVisibility.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/git.githubVisibility.conf" }
      , S.Step::{ strategy = "template", src = "git.defaultBranch.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/git.defaultBranch.conf" }
      , S.Step::{ strategy = "template", src = "git.githubTeam.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/git.githubTeam.conf" }
      , S.Step::{ strategy = "template", src = "git.githubTeamPermission.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/git.githubTeamPermission.conf" }
      , S.Step::{ strategy = "template", src = "nix.bun2nix.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/nix.bun2nix.conf" }
      , S.Step::{ strategy = "template", src = "mori.generate.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/mori.generate.conf" }
      , S.Step::{ strategy = "template", src = "mori.namespace.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/mori.namespace.conf" }
      , S.Step::{ strategy = "template", src = "mori.source-namespace.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/mori.source-namespace.conf" }
      , S.Step::{ strategy = "template", src = "mori.source-project.conf.tpl", dest = ".seihou/openapi-typescript-client-dir/mori.source-project.conf" }
      ]
    , commands = [ S.Command::{ run = "python3 .seihou/openapi-typescript-client-dir/create-client-repo.py" } ]
    }
