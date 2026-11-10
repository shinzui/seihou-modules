import { readdirSync } from "node:fs"

import tailwindcss from "@tailwindcss/vite"
import { tanstackStart } from "@tanstack/react-start/plugin/vite"
import react from "@vitejs/plugin-react"
import mdx from "fumadocs-mdx/vite"
import { nitro } from "nitro/vite"
import { defineConfig } from "vite"

// Every content page, so a page no meta.json lists (a generated index, an
// orphan) is still prerendered instead of returning 404 from the static host.
// Fumadocs drops `index` and `(group)` folders from the URL.
const docPages = readdirSync("content/docs", { encoding: "utf8", recursive: true })
  .filter((file) => /\.mdx?$/.test(file))
  .map((file) => {
    const slugs = file
      .replace(/\.mdx?$/, "")
      .split(/[\\/]/)
      .filter((slug) => !/^\(.+\)$/.test(slug))
    if (slugs.at(-1) === "index") slugs.pop()
    return ["/docs", ...slugs].join("/")
  })

export default defineConfig({
  server: {
    port: 3000,
  },
  plugins: [
    // The fumadocs-mdx plugin reads source.config.ts (code highlighting and the
    // mermaid rehype plugin are configured there, not here).
    mdx(),
    tailwindcss(),
    tanstackStart({
      // Static SPA: the build emits a fully static site under .output/public
      // (no server needed to host). `prerender` with `crawlLinks` walks every
      // content page listed below and any links it finds, producing real HTML.
      spa: {
        enabled: true,
        prerender: {
          enabled: true,
          crawlLinks: true,
        },
      },
      pages: [...new Set(["/docs", ...docPages, "/api/search"])].map((path) => ({ path })),
    }),
    react(),
    // See https://tanstack.com/start/latest/docs/framework/react/guide/hosting#nitro
    nitro(),
  ],
  resolve: {
    tsconfigPaths: true,
  },
})
