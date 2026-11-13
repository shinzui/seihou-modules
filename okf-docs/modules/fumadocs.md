---
type: SeihouModule
title: fumadocs
description: 'Fumadocs documentation site on TanStack Start + Vite, layered on nix-bun-flake''s
  dev shell: a static-SPA docs app with self-hosted custom fonts, zombie-mermaid diagrams,
  an interactive zoom/pan/expand widget for every diagram, optional OpenAPI reference
  pages, and an optional Caddy container image built with nix2container'
resource: seihou://seihou-modules/modules/typescript/fumadocs
tags:
- typescript
- fumadocs
- docs
- mermaid
- vite
- tanstack
- openapi
status: stable
generated:
  by: seihou-okf-extension/0.16.0.0
version: 0.6.2
---

# fumadocs

Fumadocs documentation site on TanStack Start + Vite, layered on nix-bun-flake's dev shell: a static-SPA docs app with self-hosted custom fonts, zombie-mermaid diagrams, an interactive zoom/pan/expand widget for every diagram, optional OpenAPI reference pages, and an optional Caddy container image built with nix2container

**Version:** 0.6.2

## Dependencies

- [nix-bun-flake](/modules/nix-bun-flake.md) (declaring registry) (with `nix.pre-commit` = `false`)

## Variables

