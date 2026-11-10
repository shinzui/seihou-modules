import { readdirSync, statSync } from "node:fs"
import { join } from "node:path"

import { createOpenAPI } from "fumadocs-openapi/server"

// The OpenAPI documents rendered as API reference pages, read at build time; the
// static site ships their pages. docs.openapi-spec names one document (a
// project-relative path or a URL) or a directory, in which case every .json,
// .yaml and .yml document in it is rendered, in sorted order.
const spec = "{{docs.openapi-spec}}"
const isUrl = /^https?:/.test(spec)
const isDirectory = !isUrl && statSync(spec, { throwIfNoEntry: false })?.isDirectory()

export const openapi = createOpenAPI({
  input: isDirectory
    ? readdirSync(spec)
        .filter((name) => /\.(json|ya?ml)$/.test(name))
        .sort()
        .map((name) => join(spec, name))
    : [spec],
})
