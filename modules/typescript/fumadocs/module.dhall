let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/b83079d377f22c77292ad5ccf88d1061a58f0c1c/package.dhall
        sha256:1d46697ed3e7ca1b0d9922020e2da034ae6e33f7b482ee454c68d94b536e8c2a

in  S.Module::{
    , name = "fumadocs"
    , version = Some "0.1.1"
    , description = Some
        "Fumadocs documentation site on TanStack Start + Vite, layered on nix-bun-flake's dev shell: a static-SPA docs app with self-hosted custom fonts, beautiful-mermaid diagrams, and an interactive zoom/pan/expand widget for every diagram"
    , vars =
      [ S.VarDecl::{
        , name = "project.name"
        , type = "text"
        , description = Some
            "Project name (package.json name). Re-declared so step `dest` paths and templates validate; the value is shared with `nix-bun-flake` via the dependency graph (it exports `project.name`)."
        , required = True
        , validation = Some "[a-z][a-z0-9-]*"
        }
      , S.VarDecl::{
        , name = "project.description"
        , type = "text"
        , description = Some
            "One-line project description (package.json description, home page intro). Inherited from `nix-bun-flake`, which exports `project.description`."
        , required = True
        }
      , S.VarDecl::{
        , name = "docs.site-name"
        , type = "text"
        , description = Some
            "Human-readable site/nav title shown in the navbar and browser tab (e.g. \"keiro runtime docs\")."
        , required = True
        }
      , S.VarDecl::{
        , name = "docs.github-user"
        , type = "text"
        , default = Some "shinzui"
        , description = Some
            "GitHub owner used for the navbar GitHub link and per-page \"edit on GitHub\" links (https://github.com/<user>/<project.name>)."
        , required = True
        }
      , S.VarDecl::{
        , name = "docs.github-branch"
        , type = "text"
        , default = Some "master"
        , description = Some
            "Branch used in per-page \"edit on GitHub\" links."
        , required = True
        }
      , S.VarDecl::{
        , name = "docs.font-family"
        , type = "text"
        , default = Some "PragmataPro Mono"
        , description = Some
            "CSS font-family name for the self-hosted monospace/code font (routed at --fd-font-mono and every code surface)."
        , required = True
        }
      , S.VarDecl::{
        , name = "docs.font-basename"
        , type = "text"
        , default = Some "PragmataProMono"
        , description = Some
            "Stable file-name prefix the font copy step writes into public/fonts/ (e.g. <basename>-Regular.otf), referenced by @font-face in app.css. Version-independent so the CSS URLs never change."
        , required = True
        }
      , S.VarDecl::{
        , name = "docs.font-flake"
        , type = "text"
        , default = Some "/Users/shinzui/Keikaku/bokuno/fonts"
        , description = Some
            "Local Nix flake path the font copy step builds to source the licensed OTFs. Tolerant: if unavailable, the build still proceeds and code falls back to system monospace."
        , required = True
        }
      , S.VarDecl::{
        , name = "docs.font-package"
        , type = "text"
        , default = Some "pragmataPro"
        , description = Some
            "Package attribute built from docs.font-flake (path:<flake>#<package>)."
        , required = True
        }
      ]
    , prompts =
      [ S.Prompt::{
        , var = "docs.site-name"
        , text = "Site title? (shown in the navbar and browser tab, e.g. \"acme docs\")"
        }
      , S.Prompt::{
        , var = "docs.github-user"
        , text = "GitHub owner for the repo link and edit-on-GitHub links?"
        }
      , S.Prompt::{
        , var = "docs.font-family"
        , text =
            "Custom code/monospace font-family name? (self-hosted via @font-face; default PragmataPro Mono)"
        }
      ]
    , dependencies =
      [ S.Dependency::{
        , module = "nix-bun-flake"
        , vars = [ { name = "nix.pre-commit", value = "false" } ]
        }
      ]
    , steps =
      [ S.Step::{
        , strategy = "template"
        , src = "package.json.tpl"
        , dest = "package.json"
        }
      , S.Step::{ strategy = "copy", src = "tsconfig.json", dest = "tsconfig.json" }
      , S.Step::{ strategy = "copy", src = "justfile", dest = "justfile" }
      , S.Step::{ strategy = "copy", src = "oxlintrc.json", dest = ".oxlintrc.json" }
      , S.Step::{ strategy = "copy", src = "oxfmtrc.json", dest = ".oxfmtrc.json" }
      , S.Step::{ strategy = "copy", src = "vite.config.ts", dest = "vite.config.ts" }
      , S.Step::{ strategy = "copy", src = "source.config.ts", dest = "source.config.ts" }
      , S.Step::{
        , strategy = "copy"
        , src = "linkinator.config.json"
        , dest = "linkinator.config.json"
        }
      , S.Step::{ strategy = "copy", src = "serve.json", dest = "serve.json" }
      , S.Step::{
        , strategy = "template"
        , src = "scripts/copy-fonts.mjs.tpl"
        , dest = "scripts/copy-fonts.mjs"
        }
      , S.Step::{ strategy = "copy", src = "src/router.tsx", dest = "src/router.tsx" }
      , S.Step::{
        , strategy = "copy"
        , src = "src/routeTree.gen.ts"
        , dest = "src/routeTree.gen.ts"
        }
      , S.Step::{ strategy = "copy", src = "src/lib/cn.ts", dest = "src/lib/cn.ts" }
      , S.Step::{ strategy = "copy", src = "src/lib/source.ts", dest = "src/lib/source.ts" }
      , S.Step::{
        , strategy = "template"
        , src = "src/lib/shared.ts.tpl"
        , dest = "src/lib/shared.ts"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "src/lib/layout.shared.tsx"
        , dest = "src/lib/layout.shared.tsx"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "src/lib/rehype-mermaid.ts"
        , dest = "src/lib/rehype-mermaid.ts"
        }
      , S.Step::{ strategy = "copy", src = "src/components/mdx.tsx", dest = "src/components/mdx.tsx" }
      , S.Step::{
        , strategy = "copy"
        , src = "src/components/mermaid.tsx"
        , dest = "src/components/mermaid.tsx"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "src/components/search.tsx"
        , dest = "src/components/search.tsx"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "src/components/not-found.tsx"
        , dest = "src/components/not-found.tsx"
        }
      , S.Step::{
        , strategy = "template"
        , src = "src/styles/app.css.tpl"
        , dest = "src/styles/app.css"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "src/routes/__root.tsx"
        , dest = "src/routes/__root.tsx"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "src/routes/index.tsx"
        , dest = "src/routes/index.tsx"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "src/routes/docs/splat.tsx"
        , dest = "src/routes/docs/\$.tsx"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "src/routes/docs/md-route.ts"
        , dest = "src/routes/docs/{\$}[.]md.ts"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "src/routes/api/search.ts"
        , dest = "src/routes/api/search.ts"
        }
      , S.Step::{
        , strategy = "template"
        , src = "content/index.mdx.tpl"
        , dest = "content/docs/index.mdx"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "content/diagram-demo.mdx"
        , dest = "content/docs/diagram-demo.mdx"
        }
      , S.Step::{
        , strategy = "copy"
        , src = "content/meta.json"
        , dest = "content/docs/meta.json"
        }
      , S.Step::{
        , strategy = "template"
        , src = "gitignore-fumadocs.tpl"
        , dest = ".gitignore"
        , patch = Some "append-line-if-absent"
        }
      ]
    , removal = Some S.Removal::{
      , steps =
        [ S.RemovalStep::{ action = "remove-file", dest = "vite.config.ts" }
        , S.RemovalStep::{ action = "remove-file", dest = "source.config.ts" }
        , S.RemovalStep::{ action = "remove-file", dest = "linkinator.config.json" }
        , S.RemovalStep::{ action = "remove-file", dest = "serve.json" }
        , S.RemovalStep::{ action = "remove-file", dest = "scripts/copy-fonts.mjs" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/router.tsx" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/routeTree.gen.ts" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/lib/cn.ts" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/lib/source.ts" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/lib/shared.ts" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/lib/layout.shared.tsx" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/lib/rehype-mermaid.ts" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/components/mdx.tsx" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/components/mermaid.tsx" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/components/search.tsx" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/components/not-found.tsx" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/styles/app.css" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/routes/__root.tsx" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/routes/index.tsx" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/routes/docs/\$.tsx" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/routes/docs/{\$}[.]md.ts" }
        , S.RemovalStep::{ action = "remove-file", dest = "src/routes/api/search.ts" }
        , S.RemovalStep::{ action = "remove-file", dest = "content/docs/index.mdx" }
        , S.RemovalStep::{ action = "remove-file", dest = "content/docs/diagram-demo.mdx" }
        , S.RemovalStep::{ action = "remove-file", dest = "content/docs/meta.json" }
        ]
      }
    }
