// Report pages whose cited source files changed between their verified revision and a
// candidate revision of the documented project. Run it before moving the pin.
//
//   bun scripts/report-source-drift.mjs --to <candidate-revision>
import { execFileSync } from "node:child_process"
import { existsSync, readFileSync } from "node:fs"
import { join } from "node:path"

import { pages, requirePin, root, sourceRefs } from "./doc-pages.mjs"
import { sourceRoot } from "./prepare-source-pin.mjs"

const candidate = process.argv.slice(2).find((arg) => arg !== "--" && arg !== "--to")
if (!candidate) {
  console.error("usage: report-source-drift.mjs --to <candidate-revision>")
  process.exit(2)
}

const pin = requirePin()
const repository = sourceRoot(pin.project)
const registerPath = process.env.VERIFICATION_FILE ?? join(root, "docs/verification.json")
const register = existsSync(registerPath) ? JSON.parse(readFileSync(registerPath, "utf8")) : {}
const changedCache = new Map()

function changedSince(revision) {
  if (!changedCache.has(revision)) {
    const output = execFileSync(
      "git",
      ["-C", repository, "diff", "--name-only", revision, candidate],
      {
        encoding: "utf8",
        maxBuffer: 64 * 1024 * 1024,
      },
    )
    changedCache.set(revision, new Set(output.split("\n").filter(Boolean)))
  }
  return changedCache.get(revision)
}

let drifted = 0
for (const { key, source } of pages()) {
  const revision = register[key]?.verifiedRevision
  if (!revision) continue
  const changed = changedSince(revision)
  const paths = [...new Set(sourceRefs(source).map((ref) => ref.path))].filter((path) =>
    changed.has(path),
  )
  if (paths.length) {
    drifted += 1
    console.log(`${key} (verified at ${revision.slice(0, 12)})`)
    for (const path of paths) console.log(`  ${path}`)
  }
}

console.log(`${drifted} page(s) cite files changed by ${candidate}.`)
