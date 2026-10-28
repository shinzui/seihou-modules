# Fumadocs module 0.2.1 to 0.3.0

Follow the shared upgrade prompt. Adopt nix-bun-flake 0.4.0 and Fumadocs module
0.3.0, including Core/UI 16.17.9 and MDX 15.4.10. This edge tracks module versions,
not upstream library versions. Do not record it without an actual 0.2.1 origin.

Replace the deprecated useDocsSearch and staticClient pair in the search dialog
with useStaticSearch({ locale }) from fumadocs-core/search/client, spreading its
result into SearchDialog and rendering SearchDialogList without items. Adapt
customized search dialogs the same way rather than discarding their changes.

Replace beautiful-mermaid with @zombie-mermaid/svg-renderer and elkjs. Browser
bundles must call registerElk with the default export of elkjs/lib/elk.bundled.js
once before the first render; load both lazily with the renderer. Keep custom
themes and interaction code. Compare rendered diagrams before and after, since
fixes in the fork can change layout.

Correct the start script to serve .output/public with --config ../../serve.json;
serve resolves the configuration relative to the served directory.

OpenAPI reference pages are opt-in. Enable docs.openapi only when the project has
an OpenAPI document and asks for API pages, set docs.openapi-spec to it, and pick
a docs.openapi-base-dir no authored content uses. Record this edge only after
validation succeeds.
