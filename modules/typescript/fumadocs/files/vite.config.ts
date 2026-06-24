import tailwindcss from "@tailwindcss/vite"
import { tanstackStart } from "@tanstack/react-start/plugin/vite"
import react from "@vitejs/plugin-react"
import mdx from "fumadocs-mdx/vite"
import { nitro } from "nitro/vite"
import { defineConfig } from "vite"

export default defineConfig({
  server: {
    port: 3000,
  },
  plugins: [
    // The fumadocs-mdx plugin reads source.config.ts (Shiki + the mermaid rehype
    // plugin are configured there, not here).
    mdx(),
    tailwindcss(),
    tanstackStart({
      // Static SPA: the build emits a fully static site under .output/public
      // (no server needed to host). `prerender` with `crawlLinks` walks the
      // pages listed below and any links it finds, producing real HTML.
      spa: {
        enabled: true,
        prerender: {
          enabled: true,
          crawlLinks: true,
        },
      },
      pages: [{ path: "/docs" }, { path: "/api/search" }],
    }),
    react(),
    // See https://tanstack.com/start/latest/docs/framework/react/guide/hosting#nitro
    nitro(),
  ],
  resolve: {
    tsconfigPaths: true,
  },
})
