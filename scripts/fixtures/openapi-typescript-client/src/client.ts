import { getOperations } from "./generated/api.js"

export interface Options {
  baseUrl: string
  fetch?: typeof globalThis.fetch
  headers?: HeadersInit
}

export function make(options: Options) {
  const base = new URL(options.baseUrl)
  const transport = options.fetch ?? globalThis.fetch
  const request = Object.assign((input: RequestInfo | URL, init?: RequestInit) => {
    const headers = new Headers(options.headers)
    new Headers(init?.headers).forEach((value, key) => headers.set(key, value))
    const url = new URL(base)
    const operation = new URL(String(input), "http://operation.invalid")
    url.pathname = `${base.pathname.replace(/\/$/, "")}${operation.pathname}`
    url.search = operation.search
    return transport(url, { ...init, headers })
  }, transport)
  return getOperations(request)
}
export type Api = ReturnType<typeof make>
