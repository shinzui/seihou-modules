// Render SVG diagrams to PNG for local visual review.
//
//   bun scripts/render-diagram.mjs overview/change-to-delivery [more ...]
//     -> .cache/diagram-previews/overview-change-to-delivery.{light,dark}.png
//
// Options: --out <dir>, --theme light|dark|both, --width <pixels>.
// Uses the same SVG transform and stylesheet as the site, rendered by headless Chrome.
import { execFileSync } from "node:child_process"
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs"
import { join, relative, resolve } from "node:path"

import { prepareDiagramSvg } from "../src/lib/diagram-svg.mjs"

const root = resolve(import.meta.dirname, "..")
const argv = process.argv.slice(2).filter((arg) => arg !== "--")
const option = (name, fallback) => {
  const index = argv.indexOf(name)
  if (index === -1) return fallback
  const [value] = argv.splice(index, 2).slice(1)
  return value
}
const out = resolve(option("--out", join(root, ".cache/diagram-previews")))
const theme = option("--theme", "both")
const widthLimit = Number(option("--width", "0"))
if (!argv.length) {
  console.error(
    "usage: render-diagram.mjs [--out dir] [--theme light|dark|both] [--width px] <diagram>",
  )
  process.exit(2)
}
mkdirSync(out, { recursive: true })

const browsers = [
  process.env.CHROME_PATH,
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/usr/bin/google-chrome",
  "/usr/bin/chromium",
].filter((path) => path && existsSync(path))
if (!browsers.length) {
  console.error("Chrome not found; set CHROME_PATH.")
  process.exit(2)
}

const css = readFileSync(join(root, "src/styles/diagrams.css"), "utf8")
const pad = 16

function screenshot(html, width, height, png) {
  const page = png.replace(/\.png$/, ".html")
  writeFileSync(page, html)
  const args = [
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    "--force-device-scale-factor=2",
    `--window-size=${Math.ceil(width + pad * 2)},${Math.ceil(height + pad * 2)}`,
    `--screenshot=${png}`,
    `file://${page}`,
  ]
  execFileSync(browsers[0], args, { stdio: "ignore", timeout: 60_000 })
  console.log(relative(root, png))
}

function fileFor(input) {
  if (input.endsWith(".svg")) return resolve(input)
  return join(root, "content/diagrams", `${input}.svg`)
}

for (const input of argv) {
  const file = fileFor(input)
  const { svg, width, height } = prepareDiagramSvg(readFileSync(file, "utf8"), "p", "preview")
  if (!width || !height) {
    console.error(`${file}: root <svg> needs a viewBox`)
    process.exitCode = 1
    continue
  }
  const shown = widthLimit > 0 ? Math.min(widthLimit, width) : width
  const shownHeight = (height * shown) / width
  const name = relative(join(root, "content/diagrams"), file)
    .replace(/\.svg$/, "")
    .replace(/\//g, "-")
  for (const mode of theme === "both" ? ["light", "dark"] : [theme]) {
    const background = mode === "dark" ? "#0b0e14" : "#ffffff"
    const html = `<!doctype html><html class="${mode}"><head><meta charset="utf-8"><style>${css}
html,body{margin:0;background:${background}}
.svg-diagram{margin:0;padding:${pad}px;border:0;border-radius:0;background:${background}}
.svg-diagram-frame svg{width:${shown}px}</style></head>
<body><figure class="svg-diagram"><div class="svg-diagram-frame">${svg}</div></figure></body></html>`
    const suffix = widthLimit > 0 ? `.${shown}` : ""
    screenshot(html, shown, shownHeight, join(out, `${name}${suffix}.${mode}.png`))
  }
}
