let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/b83079d377f22c77292ad5ccf88d1061a58f0c1c/package.dhall
        sha256:1d46697ed3e7ca1b0d9922020e2da034ae6e33f7b482ee454c68d94b536e8c2a

in  S.Recipe::{
    , name = "fumadocs-project"
    , version = Some "0.2.0"
    , description = Some
        "Create a documentation directory and Git/GitHub repository with container-enabled Fumadocs, technical writing skills and local Mori registration"
    , modules =
      [ S.Dependency::{
        , module = "repo-dir"
        , vars =
          [ { name = "repo.scaffold", value = "fumadocs-site" }
          , { name = "repo.scaffoldBindings"
            , value =
                "{\"docs.github-user\":\"git.githubOwner\",\"docs.github-branch\":\"git.defaultBranch\",\"docs.github-repo\":\"repo.name\"}"
            }
          ]
        }
      ]
    , vars =
      [ S.VarDecl::{
        , default = Some "true"
        , description = Some
            "Generate starter content for a new site; set false when adopting an existing documentation tree"
        , name = "docs.starter-content"
        , required = True
        , type = "bool"
        }
      , S.VarDecl::{
        , default = Some "false"
        , description = Some
            "Generate API reference pages from an OpenAPI document with fumadocs-openapi"
        , name = "docs.openapi"
        , required = True
        , type = "bool"
        }
      , S.VarDecl::{
        , default = Some "openapi.yaml"
        , description = Some
            "OpenAPI document rendered when docs.openapi is true: a project-relative path or a URL. New sites with starter content get an example at openapi.yaml."
        , name = "docs.openapi-spec"
        , required = True
        , type = "text"
        }
      , S.VarDecl::{
        , default = Some "api"
        , description = Some
            "Docs folder holding the generated OpenAPI pages (served under /docs/<dir>/). Pick one no authored content uses."
        , name = "docs.openapi-base-dir"
        , required = True
        , type = "text"
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , default = Some "true"
        , description = Some
            "Generate a Nix build of the static site and a non-root Caddy image built with nix2container; also requires nix.bun2nix=true and nix.package-module=nix/fumadocs-container.nix"
        , name = "docs.container"
        , required = True
        , type = "bool"
        }
      , S.VarDecl::{
        , description = Some
            "Project name (package.json name). Re-declared so step `dest` paths and templates validate; the value is shared with `nix-bun-flake` via the dependency graph (it exports `project.name`)."
        , name = "project.name"
        , required = True
        , type = "text"
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , description = Some
            "One-line project description (package.json description, home page intro). Inherited from `nix-bun-flake`, which exports `project.description`."
        , name = "project.description"
        , required = True
        , type = "text"
        }
      , S.VarDecl::{
        , description = Some
            "Human-readable site/nav title shown in the navbar and browser tab (e.g. \"keiro runtime docs\")."
        , name = "docs.site-name"
        , required = True
        , type = "text"
        }
      , S.VarDecl::{
        , default = None Text
        , description = Some
            "Optional site GitHub link override; defaults to the created repository owner/branch."
        , name = "docs.github-user"
        , required = False
        , type = "text"
        }
      , S.VarDecl::{
        , default = None Text
        , description = Some
            "Optional site GitHub link override; defaults to the created repository owner/branch."
        , name = "docs.github-branch"
        , required = False
        , type = "text"
        }
      , S.VarDecl::{
        , name = "docs.github-repo"
        , type = "text"
        , required = False
        , description = Some
            "Optional site GitHub repository override; defaults to repo.name."
        , validation = Some "[A-Za-z0-9._-]+"
        }
      , S.VarDecl::{
        , default = Some "PragmataPro Mono"
        , description = Some
            "CSS font-family name for the self-hosted monospace/code font (routed at --fd-font-mono and every code surface)."
        , name = "docs.font-family"
        , required = True
        , type = "text"
        }
      , S.VarDecl::{
        , default = Some "PragmataProMono"
        , description = Some
            "Stable file-name prefix the font copy step writes into public/fonts/ (e.g. <basename>-Regular.otf), referenced by @font-face in app.css. Version-independent so the CSS URLs never change."
        , name = "docs.font-basename"
        , required = True
        , type = "text"
        }
      , S.VarDecl::{
        , default = Some "/Users/shinzui/Keikaku/bokuno/fonts"
        , description = Some
            "Local Nix flake path the font copy step builds to source the licensed OTFs. Tolerant: if unavailable, the build still proceeds and code falls back to system monospace."
        , name = "docs.font-flake"
        , required = True
        , type = "text"
        }
      , S.VarDecl::{
        , default = Some "pragmataPro"
        , description = Some
            "Package attribute built from docs.font-flake (path:<flake>#<package>)."
        , name = "docs.font-package"
        , required = True
        , type = "text"
        }
      , S.VarDecl::{
        , description = Some "Namespace of this documentation project."
        , name = "mori.namespace"
        , required = True
        , type = "text"
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , description = Some
            "Namespace of the already registered project being documented."
        , name = "mori.source-namespace"
        , required = True
        , type = "text"
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , description = Some
            "Name of the already registered project being documented."
        , name = "mori.source-project"
        , required = True
        , type = "text"
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "skill.prefix"
        , type = "text"
        , default = Some "tech-docs"
        , required = False
        , description = Some "Prefix of the six technical writing skills."
        , validation = Some "[a-z][a-z0-9-]*"
        }
      ]
    }
