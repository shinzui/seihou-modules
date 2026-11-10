// Gate: the mechanical parts of the technical-docs writing rules
// (agents/skills/tech-docs/WRITING-RULES.md, installed by the technical-docs module).
import { relative } from "node:path"

import { docsRoot, pages, privateText, report, settings } from "./doc-pages.mjs"

const marketing = /\b(seamless(?:ly)?|powerful|blazing(?:ly)?|effortless(?:ly)?|simply)\b/i
const vagueHeading = /^(overview|introduction|installation|setup|usage)$/i
const shellFence = /^(bash|sh|shell|zsh)\b/
const generated = new Set(settings.generatedPages.map((page) => page.replace(/\.mdx$/, "")))

const errors = []

for (const { file, key, source } of pages()) {
  const page = relative(docsRoot, file)
  const skipProse = generated.has(key)
  let fence = null
  source.split("\n").forEach((text, index) => {
    const where = `${page}:${index + 1}`
    if (privateText.test(text)) errors.push(`${where}: local path or mori:// link`)
    const marker = text.match(/^\s*(```+|~~~+)\s*(.*)$/)
    if (marker) {
      fence = fence === null ? marker[2] : null
      return
    }
    if (fence !== null) {
      if (shellFence.test(fence) && /^\s*\$\s/.test(text))
        errors.push(`${where}: shell sample has a "$" prompt`)
      return
    }
    if (skipProse) return
    const word = text.match(marketing)
    if (word) errors.push(`${where}: marketing word "${word[0]}"`)
    const heading = text.match(/^#{1,6}\s+(.*?)\s*$/)
    if (heading && vagueHeading.test(heading[1]))
      errors.push(`${where}: heading "${heading[1]}" does not describe its section`)
  })
}

report(errors, "Prose rules OK.")
