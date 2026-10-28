import { createOpenAPI } from "fumadocs-openapi/server"

// The OpenAPI document (a project-relative path or a URL) rendered as API
// reference pages. Read at build time; the static site ships its pages.
export const openapi = createOpenAPI({
  input: ["{{docs.openapi-spec}}"],
})