- `docs.starter-content` — boolean, required, default `true`. Generate starter content for a new site; set false when adopting an existing documentation tree
- `docs.openapi` — boolean, required, default `false`. Generate API reference pages from an OpenAPI document with fumadocs-openapi
- `docs.openapi-spec` — text, required, default `openapi.yaml`. OpenAPI document rendered when docs.openapi is true: a project-relative path, a URL, or a directory whose .json, .yaml and .yml documents are all rendered. New sites with starter content get an example at openapi.yaml.
- `docs.openapi-base-dir` — text, required, default `api`, matching `[a-z][a-z0-9-]*`. Docs folder holding the generated OpenAPI pages (served under /docs/<dir>/). Pick one no authored content uses.
- `docs.svg-diagrams` — boolean, required, default `false`. Generate the semantic SVG diagram system: <Diagram>, theme-aware diagram styles, the authoring contract in content/diagrams/README.md, a preview renderer and the lint:diagrams gate
- `docs.container` — boolean, required, default `false`. Generate a Nix build of the static site and a non-root Caddy image built with nix2container; also requires nix.bun2nix=true and nix.package-module=nix/fumadocs-container.nix
- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project name (package.json name). Re-declared so step `dest` paths and templates validate; the value is shared with `nix-bun-flake` via the dependency graph (it exports `project.name`).
- `project.description` — text, required. One-line project description (package.json description, home page intro). Inherited from `nix-bun-flake`, which exports `project.description`.
- `docs.site-name` — text, required. Human-readable site/nav title shown in the navbar and browser tab (e.g. "keiro runtime docs").
- `docs.github-user` — text, required, default `shinzui`. GitHub owner used for the navbar GitHub link and per-page "edit on GitHub" links; the repository defaults to project.name and can be overridden with docs.github-repo.
- `docs.github-repo` — text, optional, matching `[A-Za-z0-9._-]+`. GitHub repository name for site links; defaults to project.name when omitted.
- `docs.github-branch` — text, required, default `master`. Branch used in per-page "edit on GitHub" links.
- `docs.font-family` — text, required, default `PragmataPro Mono`. CSS font-family name for the self-hosted monospace/code font (routed at --fd-font-mono and every code surface).
- `docs.font-basename` — text, required, default `PragmataProMono`. Stable file-name prefix the font copy step writes into public/fonts/ (e.g. <basename>-Regular.otf), referenced by @font-face in app.css. Version-independent so the CSS URLs never change.
- `docs.font-flake` — text, required, default `""` (JSON string). Nix flake path the font copy step builds to source licensed OTFs; DOCS_FONT_FLAKE overrides it. Leave empty in public repositories and set DOCS_FONT_FLAKE locally instead. Tolerant: if unavailable, the build still proceeds and code falls back to system monospace.
- `docs.font-package` — text, required, default `pragmataPro`. Package attribute built from docs.font-flake (path:<flake>#<package>).

## Exports

No exports declared.

## Prompts

- `docs.site-name` — `Site title? (shown in the navbar and browser tab, e.g. "acme docs")`
- `docs.github-user` — `GitHub owner for the repo link and edit-on-GitHub links?`
- `docs.font-family` — `Custom code/monospace font-family name? (self-hosted via @font-face; default PragmataPro Mono)`

## Generation steps

- `Template` `package.json.tpl` → `package.json` — Managed: owned and reconciled by Seihou updates
- `Copy` `tsconfig.json` → `tsconfig.json` — Managed: owned and reconciled by Seihou updates
- `Copy` `justfile` → `justfile` — Managed: owned and reconciled by Seihou updates
- `Copy` `oxlintrc.json` → `.oxlintrc.json` — Managed: owned and reconciled by Seihou updates
- `Copy` `oxfmtrc.json` → `.oxfmtrc.json` — Managed: owned and reconciled by Seihou updates
- `Copy` `vite.config.ts` → `vite.config.ts` — Managed: owned and reconciled by Seihou updates
- `Copy` `source.config.ts` → `source.config.ts` — Managed: owned and reconciled by Seihou updates
- `Copy` `linkinator.config.json` → `linkinator.config.json` — Managed: owned and reconciled by Seihou updates
- `Copy` `serve.json` → `serve.json` — Managed: owned and reconciled by Seihou updates
- `Template` `nix/fumadocs-container.nix.tpl` → `nix/fumadocs-container.nix` — when `Eq docs.container true` — Managed: owned and reconciled by Seihou updates
- `Copy` `nix/fumadocs-site.nix` → `nix/fumadocs-site.nix` — when `Eq docs.container true` — Managed: owned and reconciled by Seihou updates
- `Copy` `nix/caddy-config.nix` → `nix/caddy-config.nix` — when `Eq docs.container true` — Managed: owned and reconciled by Seihou updates
- `Copy` `nix/container.nix` → `nix/container.nix` — when `Eq docs.container true` — Managed: owned and reconciled by Seihou updates
- `Template` `scripts/copy-fonts.mjs.tpl` → `scripts/copy-fonts.mjs` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/router.tsx` → `src/router.tsx` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/routeTree.gen.ts` → `src/routeTree.gen.ts` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/lib/cn.ts` → `src/lib/cn.ts` — Managed: owned and reconciled by Seihou updates
- `Template` `src/lib/source.ts.tpl` → `src/lib/source.ts` — Managed: owned and reconciled by Seihou updates
- `Template` `src/lib/openapi.ts.tpl` → `src/lib/openapi.ts` — when `Eq docs.openapi true` — Managed: owned and reconciled by Seihou updates
- `Template` `src/lib/shared.ts.tpl` → `src/lib/shared.ts` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/lib/layout.shared.tsx` → `src/lib/layout.shared.tsx` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/lib/rehype-mermaid.ts` → `src/lib/rehype-mermaid.ts` — Managed: owned and reconciled by Seihou updates
- `Template` `src/components/mdx.tsx.tpl` → `src/components/mdx.tsx` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/components/diagram.tsx` → `src/components/diagram.tsx` — when `Eq docs.svg-diagrams true` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/lib/diagram-svg.mjs` → `src/lib/diagram-svg.mjs` — when `Eq docs.svg-diagrams true` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/styles/diagrams.css` → `src/styles/diagrams.css` — when `Eq docs.svg-diagrams true` — Managed: owned and reconciled by Seihou updates
- `Copy` `scripts/check-doc-diagrams.mjs` → `scripts/check-doc-diagrams.mjs` — when `Eq docs.svg-diagrams true` — Managed: owned and reconciled by Seihou updates
- `Copy` `scripts/render-diagram.mjs` → `scripts/render-diagram.mjs` — when `Eq docs.svg-diagrams true` — Managed: owned and reconciled by Seihou updates
- `Copy` `content/diagrams/README.md` → `content/diagrams/README.md` — when `Eq docs.svg-diagrams true` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/components/mermaid.tsx` → `src/components/mermaid.tsx` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/components/search.tsx` → `src/components/search.tsx` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/components/not-found.tsx` → `src/components/not-found.tsx` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/components/api-page.tsx` → `src/components/api-page.tsx` — when `Eq docs.openapi true` — Managed: owned and reconciled by Seihou updates
- `Template` `src/styles/app.css.tpl` → `src/styles/app.css` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/routes/__root.tsx` → `src/routes/__root.tsx` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/routes/index.tsx` → `src/routes/index.tsx` — Managed: owned and reconciled by Seihou updates
- `Template` `src/routes/docs/splat.tsx.tpl` → `src/routes/docs/$.tsx` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/routes/docs/md-route.ts` → `src/routes/docs/{$}[.]md.ts` — Managed: owned and reconciled by Seihou updates
- `Copy` `src/routes/api/search.ts` → `src/routes/api/search.ts` — Managed: owned and reconciled by Seihou updates
- `Template` `content/index.mdx.tpl` → `content/docs/index.mdx` — when `Eq docs.starter-content true` — Managed: owned and reconciled by Seihou updates
- `Copy` `content/diagram-demo.mdx` → `content/docs/diagram-demo.mdx` — when `Eq docs.starter-content true` — Managed: owned and reconciled by Seihou updates
- `Template` `content/meta.json.tpl` → `content/docs/meta.json` — when `Eq docs.starter-content true` — Managed: owned and reconciled by Seihou updates
- `Copy` `content/openapi.yaml` → `openapi.yaml` — when `Eq docs.openapi true && Eq docs.starter-content true && Eq docs.openapi-spec "openapi.yaml"` — Managed: owned and reconciled by Seihou updates
- `Template` `gitignore-fumadocs.tpl` → `.gitignore` (appends one line to a file another module owns, if absent) — Managed: owned and reconciled by Seihou updates

## Removal

- delete `vite.config.ts`
- delete `source.config.ts`
- delete `linkinator.config.json`
- delete `serve.json`
- delete `nix/fumadocs-container.nix`
- delete `nix/fumadocs-site.nix`
- delete `nix/caddy-config.nix`
- delete `nix/container.nix`
- delete `scripts/copy-fonts.mjs`
- delete `src/router.tsx`
- delete `src/routeTree.gen.ts`
- delete `src/lib/cn.ts`
- delete `src/lib/source.ts`
- delete `src/lib/openapi.ts`
- delete `src/lib/shared.ts`
- delete `src/lib/layout.shared.tsx`
- delete `src/lib/rehype-mermaid.ts`
- delete `src/components/mdx.tsx`
- delete `src/components/mermaid.tsx`
- delete `src/components/search.tsx`
- delete `src/components/not-found.tsx`
- delete `src/components/api-page.tsx`
- delete `src/components/diagram.tsx`
- delete `src/lib/diagram-svg.mjs`
- delete `src/styles/diagrams.css`
- delete `scripts/check-doc-diagrams.mjs`
- delete `scripts/render-diagram.mjs`
- delete `src/styles/app.css`
- delete `src/routes/__root.tsx`
- delete `src/routes/index.tsx`
- delete `src/routes/docs/$.tsx`
- delete `src/routes/docs/{$}[.]md.ts`
- delete `src/routes/api/search.ts`
