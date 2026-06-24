import { useTheme } from "fumadocs-ui/provider/base"
import { useEffect, useRef, useState, useCallback } from "react"

/** A rectangle describing the visible region of an <svg>, i.e. its viewBox. */
type ViewBoxRect = { x: number; y: number; w: number; h: number }

/** beautiful-mermaid theme object. */
type MermaidTheme = {
  bg: string
  fg: string
  line: string
  accent: string
  muted: string
  surface: string
  border: string
  font: string
  transparent: boolean
  padding: number
  nodeSpacing: number
  layerSpacing: number
  thoroughness: number
}

// Light palette (warm, high-contrast on white).
const LIGHT_THEME: MermaidTheme = {
  bg: "#ffffff",
  fg: "#1e242b",
  line: "#59616d",
  accent: "#1f6f72",
  muted: "#6b7280",
  surface: "#f4f6f8",
  border: "#b7c4ce",
  font: "Inter",
  transparent: true,
  padding: 28,
  nodeSpacing: 28,
  layerSpacing: 46,
  thoroughness: 5,
}

// Dark palette tuned for fumadocs' dark surface.
const DARK_THEME: MermaidTheme = {
  bg: "#0b0e14",
  fg: "#e6e9ef",
  line: "#8b95a5",
  accent: "#4fd1c5",
  muted: "#9aa4b2",
  surface: "#161b26",
  border: "#2b313d",
  font: "Inter",
  transparent: true,
  padding: 28,
  nodeSpacing: 28,
  layerSpacing: 46,
  thoroughness: 5,
}

// --- pure viewBox helpers ---

export function centerOf(rect: ViewBoxRect): { x: number; y: number } {
  return { x: rect.x + rect.w / 2, y: rect.y + rect.h / 2 }
}

export function clampViewBox(rect: ViewBoxRect, home: ViewBoxRect): ViewBoxRect {
  const minW = home.w / 24 // most zoomed-in
  const maxW = home.w * 16 // most zoomed-out
  const width = Math.min(maxW, Math.max(minW, rect.w))
  const height = width * (home.h / home.w)
  if (width === rect.w && height === rect.h) return rect
  const c = centerOf(rect)
  return { x: c.x - width / 2, y: c.y - height / 2, w: width, h: height }
}

export function zoomViewBoxAt(
  current: ViewBoxRect,
  home: ViewBoxRect,
  factor: number,
  point: { x: number; y: number } = centerOf(current),
): ViewBoxRect {
  const safeFactor = Number.isFinite(factor) && factor > 0 ? factor : 1
  const nextW = current.w / safeFactor
  const nextH = current.h / safeFactor
  return clampViewBox(
    {
      x: point.x - ((point.x - current.x) / current.w) * nextW,
      y: point.y - ((point.y - current.y) / current.h) * nextH,
      w: nextW,
      h: nextH,
    },
    home,
  )
}

// Strip injected web-font @import rules from the SVG (beautiful-mermaid injects an
// Inter @import; we already load fonts ourselves and want no network fetch from the SVG).
function stripFontImports(svg: string): string {
  return svg.replace(/@import url\([^)]+\);?/g, "")
}

