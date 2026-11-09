import { defineConfig } from "@playwright/test"
export default defineConfig({
  testDir: "./tests",
  workers: 1,
  use: {
    baseURL: process.env.DOCS_TEST_URL ?? "http://127.0.0.1:8080",
    permissions: ["clipboard-read", "clipboard-write"],
  },
  webServer: process.env.DOCS_TEST_URL
    ? undefined
    : {
        command: "bun run build && bun run start",
        url: "http://127.0.0.1:8080/healthz",
        reuseExistingServer: false,
      },
})
