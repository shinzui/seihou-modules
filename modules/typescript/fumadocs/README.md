# fumadocs

> Fumadocs documentation site on TanStack Start + Vite, layered on `nix-bun-flake`'s dev shell: a static-SPA docs app with self-hosted custom fonts, `zombie-mermaid` diagrams, an interactive zoom/pan/expand widget for every diagram, and optional OpenAPI reference pages.

**Version:** `0.3.0`

## Overview

Bootstraps a [Fumadocs](https://fumadocs.dev) documentation site running on TanStack
Start + Vite, configured to prerender a fully static SPA into `.output/public`. On top of
a stock Fumadocs scaffold it ships three opinionated customizations and one opt-in feature:

- **Self-hosted custom font.** A `predev`/`prebuild` hook (`scripts/copy-fonts.mjs`) builds
  a licensed font from a local Nix flake and copies the ligature OTFs into `public/fonts/`
  under stable, version-independent names. `@font-face` rules in `src/styles/app.css` route
  `--fd-font-mono` (and every code surface) at the font with contextual-ligature feature
  settings. The hook is tolerant: if the font package is unavailable it warns and exits 0,
  so dev/build still succeed with the system-monospace fallback.
- **Mermaid diagrams.** A rehype plugin (`src/lib/rehype-mermaid.ts`) rewrites
  ` ```mermaid ` fenced blocks into a `<Mermaid>` element *before* Shiki claims them, and the
  component renders SVG via [`@zombie-mermaid/svg-renderer`](https://www.npmjs.com/package/@zombie-mermaid/svg-renderer),
  the maintained fork of `beautiful-mermaid`, with light/dark theme palettes wired to the
  active fumadocs theme. Browser bundles must register ELK for graph layouts, so the
  component lazily loads the renderer and `elkjs` together and calls `registerElk` once.
  The renderer package is used instead of the umbrella `zombie-mermaid` package, which
  also installs its CLI and MCP server.
- **Zoom widget.** `src/components/mermaid.tsx` makes every diagram interactive: wheel-zoom
  toward the cursor, drag-pan, double-click-to-fit, a full-screen **Expand** overlay, and
  keyboard shortcuts (`+`/`-`/`0`/`Esc`). All interaction is driven through the SVG `viewBox`
  (no CSS transforms), so it stays crisp at any zoom.
- **OpenAPI reference (opt-in).** With `docs.openapi=true`, [`fumadocs-openapi`](https://fumadocs.dev/docs/integrations/openapi)
  reads the document named by `docs.openapi-spec` at build time and adds one page per
  operation under `/docs/<docs.openapi-base-dir>/`. The pages are prerendered, indexed by
  static search, and listed in the sidebar; their `.md` routes contain each operation and
  the component schemas it references. See [OpenAPI reference pages](#openapi-reference-pages).

This module **depends on `nix-bun-flake`**, which provides the reproducible Nix dev shell
(`bun`, `just`, `oxlint`, `oxfmt`, `typescript`), `flake.lock`, `.envrc`, and the base
`.gitignore`. It passes `nix.pre-commit = false` to that dependency (generated files like
`src/routeTree.gen.ts` and `.source/` don't play well with format/lint git hooks). This
module then overrides `package.json`, `tsconfig.json`, `justfile`, `.oxlintrc.json`, and
`.oxfmtrc.json` with Fumadocs-appropriate versions (the last two extend the ignore lists
with the generated `.source`, `.output`, `.nitro`, and `routeTree.gen.ts` paths).
Formatting also excludes the dependency-owned `nix/tooling-sources.json` metadata,
which is maintained by the shared toolchain updater.

This release targets `nix-bun-flake` **0.4.0**: Bun **1.4.2**, TypeScript **7.0.2**,
Oxlint **1.87.0**, Oxfmt **0.72.0**, and just **1.58.0**. TypeScript is supplied by
Nix; the application manifest no longer installs a second compiler. `@types/bun`
is pinned to **1.4.2**. Node-shebang application commands run explicitly under Bun
with `bun --bun run`.

Fumadocs Core/UI are pinned to **16.17.9**, MDX to **15.4.10**, and OpenAPI (when
enabled) to **12.5.6**. The compatible TanStack releases are React Start **1.169.4**,
React Router **1.170.46**, and static server functions **1.167.44**. Static search uses
Fumadocs' default ZBSearch engine through the `useStaticSearch()` hook, which replaced
the deprecated `useDocsSearch()` in Fumadocs 16.17. The exported `/api/search` index
still supports search on a static host. Diagrams use `@zombie-mermaid/svg-renderer`
**5.11** with `elkjs` **0.12**.

## Shared flake and upgrades

The dependency generates a thin flake-parts `flake.nix`, the canonical `flake.lock`,
and managed `nix/bun.nix`, `nix/tooling.nix`, and `nix/tooling-sources.json`. Hooks
stay disabled by default, while their input remains locked. Fumadocs shares the
same pinned input graph as standalone Bun projects; it does not generate its own
flake or lock. `nix flake update` cannot move the module-owned revisions.

Customize the shell through an unmanaged `flake.module.nix`, copied from
`flake.module.nix.example`, using `perSystem.bunProject.extraDevPackages`. The
module watches that file via direnv. Local environment exports belong in
`.envrc.local`.

For existing projects, install the new releases of both modules, then run:

```bash
seihou update nix-bun-flake
seihou update fumadocs
git add flake.nix flake.lock nix/
nix develop
just install
just check
```

Your global Bun configuration may reject these freshly published releases under
its minimum release age setting. For this upgrade, install the requested pins
with `bun install --minimum-release-age 0`; this leaves the global setting unchanged.

Review template conflicts during updates, especially in `package.json` and
customized `flake.nix` files. Move shell customizations to `flake.module.nix` so
later updates preserve them. Commit the regenerated `bun.lock` with the project.

Maintainers can exercise actual module composition and the static output with:

```bash
python3 scripts/test-fumadocs-bootstrap.py
python3 scripts/test-fumadocs-openapi.py
python3 scripts/test-fumadocs-adoption.py
```

Existing sites can set `docs.starter-content=false` to keep their documentation
outside scaffold generation and ownership. Starter content is retained when the
module is removed, so authored documentation is not deleted.

## OpenAPI reference pages

Enable the integration with `--var docs.openapi=true`. A new site with starter
content also gets an example document at `openapi.yaml` and lists the generated
folder in `content/docs/meta.json`. For an existing site, point
`docs.openapi-spec` at your document (a project-relative path or a URL) and add
`docs.openapi-base-dir` (default `api`) to the `pages` of your root `meta.json`
if it lists pages explicitly. Choose a base directory that no authored content uses.

```bash
seihou run fumadocs --var docs.openapi=true --var docs.openapi-spec=spec/service.yaml
```

The document is read when the site builds, so a URL must be reachable then. Each
operation page carries the bundled document in its prerendered page data, so a
very large specification grows every operation's static payload. The interactive
playground sends requests from the reader's browser, which needs the API to allow
cross-origin requests from the docs host.

## Variables

| Name | Type | Default | Required | Validation | Description |
|------|------|---------|----------|------------|-------------|
| `project.name` | `text` | — | yes | `[a-z][a-z0-9-]*` | Package name. Inherited from `nix-bun-flake` (it exports `project.name`). |
| `project.description` | `text` | — | yes | — | One-line description (package.json + home page). Inherited from `nix-bun-flake`. |
| `docs.starter-content` | `bool` | `true` | yes | — | Generate demo content; disable for adoption of an existing site. |
| `docs.openapi` | `bool` | `false` | yes | — | Generate API reference pages from an OpenAPI document with `fumadocs-openapi`. |
| `docs.openapi-spec` | `text` | `openapi.yaml` | yes | — | OpenAPI document (project-relative path or URL); new sites with starter content get an example. |
| `docs.openapi-base-dir` | `text` | `api` | yes | `[a-z][a-z0-9-]*` | Docs folder for the generated pages, served under `/docs/<dir>/`. |
| `docs.site-name` | `text` | — | yes | — | Site/nav title shown in the navbar and browser tab. |
| `docs.github-user` | `text` | `shinzui` | yes | — | GitHub owner for the navbar + edit-on-GitHub links. |
| `docs.github-branch` | `text` | `master` | yes | — | Branch used in edit-on-GitHub links. |
| `docs.font-family` | `text` | `PragmataPro Mono` | yes | — | CSS `font-family` for the self-hosted code font. |
| `docs.font-basename` | `text` | `PragmataProMono` | yes | — | Stable file-name prefix written into `public/fonts/` (referenced by `@font-face`). |
| `docs.font-flake` | `text` | `/Users/shinzui/Keikaku/bokuno/fonts` | yes | — | Local Nix flake path the copy step builds to source the OTFs. |
| `docs.font-package` | `text` | `pragmataPro` | yes | — | Package attribute built from `docs.font-flake` (`path:<flake>#<package>`). |

`project.name` and `project.description` are inherited from the `nix-bun-flake` dependency
(prompted once, there), so they are not re-prompted here.

## Prompts

The following values are asked interactively (unless supplied via `--var`):

- **`docs.site-name`** — Site title? (shown in the navbar and browser tab)
- **`docs.github-user`** — GitHub owner for the repo link and edit-on-GitHub links?
- **`docs.font-family`** — Custom code/monospace font-family name?

The remaining `docs.font-*` vars carry defaults and are only set via `--var`.

## Dependencies

- **`nix-bun-flake`** (with `nix.pre-commit = false`) — provides the Nix dev shell, `flake.lock`,
  `.envrc`, and base `.gitignore`, and exports `project.name` + `project.description`.

## Generated Files

When run (after the `nix-bun-flake` dependency), this module writes:

- `package.json` — strategy: `template` (overrides the dependency's)
- `tsconfig.json`, `justfile`, `.oxlintrc.json`, `.oxfmtrc.json` — strategy: `copy` (override the dependency's)
- `vite.config.ts`, `source.config.ts`, `linkinator.config.json`, `serve.json` — strategy: `copy`
- `scripts/copy-fonts.mjs` — strategy: `template`
- `src/router.tsx`, `src/routeTree.gen.ts` — strategy: `copy`
- `src/lib/cn.ts`, `src/lib/layout.shared.tsx`, `src/lib/rehype-mermaid.ts` — strategy: `copy`
- `src/lib/source.ts`, `src/lib/shared.ts` — strategy: `template`
- `src/lib/openapi.ts` — strategy: `template`, when `docs.openapi=true`
- `src/components/{mdx,mermaid,search,not-found}.tsx` — strategy: `copy`
- `src/components/api-page.tsx` — strategy: `copy`, when `docs.openapi=true`
- `src/styles/app.css` — strategy: `template`
- `src/routes/{__root,index}.tsx`, `src/routes/docs/{$}[.]md.ts`, `src/routes/api/search.ts` — strategy: `copy`
- `src/routes/docs/$.tsx` — strategy: `template`
- `content/docs/index.mdx`, `content/docs/meta.json` — strategy: `template`, when `docs.starter-content=true`
- `content/docs/diagram-demo.mdx` — strategy: `copy`, when `docs.starter-content=true`
- `openapi.yaml` — strategy: `copy`, when `docs.openapi=true`, `docs.starter-content=true`, and `docs.openapi-spec` is the default
- `.gitignore` — strategy: `template`, patch mode: `append-line-if-absent` (adds `.source`, `.output`, `.nitro`, `public/fonts`, …)

## Removal

This module supports removal via:

```bash
seihou remove fumadocs
```

Removal removes the Fumadocs-specific files it created (the app, components, styles, scripts,
excluding documentation content and the OpenAPI document). Shared files it overrode from `nix-bun-flake`
(`package.json`, `tsconfig.json`, `justfile`, `.oxlintrc.json`, `.oxfmtrc.json`) are
not explicit removal steps; review shared ownership before regenerating Bun-only
versions. Lines appended to `.gitignore` are left in place.

## Usage

Apply the module (pulls in `nix-bun-flake`):

```bash
seihou run fumadocs
```

With variable overrides:

```bash
seihou run fumadocs \
  --var project.name=acme-docs \
  --var project.description="Acme product documentation" \
  --var docs.site-name="Acme Docs" \
  --var docs.github-user=acme \
  --var docs.font-family="PragmataPro Mono"
```

Preview without writing files:

```bash
seihou run fumadocs --dry-run
```

Once generated, enter the dev shell (`direnv allow` or `nix develop`) and:

```bash
just install      # bun install (runs the fumadocs-mdx postinstall)
just dev          # vite dev on http://localhost:3000 (copies fonts first)
just build        # static build into .output/public
just typecheck    # fumadocs-mdx + tsc --noEmit
just check        # typecheck + lint + format-check + build
```

Then open `/docs/diagram-demo` to confirm fonts and interactive Mermaid diagrams render.

## See Also

- `module.dhall` — full module definition and authoritative source
- `files/` — template sources
- [`nix-bun-flake`](../nix-bun-flake/README.md) — the dev-shell dependency
