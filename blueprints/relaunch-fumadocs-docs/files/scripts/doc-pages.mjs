// Shared helpers for the documentation gates.
//
// The pinned source lives in docs-source.json at the site root. Optional site settings
// live in docs-gates.json; every setting has a default, so the file may be absent.
import { existsSync, readFileSync, readdirSync } from "node:fs"
import { homedir } from "node:os"
import { basename, join, relative, resolve } from "node:path"

export const root = resolve(import.meta.dirname, "..")
export const docsRoot = join(root, "content/docs")

const pinPath = join(root, "docs-source.json")
const gatesPath = join(root, "docs-gates.json")

// The pin, or null before scripts/prepare-source-pin.mjs --init has written it.
export const pin = existsSync(pinPath) ? JSON.parse(readFileSync(pinPath, "utf8")) : null

export function requirePin() {
  if (!pin?.revision) {
    console.error("docs-source.json is missing. Run: bun scripts/prepare-source-pin.mjs --init")
    process.exit(2)
  }
  return pin
}

const gates = existsSync(gatesPath) ? JSON.parse(readFileSync(gatesPath, "utf8")) : {}

export const settings = {
  // The directory named by the fumadocs module's docs.openapi-spec, relative to the site.
  openapiDir: gates.openapiDir ?? "openapi",
  // The fumadocs module's docs.openapi-base-dir: operation pages render under /docs/<dir>/.
  apiBaseDir: gates.apiBaseDir ?? "api",
  // Generated pages, relative to content/docs, that the prose gate does not read.
  generatedPages: gates.generatedPages ?? [],
  // Page used for the HTTP API index, and its wording.
  apiIndex: gates.apiIndex ?? {},
}

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}

// Text that must never appear in pages or published output: local home directories,
// mori:// links, this checkout's own path, and any extra patterns. Extra patterns come
// from docs-gates.json "privateText" and from DOCS_PRIVATE_TEXT (regular expressions
// separated by newlines), so a private word need not be committed to the repository.
export const privateText = new RegExp(
  [
    "/Users/",
    "/home/[a-z]",
    "mori://",
    // Deep checkout paths only: a short one such as /work also matches ordinary prose.
    ...[homedir(), root].filter((path) => path.split("/").length > 3).map(escapeRegExp),
    ...(gates.privateText ?? []),
    ...(process.env.DOCS_PRIVATE_TEXT ?? "").split("\n").filter(Boolean),
  ].join("|"),
)

// The subset checked in client bundles, where library code legitimately carries
// strings such as /home/ in examples: mori:// links and this checkout's own path.
export const bundlePrivateText = new RegExp(
  ["mori://", ...(root.split("/").length > 3 ? [escapeRegExp(root)] : [])].join("|"),
)

export function collect(directory, extension, files = []) {
  if (!existsSync(directory)) return files
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name)
    if (entry.isDirectory()) collect(path, extension, files)
    else if (entry.name.endsWith(extension)) files.push(path)
  }
  return files
}

// Every page, keyed the way docs/verification.json names it.
export function pages() {
  return collect(docsRoot, ".mdx").map((file) => ({
    file,
    key: relative(docsRoot, file).replace(/\.mdx$/, ""),
    source: readFileSync(file, "utf8"),
  }))
}

// Citations of the documented project's source on a page: <SourceRef path="..." symbol="..." />.
export function sourceRefs(source) {
  return [...source.matchAll(/<SourceRef\b([\s\S]*?)\/>/g)].map((match) => ({
    path: match[1].match(/\bpath="([^"]+)"/)?.[1],
    symbol: match[1].match(/\bsymbol="([^"]+)"/)?.[1],
  }))
}

// Parse one OpenAPI document. YAML needs Bun, which every gate runs under.
function parseDocument(file) {
  const text = readFileSync(file, "utf8")
  if (file.endsWith(".json")) return JSON.parse(text)
  if (!globalThis.Bun?.YAML) throw new Error(`${file}: run this script with bun to read YAML`)
  return globalThis.Bun.YAML.parse(text)
}

// The OpenAPI documents the fumadocs module renders, in the order it renders them:
// every .json, .yaml and .yml file in the openapi directory, sorted by name.
export function openapiDocuments() {
  const directory = join(root, settings.openapiDir)
  if (!existsSync(directory)) return []
  return readdirSync(directory)
    .filter((name) => /\.(json|ya?ml)$/.test(name))
    .toSorted()
    .map((name) => ({
      name,
      label: basename(name).replace(/\.(json|ya?ml)$/, ""),
      document: parseDocument(join(directory, name)),
    }))
}

export const methods = ["get", "put", "post", "delete", "patch", "head", "options", "trace"]

// Every operation, once per operationId. An operation that two documents share is
// rendered once, so it is listed once with every document that declares it.
export function openapiOperations() {
  const operations = new Map()
  for (const { label, document } of openapiDocuments()) {
    for (const [path, item] of Object.entries(document.paths ?? {})) {
      for (const method of methods) {
        const operation = item?.[method]
        if (!operation?.operationId) continue
        const existing = operations.get(operation.operationId)
        if (existing) existing.documents.push(label)
        else
          operations.set(operation.operationId, {
            id: operation.operationId,
            method: method.toUpperCase(),
            path,
            summary: operation.summary ?? "",
            documents: [label],
          })
      }
    }
  }
  return operations
}

export function report(errors, success) {
  if (errors.length) {
    for (const error of errors) console.error(error)
    console.error(`\n${errors.length} problem(s).`)
    process.exit(1)
  }
  console.log(success)
}
