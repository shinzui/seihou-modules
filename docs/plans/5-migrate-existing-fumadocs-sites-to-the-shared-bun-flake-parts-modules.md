---
id: 5
slug: migrate-existing-fumadocs-sites-to-the-shared-bun-flake-parts-modules
title: "Migrate existing Fumadocs sites to the shared Bun flake-parts modules"
kind: exec-plan
created_at: 2026-10-08T14:52:21Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-10-08T14:52:21Z
  revisions:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-10-08T15:09:27Z
      mode: "implement"
      note: "Implement safe Fumadocs adoption blueprint and validate the existing documentation pilot"
---

# Migrate existing Fumadocs sites to the shared Bun flake-parts modules

## Purpose / Big Picture

Existing Fumadocs sites can adopt the released shared flake-parts environment and
current Fumadocs packages without losing documentation, custom components, CI gates,
or a pnpm workflow. A reusable agent blueprint will guide that merge. The concrete
pilot is mori://shinzui/keiro-runtime-docs.

## Progress

- [x] Inventory module composition and the pilot's existing customizations.
- [x] Implement a validated discoverable blueprint and test both prompt entry points.
- [x] Migrate the pilot using Seihou-owned baselines and portable origins.
- [x] Pass the pilot's complete quality gates and static-output checks; document results.

## Surprises & Discoveries

The pilot records nix-bun-flake 0.2.0 but its Fumadocs application is hand-authored.
Its flake replaces Bun with Node 22/pnpm. The new module's Nix compiler would be
shadowed by its local TypeScript 6 dependency. CI uses old Oxc dlx pins. The schema
pin used by existing blueprints predates migration fields; a record extension is
required to declare an ordered edge accepted by the current CLI. Debug agent run
records blueprint provenance even with no baseline; debug migrate is read-only.
Noninteractive update needs --json to accept the reviewed plan; otherwise cancellation
can return exit zero. repair-origins cannot convert project origins. Starter content
needs a separate flag, and module removal must retain documentation.

## Decision Log

Preserve Node/pnpm in the unmanaged flake.module.nix; the shared Bun toolchain is
additive. Do not switch the package manager. Use an empty blueprint baseline to
prevent starter content from replacing an existing site. Track the Fumadocs module
0.1.2-to-0.2.1 edge; ordinary agent run supports legacy adoption without receipts.
Use Seihou operations to create baseline hashes and application identifiers, with
external candidate copies carrying the owning remote provenance. Publication of the
Fumadocs and blueprint changes remains pending. No commits or
pushes are part of this request.

## Outcomes & Retrospective

Implemented the discoverable upgrade-fumadocs blueprint and migrated the pilot to
Fumadocs module 0.2.1/shared Bun module 0.3.0. The complete pnpm check passed,
including production prerendering and source links across 500 MDX pages. All 805
content files and the custom Keiro grammar are unchanged. Frozen pnpm installation,
Nix flake checks, and fresh-scaffold bootstrap passed. The adoption regression test
verifies repeated generation, unclaimed existing content, retained content on removal,
and both blueprint prompt entry points. The user requested atomic commits after
validation. Separate commits record the module release, migration blueprint,
consumer adoption, and consumer documentation.

## Context and Orientation

modules/typescript/fumadocs owns the application templates and depends on
nix-bun-flake. blueprints/upgrade-fumadocs supplies merge guidance rather than
automatic starter generation. The pilot has source, MDX content, a custom Keiro
grammar, editorial/terminology/navigation/diagram/link checks and portable licensed
font handling. All must survive. ADR 3 (docs/adr/3-separate-managed-scaffold-nix-wiring-from-user-extensions.md)
establishes that module-generated wiring and unmanaged project extensions have
separate ownership; this migration applies that boundary to TypeScript.

## Plan of Work

Validate blueprint schema and debug-render both run and migrate prompts without
launching another agent. Back up the pilot outside its tree and hash all content.
Generate the current composed scaffold in isolation, reconcile the recorded Bun
application, adopt Fumadocs with explicit existing values, and merge custom app
files. Retain hooks, pnpm/Node, scripts and optional-font behavior. Update the
package cohort and CI, regenerate the pnpm lock, then run all gates. Keep Seihou
baselines canonical so later changes remain visible as user modifications.

## Concrete Steps

```bash
seihou validate-blueprint blueprints/upgrade-fumadocs
seihou agent --debug run upgrade-fumadocs --no-baseline
seihou agent --debug migrate upgrade-fumadocs --from 0.1.2 --to 0.2.1
```

Pilot commands use external unpublished candidate copies with canonical remote origin
metadata, discovered via ignored project-local symlinks. Seihou-generated IDs and
baselines are preserved. Shared ownership remains between the legacy Bun application
and the new Fumadocs composition; future updates must include shared owners.
Make new Nix paths visible with git add -N.

## Validation and Acceptance

Blueprint validation and prompt rendering pass. All pilot content hashes remain
unchanged. Shared lock pins match the module before and after full flake update.
TypeScript 7 and current Oxc tools run from Nix, while pnpm/Node remain available.
The complete project check covers editorial tests, prose, terminology, navigation,
diagrams, typecheck, lint, formatting, production prerendering and internal links.
Actual staticClient queries find an existing docs page; Markdown and server-function
cache output exist. Repeat adoption preserves project customizations.

## Idempotence and Recovery

Backups live outside the pilot; restore only paths changed by this migration if a
step fails, leaving unrelated work untouched. Keep package/lock updates together.
Do not mark migration receipts complete until validation passes. Candidate module discovery links remain ignored. No reset, blanket clean or content deletion is needed.

## Interfaces and Dependencies

The tested cohort is nix-bun-flake 0.3.0, fumadocs module 0.2.1, Bun 1.4.2,
TypeScript 7.0.2, Core/UI 16.16.2 and MDX 15.4.6. Source lookup used
mori://shinzui/seihou and mori://shinzui/seihou-schema (Blueprint.dhall project-relative
schema artifact URI pending). Existing upstream version checks came from npm and
release tags. ADR 4 (docs/adr/4-preserve-authored-content-during-fumadocs-adoption.md)
records the content/adoption boundary. The pilot's pnpm lock and package-manager choice remain authoritative.
