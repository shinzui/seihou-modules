# Orval 8.46.0 qualification

Run `python3 scripts/test-openapi-typescript-client.py --toolchain-only` at the repository root.
The fixture lock fixes the qualification dependency graph; consumer locks are created separately.
The harness uses temporary copies and the shared TypeScript 7+ compiler. It reproduces the built-in
valid-404 failure, then checks the adapter against real HTTP responses and an independent packed
package under Node and Bun. Positive and negative compiler assertions exercise public request/response
types; generated contracts compare validator inputs/outputs with every response model in both directions.

Fixtures exercise OpenAPI 3.1 and a generated 3.0 equivalent: exact optional and nullable properties,
closed and open objects, literal enums, exclusive overlapping oneOf and inclusive anyOf, tagged unions,
allOf of disjoint open object branches, recursive and nested local references, readOnly/writeOnly
projection, 200/201/404/422 responses, empty, primitive and array payloads. Tests reject invalid
success/error bodies, undeclared statuses/media, broken JSON, missing/stale/obsolete output, malformed
schemas/references/path declarations and duplicate operation IDs/parameters. Checks preserve both
generated trees, including on input failure. A fake TypeScript 6 executable proves the version gate.

The adapter supports a defined subset. Only explicit status codes, JSON media and local references
are implemented; response ranges/defaults, remote refs, non-JSON media and unknown validation keywords
fail before output replacement. Closed or overlapping allOf branches are also rejected because Orval's
object merging can erase constraints. The generated-project README lists the supported surface.
Raw Orval output stays byte-identical; derived output has separately compared compatibility repairs.
Orval's private TypeScript 6 generator dependency is permitted; it never selects the project compiler.
