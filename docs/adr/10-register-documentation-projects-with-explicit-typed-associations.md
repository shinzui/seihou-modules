# Register documentation projects with explicit typed associations

## Status

Accepted on 2026-11-09.

## Context

A documentation site has its own checkout, identity and authored content. Its name,
namespace and GitHub owner can differ from those of the project it documents.
Composing site generation with external writing skills also crosses registry ownership
boundaries. A successful scaffold render alone does not prove local registration.

## Decision

`fumadocs-site` composes the existing Fumadocs module with all three container
bindings, writing skills from `mori://shinzui/agent-seihou/templates/technical-docs`,
and a final local Mori bootstrap command. Acquire external skills through Seihou's
source-aware dependency graph; do not vendor their source. Keep ordinary Fumadocs
dependency identities and container defaults unchanged, following
[ADR 7](7-keep-service-images-unmanaged-and-use-nix2container-transports.md).

Documentation and source identities are separate required inputs. Require the source
identity to exist in the local registry, reject self-association, and reject an existing
documentation identity at a different path before creating a manifest or registering.
Use subprocess argument arrays and staged value files; serialize values as Dhall text
with interpolation escaped.

Seed a minimal `Schema.Project::{ ... }` manifest from the immutable, integrity-hashed
schema pinned by the qualified release of `mori://shinzui/mori`. Use
`Other "Documentation"`, `TypeScript`, `Active`, a local `site` guide at `content/docs`,
and one project-level typed `dependencyRefs` entry for the documented project.
The schema has no dedicated documents-project relation. `depends-on` therefore denotes
this documented-project association; `upstream` remains reserved for fork/vendor origin.
Do not infer packages, repository URLs or deployment details.

The manifest is an authored seed outside Seihou file ownership. Create it exclusively
when absent. On reruns, validate and check identity and association without rewriting
existing bytes or removing additional fields. Always call `mori register --local` with
the absolute documentation root. Report completion only after reading back the exact
identity/path and resolved relation. Registration failure must remain a failure with
retry guidance; generated files and any already completed registration persist.

Removal preserves the manifest, content and registry identity. Registry lifecycle is
managed explicitly with Mori; Seihou file rollback cannot roll back this external effect.
This extends the authored-content boundary in
[ADR 4](4-preserve-authored-content-during-fumadocs-adoption.md).

## Consequences

`fumadocs-project` 0.2.0 creates a complete repository through `repo-dir` 0.2.0.
The directory module acquires and applies `fumadocs-site` inside the new target,
then delegates initial commit, GitHub creation/push and team access to the existing
`git-init`. No Git/GitHub command logic is duplicated. The initial commit includes
the site, skills, authored Mori manifest and Seihou manifest. GitHub creation happens
only after the scaffold and local Mori registration succeed.

Seihou 0.15 applies all ordinary dependencies in the invocation directory and has no
install-only edge. The directory command therefore acquires its declared child scaffold
and git-init through the normal installer before nested application. The child recipe
retains the external skills' source-qualified dependency graph. `repo.source` selects
the registry, including forks or local fixtures; acquisition never forces replacement
of foreign installed artifacts. This command needs network or the chosen local source.

Resolve wrapper inputs before changing directories. Read the active application's
`recipeInputs` and repo-dir instance's `resolvedVars` from Seihou's pre-command
manifest, scoped by the current generation timestamp; fail if the active application
is ambiguous. A generic repo.scaffoldBindings map supplies omitted child inputs from
resolved outer inputs while explicit child values win. Fumadocs site-link owner/name/branch
default to the actual created remote; optional docs.github-repo keeps package/Mori and
repository names independent. The legacy flat `variables` summary omits recipe-only inputs. Pass values
to child commands as argument data. Reject nonempty targets, files and symlinks before
acquisition or creation. Partial failures preserve the checkout; recovery happens inside
it, while repeated creation refuses to overwrite it. Existing checkouts apply
`fumadocs-site` directly. Removing the outer directory wrapper never deletes the child.

Consumers can discover associations through `mori registry relations --from` and
`--to`. Mori 7.2's `registry dependents` omits typed-only project references, so it
is not acceptance evidence for this contract. `mori show --json` also omits
`dependencyRefs`; the bootstrap uses `dhall-to-json` to inspect authored manifests
after `mori validate`.

End-to-end fixtures acquire both registries through real Git transport, isolate Seihou
configuration and run a private migrated PostgreSQL cluster. Temporary HOME alone
does not isolate the registry; the fixtures override `MORI_PG_CONNECTION_STRING` and
other PostgreSQL settings before any writes.

Seihou 0.15's OKF exporter treats external recipe members as dangling local links.
Until a released exporter handles them, `scripts/generate-okf-docs.py` stages the local
graph, invokes that exporter, restores external edges as canonical Mori links in original
order and validates the final generated bundle. Neither published descriptors nor
external skill templates are changed by documentation generation. Remove this adapter
when a released exporter preserves and validates the same external attribution.