export function Mermaid({ chart }: { chart: string }) {
  const { resolvedTheme } = useTheme()
  const isDark = resolvedTheme === "dark"

  const containerRef = useRef<HTMLDivElement>(null)
  const figureRef = useRef<HTMLElement>(null)
  const svgRef = useRef<SVGSVGElement | null>(null)
  const homeRef = useRef<ViewBoxRect | null>(null)
  const stateRef = useRef<ViewBoxRect | null>(null)
  const dragRef = useRef<{
    id: number
    x: number
    y: number
    ox: number
    oy: number
  } | null>(null)

  const [svg, setSvg] = useState<string | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [expanded, setExpanded] = useState(false)

  // Render the diagram whenever the source or the theme changes.
  useEffect(() => {
    let cancelled = false
    setError(null)
    setSvg(null)
    ;(async () => {
      try {
        const mod = await import("beautiful-mermaid")
        const theme = isDark ? DARK_THEME : LIGHT_THEME
        const rendered = await mod.renderMermaidSVG(chart, theme)
        if (!cancelled) setSvg(stripFontImports(rendered))
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : String(e))
        }
      }
    })()
    return () => {
      cancelled = true
    }
  }, [chart, isDark])

  // After the SVG HTML is in the DOM, capture its viewBox and wire interactions.
  useEffect(() => {
    const frame = figureRef.current
    if (!frame || !svg) return
    const svgEl = frame.querySelector("svg")
    if (!svgEl || !svgEl.viewBox || !svgEl.viewBox.baseVal) return

    svgRef.current = svgEl
    const vb = svgEl.viewBox.baseVal
    const home: ViewBoxRect = { x: vb.x, y: vb.y, w: vb.width, h: vb.height }
    homeRef.current = home
    stateRef.current = { ...home }
    // Make the SVG fill its frame; interaction happens via viewBox, not CSS scale.
    svgEl.setAttribute("preserveAspectRatio", "xMidYMid meet")
    svgEl.style.width = "100%"
    svgEl.style.height = "100%"
  }, [svg, expanded])

  const apply = useCallback(() => {
    const svgEl = svgRef.current
    const s = stateRef.current
    if (!svgEl || !s) return
    svgEl.setAttribute("viewBox", [s.x, s.y, s.w, s.h].join(" "))
  }, [])

  const pointFromEvent = useCallback(
    (clientX: number, clientY: number): { x: number; y: number } => {
      const svgEl = svgRef.current
      const s = stateRef.current
      if (!svgEl || !s) return { x: 0, y: 0 }
      const rect = svgEl.getBoundingClientRect()
      return {
        x: s.x + ((clientX - rect.left) / rect.width) * s.w,
        y: s.y + ((clientY - rect.top) / rect.height) * s.h,
      }
    },
    [],
  )

  const zoomAt = useCallback(
    (factor: number, point?: { x: number; y: number }) => {
      const home = homeRef.current
      const s = stateRef.current
      if (!home || !s) return
      stateRef.current = zoomViewBoxAt(s, home, factor, point)
      apply()
    },
    [apply],
  )

  const fit = useCallback(() => {
    const home = homeRef.current
    if (!home) return
    stateRef.current = { ...home }
    apply()
  }, [apply])

  // Wheel zoom (toward cursor), drag pan, double-click fit, keyboard shortcuts.
  useEffect(() => {
    const frame = figureRef.current
    if (!frame || !svg) return

    const onWheel = (e: WheelEvent) => {
      e.preventDefault()
      zoomAt(Math.exp(-e.deltaY * 0.0012), pointFromEvent(e.clientX, e.clientY))
    }
    const onPointerDown = (e: PointerEvent) => {
      if ((e.target as HTMLElement).closest(".diagram-toolbar")) return
      const s = stateRef.current
      if (!s) return
      frame.setPointerCapture(e.pointerId)
      dragRef.current = {
        id: e.pointerId,
        x: e.clientX,
        y: e.clientY,
        ox: s.x,
        oy: s.y,
      }
    }
    const onPointerMove = (e: PointerEvent) => {
      const drag = dragRef.current
      const svgEl = svgRef.current
      const s = stateRef.current
      if (!drag || drag.id !== e.pointerId || !svgEl || !s) return
      const rect = svgEl.getBoundingClientRect()
      stateRef.current = {
        ...s,
        x: drag.ox - ((e.clientX - drag.x) / rect.width) * s.w,
        y: drag.oy - ((e.clientY - drag.y) / rect.height) * s.h,
      }
      apply()
    }
    const endDrag = () => {
      dragRef.current = null
    }
    const onDblClick = () => fit()
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === "+" || e.key === "=") zoomAt(1.25)
      else if (e.key === "-" || e.key === "_") zoomAt(1 / 1.25)
      else if (e.key === "0") fit()
      else if (e.key === "Escape") setExpanded(false)
    }

    frame.addEventListener("wheel", onWheel, { passive: false })
    frame.addEventListener("pointerdown", onPointerDown)
    frame.addEventListener("pointermove", onPointerMove)
    frame.addEventListener("pointerup", endDrag)
    frame.addEventListener("pointercancel", endDrag)
    frame.addEventListener("dblclick", onDblClick)
    frame.addEventListener("keydown", onKeyDown)

    return () => {
      frame.removeEventListener("wheel", onWheel)
      frame.removeEventListener("pointerdown", onPointerDown)
      frame.removeEventListener("pointermove", onPointerMove)
      frame.removeEventListener("pointerup", endDrag)
      frame.removeEventListener("pointercancel", endDrag)
      frame.removeEventListener("dblclick", onDblClick)
      frame.removeEventListener("keydown", onKeyDown)
    }
  }, [svg, zoomAt, fit, apply, pointFromEvent])

  // Lock body scroll while the full-screen overlay is open.
  useEffect(() => {
    if (!expanded) return
    const prev = document.body.style.overflow
    document.body.style.overflow = "hidden"
    return () => {
      document.body.style.overflow = prev
    }
  }, [expanded])

  if (error) {
    return (
      <pre className="diagram-error">
        <code>{`Mermaid render error: ${error}\n\n${chart}`}</code>
      </pre>
    )
  }

  return (
    <div ref={containerRef}>
      {expanded && <div className="diagram-backdrop" onClick={() => setExpanded(false)} />}
      <figure
        ref={figureRef}
        className={`diagram zoomable${expanded ? " expanded" : ""}`}
        tabIndex={0}
        role="region"
        aria-label="Zoomable diagram. Wheel or pinch to zoom, drag to pan."
      >
        <div className="diagram-toolbar" aria-label="Diagram controls">
          <button type="button" title="Zoom in" onClick={() => zoomAt(1.35)}>
            +
          </button>
          <button type="button" title="Zoom out" onClick={() => zoomAt(1 / 1.35)}>
            −
          </button>
          <button type="button" title="Fit diagram" onClick={fit}>
            Fit
          </button>
          <button
            type="button"
            data-expand
            title={expanded ? "Close expanded diagram" : "Expand diagram"}
            onClick={() => setExpanded((v) => !v)}
          >
            {expanded ? "Close" : "Expand"}
          </button>
        </div>
        <div className="diagram-hint">Wheel zoom · drag pan · double-click fit</div>
        {svg ? (
          <div
            className="diagram-frame"
            ref={(node) => {
              if (node) node.innerHTML = svg
            }}
          />
        ) : (
          <div className="diagram-loading">Rendering diagram…</div>
        )}
      </figure>
    </div>
  )
}

export default Mermaid
