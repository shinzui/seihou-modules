# Documentation relaunch migration ledger

This ledger records every non-content change made while relaunching this site with the `relaunch-fumadocs-docs` blueprint from mori://shinzui/seihou-modules. It is append-only, and entries are numbered in order. Content changes belong in the verification register, `docs/verification.json`, not here. An entry is written in the same change as the work it records, not reconstructed afterward.

## Entry format

Every entry has these fields, in this order.

- **Plan**: the plan or blueprint phase that made the change.
- **Commit**: the short hash in this repository, `<hash> in mori://<namespace>/<project>` for another repository, or `none; scratch procedure` for work that left no commit.
- **Area**: one of `platform` (modules, toolchain, build, image), `authoring-system` (source pin, citations, components, diagrams), `gates` (checks that fail a build), or `content-process` (how pages are measured, written, proven and reviewed).
- **Applies to**: `every-site`, `this-site-only`, or a named class such as `sites-with-openapi` or `sites-without-generated-reference`.
- **Automate as**: `module-change` (belongs in a Seihou module), `blueprint-file` (a file the blueprint carries), `blueprint-prompt` (an instruction the blueprint gives), or `site-judgment` (a decision for each site's operator).
- **Commands**: the commands actually run, with their real flags and variables. Name files changed. Never write a local absolute path; use a `mori://` URI or a repository-relative path.
- **Why**: the problem the change solves, in one or two sentences.
- **Verified by**: the observed result, with numbers: exit status, page and route counts, the gate that passed, or the violation a gate rejected.
- **Watch out**: what surprised you, what a later site will meet, and what should move into a module.

## Entries

### L-1: <Imperative title of the change>

- Plan: <plan path or blueprint phase>
- Commit: <hash, or none; scratch procedure>
- Area: <platform | authoring-system | gates | content-process>
- Applies to: <every-site | this-site-only | sites-with-...>
- Automate as: <module-change | blueprint-file | blueprint-prompt | site-judgment>
- Commands: <commands run>
- Why: <reason>
- Verified by: <observed result>
- Watch out: <surprises and promotion candidates>

## Merge list

Record here, as a table, every file the `fumadocs-site` recipe changed and what was merged back into it.

| File | Decision |
| ---- | -------- |

## Open links

Links from finished pages to pages not yet written. Each must resolve before release.
