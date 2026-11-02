import type { ZodType } from "zod"

export type ResponseRegistry = readonly {
  name: string
  method: string
  path: string
  responses: Readonly<Record<string, ZodType | null>>
}[]
export type Fetch = (input: RequestInfo | URL, init?: RequestInit) => Promise<Response>
export interface Options {
  baseUrl: string
  fetch?: Fetch
  headers?: HeadersInit
}
export class ClientError extends Error {
  constructor(
    readonly code:
      | "transport"
      | "invalid-json"
      | "invalid-payload"
      | "unsupported-status"
      | "unsupported-media"
      | "unexpected-body",
    message: string,
    options?: ErrorOptions,
  ) {
    super(message, options)
    this.name = "ClientError"
  }
}

export function validatedFetch(options: Options, registry: ResponseRegistry): Fetch {
  const base = new URL(options.baseUrl)
  if (!["http:", "https:"].includes(base.protocol) || base.search || base.hash)
    throw new Error("baseUrl must be an HTTP(S) URL without query or fragment")
  const transport = options.fetch ?? globalThis.fetch
  const defaults = new Headers(options.headers)
  const operations = registry.map((op) => ({
    ...op,
    pattern: new RegExp(
      `^${op.path
        .split("/")
        .map((segment) =>
          /^\{[^}]+\}$/.test(segment) ? "[^/]+" : segment.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"),
        )
        .join("/")}$`,
    ),
  }))
  return async (input, init) => {
    const path = String(input)
    if (!path.startsWith("/") || path.startsWith("//"))
      throw new Error("Expected a generated relative operation URL")
    const relative = new URL(`http://operation.invalid${path}`)
    if (relative.pathname !== path.split("?")[0])
      throw new Error("Generated paths cannot contain dot segments")
    const method = init?.method ?? "GET"
    const operation = operations.find(
      (op) => op.method === method && op.pattern.test(relative.pathname),
    )
    if (!operation)
      throw new Error(`No generated response registry for ${method} ${relative.pathname}`)
    const url = new URL(base)
    url.pathname = `${base.pathname.replace(/\/$/, "")}${relative.pathname}`
    url.search = relative.search
    const headers = new Headers(defaults)
    new Headers(init?.headers).forEach((value, key) => headers.set(key, value))
    let response: Response
    try {
      response = await transport(url, { ...init, headers })
    } catch (cause) {
      throw new ClientError("transport", `${operation.name}: request failed`, { cause })
    }
    const validator = operation.responses[String(response.status)]
    if (validator === undefined)
      throw new ClientError(
        "unsupported-status",
        `${operation.name}: undeclared status ${response.status}`,
      )
    let body: string
    try {
      body = await response.clone().text()
    } catch (cause) {
      throw new ClientError("transport", `${operation.name}: response read failed`, { cause })
    }
    if (validator === null) {
      if (body.length)
        throw new ClientError("unexpected-body", `${operation.name}: expected an empty response`)
    } else {
      const media = response.headers.get("content-type")?.split(";")[0]?.trim().toLowerCase()
      if (media !== "application/json")
        throw new ClientError(
          "unsupported-media",
          `${operation.name}: expected application/json, got ${media ?? "(missing)"}`,
        )
      let value: unknown
      try {
        value = JSON.parse(body)
      } catch (cause) {
        throw new ClientError("invalid-json", `${operation.name}: invalid JSON`, { cause })
      }
      const result = validator.safeParse(value)
      if (!result.success)
        throw new ClientError(
          "invalid-payload",
          `${operation.name}: invalid ${response.status} payload`,
          { cause: result.error },
        )
    }
    return response
  }
}
