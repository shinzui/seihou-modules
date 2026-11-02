import { expect, test } from "bun:test"

import { make } from "../src/index.js"

test("generated operations validate both success and declared errors", async () => {
  const server = Bun.serve({
    hostname: "127.0.0.1",
    port: 0,
    fetch(request) {
      const path = new URL(request.url).pathname
      if (path.endsWith("/missing")) return Response.json({ message: "Not found" }, { status: 404 })
      if (path.endsWith("/invalid")) return Response.json({ id: 1, name: "One" })
      return Response.json(
        { id: "one", name: "One" },
        { status: request.method === "POST" ? 201 : 200 },
      )
    },
  })
  try {
    const api = make({ baseUrl: `http://127.0.0.1:${server.port}` })
    expect((await api.getWidget("one")).status).toBe(200)
    const missing = await api.getWidget("missing")
    if (missing.status === 404) expect(missing.data.message).toBe("Not found")
    else throw new Error("Expected 404")
    await expect(api.getWidget("invalid")).rejects.toMatchObject({ code: "invalid-payload" })
    expect((await api.createWidget({ name: "One" })).status).toBe(201)
  } finally {
    await server.stop(true)
  }
})
