# Fumadocs module 0.1.2 to 0.2.1

Follow the shared upgrade prompt. Adopt nix-bun-flake 0.3.0 and Fumadocs module
0.2.1, including Core/UI 16.16.2 and MDX 15.4.6. This edge tracks module versions,
not upstream library versions. For a legacy site without a Fumadocs application,
use agent run for adoption; do not record this edge without an actual 0.1.2 origin.

Replace the Orama static initializer with the Fumadocs staticClient, retain the
exported /api/search route, and verify real queries against its built index.
Use the Nix-provided TypeScript 7 compiler rather than a second local compiler.
Fix necessary source compatibility issues without rewriting documentation or
removing project-specific checks. Record this edge only after validation succeeds.
