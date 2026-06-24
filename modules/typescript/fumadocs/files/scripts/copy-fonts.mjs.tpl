// Copies the four PragmataPro ligature Mono OTFs into public/fonts/ so they can be
// served as static assets and referenced by @font-face in src/styles/app.css.
// Tolerant by design: if the licensed font package is unavailable on this machine,
// it warns and exits 0 so dev/build still proceed (site falls back to system monospace).
//
// Runs under Bun (the dev shell ships bun, not node); the node: builtins below are
// Bun-compatible. Re-targeting to a different font means adjusting the LIGA_GLOB /
// STYLE_NAMES mapping and the docs.font-* vars in module.dhall.
import { execFileSync } from "node:child_process"
import {
  chmodSync,
  copyFileSync,
  existsSync,
  mkdirSync,
  readdirSync,
  realpathSync,
  rmSync,
} from "node:fs"
import { join } from "node:path"

const repoRoot = process.cwd()
const targetDir = join(repoRoot, "public", "fonts")
const FONTS_FLAKE = "{{docs.font-flake}}"
const FONT_PACKAGE = "{{docs.font-package}}"
const OUTPUT_BASENAME = "{{docs.font-basename}}"
// Match the ligature Mono OTFs and capture the style letter. The version token
// (e.g. `09` or `0901`) varies between font releases, so we never hard-code it:
// we glob it here and rename to a stable, version-independent filename below so
// the @font-face URLs in src/styles/app.css never need to change.
const LIGA_GLOB = /_Mono_([RBIZ])_liga_.*\.otf$/
const STYLE_NAMES = { R: "Regular", B: "Bold", I: "Italic", Z: "BoldItalic" }

function resolveFontDir() {
  // 1) Preferred: ask Nix to build the package attribute (never #default).
  try {
    const out = execFileSync(
      "nix",
      ["build", "--no-link", "--print-out-paths", `path:${FONTS_FLAKE}#${FONT_PACKAGE}`],
      { encoding: "utf8" },
    ).trim()
    const dir = join(out, "share", "fonts", "opentype")
    if (existsSync(dir)) return dir
  } catch {
    // fall through
  }
  // 2) Fallback: the fonts repo's own `result` symlink, if someone already built it.
  try {
    const dir = join(realpathSync(join(FONTS_FLAKE, "result")), "share", "fonts", "opentype")
    if (existsSync(dir)) return dir
  } catch {
    // fall through
  }
  return null
}

const sourceDir = resolveFontDir()
if (!sourceDir) {
  console.warn(
    "[copy-fonts] font package not available on this machine; " +
      "code blocks will use the system monospace fallback (no ligatures).",
  )
  process.exit(0)
}

const ligas = readdirSync(sourceDir)
  .filter((f) => !f.startsWith("._"))
  .map((f) => ({ name: f, m: f.match(LIGA_GLOB) }))
  .filter((e) => e.m)
if (ligas.length === 0) {
  console.warn(`[copy-fonts] No *_Mono_*_liga_*.otf found in ${sourceDir}; skipping.`)
  process.exit(0)
}

mkdirSync(targetDir, { recursive: true })
for (const { name, m } of ligas) {
  const dest = join(targetDir, `${OUTPUT_BASENAME}-${STYLE_NAMES[m[1]]}.otf`)
  // The source lives in the read-only Nix store, so copies inherit mode 0444.
  // Remove any prior copy and re-chmod so re-runs (predev/prebuild) don't hit
  // EACCES overwriting a read-only destination.
  rmSync(dest, { force: true })
  copyFileSync(join(sourceDir, name), dest)
  chmodSync(dest, 0o644)
}
console.log(`[copy-fonts] Copied ${ligas.length} OTF(s) into public/fonts/.`)
