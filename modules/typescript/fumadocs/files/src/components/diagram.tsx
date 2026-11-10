import { type CSSProperties, useEffect, useId, useState } from "react"

import { prepareDiagramSvg } from "@/lib/diagram-svg.mjs"

// Hand-authored SVG diagrams live under content/diagrams/<product>/<name>.svg and
// are referenced from MDX as <Diagram src="<product>/<name>" alt="..." />. Each
// file becomes its own lazy chunk, so a page only downloads the diagrams it uses.
// The SVG is inlined (not an <img>) so the semantic classes in diagrams.css can
// follow the light/dark theme.
const sources = import.meta.glob<string>("../../content/diagrams/**/*.svg", {
  query: "?raw",
  import: "default",
})

type Prepared = { svg: string; width: number | null; height: number | null }

export function Diagram({ src, alt, caption }: { src: string; alt: string; caption?: string }) {
  const prefix = `dg${useId().replace(/[^a-zA-Z0-9-]/g, "")}`
  const load = sources[`../../content/diagrams/${src}.svg`] as (() => Promise<string>) | undefined
  const [prepared, setPrepared] = useState<Prepared | null>(null)
  const [error, setError] = useState<string | null>(load ? null : `Unknown diagram: ${src}`)
  const [expanded, setExpanded] = useState(false)

  useEffect(() => {
    if (!load) return
    let cancelled = false
    load()
      .then((raw) => {
        if (!cancelled) setPrepared(prepareDiagramSvg(raw, prefix, alt))
      })
      .catch((e: unknown) => {
        if (!cancelled) setError(e instanceof Error ? e.message : String(e))
      })
    return () => {
      cancelled = true
    }
  }, [load, prefix, alt])

  useEffect(() => {
    if (!expanded) return
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setExpanded(false)
    }
    window.addEventListener("keydown", onKey)
    return () => window.removeEventListener("keydown", onKey)
  }, [expanded])

  if (error) {
    return (
      <pre className="diagram-error">
        <code>{error}</code>
      </pre>
    )
  }

  return (
    <>
      {expanded && <div className="diagram-backdrop" onClick={() => setExpanded(false)} />}
      <figure className={`svg-diagram${expanded ? " expanded" : ""}`}>
        <button
          type="button"
          className="svg-diagram-expand"
          title={expanded ? "Close expanded diagram" : "Expand diagram"}
          onClick={() => setExpanded((v) => !v)}
        >
          {expanded ? "Close" : "Expand"}
        </button>
        {prepared ? (
          <div
            className="svg-diagram-frame"
            style={
              {
                "--diagram-width": `${prepared.width ?? 660}px`,
                ...(prepared.width && !expanded ? { maxWidth: `${prepared.width}px` } : {}),
              } as CSSProperties
            }
            dangerouslySetInnerHTML={{ __html: prepared.svg }}
          />
        ) : (
          <div className="svg-diagram-loading" role="img" aria-label={alt}>
            Rendering diagram…
          </div>
        )}
        {caption && <figcaption>{caption}</figcaption>}
      </figure>
    </>
  )
}

export default Diagram
