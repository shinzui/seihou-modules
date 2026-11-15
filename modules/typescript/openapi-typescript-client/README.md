# openapi-typescript-client

**Version:** `0.3.0` — depends on `nix-bun-flake` 0.6.1.

Version 0.3.0 removes the custom schema adapter, Zod response validation, generated-code
rewrites, response registry and duplicate generated trees. It uses standard typed Orval 8.46.0
fetch output in one file. This changes runtime behavior: payloads are no longer automatically
validated and `ClientError` is no longer exported. The `make` facade supplies only base URL,
headers and fetch injection.

Existing projects own their seeds, so updating Seihou does not migrate them automatically.
Review the new package/config/source/helper seeds against your project, remove the old
`scripts/schema.ts`, `src/transport.ts` and generated `raw`/`client` trees, regenerate with
`just generate`, and update validation-specific tests and callers. No source schema rewrite is needed.

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

The inventory declares a private TypeScript `Client` package and `apiSource` with a typed source-project reference. Declare the API
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
