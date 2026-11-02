import { getOperations } from "./generated/client/api.js"
import { registry } from "./generated/client/registry.js"
import { validatedFetch } from "./transport.js"
import type { Options } from "./transport.js"

export function make(options: Options) {
  return getOperations(validatedFetch(options, registry))
}
export type Api = ReturnType<typeof make>
