---
type: SeihouModule
title: docs-microapp
description: Documentation reader with TanStack Start, React Aria, Highlights, local
  fonts and immutable content images
resource: seihou://seihou-modules/modules/typescript/docs-microapp
tags:
- typescript
- docs
- bun
- tanstack
- nix
status: stable
generated:
  by: seihou-okf-extension/0.15.0.0
version: 0.1.0
---

# docs-microapp

Documentation reader with TanStack Start, React Aria, Highlights, local fonts and immutable content images

**Version:** 0.1.0

## Dependencies

- [nix-bun-flake](/modules/nix-bun-flake.md) (with `bun.starter-files` = `false`, `nix.bun2nix` = `true`, `nix.package-module` = `nix/docs-microapp.nix`, `nix.pre-commit` = `false`)

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`
- `project.description` — text, required
- `docs.site-name` — text, required

## Exports

No exports declared.

## Generation steps

- `Copy` `.oxfmtrc.json` → `.oxfmtrc.json`
- `Copy` `.oxlintrc.json` → `.oxlintrc.json`
- `Template` `apps/docs/package.json.tpl` → `apps/docs/package.json`
- `Copy` `apps/docs/public/fonts/font-sources.json` → `apps/docs/public/fonts/font-sources.json`
- `Copy` `apps/docs/public/fonts/geist-serif-LICENSE.txt` → `apps/docs/public/fonts/geist-serif-LICENSE.txt`
- `Copy` `apps/docs/public/fonts/geist-serif-OFL.txt` → `apps/docs/public/fonts/geist-serif-OFL.txt`
- `Copy` `apps/docs/public/fonts/paper-mono-LICENSE.txt` → `apps/docs/public/fonts/paper-mono-LICENSE.txt`
- `Copy` `apps/docs/public/fonts/paper-mono-OFL.txt` → `apps/docs/public/fonts/paper-mono-OFL.txt`
- `Copy` `apps/docs/server.ts` → `apps/docs/server.ts`
- `Template` `apps/docs/site-name.txt.tpl` → `apps/docs/site-name.txt`
- `Copy` `apps/docs/src/components/code-block.tsx` → `apps/docs/src/components/code-block.tsx`
- `Template` `apps/docs/src/components/markdown.tsx.tpl` → `apps/docs/src/components/markdown.tsx`
- `Template` `apps/docs/src/components/shell.tsx.tpl` → `apps/docs/src/components/shell.tsx`
- `Copy` `apps/docs/src/router.tsx` → `apps/docs/src/router.tsx`
- `Template` `apps/docs/src/routes/__root.tsx.tpl` → `apps/docs/src/routes/__root.tsx`
- `Copy` `apps/docs/src/routes/docs/$.tsx` → `apps/docs/src/routes/docs/$.tsx`
- `Copy` `apps/docs/src/routes/index.tsx` → `apps/docs/src/routes/index.tsx`
- `Copy` `apps/docs/src/routes/published/$.ts` → `apps/docs/src/routes/published/$.ts`
- `Template` `apps/docs/src/server/content.ts.tpl` → `apps/docs/src/server/content.ts`
- `Copy` `apps/docs/vite.config.ts` → `apps/docs/vite.config.ts`
- `Copy` `content/docs/index.md` → `content/docs/index.md`
- `Copy` `content.config.json` → `content.config.json`
- `Template` `gitignore-docs.tpl` → `.gitignore` (appends one line to a file another module owns, if absent)
- `Copy` `justfile` → `justfile`
- `Template` `nix/docs-microapp.nix.tpl` → `nix/docs-microapp.nix`
- `Template` `package.json.tpl` → `package.json`
- `Template` `packages/corpus/package.json.tpl` → `packages/corpus/package.json`
- `Copy` `packages/corpus/src/index.ts` → `packages/corpus/src/index.ts`
- `Copy` `packages/corpus/src/types.ts` → `packages/corpus/src/types.ts`
- `Copy` `packages/ui/NOTICE.md` → `packages/ui/NOTICE.md`
- `Template` `packages/ui/components.json.tpl` → `packages/ui/components.json`
- `Template` `packages/ui/package.json.tpl` → `packages/ui/package.json`
- `Copy` `packages/ui/src/components.tsx` → `packages/ui/src/components.tsx`
- `Copy` `packages/ui/src/styles/globals.css` → `packages/ui/src/styles/globals.css`
- `Template` `scripts/content.ts.tpl` → `scripts/content.ts`
- `Copy` `tsconfig.json` → `tsconfig.json`
- `Copy` `apps/docs/public/fonts/geist-serif.woff2.base64` → `apps/docs/public/fonts/geist-serif.woff2.base64`
- `Copy` `apps/docs/public/fonts/paper-mono.woff2.base64` → `apps/docs/public/fonts/paper-mono.woff2.base64`
- `Copy` `nix/docs-microapp-app.nix` → `nix/docs-microapp-app.nix`
- `Copy` `nix/docs-microapp-content.nix` → `nix/docs-microapp-content.nix`
- `Copy` `nix/docs-microapp-image.nix` → `nix/docs-microapp-image.nix`
- `Copy` `nix/docs-microapp-snapshot.py` → `nix/docs-microapp-snapshot.py`
- `Template` `apps/docs/src/server/reader.server.ts.tpl` → `apps/docs/src/server/reader.server.ts`
- `Copy` `packages/corpus/tests/reader.test.ts` → `packages/corpus/tests/reader.test.ts`
- `Copy` `playwright.config.ts` → `playwright.config.ts`
- `Copy` `tests/reader.spec.ts` → `tests/reader.spec.ts`
- `Copy` `apps/docs/src/env.d.ts` → `apps/docs/src/env.d.ts`
- `Copy` `packages/corpus/src/links.ts` → `packages/corpus/src/links.ts`
- `Copy` `README.md` → `README.md`
- `Copy` `scripts/dev.ts` → `scripts/dev.ts`

## Removal

- delete `nix/docs-microapp.nix`
- delete `nix/docs-microapp-app.nix`
- delete `nix/docs-microapp-content.nix`
- delete `nix/docs-microapp-image.nix`
- delete `nix/docs-microapp-snapshot.py`
