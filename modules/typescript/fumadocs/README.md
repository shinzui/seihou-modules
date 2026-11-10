# fumadocs

> Fumadocs documentation site on TanStack Start + Vite, layered on `nix-bun-flake`'s dev shell: a static-SPA docs app with self-hosted custom fonts, `zombie-mermaid` diagrams, an interactive zoom/pan/expand widget for every diagram, optional OpenAPI reference pages, and an optional Caddy container image built with nix2container.

**Version:** `0.6.2`

## Overview

Bootstraps a [Fumadocs](https://fumadocs.dev) documentation site running on TanStack
Start + Vite, configured to prerender a fully static SPA into `.output/public`. Every file under
`content/docs` is prerendered, including pages that no `meta.json` lists, and the link crawl
adds whatever those pages link to. On top of
a stock Fumadocs scaffold it ships three opinionated customizations and one opt-in feature:

- **Self-hosted custom font.** A `predev`/`prebuild` hook (`scripts/copy-fonts.mjs`) builds
  a licensed font from a local Nix flake and copies the ligature OTFs into `public/fonts/`
  under stable, version-independent names. `@font-face` rules in `src/styles/app.css` route
  `--fd-font-mono` (and every code surface) at the font with contextual-ligature feature
  settings. The hook is tolerant: if the font package is unavailable it warns and exits 0,
  so dev/build still succeed with the system-monospace fallback.
- **Mermaid diagrams.** A rehype plugin (`src/lib/rehype-mermaid.ts`) rewrites
  ` ```mermaid ` fenced blocks into a `<Mermaid>` element *before* the code highlighter claims them, and the
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

Fumadocs Core/UI are pinned to **16.18.4**, MDX to **15.5.3**, and OpenAPI (when
enabled) to **12.6.0**. The compatible TanStack releases are React Start **1.169.4**,
React Router **1.170.46**, and static server functions **1.167.44**. Static search uses
Fumadocs' default ZBSearch engine through the `useStaticSearch()` hook, which replaced
the deprecated `useDocsSearch()` in Fumadocs 16.17. The exported `/api/search` index
still supports search on a static host. Diagrams use `@zombie-mermaid/svg-renderer`
**5.11** with `elkjs` **0.12**.

Code blocks are highlighted by [`@pierre/highlights`](https://www.npmjs.com/package/@pierre/highlights)
**0.5.0** through Fumadocs' `createHighlights()`, not Shiki. `source.config.ts` sets
`rehypeCodeOptions: false` and adds `rehypeCodeFromHighlighter`, which still runs Fumadocs'
default code transformers on the Highlights tokens. OpenAPI pages use
`createOpenAPIPageBase` from `fumadocs-openapi/ui/base` with the same highlighter.
Fumadocs 16.18.4 declares `@pierre/highlights` `^0.2.0` as an optional peer; 0.5.0 is
qualified here and accepted by upstream's `0.x.x` range on `main`. Shiki remains a
transitive dependency of Fumadocs. With OpenAPI enabled, the manifest declares `shiki`
directly: `fumadocs-openapi` imports its Oniguruma engine on the server, and under the
isolated Bun linker that the Nix build uses, an undeclared Shiki is not resolvable from
the project root, so Rolldown would try to bundle `onig.wasm` and fail.

`docs.openapi-spec` may name a directory: every `.json`, `.yaml` and `.yml` document in it
is rendered, in sorted order, so a project with several OpenAPI documents needs no change to
`src/lib/openapi.ts`.

`docs.svg-diagrams=true` (default `false`) generates hand-authored SVG diagram support:
`<Diagram src alt caption>` in `src/components/diagram.tsx`, theme-aware semantic classes in
`src/styles/diagrams.css`, the authoring contract in `content/diagrams/README.md`, a preview
renderer (`bun run preview:diagram -- <name>`, which needs Chrome) and the `lint:diagrams`
gate, which `check` runs. Diagram files carry no colors, so one file follows both themes.

`lint:links` starts a crawl at `docs/index.html` and skips only external URLs. Earlier
releases skipped every URL, including the local server's, and so checked nothing.
`tsconfig.json` excludes `agents/`, and formatting ignores `docs/plans`, `docs/masterplans`
and `docs/friction-log`, so sites with the planning skills pass `check`.

`docs.font-flake` defaults to empty. The font copy step reads `DOCS_FONT_FLAKE` first, so a
public repository can set the flake path in an ignored `.envrc.local` instead of committing it.

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
python3 scripts/test-fumadocs-container.py --native-linux x86_64-linux
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

## Container image

Three variables together build the static site in the Nix sandbox and serve it from a
non-root Caddy image built with `nix2container`. Without them, a site is unchanged by this
feature, and the lock is the same either way. Seihou dependency bindings are static literals,
and adding one changes a dependency's identity, so this module cannot set the other two for you.

```bash
seihou update fumadocs --dry-run --var docs.container=true --var nix.bun2nix=true \
  --var nix.package-module=nix/fumadocs-container.nix
seihou update fumadocs --var docs.container=true --var nix.bun2nix=true \
  --var nix.package-module=nix/fumadocs-container.nix
bun install
nix run .#bun2nix -- --lock-file bun.lock --output-file bun-deps.nix
git add flake.nix flake.lock nix/ bun.lock bun-deps.nix
nix build .#docs-site
```

`bun-deps.nix` is yours to generate and commit, and `docs-site` stays absent until Git tracks
it. Regenerate it whenever `bun.lock` changes. On Linux:

```bash
nix build .#dockerImage
nix run .#dockerImage.copyToDockerDaemon
nix run .#dockerImage.copyToRegistry
nix run .#dockerImage.copyTo -- oci-archive:/absolute/artifacts/docs.tar:docs:latest
```

The build result is an image description, so `docker load < result` does not work. macOS
omits `dockerImage`; build it in Linux CI or with a matching Linux builder. The site build
fails if prerendering did not produce `/docs` and its server-function data. Prerendering uses a local preview server, and
concurrent builds on one machine have produced incomplete sites, so build one site at a time.

The image runs as `65532:65532` on port 8080, with Caddy and the site in separate layers. It
serves plain HTTP, has no Caddy admin API, and runs on a read-only root filesystem. `nix/caddy-config.nix` validates a Caddyfile
that matches `serve.json`: pages resolve to their prerendered HTML and anything else falls
back to `_shell.html`. Missing `/assets/*` and `/fonts/*` files return 404 and are not cached.
Terminate TLS in front of the container.

Three limits apply to the sandboxed build:

- **Fonts.** `scripts/copy-fonts.mjs` cannot reach the font flake from the sandbox and falls
  back to system monospace. To include fonts, track a directory holding the files `app.css`
  references (`<docs.font-basename>-Regular.otf` and so on) and set
  `perSystem.docsContainer.fonts = ./fonts;` in `flake.module.nix`. Check that the font's
  license permits redistributing them in an image.
- **Remote OpenAPI documents.** The sandbox has no network, so `docs.openapi-spec` must be a
  project-relative path.
- **Lifecycle scripts.** They do not run. The build runs `fumadocs-mdx` itself, so a
  `postinstall` you add to `package.json` is skipped.

To turn the feature off, first remove any `docsContainer` setting from `flake.module.nix`,
because the option disappears with the module and Nix would reject the flake. Then set
`docs.container` and `nix.bun2nix` to false. Unedited managed files are removed; `bun.lock`, `bun-deps.nix` and `flake.module.nix` are kept. The
`nix.package-module` import remains but is guarded by the file's existence, so it is inert. Keep `nix-bun-flake` at 0.6.0 or
later, which provides the `nix2container` input. The image recipe is managed by this module,
so customize it by changing `docsContainer` options rather than editing `nix/container.nix`.

## Variables

| Name | Type | Default | Required | Validation | Description |
|------|------|---------|----------|------------|-------------|
| `project.name` | `text` | — | yes | `[a-z][a-z0-9-]*` | Package name. Inherited from `nix-bun-flake` (it exports `project.name`). |
| `project.description` | `text` | — | yes | — | One-line description (package.json + home page). Inherited from `nix-bun-flake`. |
| `docs.starter-content` | `bool` | `true` | yes | — | Generate demo content; disable for adoption of an existing site. |
| `docs.openapi` | `bool` | `false` | yes | — | Generate API reference pages from an OpenAPI document with `fumadocs-openapi`. |
| `docs.openapi-spec` | `text` | `openapi.yaml` | yes | — | OpenAPI document (project-relative path or URL); new sites with starter content get an example. |
| `docs.openapi-base-dir` | `text` | `api` | yes | `[a-z][a-z0-9-]*` | Docs folder for the generated pages, served under `/docs/<dir>/`. |
| `docs.container` | `bool` | `false` | yes | — | Generate the Nix site build and Caddy image; also requires `nix.bun2nix=true` and `nix.package-module=nix/fumadocs-container.nix`. |
| `docs.site-name` | `text` | — | yes | — | Site/nav title shown in the navbar and browser tab. |
| `docs.github-user` | `text` | `shinzui` | yes | — | GitHub owner for the navbar + edit-on-GitHub links. |
| `docs.github-repo` | `text` | `project.name` | no | `[A-Za-z0-9._-]+` | Optional GitHub repository override for navbar/edit links. |
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
- `nix/fumadocs-container.nix` — strategy: `template`, when `docs.container=true`
- `nix/fumadocs-site.nix`, `nix/caddy-config.nix`, `nix/container.nix` — strategy: `copy`, when `docs.container=true`
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

`docs.github-repo` optionally overrides the repository name in navbar and edit links;
it defaults to `project.name`. Version 0.4.1 adds this input without changing ordinary
site defaults. The `fumadocs-project` wrapper defaults these links to the created remote
while preserving explicit overrides.
