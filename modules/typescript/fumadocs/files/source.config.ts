import { defineConfig, defineDocs } from "fumadocs-mdx/config"

import { rehypeMermaid } from "./src/lib/rehype-mermaid"

// Docs collection: every .mdx under content/docs/ becomes a page.
// `includeProcessedMarkdown` keeps a plain-markdown copy of each page so the
// static client loader (and the raw-markdown / llms.txt routes) can use it.
export const docs = defineDocs({
  dir: "content/docs",
  docs: {
    postprocess: {
      includeProcessedMarkdown: true,
    },
  },
})

// `themes` pins a light/dark Shiki pair (fumadocs renders both and CSS shows the
// right one per theme). `langs` preloads the grammars the docs use. We do NOT
// pass `transformers`, so fumadocs' default code transformers (notation
// highlight/diff/focus) are preserved.
export default defineConfig({
  mdxOptions: {
    rehypeCodeOptions: {
      themes: { light: "github-light", dark: "github-dark" },
      langs: ["bash", "json", "ts", "tsx", "typescript"],
    },
    // Turn ```mermaid fences into <Mermaid> before any code highlighting runs.
    // The function form prepends rehypeMermaid to the default plugin array (`v`,
    // which includes fumadocs' built-in Shiki `rehypeCode`), so our plugin runs
    // FIRST and removes the language-mermaid pre/code node before Shiki can claim
    // it. The plain array form `[rehypeMermaid]` runs AFTER the defaults, by which
    // point Shiki has already rewritten the node and the match no longer fires.
    rehypePlugins: (v) => [rehypeMermaid, ...v],
  },
})
