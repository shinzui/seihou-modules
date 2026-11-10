import { createHighlights } from "fumadocs-core/highlight/highlights"
import { createOpenAPIPageBase } from "fumadocs-openapi/ui/base"

// The base page leaves out fumadocs-openapi's default Shiki bundle and highlights
// request and response samples with the same @pierre/highlights engine as MDX.
export const OpenAPIPage = createOpenAPIPageBase({ highlighter: createHighlights() })
