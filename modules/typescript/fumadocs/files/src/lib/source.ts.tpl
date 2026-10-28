import { docs } from "collections/server"
import { loader } from "fumadocs-core/source"
import { lucideIconsPlugin } from "fumadocs-core/source/lucide-icons"

{{#if Eq docs.openapi true}}
import { openapi } from "./openapi"
{{/if}}
import { docsRoute } from "./shared"

// `collections/server` is a virtual module: fumadocs-mdx generates the
// `.source/` directory and the tsconfig `paths` alias `collections/*` ->
// `.source/*` makes it importable. `docs` is the collection from
// source.config.ts.
{{#if Eq docs.openapi true}}
//
// The `openapi` source adds one virtual page per operation of the OpenAPI
// document under `{{docs.openapi-base-dir}}/`. It reads the document on the
// server, so client code imports `docs` from `collections/browser` instead.
export const source = loader(
  {
    docs: docs.toFumadocsSource(),
    openapi: await openapi.staticSource({ baseDir: "{{docs.openapi-base-dir}}" }),
  },
  {
    baseUrl: docsRoute,
    plugins: [lucideIconsPlugin(), openapi.loaderPlugin()],
  },
)
{{#else}}
export const source = loader({
  source: docs.toFumadocsSource(),
  baseUrl: docsRoute,
  plugins: [lucideIconsPlugin()],
})
{{/if}}

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
{{#if Eq docs.openapi true}}
  if (page.type === "openapi") return getOpenAPIText(page)

{{/if}}
  const processed = await page.data.getText("processed")

  return `# ${page.data.title} (${page.url})

${processed}`
}
{{#if Eq docs.openapi true}}

type OpenAPIPage = Extract<(typeof source)["$inferPage"], { type: "openapi" }>

// OpenAPI pages have no MDX source: render each operation and the component
// schemas it references (transitively) as JSON, so the Markdown stands alone
// without the whole document.
function getOpenAPIText(page: OpenAPIPage) {
  const { operations = [] } = page.data.getOpenAPIPageProps()
  const { bundled } = page.data.getSchema()
  const json = (value: unknown) => "```json\n" + JSON.stringify(value, null, 2) + "\n```"

  const sections: string[] = []
  const refs = new Set<string>()
  for (const { method, path } of operations) {
    const operation = bundled.paths?.[path]?.[method]
    sections.push(`## ${method.toUpperCase()} ${path}`, json(operation))
    collectRefs(operation, refs)
  }

  const pending = [...refs]
  if (pending.length > 0) sections.push("## Schemas")
  // `pending` grows as referenced schemas reveal further references.
  for (let i = 0; i < pending.length; i++) {
    const target = resolvePointer(bundled, pending[i])
    sections.push(`### ${pending[i].slice(2)}`, json(target))
    const nested = new Set<string>()
    collectRefs(target, nested)
    for (const ref of nested) {
      if (!refs.has(ref)) {
        refs.add(ref)
        pending.push(ref)
      }
    }
  }

  return `# ${page.data.title} (${page.url})

${[page.data.description ?? "", ...sections].filter(Boolean).join("\n\n")}`
}

function collectRefs(value: unknown, refs: Set<string>) {
  if (Array.isArray(value)) {
    for (const item of value) collectRefs(item, refs)
  } else if (value && typeof value === "object") {
    for (const [key, item] of Object.entries(value)) {
      if (key === "$ref" && typeof item === "string" && item.startsWith("#/")) refs.add(item)
      else collectRefs(item, refs)
    }
  }
}

// Resolve a local JSON pointer like `#/components/schemas/Note`.
function resolvePointer(document: unknown, ref: string): unknown {
  return ref
    .slice(2)
    .split("/")
    .map((key) => key.replaceAll("~1", "/").replaceAll("~0", "~"))
    .reduce<unknown>(
      (node, key) =>
        node && typeof node === "object" ? (node as Record<string, unknown>)[key] : undefined,
      document,
    )
}
{{/if}}
