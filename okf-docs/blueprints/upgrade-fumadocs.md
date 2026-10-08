---
type: SeihouBlueprint
title: upgrade-fumadocs
description: Upgrade existing Fumadocs sites to the shared Bun flake-parts modules
  while preserving custom content, package-manager workflows, fonts, CI gates, and
  Seihou ownership
resource: seihou://seihou-modules/blueprints/upgrade-fumadocs
tags:
- typescript
- fumadocs
- nix
- flake-parts
- migration
status: stable
generated:
  by: seihou-okf-extension/0.9.0.0
version: 0.1.0
---

# upgrade-fumadocs

Upgrade existing Fumadocs sites to the shared Bun flake-parts modules while preserving custom content, package-manager workflows, fonts, CI gates, and Seihou ownership

**Version:** 0.1.0

## Base modules

This blueprint declares no base modules.

## Agent prompt

# Upgrade this Fumadocs site and adopt the shared flake-parts modules

```text
# Upgrade this Fumadocs site and adopt the shared flake-parts modules

Upgrade the existing project in place using the tested cohort in target-versions.json.
The canonical scaffold belongs to mori://shinzui/seihou-modules/templates/fumadocs
and mori://shinzui/seihou-modules/templates/nix-bun-flake. Read the
current installed/source module definitions and templates before changing files.
Do not use the blueprint references as an independent replacement scaffold.

## Inventory and preservation

Read project instructions, git status, package.json, its lock, CI, justfile, flake.nix,
.envrc, tsconfig, lint/format configuration, content configuration, and the Seihou manifest.
Back up modified managed files and the manifest outside the project. Record the initial
content hashes. Preserve unrelated dirty files, documentation, navigation, custom routes,
MDX registrations, SVG/interactive diagrams, syntax grammars, highlighting, font fallback,
existing ports, package-manager choice, and every quality gate. Never replace the content
with the template's starter pages. Do not introduce personal paths or licensed font files.
Do not commit or push unless the user explicitly authorizes it.

baseModules is deliberately empty: applying a fresh baseline before inspecting a legacy
site would overwrite its package/configuration files and documentation entry page.

## Canonical environment and ownership

Refresh or discover the current module copies. Install from the registered remote for normal
use. For an unpublished checkout test, use an isolated external candidate cache seeded
from the registered remote and overlaid with the reviewed module checkout. Retain remote
origin metadata and document that publication is pending. Project-local copies record
project origins, which require committing those definitions; repair-origins only repairs
machine-local remote URLs and cannot convert a project origin. Do not hand-edit identities.
Generate a fresh composed scaffold in a temporary project using those exact module copies
and the existing project variables. Set docs.starter-content=false for adoption. This gives the canonical lock and hashes without
modifying the real project. Keep hooks at their existing setting; if enabled, preserve all
custom hooks in an unmanaged extension and ignore generated route/collection files.

Move extra tools into flake.module.nix via perSystem.bunProject.extraDevPackages.
A pnpm project can retain Node and pnpm there; adopting the Bun module does not require
changing the package manager. Move environment exports to ignored .envrc.local and retain
portable font handling. The managed environment is flake.nix, flake.lock, nix/bun.nix,
nix/tooling.nix, nix/tooling-sources.json, optional nix/pre-commit.nix, and .envrc.
Keep every revision-pinned module input and the follows graph from the current module.
Keep custom inputs pinned separately; additional inputs append lock nodes.

Use seihou update for a recorded application. Preview first. If an older Bun-only application
owns the shared files, update it after preserving its customizations, then adopt the composed
Fumadocs application with seihou run fumadocs using explicit project/docs variables. Use
--force only after preserving and reviewing each collision, then merge back customizations
from the backup. Do not remove an application blindly: removing it deletes its managed files.
Pass --json when applying a reviewed update noninteractively: without it an unattended
confirmation can cancel with exit status zero. Use Seihou's own operations to establish application IDs, module instances and baselines;
never fabricate hashes or application identifiers. If a reviewed manifest repair is necessary,
back it up and preserve canonical generated baselines, origins, and all unrelated records.
Document that consumer-owned edits to managed Fumadocs app files remain modifications; do
not disguise them as generated content. Use supported manifest repair-origins for local URLs.

## Package and source upgrade

Merge target dependency changes into the existing manifest, retaining custom scripts and
packages. Remove the obsolete @orama/orama dependency only if no custom feature still uses
it. Use staticClient from fumadocs-core/search/client/orama-static with useDocsSearch({ client:
staticClient({ locale }) }); let createFromSource use its default ZBSearch engine and export
staticGET. Preserve customized searches if present and adapt them using upstream source.
Use Mori to locate sources; verify releases against npm and upstream tags before selecting
new versions beyond the tested cohort.

Remove a project-local TypeScript compiler that shadows the shared Nix compiler. CI must
enter the same Nix shell for typechecking, linting, and formatting; do not keep old dlx pins.
Retain pnpm's workspace/lock and packageManager if it is the project's workflow, or create a
Bun lock if it already uses Bun. Keep frozen-lock installation in CI. For a configured release
age that blocks explicitly requested fresh pins, use a one-time install override rather than
weakening global settings. Run application Node-shebang commands under the retained Node
runtime or explicitly under Bun. Include the MDX generation step in typechecking.

Fix compiler/linter compatibility issues precisely. HAST className can be treated as unknown
before validating string/array forms. Mermaid render state should be keyed by chart and theme,
with asynchronous completion setting one result; avoid synchronous setState resets in effects.
Use TanStack's validator method in place of deprecated inputValidator. Merge template ignore
patterns with existing project ignores, including dependency-owned nix/tooling-sources.json.
Do not suppress errors broadly or delete custom diagram/editorial gates to obtain green tests.

## Validation and handoff

Make new Nix files visible with git add -N for the exact new paths; leave existing staging
alone. Verify the dependency-free canonical lock is byte-identical to the module's lock, and
nix flake lock and nix flake update preserve module revisions. Verify the custom dev tools
actually appear in nix develop. Run the existing project's complete check command, not just
Vite: editorial tests, terminology, navigation, diagram tests, typecheck, lint, format, build,
and internal links when present. Report pre-existing failures separately with evidence.

Inspect prerendered docs HTML, raw Markdown routes, static server-function data, and search
index. Query the actual Fumadocs staticClient against the exported index and require a known
existing page in the results. Test custom diagram rendering and preview routes as applicable.
Verify content hashes and custom grammar/component/font behavior were preserved. Leave a
migration report with the tested module/library versions, customization mapping, commands,
remaining warnings/limitations, and origins. A second run should preserve customizations and
produce no toolchain drift. Do not record a migration receipt until the checks pass.
```

## Reference files

- `target-versions.json` - Tested target cohort; refresh alongside the modules, never guess versions from an old reference
- `flake.module.nix` - Unmanaged extension example retaining a pnpm/Node workflow beside the shared Bun toolchain

## Migrations

### 0.1.2 → 0.2.1

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
