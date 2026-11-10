// Gate: every page is prerendered and searchable, and no output leaks a private path.
// Run after the build, from the site root.
import { existsSync, readFileSync } from "node:fs"
import { join, relative } from "node:path"

import { bundlePrivateText, collect, pages, privateText, report, root } from "./doc-pages.mjs"

const publicRoot = join(root, ".output/public")
const errors = []

function route(key) {
  const path = key === "index" ? "" : key.replace(/\/index$/, "").replace(/^index$/, "")
  return path ? `/docs/${path}` : "/docs"
}

const routes = pages().map(({ key }) => route(key))

for (const url of routes) {
  const file = join(publicRoot, url, "index.html")
  if (!existsSync(file)) errors.push(`${url}: missing ${relative(root, file)}`)
}

const searchFile = join(publicRoot, "api/search")
if (!existsSync(searchFile)) {
  errors.push("/api/search: missing generated search JSON")
} else {
  const text = readFileSync(searchFile, "utf8")
  for (const url of routes)
    if (!text.includes(`"${url}"`)) errors.push(`/api/search: missing document ${url}`)
  if (privateText.test(text)) errors.push("/api/search: contains a private path or mori:// link")
}

// Pages and raw Markdown routes get the full scan. Client bundles get the narrower one,
// which still catches a mori:// URI bundled by importing all of docs-source.json.
const scans = [
  [[".html", ".md", ".txt"], privateText],
  [[".js", ".json"], bundlePrivateText],
]
for (const [extensions, pattern] of scans) {
  for (const extension of extensions) {
    for (const file of collect(publicRoot, extension)) {
      const match = readFileSync(file, "utf8").match(pattern)
      if (match) errors.push(`${relative(publicRoot, file)}: contains "${match[0]}"`)
    }
  }
}

report(errors, `Static output OK: ${routes.length} route(s) prerendered and searchable.`)
