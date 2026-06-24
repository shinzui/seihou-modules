@import "tailwindcss";
@import "fumadocs-ui/css/neutral.css";
@import "fumadocs-ui/css/preset.css";

html {
  scrollbar-gutter: stable;
}

html > body[data-scroll-locked] {
  margin-right: 0px !important;
  --removed-body-scroll-bar-size: 0px !important;
}

/*
 * Self-hosted custom code/monospace font.
 *
 * The OTFs are copied into public/fonts/ by scripts/copy-fonts.mjs (a predev/
 * prebuild hook), which renames the version-tokened source files to stable,
 * version-independent names so these URLs never need to change. In a Vite /
 * TanStack Start app, files under public/ are served at the site root, so
 * public/fonts/X.otf is reachable at the URL /fonts/X.otf. We self-host with
 * plain @font-face (no network fetch). If the font package is unavailable the
 * copy step is a no-op and the system monospace fallback is used.
 */
@font-face {
  font-family: "{{docs.font-family}}";
  src: url("/fonts/{{docs.font-basename}}-Regular.otf") format("opentype");
  font-weight: 400;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: "{{docs.font-family}}";
  src: url("/fonts/{{docs.font-basename}}-Bold.otf") format("opentype");
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}
@font-face {
  font-family: "{{docs.font-family}}";
  src: url("/fonts/{{docs.font-basename}}-Italic.otf") format("opentype");
  font-weight: 400;
  font-style: italic;
  font-display: swap;
}
@font-face {
  font-family: "{{docs.font-family}}";
  src: url("/fonts/{{docs.font-basename}}-BoldItalic.otf") format("opentype");
  font-weight: 700;
  font-style: italic;
  font-display: swap;
}

/* Route fumadocs' monospace at the custom font with system fallbacks. */
:root {
  --fd-font-mono: "{{docs.font-family}}", ui-monospace, SFMono-Regular, Menlo, monospace;
}

/* Enable contextual ligatures on every code surface, including fumadocs'
   Shiki output (.shiki) and inline/block code. */
code,
pre,
kbd,
samp,
.shiki,
.shiki code,
pre code {
  font-family: "{{docs.font-family}}", ui-monospace, SFMono-Regular, Menlo, monospace;
  font-feature-settings:
    "liga" 1,
    "calt" 1;
  font-variant-ligatures: contextual common-ligatures;
}

/* ---- beautiful Mermaid diagrams (zoom / pan / expand) ---- */

.diagram {
  margin: 1rem 0;
  position: relative;
  height: min(76vh, 760px);
  min-height: 420px;
  overflow: hidden;
  padding: 0;
  border: 1px solid var(--fd-border, #e5e7eb);
  border-radius: 8px;
  background: var(--fd-card, transparent);
  touch-action: none;
  cursor: grab;
}

.diagram:active {
  cursor: grabbing;
}

.diagram .diagram-frame,
.diagram .diagram-frame svg {
  width: 100%;
  height: 100%;
  display: block;
}

.diagram.expanded {
  position: fixed;
  inset: 18px;
  z-index: 50;
  height: auto;
  min-height: 0;
  border-radius: 10px;
  background: var(--fd-background, #fff);
  box-shadow: 0 28px 90px rgba(0, 0, 0, 0.35);
}

.diagram-backdrop {
  position: fixed;
  inset: 0;
  z-index: 49;
  background: rgba(23, 22, 20, 0.52);
  backdrop-filter: blur(3px);
}

.diagram-toolbar {
  position: absolute;
  right: 12px;
  top: 12px;
  z-index: 2;
  display: flex;
  gap: 6px;
  padding: 6px;
  border: 1px solid var(--fd-border, #e5e7eb);
  border-radius: 8px;
  background: var(--fd-card, rgba(255, 255, 255, 0.9));
  backdrop-filter: blur(10px);
  box-shadow: 0 8px 24px rgba(43, 37, 28, 0.12);
}

.diagram-toolbar button {
  display: inline-grid;
  place-items: center;
  min-width: 34px;
  height: 32px;
  padding: 0 10px;
  border: 1px solid var(--fd-border, #e5e7eb);
  border-radius: 7px;
  background: var(--fd-secondary, transparent);
  color: var(--fd-foreground, inherit);
  font:
    700 14px Inter,
    system-ui,
    sans-serif;
  cursor: pointer;
}

.diagram-toolbar button:hover {
  background: var(--fd-accent, rgba(0, 0, 0, 0.06));
}

.diagram-hint {
  position: absolute;
  left: 12px;
  bottom: 10px;
  z-index: 2;
  padding: 4px 8px;
  border-radius: 7px;
  background: var(--fd-card, rgba(255, 255, 255, 0.88));
  color: var(--fd-muted-foreground, #6b7280);
  font-size: 0.78rem;
}

.diagram-loading {
  display: grid;
  place-items: center;
  width: 100%;
  height: 100%;
  color: var(--fd-muted-foreground, #6b7280);
  font-size: 0.9rem;
}

.diagram-error {
  white-space: pre-wrap;
  background: var(--fd-secondary, #f4f4f5);
  color: var(--fd-foreground, inherit);
  padding: 18px;
  border-radius: 8px;
}

body:has(.diagram.expanded) {
  overflow: hidden;
}
