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
  by: seihou-okf-extension/0.16.0.0
version: 0.1.0
---

# docs-microapp

Documentation reader with TanStack Start, React Aria, Highlights, local fonts and immutable content images

**Version:** 0.1.0

## Declaration metadata

- description: `Documentation reader with TanStack Start, React Aria, Highlights, self-hosted Geist Serif/Paper Mono and explicit immutable content images (Seihou 0.15+)`

## Dependencies

- [nix-bun-flake](/modules/nix-bun-flake.md) (declaring registry) (with `bun.starter-files` = `false`, `nix.bun2nix` = `true`, `nix.package-module` = `nix/docs-microapp.nix`, `nix.pre-commit` = `false`)

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`
- `project.description` — text, required
- `docs.site-name` — text, required

## Exports

No exports declared.

## Generation steps

- `Copy` `.oxfmtrc.json` → `.oxfmtrc.json` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `.oxlintrc.json` → `.oxlintrc.json` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `apps/docs/package.json.tpl` → `apps/docs/package.json` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/public/fonts/font-sources.json` → `apps/docs/public/fonts/font-sources.json` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/public/fonts/geist-serif-LICENSE.txt` → `apps/docs/public/fonts/geist-serif-LICENSE.txt` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/public/fonts/geist-serif-OFL.txt` → `apps/docs/public/fonts/geist-serif-OFL.txt` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/public/fonts/paper-mono-LICENSE.txt` → `apps/docs/public/fonts/paper-mono-LICENSE.txt` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/public/fonts/paper-mono-OFL.txt` → `apps/docs/public/fonts/paper-mono-OFL.txt` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/server.ts` → `apps/docs/server.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `apps/docs/site-name.txt.tpl` → `apps/docs/site-name.txt` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/src/components/code-block.tsx` → `apps/docs/src/components/code-block.tsx` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `apps/docs/src/components/markdown.tsx.tpl` → `apps/docs/src/components/markdown.tsx` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `apps/docs/src/components/shell.tsx.tpl` → `apps/docs/src/components/shell.tsx` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/src/router.tsx` → `apps/docs/src/router.tsx` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `apps/docs/src/routes/__root.tsx.tpl` → `apps/docs/src/routes/__root.tsx` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/src/routes/docs/$.tsx` → `apps/docs/src/routes/docs/$.tsx` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/src/routes/index.tsx` → `apps/docs/src/routes/index.tsx` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/src/routes/published/$.ts` → `apps/docs/src/routes/published/$.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `apps/docs/src/server/content.ts.tpl` → `apps/docs/src/server/content.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/vite.config.ts` → `apps/docs/vite.config.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `content/docs/index.md` → `content/docs/index.md` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `content.config.json` → `content.config.json` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `gitignore-docs.tpl` → `.gitignore` (appends one line to a file another module owns, if absent) — Managed: owned and reconciled by Seihou updates
- `Copy` `justfile` → `justfile` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `nix/docs-microapp.nix.tpl` → `nix/docs-microapp.nix` — Managed: owned and reconciled by Seihou updates
- `Template` `package.json.tpl` → `package.json` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `packages/corpus/package.json.tpl` → `packages/corpus/package.json` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `packages/corpus/src/index.ts` → `packages/corpus/src/index.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `packages/corpus/src/types.ts` → `packages/corpus/src/types.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `packages/ui/NOTICE.md` → `packages/ui/NOTICE.md` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `packages/ui/components.json.tpl` → `packages/ui/components.json` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `packages/ui/package.json.tpl` → `packages/ui/package.json` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `packages/ui/src/components.tsx` → `packages/ui/src/components.tsx` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `packages/ui/src/styles/globals.css` → `packages/ui/src/styles/globals.css` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `scripts/content.ts.tpl` → `scripts/content.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `tsconfig.json` → `tsconfig.json` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/public/fonts/geist-serif.woff2.base64` → `apps/docs/public/fonts/geist-serif.woff2.base64` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/public/fonts/paper-mono.woff2.base64` → `apps/docs/public/fonts/paper-mono.woff2.base64` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `nix/docs-microapp-app.nix` → `nix/docs-microapp-app.nix` — Managed: owned and reconciled by Seihou updates
- `Copy` `nix/docs-microapp-content.nix` → `nix/docs-microapp-content.nix` — Managed: owned and reconciled by Seihou updates
- `Copy` `nix/docs-microapp-image.nix` → `nix/docs-microapp-image.nix` — Managed: owned and reconciled by Seihou updates
- `Copy` `nix/docs-microapp-snapshot.py` → `nix/docs-microapp-snapshot.py` — Managed: owned and reconciled by Seihou updates
- `Template` `apps/docs/src/server/reader.server.ts.tpl` → `apps/docs/src/server/reader.server.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `packages/corpus/tests/reader.test.ts` → `packages/corpus/tests/reader.test.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `playwright.config.ts` → `playwright.config.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `tests/reader.spec.ts` → `tests/reader.spec.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `apps/docs/src/env.d.ts` → `apps/docs/src/env.d.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `packages/corpus/src/links.ts` → `packages/corpus/src/links.ts` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `README.md` → `README.md` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Copy` `scripts/dev.ts` → `scripts/dev.ts` — Seed: created once when absent, then project owned; updates and removal preserve it

## Removal

- delete `nix/docs-microapp.nix`
- delete `nix/docs-microapp-app.nix`
- delete `nix/docs-microapp-content.nix`
- delete `nix/docs-microapp-image.nix`
- delete `nix/docs-microapp-snapshot.py`
