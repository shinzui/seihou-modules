// Shared transform for hand-authored SVG diagrams under content/diagrams/.
//
// Used by the <Diagram> component (src/components/diagram.tsx) and by the
// preview/check scripts (scripts/render-diagram.mjs, scripts/check-doc-diagrams.mjs),
// so the browser and the local preview render the same markup.
//
// Authoring contract (see content/diagrams/README.md):
// - Colors come from semantic classes styled in src/styles/diagrams.css, never
//   from fill/stroke literals, so a diagram follows the light/dark theme.
// - Arrowheads reference the built-in markers `url(#arrow)`, `url(#arrow-<tone>)`
//   and `url(#dot)`; this transform injects them.
// - Every id is prefixed per instance, so two diagrams on one page never collide.

/** Tones shared by shapes, text, edges, and markers. */
export const DIAGRAM_TONES = ["accent", "amber", "violet", "rose", "green", "muted"]

/** Ids the transform injects. Diagram files must not define these ids. */
export const BUILTIN_MARKER_IDS = [
  "arrow",
  ...DIAGRAM_TONES.map((tone) => `arrow-${tone}`),
  "dot",
  ...DIAGRAM_TONES.map((tone) => `dot-${tone}`),
]

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
}

function escapeXml(text) {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
}

function markerDefs(prefix) {
  const arrow = (id, tone) =>
    `<marker id="${prefix}-${id}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path class="arrowhead${tone ? ` ${tone}` : ""}" d="M0,1 L10,5 L0,9 z"/></marker>`
  const dot = (id, tone) =>
    `<marker id="${prefix}-${id}" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="5" markerHeight="5"><circle class="arrowhead${tone ? ` ${tone}` : ""}" cx="5" cy="5" r="4"/></marker>`
  return [
    arrow("arrow"),
    ...DIAGRAM_TONES.map((tone) => arrow(`arrow-${tone}`, tone)),
    dot("dot"),
    ...DIAGRAM_TONES.map((tone) => dot(`dot-${tone}`, tone)),
  ].join("")
}

/**
 * Prepare raw SVG source for inline rendering.
 *
 * @param {string} raw the file contents
 * @param {string} prefix a per-instance id prefix (letters, digits, dashes)
 * @param {string} alt the accessible description
 * @returns {{ svg: string, width: number | null, height: number | null }}
 */
export function prepareDiagramSvg(raw, prefix, alt) {
  let svg = raw
    .replace(/<\?xml[\s\S]*?\?>/g, "")
    .replace(/<!DOCTYPE[\s\S]*?>/gi, "")
    // An inline <style> would apply to the whole page; styles live in diagrams.css.
    .replace(/<style[\s\S]*?<\/style>/g, "")
    .trim()

  const ids = new Set([...svg.matchAll(/\bid="([^"]+)"/g)].map((m) => m[1]))
  for (const id of [...ids, ...BUILTIN_MARKER_IDS]) {
    const e = escapeRegExp(id)
    svg = svg
      .replace(new RegExp(`\\bid="${e}"`, "g"), `id="${prefix}-${id}"`)
      .replace(new RegExp(`url\\(#${e}\\)`, "g"), `url(#${prefix}-${id})`)
      .replace(new RegExp(`href="#${e}"`, "g"), `href="#${prefix}-${id}"`)
  }

  const open = svg.match(/<svg\b[^>]*>/)
  if (!open) return { svg: "", width: null, height: null }
  const viewBox = open[0].match(/viewBox="([^"]+)"/)
  const [, , width, height] = viewBox
    ? viewBox[1]
        .trim()
        .split(/[\s,]+/)
        .map(Number)
    : []
  const root = open[0]
    .replace(/\s(?:width|height|role|aria-label)="[^"]*"/g, "")
    .replace(/<svg\b/, `<svg role="img" aria-label="${escapeXml(alt)}"`)
  // A replacer function, so `$` in the alt text is never read as a replacement pattern.
  svg = svg.replace(
    open[0],
    () => `${root}<title>${escapeXml(alt)}</title><defs>${markerDefs(prefix)}</defs>`,
  )
  return { svg, width: width ?? null, height: height ?? null }
}
