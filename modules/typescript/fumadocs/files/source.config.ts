import { createHighlights } from "fumadocs-core/highlight/highlights"
import { rehypeCodeFromHighlighter } from "fumadocs-core/mdx-plugins/rehype-code.core"
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

// Code blocks are highlighted by @pierre/highlights, whose languages are built in.
// `rehypeCodeOptions: false` removes fumadocs' Shiki rehypeCode; the replacement
// receives fumadocs' default code transformers (notation highlight/diff/focus,
// titles, icons) and runs them on the Highlights tokens. Its default themes are
// GitHub Light and GitHub Dark, rendered together and switched by CSS.
//
// Order matters: rehypeMermaid must come FIRST so that ```mermaid fences become a
// <Mermaid> element before the highlighter rewrites the pre/code node.
const highlighter: Parameters<typeof rehypeCodeFromHighlighter>[0] = ({ transformers }) =>
  createHighlights({ shikiTransformers: transformers })

export default defineConfig({
  mdxOptions: {
    rehypeCodeOptions: false,
    rehypePlugins: (v) => [rehypeMermaid, [rehypeCodeFromHighlighter, highlighter], ...v],
  },
})
