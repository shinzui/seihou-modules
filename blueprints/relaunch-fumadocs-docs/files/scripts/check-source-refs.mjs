// Gate: every <SourceRef> names a file that exists at the pinned revision of the
// documented project, and any symbol occurs in that file.
import { spawnSync } from "node:child_process"
import { relative } from "node:path"

import { docsRoot, pages, report, requirePin, sourceRefs } from "./doc-pages.mjs"
import { sourceRoot } from "./prepare-source-pin.mjs"

const pin = requirePin()
const repository = sourceRoot(pin.project)
const errors = []
const cache = new Map()
let checked = 0

function fileAtPin(path) {
  if (!cache.has(path)) {
    const shown = spawnSync("git", ["-C", repository, "show", `${pin.revision}:${path}`], {
      encoding: "utf8",
      maxBuffer: 64 * 1024 * 1024,
    })
    cache.set(path, shown.status === 0 ? shown.stdout : null)
  }
  return cache.get(path)
}

for (const { file, source } of pages()) {
  const page = relative(docsRoot, file)
  for (const { path, symbol } of sourceRefs(source)) {
    checked += 1
    if (!path) {
      errors.push(`${page}: <SourceRef> without path`)
      continue
    }
    const contents = fileAtPin(path)
    if (contents === null) errors.push(`${page}: ${path} does not exist at ${pin.revision}`)
    else if (symbol && !contents.includes(symbol))
      errors.push(`${page}: symbol ${symbol} does not occur in ${path} at ${pin.revision}`)
  }
}

report(errors, `Source references OK: ${checked} citation(s) at ${pin.revision.slice(0, 12)}.`)
