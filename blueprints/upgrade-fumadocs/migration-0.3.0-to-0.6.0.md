# Fumadocs module 0.3.0 to 0.6.0

Follow the shared upgrade prompt. Adopt nix-bun-flake 0.6.1 and Fumadocs module
0.6.0, including Core/UI 16.18.4, MDX 15.5.3 and, when enabled, OpenAPI 12.6.0.
This edge tracks module versions, not upstream library versions.

Code blocks are highlighted by @pierre/highlights instead of Shiki. In
source.config.ts set rehypeCodeOptions to false and add rehypeCodeFromHighlighter
with createHighlights() from fumadocs-core/highlight/highlights, after
rehypeMermaid and before the default plugins. Type the callback with
Parameters<typeof rehypeCodeFromHighlighter>[0]. Move any custom Shiki themes or
languages to Highlights options, and check that every fence language the site
uses still highlights; replace a language Highlights lacks with text.
OpenAPI pages use createOpenAPIPageBase from fumadocs-openapi/ui/base with the
same highlighter. With OpenAPI enabled, declare shiki directly so the isolated
Bun install of the Nix site build can resolve it; verify nix build .#docs-site.

docs.openapi-spec may name a directory, and every .json, .yaml and .yml document
in it is rendered. Use this for a project with several OpenAPI documents rather
than editing src/lib/openapi.ts.

docs.svg-diagrams=true generates the semantic SVG diagram system. If the site
already has a hand-ported copy, compare it with the generated files, keep only
real customizations, and move authored diagrams under content/diagrams/.

The link check now starts at docs/index.html and skips only external URLs; the
old skip pattern also skipped the local server, so it never checked anything.
Expect it to find real broken links, and fix them. tsconfig.json excludes
agents/, and formatting ignores docs/plans, docs/masterplans and
docs/friction-log.

docs.font-flake defaults to empty, and the font copy step reads DOCS_FONT_FLAKE
first. A site that relied on the old default should set DOCS_FONT_FLAKE in an
ignored .envrc.local instead of committing a local path.

seihou update cannot update an application created by the fumadocs-site recipe,
because it refuses the recipe's files under .seihou/. Reapply the recipe with
--force, --with-migrations and every variable, then restore local edits to
managed files from a backup. Record this edge only after validation succeeds.
