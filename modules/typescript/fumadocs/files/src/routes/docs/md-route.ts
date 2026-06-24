import { createFileRoute, notFound } from "@tanstack/react-router"

import { getLLMText, markdownPathToSlugs, source } from "@/lib/source"

// Serves the raw processed markdown for a docs page at /docs/<slug>.md. This
// backs the "copy markdown" / "view as markdown" controls on the docs page.
export const Route = createFileRoute("/docs/{$}.md")({
  server: {
    handlers: {
      GET: async ({ params }) => {
        const slugs = markdownPathToSlugs(params._splat?.split("/") ?? [])
        const page = source.getPage(slugs)
        if (!page) throw notFound()

        return new Response(await getLLMText(page), {
          headers: {
            "Content-Type": "text/markdown",
          },
        })
      },
    },
  },
})
