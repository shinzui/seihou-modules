---
type: SeihouModule
title: fumadocs
description: 'Fumadocs documentation site on TanStack Start + Vite, layered on nix-bun-flake''s
  dev shell: a static-SPA docs app with self-hosted custom fonts, beautiful-mermaid
  diagrams, and an interactive zoom/pan/expand widget for every diagram'
resource: seihou://seihou-modules/modules/typescript/fumadocs
tags:
- typescript
- fumadocs
- docs
- mermaid
- vite
- tanstack
status: stable
generated:
  by: seihou-okf-extension/0.8.0.0
version: 0.1.2
---

# fumadocs

Fumadocs documentation site on TanStack Start + Vite, layered on nix-bun-flake's dev shell: a static-SPA docs app with self-hosted custom fonts, beautiful-mermaid diagrams, and an interactive zoom/pan/expand widget for every diagram

**Version:** 0.1.2

## Dependencies

- [nix-bun-flake](/modules/nix-bun-flake.md) (with `nix.pre-commit` = `false`)

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project name (package.json name). Re-declared so step `dest` paths and templates validate; the value is shared with `nix-bun-flake` via the dependency graph (it exports `project.name`).
- `project.description` — text, required. One-line project description (package.json description, home page intro). Inherited from `nix-bun-flake`, which exports `project.description`.
- `docs.site-name` — text, required. Human-readable site/nav title shown in the navbar and browser tab (e.g. "keiro runtime docs").
- `docs.github-user` — text, required, default `shinzui`. GitHub owner used for the navbar GitHub link and per-page "edit on GitHub" links (https://github.com/<user>/<project.name>).
- `docs.github-branch` — text, required, default `master`. Branch used in per-page "edit on GitHub" links.
- `docs.font-family` — text, required, default `PragmataPro Mono`. CSS font-family name for the self-hosted monospace/code font (routed at --fd-font-mono and every code surface).
- `docs.font-basename` — text, required, default `PragmataProMono`. Stable file-name prefix the font copy step writes into public/fonts/ (e.g. <basename>-Regular.otf), referenced by @font-face in app.css. Version-independent so the CSS URLs never change.
- `docs.font-flake` — text, required, default `/Users/shinzui/Keikaku/bokuno/fonts`. Local Nix flake path the font copy step builds to source the licensed OTFs. Tolerant: if unavailable, the build still proceeds and code falls back to system monospace.
- `docs.font-package` — text, required, default `pragmataPro`. Package attribute built from docs.font-flake (path:<flake>#<package>).

## Exports

No exports declared.

## Prompts

- `docs.site-name` — Site title? (shown in the navbar and browser tab, e.g. "acme docs")
- `docs.github-user` — GitHub owner for the repo link and edit-on-GitHub links?
- `docs.font-family` — Custom code/monospace font-family name? (self-hosted via @font-face; default PragmataPro Mono)

## Generation steps

- `Template` `package.json.tpl` → `package.json`
- `Copy` `tsconfig.json` → `tsconfig.json`
- `Copy` `justfile` → `justfile`
- `Copy` `oxlintrc.json` → `.oxlintrc.json`
- `Copy` `oxfmtrc.json` → `.oxfmtrc.json`
- `Copy` `vite.config.ts` → `vite.config.ts`
- `Copy` `source.config.ts` → `source.config.ts`
- `Copy` `linkinator.config.json` → `linkinator.config.json`
- `Copy` `serve.json` → `serve.json`
- `Template` `scripts/copy-fonts.mjs.tpl` → `scripts/copy-fonts.mjs`
- `Copy` `src/router.tsx` → `src/router.tsx`
- `Copy` `src/routeTree.gen.ts` → `src/routeTree.gen.ts`
- `Copy` `src/lib/cn.ts` → `src/lib/cn.ts`
- `Copy` `src/lib/source.ts` → `src/lib/source.ts`
- `Template` `src/lib/shared.ts.tpl` → `src/lib/shared.ts`
- `Copy` `src/lib/layout.shared.tsx` → `src/lib/layout.shared.tsx`
- `Copy` `src/lib/rehype-mermaid.ts` → `src/lib/rehype-mermaid.ts`
- `Copy` `src/components/mdx.tsx` → `src/components/mdx.tsx`
- `Copy` `src/components/mermaid.tsx` → `src/components/mermaid.tsx`
- `Copy` `src/components/search.tsx` → `src/components/search.tsx`
- `Copy` `src/components/not-found.tsx` → `src/components/not-found.tsx`
- `Template` `src/styles/app.css.tpl` → `src/styles/app.css`
- `Copy` `src/routes/__root.tsx` → `src/routes/__root.tsx`
- `Copy` `src/routes/index.tsx` → `src/routes/index.tsx`
- `Copy` `src/routes/docs/splat.tsx` → `src/routes/docs/$.tsx`
- `Copy` `src/routes/docs/md-route.ts` → `src/routes/docs/{$}[.]md.ts`
- `Copy` `src/routes/api/search.ts` → `src/routes/api/search.ts`
- `Template` `content/index.mdx.tpl` → `content/docs/index.mdx`
- `Copy` `content/diagram-demo.mdx` → `content/docs/diagram-demo.mdx`
- `Copy` `content/meta.json` → `content/docs/meta.json`
- `Template` `gitignore-fumadocs.tpl` → `.gitignore` (appends one line to a file another module owns, if absent)

## Removal

- delete `vite.config.ts`
- delete `source.config.ts`
- delete `linkinator.config.json`
- delete `serve.json`
- delete `scripts/copy-fonts.mjs`
- delete `src/router.tsx`
- delete `src/routeTree.gen.ts`
- delete `src/lib/cn.ts`
- delete `src/lib/source.ts`
- delete `src/lib/shared.ts`
- delete `src/lib/layout.shared.tsx`
- delete `src/lib/rehype-mermaid.ts`
- delete `src/components/mdx.tsx`
- delete `src/components/mermaid.tsx`
- delete `src/components/search.tsx`
- delete `src/components/not-found.tsx`
- delete `src/styles/app.css`
- delete `src/routes/__root.tsx`
- delete `src/routes/index.tsx`
- delete `src/routes/docs/$.tsx`
- delete `src/routes/docs/{$}[.]md.ts`
- delete `src/routes/api/search.ts`
- delete `content/docs/index.mdx`
- delete `content/docs/diagram-demo.mdx`
- delete `content/docs/meta.json`
