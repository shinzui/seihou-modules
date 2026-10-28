import { createFileRoute, Link, notFound } from "@tanstack/react-router"
import { createServerFn } from "@tanstack/react-start"
import { staticFunctionMiddleware } from "@tanstack/start-static-server-functions"
import browserCollections from "collections/browser"
import { useFumadocsLoader } from "fumadocs-core/source/client"
import { DocsLayout } from "fumadocs-ui/layouts/docs"
import {
  DocsBody,
  DocsDescription,
  DocsPage,
  DocsTitle,
  MarkdownCopyButton,
  ViewOptionsPopover,
} from "fumadocs-ui/layouts/docs/page"
import { Suspense } from "react"

{{#if Eq docs.openapi true}}
import { OpenAPIPage } from "@/components/api-page"
{{/if}}
import { useMDXComponents } from "@/components/mdx"
import { baseOptions } from "@/lib/layout.shared"
import { gitConfig } from "@/lib/shared"
import { slugsToMarkdownPath, source } from "@/lib/source"

export const Route = createFileRoute("/docs/$")({
  component: Page,
  loader: async ({ params }) => {
    const slugs = params._splat?.split("/") ?? []
    const data = await loader({ data: slugs })
{{#if Eq docs.openapi true}}
    if (data.type === "docs") await clientLoader.preload(data.path)
{{#else}}
    await clientLoader.preload(data.path)
{{/if}}
    return data
  },
})

const loader = createServerFn({
  method: "GET",
})
  .validator((slugs: string[]) => slugs)
  .middleware([staticFunctionMiddleware])
  .handler(async ({ data: slugs }) => {
    const page = source.getPage(slugs)
    if (!page) throw notFound()

{{#if Eq docs.openapi true}}
    const markdownUrl = slugsToMarkdownPath(page.slugs).url
    const pageTree = await source.serializePageTree(source.getPageTree())
    if (page.type === "openapi") {
      return {
        type: "openapi" as const,
        title: page.data.title,
        description: page.data.description,
        markdownUrl,
        pageTree,
        props: page.data.getOpenAPIPageProps(),
      }
    }

    return {
      type: "docs" as const,
      path: page.path,
      markdownUrl,
      pageTree,
    }
{{#else}}
    return {
      path: page.path,
      markdownUrl: slugsToMarkdownPath(page.slugs).url,
      pageTree: await source.serializePageTree(source.getPageTree()),
    }
{{/if}}
  })

const clientLoader = browserCollections.docs.createClientLoader({
  component(
    { toc, frontmatter, default: MDX },
    {
      markdownUrl,
      path,
    }: {
      markdownUrl: string
      path: string
    },
  ) {
    return (
      <DocsPage toc={toc}>
        <DocsTitle>{frontmatter.title}</DocsTitle>
        <DocsDescription>{frontmatter.description}</DocsDescription>
        <div className="flex flex-row gap-2 items-center border-b -mt-4 pb-6">
          <MarkdownCopyButton markdownUrl={markdownUrl} />
          <ViewOptionsPopover
            markdownUrl={markdownUrl}
            githubUrl={`https://github.com/${gitConfig.user}/${gitConfig.repo}/blob/${gitConfig.branch}/content/docs/${path}`}
          />
        </div>
        <DocsBody>
          <MDX components={useMDXComponents()} />
        </DocsBody>
      </DocsPage>
    )
  },
})

{{#if Eq docs.openapi true}}
// A separate component so the client loader's hook only runs for MDX pages.
function DocsContent({ markdownUrl, path }: { markdownUrl: string; path: string }) {
  return clientLoader.useContent(path, { markdownUrl, path })
}

function Page() {
  const data = useFumadocsLoader(Route.useLoaderData())

  return (
    <DocsLayout {...baseOptions()} tree={data.pageTree}>
      <Link to={data.markdownUrl} hidden />
      {data.type === "openapi" ? (
        <DocsPage full>
          <DocsTitle>{data.title}</DocsTitle>
          <DocsDescription>{data.description}</DocsDescription>
          <DocsBody>
            <OpenAPIPage {...data.props} />
          </DocsBody>
        </DocsPage>
      ) : (
        <Suspense>
          <DocsContent markdownUrl={data.markdownUrl} path={data.path} />
        </Suspense>
      )}
    </DocsLayout>
  )
}
{{#else}}
function Page() {
  const { pageTree, path, markdownUrl } = useFumadocsLoader(Route.useLoaderData())

  return (
    <DocsLayout {...baseOptions()} tree={pageTree}>
      <Link to={markdownUrl} hidden />
      <Suspense>{clientLoader.useContent(path, { markdownUrl, path })}</Suspense>
    </DocsLayout>
  )
}
{{/if}}
