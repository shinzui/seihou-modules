import { defineConfig } from "orval"

const input = process.env.OPENAPI_INPUT
const output = process.env.OPENAPI_RAW
if (!input || !output) throw new Error("Use the generate or generated-check task")
export default defineConfig({
  client: {
    input,
    output: {
      target: `${output}/api.ts`,
      schemas: `${output}/models`,
      client: "fetch",
      mode: "split",
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
  validators: {
    input,
    output: {
      target: `${output}/validators.ts`,
      client: "zod",
      mode: "single",
      override: {
        zod: {
          version: 4,
          generateReusableSchemas: true,
          generateEachHttpStatus: true,
          generateXor: true,
          exactOptional: true,
          strict: { response: true, body: true },
          coerce: { response: false, body: false },
        },
      },
    },
  },
})
