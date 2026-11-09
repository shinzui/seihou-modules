// Browser-safe publication link resolution; no filesystem access.
export const docHref = (path: string) =>
  "/docs/" + path.replace(/\.md$/i, "").split("/").map(encodeURIComponent).join("/")
export function publishedLink(
  source: string,
  href: string,
  links: Record<string, string>,
): string | null {
  if (href.startsWith("#")) return href
  if (/^https?:\/\//i.test(href) || /^mailto:/i.test(href)) return href
  if (/^[a-z]+:/i.test(href) || href.startsWith("/") || href.includes("\\")) return null
  try {
    const url = new URL(href, "https://publication.invalid/" + source)
    if (url.origin !== "https://publication.invalid") return null
    const target = decodeURIComponent(url.pathname.slice(1))
    return links[target] ? links[target] + url.hash : null
  } catch {
    return null
  }
}
export function resolveLink(
  source: string,
  href: string,
  documents: string[],
  assets: string[],
): string | null {
  const links = Object.fromEntries([
    ...documents.map((p) => [p, docHref(p)]),
    ...assets.map((p) => [p, "/published/" + p.split("/").map(encodeURIComponent).join("/")]),
  ])
  return publishedLink(source, href, links)
}
