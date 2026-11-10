// Gate for hand-authored SVG diagrams (content/diagrams/**.svg).
//
// - Every <Diagram src="..."> in content/docs resolves to a file and has alt text.
// - Every diagram file is used by at least one page.
// - Every diagram file is well-formed, has a viewBox, and follows the authoring
//   contract in content/diagrams/README.md (no inline <style>, no color literals,
//   no redefinition of the built-in marker ids).
import { readFileSync, readdirSync } from "node:fs"
import { join, relative, resolve } from "node:path"

import { BUILTIN_MARKER_IDS } from "../src/lib/diagram-svg.mjs"

const root = resolve(import.meta.dirname, "..")
const docs = join(root, "content/docs")
const diagrams = join(root, "content/diagrams")

function collect(directory, extension, files = []) {
  for (const entry of readdirSync(directory, { withFileTypes: true })) {
    const path = join(directory, entry.name)
    if (entry.isDirectory()) collect(path, extension, files)
    else if (entry.name.endsWith(extension)) files.push(path)
  }
  return files
}

const errors = []
const fail = (file, detail) => errors.push(`${relative(root, file)}: ${detail}`)

const svgFiles = new Map(
  collect(diagrams, ".svg").map((path) => [relative(diagrams, path).replace(/\.svg$/, ""), path]),
)
const used = new Set()

for (const page of collect(docs, ".mdx")) {
  const source = readFileSync(page, "utf8")
  for (const match of source.matchAll(/<Diagram\b([\s\S]*?)\/>/g)) {
    const attrs = match[1]
    const src = attrs.match(/\bsrc="([^"]+)"/)?.[1]
    const alt = attrs.match(/\balt="([^"]*)"/)?.[1]
    if (!src) fail(page, "<Diagram> without src")
    else if (!svgFiles.has(src))
      fail(page, `<Diagram src="${src}"> has no content/diagrams/${src}.svg`)
    else used.add(src)
    if (!alt || alt.trim().length < 10)
      fail(page, `<Diagram src="${src}"> needs descriptive alt text`)
  }
}

// A small well-formedness check: balanced tags and quoted attributes.
function wellFormed(source) {
  const body = source
    .replace(/<!--[\s\S]*?-->/g, "")
    .replace(/<\?[\s\S]*?\?>/g, "")
    .replace(/<!DOCTYPE[\s\S]*?>/gi, "")
  const stack = []
  for (const tag of body.matchAll(
    /<(\/?)([A-Za-z][\w:.-]*)((?:\s+[\w:.-]+\s*=\s*(?:"[^"]*"|'[^']*'))*)\s*(\/?)>/g,
  )) {
    const [, closing, name, , selfClosing] = tag
    if (selfClosing) continue
    if (closing) {
      const open = stack.pop()
      if (open !== name) return `</${name}> closes <${open ?? "nothing"}>`
    } else stack.push(name)
  }
  if (stack.length) return `unclosed <${stack.at(-1)}>`
  const stray = body.replace(
    /<(\/?)([A-Za-z][\w:.-]*)((?:\s+[\w:.-]+\s*=\s*(?:"[^"]*"|'[^']*'))*)\s*(\/?)>/g,
    "",
  )
  if (/[<>]/.test(stray)) return "malformed tag or unescaped < > in text (use &lt; &gt;)"
  if (/&(?!(?:amp|lt|gt|quot|apos|#\d+|#x[0-9a-fA-F]+);)/.test(stray))
    return "unescaped & (use &amp;)"
  return null
}

for (const [name, path] of svgFiles) {
  const source = readFileSync(path, "utf8")
  if (!used.has(name)) fail(path, "not used by any page")
  const problem = wellFormed(source)
  if (problem) fail(path, problem)
  const open = source.match(/<svg\b[^>]*>/)
  if (!open) fail(path, "no root <svg>")
  else {
    if (!/viewBox="[^"]+"/.test(open[0])) fail(path, "root <svg> needs a viewBox")
    if (!/xmlns="http:\/\/www\.w3\.org\/2000\/svg"/.test(open[0]))
      fail(path, "root <svg> needs xmlns")
  }
  if (/<style\b/.test(source))
    fail(path, "inline <style> is not allowed; use classes from diagrams.css")
  if (
    /\b(?:fill|stroke|color|stop-color)\s*[=:]\s*"?\s*(?:#|rgb|hsl|black|white|red|blue|green|gray|grey)/i.test(
      source,
    )
  )
    fail(path, 'color literal found; use semantic classes (fill="none" is allowed)')
  for (const id of BUILTIN_MARKER_IDS)
    if (source.includes(`id="${id}"`)) fail(path, `id="${id}" is reserved for a built-in marker`)
}

if (errors.length) {
  for (const error of errors) console.error(error)
  console.error(`\n${errors.length} diagram problem(s).`)
  process.exit(1)
}
console.log(`Diagrams OK: ${svgFiles.size} SVG file(s), ${used.size} referenced.`)
