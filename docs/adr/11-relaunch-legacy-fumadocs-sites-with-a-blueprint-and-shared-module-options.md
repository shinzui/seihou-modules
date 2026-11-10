# Relaunch legacy Fumadocs sites with a blueprint and shared module options

## Status

Accepted on 2026-11-10.

## Context

Several of the operator's documentation sites were generated in mid-2026 on early
`fumadocs` and `nix-bun-flake` releases, with Mermaid-only diagrams, no writing skills
and no release gates. The Kotei documentation was relaunched first, under
mori://shinzui/kotei-docs/masterplans/2-relaunch-the-kotei-documentation-for-the-initial-public-release,
and every non-content change was recorded in its migration ledger
(`docs/migration-ledger.md` in mori://shinzui/kotei-docs; artifact-level URI pending).
That ledger showed two kinds of change. Some were the same edit to a managed file in
every site: a diagram component and styles, several OpenAPI documents, a link check that
checked nothing, typecheck and format scopes that broke on the planning skills, a local
font path, and Pierre Highlights in place of Shiki. Others needed judgment per site:
whether to restart or refresh the content, what the documented project is, which gates
its pages can pass yet.

## Decision

Change shared behavior in the `fumadocs` module, as options with safe defaults, and
leave per-site judgment to an agent blueprint.

The module owns the diagram system (`docs.svg-diagrams`), directory input for OpenAPI
documents, a link check that crawls real pages, the typecheck and format exclusions, an
environment-provided font flake, and Pierre Highlights. A site gains these by
reapplying the recipe, not by carrying local edits to managed files.

The `relaunch-fumadocs-docs` blueprint owns what depends on the site and the documented
project: inventory and backup, the rehearsed platform upgrade, Mori registration, the
source pin and its citation component, the release gates, and a measured content
assessment. The blueprint stops after the assessment, with a restart-or-refresh
recommendation, a page list and a diagram catalog, because the writing skills require
the operator to confirm a page list before pages are written. It keeps `baseModules`
empty, following [ADR 4](4-preserve-authored-content-during-fumadocs-adoption.md).

Product-specific generators, such as a CLI reference built from one program's parser,
stay out of both. The blueprint names them as an option.

## Consequences

A site relaunched this way still carries three kinds of managed-file edit: its own gate
scripts in `package.json` and `justfile`, generated pages in the format ignores, and the
registration of `<SourceRef>` and `<TestedWith />` in `src/components/mdx.tsx`. Each
reapplication of the recipe overwrites them and the blueprint restores them from a
backup. An extension point for MDX components would remove the last.

`seihou update` cannot update applications of the `fumadocs-site` recipe, because it
refuses the recipe's files under `.seihou/`. Until Seihou supports that, sites move to a
new module release by reapplying the recipe with every variable.

The release gates are blueprint files, not module files, because they read a
project-neutral source pin and site settings that a module cannot know. Legacy pages
fail several of them, so the blueprint wires them into a separate `check:release` until
the content passes.
