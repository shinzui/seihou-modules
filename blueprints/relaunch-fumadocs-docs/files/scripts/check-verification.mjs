// Gate: every page has a record in docs/verification.json, verified at the pin.
// The record format is described by verification.schema.json in the relaunch blueprint.
import { existsSync, readFileSync } from "node:fs"
import { join } from "node:path"

import { pages, report, requirePin, root } from "./doc-pages.mjs"

const pin = requirePin()
const forms = new Set(["tutorial", "how-to", "reference", "explanation", "walkthrough", "landing"])
const registerPath = join(root, "docs/verification.json")
const register = existsSync(registerPath) ? JSON.parse(readFileSync(registerPath, "utf8")) : {}
const errors = []
const keys = new Set()

for (const { key } of pages()) {
  keys.add(key)
  const record = register[key]
  if (!record) {
    errors.push(`${key}: no record in docs/verification.json`)
    continue
  }
  if (!forms.has(record.form)) errors.push(`${key}: unknown form "${record.form}"`)
  if (!record.reader?.trim()) errors.push(`${key}: record names no reader`)
  if (record.verifiedRevision !== pin.revision)
    errors.push(`${key}: verifiedRevision is not the pinned revision`)
  if (!Array.isArray(record.environments) || record.environments.length === 0)
    errors.push(`${key}: record names no environments`)
  if (!Array.isArray(record.ran)) errors.push(`${key}: "ran" must be a list`)
  if (!Array.isArray(record.notChecked)) errors.push(`${key}: "notChecked" must be a list`)
}

for (const key of Object.keys(register))
  if (key !== "$schema" && !keys.has(key))
    errors.push(`${key}: record has no page under content/docs`)

report(errors, `Verification register OK: ${keys.size} page(s) at ${pin.revision.slice(0, 12)}.`)
