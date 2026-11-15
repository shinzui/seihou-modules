import { expect, test } from "bun:test"

import { make } from "../src/index.js"

test("returns typed HTTP errors and resolves base paths and headers", async () => {
  const server = Bun.serve({
    hostname: "127.0.0.1",
    port: 0,
    fetch(request) {
      expect(new URL(request.url).pathname).toBe("/api/widgets/missing")
      expect(request.headers.get("x-client")).toBe("test")
      return Response.json({ message: "Not found" }, { status: 404 })
    },
  })
  try {
    const api = make({
      baseUrl: `http://127.0.0.1:${server.port}/api`,
      headers: { "x-client": "test" },
    })
    const result = await api.getWidget("missing")
    expect(result.status).toBe(404)
    if (result.status === 404) expect(result.data.message).toBe("Not found")
  } finally {
    await server.stop(true)
  }
})
