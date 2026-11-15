import { defineConfig } from "orval"

export default defineConfig({
  client: {
    input: process.env.OPENAPI_INPUT ?? "openapi.yaml",
    output: {
      target: "src/generated/api.ts",
      client: "fetch",
      mode: "single",
      urlEncodeParameters: true,
      override: {
        title: () => "Operations",
        useDates: false,
        fetch: {
          includeHttpResponseReturnType: true,
          forceSuccessResponse: false,
          useRuntimeFetcher: true,
          httpClientInjection: "factory",
        },
      },
    },
  },
})
