# openapi-typescript-client

**Version:** `0.2.2` — depends on `nix-bun-flake` 0.5.0.

Version 0.2.2 removes the adapter's PascalCase-only component-name restriction.
Orval owns TypeScript naming and collision handling; the OpenAPI document keeps
its original keys and references. Existing projects own `scripts/schema.ts` as a
seed, so `seihou update` preserves their copy. Review and apply the updated
`files/scripts/schema.ts` to that project-owned file to receive this fix.

Requires [Seihou](mori://shinzui/seihou) >=0.15.0.0 for conditional removal and recorded-root retirement.
Update to the published 0.15.0.0 release before applying this module.

```bash
seihou run openapi-typescript-client --var project.name=example-api-client \
  --var 'project.description=Example API client'
nix develop --command just install
nix develop --command just generate
nix develop --command just check
```

Set `--var openapi.schema=spec/api.json` when first applying to an existing local schema.
The managed file `nix/openapi-typescript-client.nix` supplies Node >=22.18.0. It preserves
the base compiler/lock, disables base starters and pre-commit hooks, and leaves bun2nix off.
All other client outputs are project-owned seeds. The tests below apply to the default
example; custom schemas own their tests.

To seed a `mori.dhall` describing the client and its OpenAPI source, opt in on
application (following [the MLS client](mori://tan/mls-service-v2-ts-client)):

```bash
seihou run openapi-typescript-client --var project.name=example-api-client \
  --var 'project.description=Example API client' \
  --var openapi.schema=spec/api.json \
  --var mori.generate=true --var mori.namespace=example \
  --var mori.source-namespace=example --var mori.source-project=example-service
```

`mori.generate` defaults to `false`. When enabled, `mori.namespace`,
`mori.source-namespace`, and `mori.source-project` are required; interactive runs
prompt for missing values. Each uses lowercase names with optional digits and hyphens.
The source values identify the provider's existing Mori project, independently of
the client's namespace and name.

The inventory declares a private TypeScript `Client` package, its Zod runtime
dependency, and `apiSource` with a typed source-project reference. Declare the API
and its spec path in the provider's Mori descriptor, and list the client among that
API's consumers. The client resolves the provider's single API by default; set
`apiSource.api` to its declared name when needed. `openapi.schema` configures the
client's local generator input and is not a Mori source path. The inventory also
records the provider as a project dependency. It does not claim the provider API
as its own or register either project. Only the existing README is listed as
documentation; no local checkout path, GitHub repository or changelog is invented.

The descriptor is a project-owned seed: existing files, authored edits and intentional
deletion survive reruns, forced updates, opt-out and module removal. Edit it as the
client evolves. The initial description uses the client name; customize it after creation.
Run `mori validate` to check it, then register the project separately if desired.

```bash
python3 scripts/test-openapi-typescript-client.py --mori-only
python3 scripts/test-openapi-typescript-client.py --toolchain-only
python3 scripts/test-openapi-typescript-client.py --render-only
python3 scripts/test-openapi-typescript-client.py
```


Generate a reusable ESM client from a local OpenAPI document.

This private ESM client package uses a local OpenAPI document at `openapi.yaml`.
Enter `nix develop`, then run `just install`, `just generate`, and `just check`.
Commit the resulting `bun.lock`; subsequent installs can use `bun install --frozen-lockfile`.
Generation is explicit. No dependencies or schemas are downloaded by entering the shell.
Custom schema paths must exist before `just generate`; only the default path gets an example.

```typescript
import { make } from 'example-api-client'

const api = make({ baseUrl: 'https://api.example.com', headers: { Authorization: 'Bearer token' } })
const response = await api.getWidget('one')
if (response.status === 200) console.log(response.data.name)
else console.log(response.data.message)
```

Replace the example operations and tests as you evolve the schema. Each instance has its own
base URL, default headers, and optional `fetch` implementation; injected transports still validate.
JSON responses return `{ status, data, headers }`; narrow the literal status before reading data.
Declared HTTP errors are ordinary validated results. `ClientError.code` distinguishes `transport`,
`invalid-json`, `invalid-payload`, `unsupported-status`, `unsupported-media`, and `unexpected-body`.
Declared empty responses have `data: undefined`. Dates stay wire strings.

`just validate-schema` checks OpenAPI structure and references using Redocly. Generation also
checks the supported schema subset; runtime Zod validation checks each server payload against
its actual declared status. These are separate guarantees. Runtime validation is never bypassed
by a custom fetch function. Request types are checked by TypeScript; requests are not runtime-validated.

`just generated-check` never rewrites source: it invokes Orval `--outdated`, computes expected
output in a temporary directory, then compares every path and byte in raw and derived trees.
`just check` runs freshness first, followed by typecheck, tests, lint, format-check, and build.
`just format` only formats authored code. `just build` emits ESM and declarations into `dist/`;
`npm pack --ignore-scripts` packages those files for another Node >=22.18 or Bun project.
Zod is the only runtime dependency. The public declarations require no Bun or generator types.

The shared shell supplies TypeScript 7.0.2. Typecheck/build print the selected compiler and reject
versions below 7 without downloading a compiler. Orval has private TypeScript 6 tooling dependencies;
these are permitted and are excluded when selecting the project compiler. Future compiler versions
need qualification. Do not add a local compiler that bypasses `scripts/compiler.ts`.

Supported OpenAPI 3.0/3.1 schema features include JSON objects (closed, explicitly open, or implicitly
open), required/optional/nullable fields, primitive types, arrays, enum/literal values, local recursive
references, tagged/exclusive `oneOf`, inclusive `anyOf`, and `allOf` of open object branches with disjoint
properties. Requests exclude read-only fields; responses exclude write-only fields. Basic bounds,
string patterns, and date/date-time/uuid/email/uri formats are generated by Orval. Optional fields reject
explicit `undefined`. Object properties allowed by the schema are retained; forbidden properties fail.

Only explicit response status codes and `application/json` (or no content) are supported. Remote
references, ranges/default responses, other media, boolean schemas, overlapping/closed `allOf`, `$ref`
validation siblings, defaults/transforms, unrecognized validation keywords and formats fail generation
with a schema pointer before old output is replaced. Staged validator/model contracts must pass the shared compiler before replacement. Local YAML/JSON references remain inside the project
and use paths without traversal. Component keys accept OpenAPI's letters, digits, dots,
hyphens, and underscores, including leading digits. Source keys and references are preserved;
Orval handles TypeScript identifier naming and collisions. Operation IDs must be camelCase.
Path parameters are encoded strings; query parameters use scalar form style, repeated scalar arrays, or closed flat deepObject values. Other parameter styles and ambiguous method/path routes are diagnosed. Pass request headers through client/operation options. This is a bounded schema subset, not arbitrary JSON Schema equivalence. Inspect diagnostics instead of
removing source constraints to get usable but weaker validators.

`src/generated/raw/` preserves Orval output. `src/generated/client/` contains Node-compatible copies,
per-status registry entries, and compile-time input/output contracts. The compatibility stage corrects
Orval 8.46.0's nullable optionals, recursive input annotations, platform fetch signature, and empty response
decoding. Requalify it whenever generator/runtime pins move. Both trees are command products.

Package metadata, configs, recipes, source, helpers, schema and example tests are Seihou seeds: after
creation they belong to this project, including intentional deletion. Managed Nix files can update;
put Nix additions in the unmanaged `flake.module.nix`. Generated sources, `dist/`, and `bun.lock` are
project artifacts. Removing the client module preserves seeds and command products. Seihou >=0.15.0.0
is required for composed seed ownership and conditional removal.
