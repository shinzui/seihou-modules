# {{project.name}}

{{project.description}}

Run `just install`, `just generate`, and `just check` inside `nix develop`.
The input is `{{openapi.schema}}`; commit the resulting `bun.lock`.
Generation uses Orval 8.46.0 directly and writes `src/generated/api.ts`.
Redocly checks the source document. There is no custom schema subset or output rewriting.

```typescript
import { make } from '{{project.name}}'

const api = make({ baseUrl: 'https://api.example.com' })
const response = await api.getWidget('one')
if (response.status === 200) console.log(response.data.name)
else console.log(response.data.message)
```

`make` only supplies a per-instance base URL, default headers and optional fetch implementation.
Generated operations and models are also exported directly. Declared HTTP errors are returned as
status-discriminated results. The client uses standard Orval behavior; TypeScript types do not
validate server payloads at runtime. There is no runtime validation dependency.

`just generated-check` runs Orval's native `--outdated` check without rewriting output.
`just check` runs freshness, typechecking, tests, lint, formatting checks and build.
`just build` emits ESM and declarations to `dist/`, suitable for Node or Bun consumers.
The shared shell supplies TypeScript 7+, selected by `scripts/compiler.ts`.
The generator's private compiler dependencies do not select the project compiler.

Replace the example tests and usage with operations from your schema. A custom schema must already
exist; only the default `openapi.yaml` receives example content. Inspect Orval diagnostics directly.

If seeded, `mori.dhall` records the client and its source project. Set `apiSource.api` to the
provider's declared API name as needed; it defaults to the provider's single API. The local
input path is independent of the provider's spec path. Run `mori validate` and register separately.

Configs, source, helpers and tests are project-owned seeds. Seihou updates preserve your edits.
Generated output, `dist/` and `bun.lock` are command products. Put Nix extensions in `flake.module.nix`.
