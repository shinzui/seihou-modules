import { docs } from "collections/server"
import { loader } from "fumadocs-core/source"
import { lucideIconsPlugin } from "fumadocs-core/source/lucide-icons"

import { docsRoute } from "./shared"

// `collections/server` is a virtual module: fumadocs-mdx generates the
// `.source/` directory and the tsconfig `paths` alias `collections/*` ->
// `.source/*` makes it importable. `docs` is the collection from
// source.config.ts.
export const source = loader({
  source: docs.toFumadocsSource(),
  baseUrl: docsRoute,
  plugins: [lucideIconsPlugin()],
})

// Map a docs slug array to the `.md` path used for raw-markdown links.
export function slugsToMarkdownPath(slugs: string[]) {
  const segments = [...slugs]
  if (segments.length === 0) {
    segments.push("index.md")
  } else {
    segments[segments.length - 1] += ".md"
  }

  return {
    segments,
    url: `${docsRoute}/${segments.join("/")}`,
  }
}

// Inverse of slugsToMarkdownPath: strip the trailing `.md` and drop a bare
// `index` so the raw-markdown route can look the page up.
export function markdownPathToSlugs(segs: string[]) {
  if (segs.length === 0) return []

  const out = [...segs]
  out[out.length - 1] = out[out.length - 1].replace(/\.md$/, "")
  if (out.length === 1 && out[0] === "index") out.pop()
  return out
}

// Plain-markdown body for a page, used by the raw-markdown route (and any
// future llms.txt routes). Relies on `includeProcessedMarkdown` in
// source.config.ts.
export async function getLLMText(page: (typeof source)["$inferPage"]) {
  const processed = await page.data.getText("processed")

  return `# ${page.data.title} (${page.url})

${processed}`
}
