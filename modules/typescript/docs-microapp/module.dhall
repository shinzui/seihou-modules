let S =
      https://raw.githubusercontent.com/shinzui/seihou-schema/e9f91438f081fba90f40f987de93df9f74c7117d/package.dhall
        sha256:00f822087302b53f7ffe74e6505a633c59a0c2f206d12bfadb58a2fe211c0e40

in S.Module::{
  , name = "docs-microapp"
  , version = Some "0.1.0"
  , description = Some "Documentation reader with TanStack Start, React Aria, Highlights, self-hosted Geist Serif/Paper Mono and explicit immutable content images (Seihou 0.15+)"
  , vars = [ S.VarDecl::{ name = "project.name", type = "text", required = True, validation = Some "[a-z][a-z0-9-]*" }
           , S.VarDecl::{ name = "project.description", type = "text", required = True }
           , S.VarDecl::{ name = "docs.site-name", type = "text", required = True }
           ]
  , dependencies = [ S.Dependency::{ module = "nix-bun-flake", vars = [ { name = "bun.starter-files", value = "false" }, { name = "nix.pre-commit", value = "false" }, { name = "nix.bun2nix", value = "true" }, { name = "nix.package-module", value = "nix/docs-microapp.nix" } ] } ]
  , steps = [
S.Step::{ strategy = "copy", src = ".oxfmtrc.json", dest = ".oxfmtrc.json", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = ".oxlintrc.json", dest = ".oxlintrc.json", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "apps/docs/package.json.tpl", dest = "apps/docs/package.json", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/public/fonts/font-sources.json", dest = "apps/docs/public/fonts/font-sources.json", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/public/fonts/geist-serif-LICENSE.txt", dest = "apps/docs/public/fonts/geist-serif-LICENSE.txt", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/public/fonts/geist-serif-OFL.txt", dest = "apps/docs/public/fonts/geist-serif-OFL.txt", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/public/fonts/paper-mono-LICENSE.txt", dest = "apps/docs/public/fonts/paper-mono-LICENSE.txt", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/public/fonts/paper-mono-OFL.txt", dest = "apps/docs/public/fonts/paper-mono-OFL.txt", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/server.ts", dest = "apps/docs/server.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "apps/docs/site-name.txt.tpl", dest = "apps/docs/site-name.txt", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/src/components/code-block.tsx", dest = "apps/docs/src/components/code-block.tsx", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "apps/docs/src/components/markdown.tsx.tpl", dest = "apps/docs/src/components/markdown.tsx", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "apps/docs/src/components/shell.tsx.tpl", dest = "apps/docs/src/components/shell.tsx", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/src/router.tsx", dest = "apps/docs/src/router.tsx", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "apps/docs/src/routes/__root.tsx.tpl", dest = "apps/docs/src/routes/__root.tsx", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/src/routes/docs/$.tsx", dest = "apps/docs/src/routes/docs/\$.tsx", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/src/routes/index.tsx", dest = "apps/docs/src/routes/index.tsx", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/src/routes/published/$.ts", dest = "apps/docs/src/routes/published/\$.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "apps/docs/src/server/content.ts.tpl", dest = "apps/docs/src/server/content.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/vite.config.ts", dest = "apps/docs/vite.config.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "content/docs/index.md", dest = "content/docs/index.md", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "content.config.json", dest = "content.config.json", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "gitignore-docs.tpl", dest = ".gitignore", patch = Some "append-line-if-absent" }
    , S.Step::{ strategy = "copy", src = "justfile", dest = "justfile", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "nix/docs-microapp.nix.tpl", dest = "nix/docs-microapp.nix" }
    , S.Step::{ strategy = "template", src = "package.json.tpl", dest = "package.json", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "packages/corpus/package.json.tpl", dest = "packages/corpus/package.json", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "packages/corpus/src/index.ts", dest = "packages/corpus/src/index.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "packages/corpus/src/types.ts", dest = "packages/corpus/src/types.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "packages/ui/NOTICE.md", dest = "packages/ui/NOTICE.md", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "packages/ui/components.json.tpl", dest = "packages/ui/components.json", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "packages/ui/package.json.tpl", dest = "packages/ui/package.json", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "packages/ui/src/components.tsx", dest = "packages/ui/src/components.tsx", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "packages/ui/src/styles/globals.css", dest = "packages/ui/src/styles/globals.css", lifecycle = Some "seed" }
    , S.Step::{ strategy = "template", src = "scripts/content.ts.tpl", dest = "scripts/content.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "tsconfig.json", dest = "tsconfig.json", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/public/fonts/geist-serif.woff2.base64", dest = "apps/docs/public/fonts/geist-serif.woff2.base64", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/public/fonts/paper-mono.woff2.base64", dest = "apps/docs/public/fonts/paper-mono.woff2.base64", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "nix/docs-microapp-app.nix", dest = "nix/docs-microapp-app.nix" }
    , S.Step::{ strategy = "copy", src = "nix/docs-microapp-content.nix", dest = "nix/docs-microapp-content.nix" }
    , S.Step::{ strategy = "copy", src = "nix/docs-microapp-image.nix", dest = "nix/docs-microapp-image.nix" }
    , S.Step::{ strategy = "copy", src = "nix/docs-microapp-snapshot.py", dest = "nix/docs-microapp-snapshot.py" }
    , S.Step::{ strategy = "template", src = "apps/docs/src/server/reader.server.ts.tpl", dest = "apps/docs/src/server/reader.server.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "packages/corpus/tests/reader.test.ts", dest = "packages/corpus/tests/reader.test.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "playwright.config.ts", dest = "playwright.config.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "tests/reader.spec.ts", dest = "tests/reader.spec.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "apps/docs/src/env.d.ts", dest = "apps/docs/src/env.d.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "packages/corpus/src/links.ts", dest = "packages/corpus/src/links.ts", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "README.md", dest = "README.md", lifecycle = Some "seed" }
    , S.Step::{ strategy = "copy", src = "scripts/dev.ts", dest = "scripts/dev.ts", lifecycle = Some "seed" }
  ]
  , removal = Some S.Removal::{ steps = [ S.RemovalStep::{ action = "remove-file", dest = "nix/docs-microapp.nix" } , S.RemovalStep::{ action = "remove-file", dest = "nix/docs-microapp-app.nix" } , S.RemovalStep::{ action = "remove-file", dest = "nix/docs-microapp-content.nix" } , S.RemovalStep::{ action = "remove-file", dest = "nix/docs-microapp-image.nix" } , S.RemovalStep::{ action = "remove-file", dest = "nix/docs-microapp-snapshot.py" } ] }
}
