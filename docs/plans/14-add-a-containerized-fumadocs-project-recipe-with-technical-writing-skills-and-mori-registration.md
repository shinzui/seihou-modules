---
id: 14
slug: add-a-containerized-fumadocs-project-recipe-with-technical-writing-skills-and-mori-registration
title: "Add a containerized Fumadocs project recipe with technical writing skills and Mori registration"
kind: exec-plan
created_at: 2026-11-09T23:10:27Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-11-09T23:10:27Z
  revisions:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-11-09T23:13:17Z
      mode: "other"
      note: "Ground the new recipe plan in released cross-registry acquisition and Mori manifest and registration contracts"
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-11-09T23:23:38Z
      mode: "implement"
      note: "Implement and qualify the containerized documentation recipe and local Mori bootstrap"
---


# Add a containerized Fumadocs project recipe with technical writing skills and Mori registration

This ExecPlan is a living document. Keep Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective current. Record implementation friction with the exec-plan skill scripts and distill durable decisions into docs/adr/ before completion.

## Purpose / Big Picture

A user installs and runs `fumadocs-project` from a launch directory, supplying repo.parentDir and repo.name. The recipe creates the selected child directory, applies the documentation scaffold there, then reuses git-init for its initial commit, GitHub repository and push. Existing checkouts use `fumadocs-site` directly. It will generate the existing Fumadocs site with its nix2container build enabled, acquire and apply `technical-docs` from agent-seihou, create a minimal `mori.dhall`, associate the documentation project with the project it describes, and register the documentation project in the local Mori registry. A user can then find that association through Mori and build the site and Linux container using the existing Fumadocs commands.

This plan implements recipe authoring for future documentation projects. Fixture acquisition and registration use disposable registries and a private PostgreSQL cluster. A recipe is a named composition of Seihou modules; a Mori manifest is a typed Dhall file describing a project's identity and discoverable artifacts. nix2container produces an image description with explicit export helpers.

## Progress

- [x] Milestone 1 (2026-11-09, real two-registry acquisition and no-commands rendering passed): Installing and applying the composition acquires Fumadocs, its Bun base, technical-docs and agent-gitignore from their correct registries; rendering enables all three container settings and installs the writing skills.
- [x] Milestone 2 (2026-11-09, full real Mori 7.2 fixture passed): Running the recipe creates a valid minimal documentation manifest with the documented-project association and registers it locally; reruns preserve authored manifests and reject conflicting identities.
- [x] Milestone 3 (2026-11-09, isolated fixture, sandbox site build, native aarch64 Linux export/HTTP and both catalogs/generated docs verified): Isolated end-to-end checks prove acquisition, registration, association, recovery and ownership; the existing site/container checks pass and the recipe is discoverable in both catalogs and generated documentation.

- [x] Milestone 4 (2026-11-09, full repository/registry fixture, host site/container checks and existing OpenAPI repository regression passed): The public recipe creates a chosen directory, applies the site inside it, and delegates initial commit, GitHub creation/push and optional team access to existing repo-dir/git-init modules; isolated tests prove ordering, ownership, context forwarding and failure protection.

No intention is active; the user selected Skip. All four milestones, including the user-requested repository creation extension, are complete. The comprehensive fixture passed acquisition, registration, both-direction relation discovery, content discovery, two independent consumers, preserved authored additions, invalid/missing/self/colliding inputs, escaped descriptions, registry-write failure, actual PostgreSQL outage/recovery, plain Fumadocs update behavior and removal preservation. Host site/container checks passed. Native Apple-container build/archive inspection, uniquely tagged export, HTTP startup and cleanup passed. Both catalogs validate, generated documentation is byte-stable and strictly valid, and ADR 10 records the durable ownership contract.

## Surprises & Discoveries

2026-11-09: The released OKF exporter emits a local link for every recipe member, including source-qualified external members, then rejects the dangling `modules/technical-docs` link. `scripts/generate-okf-docs.py` stages the local graph for the released exporter and restores external members as canonical Mori links in original order before strict final validation. The public descriptor retains its real external source; no skill templates are vendored. See FRIC-14 in `docs/friction-log/`.

2026-11-09: Mori 7.2 resolves typed `dependencyRefs` into `depends-on` relations but `registry dependents` returns no rows for these typed-only project edges. Use `registry relations --to` for reverse discovery. Its `show --json` also omits `dependencyRefs`, so the helper requires `dhall-to-json` to inspect the validated typed manifest. See FRIC-15 in `docs/friction-log/`.

2026-11-09: Recipe member enumeration is topologically sorted rather than declaration ordered. Released Seihou executes all generation steps before the command phase, so the helper command can register only after both the site and writing skill files exist. No dependency identity changes are necessary.

## Decision Log

2026-11-09: Compose the existing `fumadocs` module with explicit container bindings, the external `technical-docs` module, and a small local `docs-mori-bootstrap` helper. This uses released cross-registry dependency acquisition and keeps existing Fumadocs dependency identities unchanged.

2026-11-09: Represent the association in the documentation project's `dependencyRefs` as a typed project-level Mori reference. The inspected schema has no dedicated “documents project” relationship field. This makes the target queryable through the supported dependency relation without modifying another checkout or inventing schema fields. Documentation must label this as the documented-project association. Add a local `DocRef` for the site's `content/docs` tree. Do not use `upstream`, which describes fork/vendor origin.

2026-11-09: Apply the recipe in the user's chosen documentation directory. The original scope excluded directory/GitHub creation. The user explicitly added directory, Git and GitHub creation on 2026-11-09; image publication and deployment remain outside scope. Local registration is a required normal command step, never an opt-in defaulting to false.

2026-11-09: Keep the typed association minimal and use Mori's relation queries for both directions instead of adding redundant legacy dependency text to accommodate `dependents`. Add `dhall-to-json` as an explicit helper prerequisite. Use the repository generation adapter until a released exporter supports external recipe-member links. Durable context is recorded in [ADR 10](../adr/10-register-documentation-projects-with-explicit-typed-associations.md).

2026-11-09: The user added directory, Git and GitHub repository creation. Promote the existing direct composition to `fumadocs-site` 0.1.0 and make `fumadocs-project` 0.2.0 drive `repo-dir` 0.2.0. Extend the existing directory module to accept an optional child scaffold, apply it before `git-init`, and forward resolved recipe variables as argument data. This ensures the site, skills, Mori manifest, initial commit and remote all belong to the created checkout. Preserve GitHub owner/context/visibility/team handling through the existing git-init module. Released Seihou has no install-only dependency edge; repo-dir must acquire its declared child scaffold and git-init with the normal installer before nested application. The external skills remain in the child recipe's dependency graph. See FRIC-16 in `docs/friction-log/`.

2026-11-09: Default the public workflow's site GitHub links to the actual created owner/name/branch through a generic repo.scaffoldBindings map. Explicit site overrides win. Fumadocs 0.4.1 adds optional docs.github-repo, so repo.name and project.name can differ without broken links; direct sites still default to project.name. No toolchain, container or dependency-source pins changed.

## Outcomes & Retrospective

Implemented on 2026-11-09. The initial local artifacts were `fumadocs-project` 0.1.0 and `docs-mori-bootstrap` 0.1.0. The repository-creation extension now publishes `fumadocs-project` 0.2.0, `fumadocs-site` 0.1.0 and `repo-dir` 0.2.0, plus Fumadocs 0.4.1 for repository-link overrides and the unchanged bootstrap module, in both catalogs and a regenerated 28-concept documentation bundle. The inner composition preserves ordinary Fumadocs dependency identities and pins and acquires its six artifacts through the proper registries, enables all three container bindings, and creates six skill sources with eighteen discovery links. Real Mori 7.2 registration is verified after validation; authored manifests, documentation and registry identities survive reruns/removal. The initial scope and the subsequent Milestone 4 repository creation extension are complete; no implementation work remains. Publishing this checkout upstream remains a separate action.

Acceptance used `seihou` 0.15.0.0 (`a4fcee6`) and the released Mori 7.2.0.0 (`34ce2cf`). `scripts/test-fumadocs-project.py` passed with its private migrated PostgreSQL cluster, real Git acquisition, independent consumer identities, both-direction resolved association queries, local content discovery, preserved manifest additions, invalid and conflicting inputs, literal escaped text, precise registration failure, actual service outage/recovery and ownership removal. `scripts/test-fumadocs-bootstrap.py` passed the shared lock, toolchain, static prerender/search/Markdown/diagram and flake checks. `scripts/test-fumadocs-container.py --apple-linux` passed the host sandbox site build and Caddy routes, Linux helper evaluation, Darwin exclusion, default/update/removal behavior, native aarch64 image build, OCI archive inspection/export and an actual HTTP 200 from the image on port 8080. The native runner was a fresh local Apple container using `ghcr.io/nixos/nix:2.35.2`; its nested Nix sandbox was disabled, while the separate host site build used the sandbox. No remote builder was needed.

Descriptor validation, `seihou registry sync-versions`, `seihou registry validate`, root Mori manifest evaluation, strict generated-bundle validation, byte-stable regeneration, strict friction-log/profile/log validation and `git diff --check` passed. The plain exporter cannot generate the new external edge by itself; the checked-in adapter is the documented generation entry point until upstream support exists.

FRIC-13 in `docs/friction-log/` is resolved: temporary Nix builds provided the exact released Mori and migration runner without replacing global tools. FRIC-14 is accepted: keep the external-edge documentation adapter until the released exporter handles source-qualified members. FRIC-15 is accepted: use typed relation queries for this association, since Mori 7.2 dependents omits typed-only project edges. All initial entries are triaged. FRIC-16, recorded for the repository-creation extension, is accepted: repo-dir acquires nested members through the normal source-aware installer because ordinary dependencies apply in the invocation directory. [ADR 10](../adr/10-register-documentation-projects-with-explicit-typed-associations.md) distills registration, identity, ownership, query and documentation-generation boundaries.

Repository-creation acceptance completed on 2026-11-09. The final `scripts/test-fumadocs-project.py` passed real acquisition from disposable Git registries, real initial commits and pushes to local bare remotes, all six skills and both manifests in the first pushed commit, distinct repository/Mori names, exact child registry paths, context-selected owner/team, public/private visibility and main/master branches, defaulted and overridden site links, dry-run/no-commands, quoted parent paths, symlink/nonempty protection, missing-target and GitHub failure preservation, direct empty-repository creation, and outer-wrapper removal preserving the child checkout and registry identity. The GitHub service was an offline CLI fixture; no live GitHub test repositories were created. The direct-site registry, outage/recovery, manifest ownership and plain Fumadocs update checks remained green. `scripts/test-openapi-typescript-client-repo.py`, the fresh Fumadocs bootstrap and host container checks also passed. Descriptor/catalog/Mori checks and strict generated-doc/friction validation passed. ADR 10 records the generalized child-directory/acquisition/input-binding contract. FRIC-16 is accepted as documented above. The prior native Apple-container image evidence remains valid for unchanged container wiring and pins; this extension reran host builds and serving for the new optional link field.

## Context and Orientation

The repository publishes file-generating modules in `modules/`, compositions in `recipes/`, a Seihou acquisition catalog in `seihou-registry.dhall`, and Mori template discovery entries in `mori.dhall`. `README.md` documents authoring and catalog regeneration. `okf-docs/` is generated and must be regenerated rather than edited manually. There is no repository-root flake; generated consumer projects own their flakes.

`modules/typescript/fumadocs/module.dhall` is version 0.4.1 after the repository-creation extension; its optional docs.github-repo preserves ordinary defaults while allowing the created remote and package/Mori identity to differ. It depends on `nix-bun-flake` and already supports `docs.container=true`, `nix.bun2nix=true` and `nix.package-module=nix/fumadocs-container.nix`. All three values are required together. `modules/typescript/fumadocs/README.md` explains the sandboxed static build, Caddy on port 8080 with user 65532, fonts and generated lock files. `modules/typescript/fumadocs/files/source.config.ts` reads `content/docs`. The module owns its known static-site image; the consumer owns `bun.lock`, `bun-deps.nix`, and `flake.module.nix`. The recipe must leave the ordinary module's defaults unchanged.

`recipes/docs-microapp-labs/recipe.dhall` demonstrates composition. `scripts/test-docs-microapp-labs.py` demonstrates real installation from a disposable Git registry with isolated Seihou cache/configuration; adapt that pattern rather than copying files into the installed module cache as the only acceptance check. `modules/typescript/openapi-typescript-client-dir/module.dhall` demonstrates staging a Python helper and value files to keep values out of shell command text. `scripts/test-fumadocs-bootstrap.py` and `scripts/test-fumadocs-container.py` provide the existing consumer and native image acceptance paths.

The external module is `mori://shinzui/agent-seihou/templates/technical-docs`, currently version 0.1.0. Its owning project is `mori://shinzui/agent-seihou`; artifact-level source URI coverage is pending for project-relative `modules/technical-docs/module.dhall`. It creates `agents/skills/tech-docs/SKILL.md` and five form skills with shared writing rules, with checkout links under `.claude/skills`, `.codex/skills`, and `.agents/skills`. It depends on `agent-gitignore` in the same external registry. The `skill.prefix` default is `tech-docs`. Use `https://github.com/shinzui/agent-seihou.git` as the acquisition source; source URLs in executable descriptors are distinct from durable cross-repository citations.

Mori owns the registry contract: `mori://shinzui/mori`. The schema belongs to `mori://shinzui/mori-schema`; artifact-level source URI coverage is pending for `Project.dhall`, `records/MoriRef.dhall`, `records/DocRef.dhall`, and `types/DocLocation.dhall`. `Project` has `dependencyRefs`, `docs`, and defaults for omitted lists. `MoriRef::{ namespace = ..., name = ... }` points at a project when kind/key are omitted. `DocLocation.LocalDir` identifies the local content tree. The current inspected `PackageType` uses `Other "Documentation"`, not a nonexistent `Documentation` union arm. Canonical project URIs have the form `mori://<namespace>/<name>`.

Research found installed Seihou 0.15.0.0 and Mori 7.1.0.0. GitHub's release endpoints and tags report Seihou v0.15.0.0 and Mori v7.2.0.0 as latest; the Mori working checkout can lag those releases. The released Seihou v0.15.0.0 install closure reads an explicit dependency `source` and locates transitive dependencies in that registry. The local schema's `Dependency` record also exposes `source : Optional Text`. Before selecting an immutable schema import, verify the published schema at the chosen revision and the current Mori release's pinned schema; do not assume this repository's older import is appropriate. No application dependency upgrade is needed for this recipe.

Relevant local ADRs were scanned by filenames/headings and read. [ADR 3](../adr/3-separate-managed-scaffold-nix-wiring-from-user-extensions.md) preserves the managed package-module seam and unmanaged extension file. [ADR 4](../adr/4-preserve-authored-content-during-fumadocs-adoption.md) requires preserving authored content and makes existing-site adoption a distinct workflow. [ADR 6](../adr/6-share-an-opt-in-bun2nix-helper-and-isolate-registry-caches.md) leaves lock generation explicit and consumer owned. [ADR 7](../adr/7-keep-service-images-unmanaged-and-use-nix2container-transports.md) explicitly permits the managed Fumadocs Caddy image, requires explicit transports, and explains why container bindings cannot be imposed on every Fumadocs dependency. The current manifest has no profiled docs/adr bundle; preserve the existing filesystem ADR convention. No existing ADR defines this new documentation-project registration contract.

## Plan of Work

### Milestone 1: Acquire and render the composition

Create the direct composition in `recipes/fumadocs-site/recipe.dhall` and its README. The original 0.1.0 public recipe became this inner composition when Milestone 4 added repository creation. Bind all three container values on its Fumadocs member. Declare `technical-docs` with `source = Some "https://github.com/shinzui/agent-seihou.git"`; keep local members in the declaring registry. Use descriptor records compatible with released Seihou 0.15, including explicit `source = None Text` where required by the selected common record type. Add the helper module described below as the final member. Do not duplicate the external writing skill templates or add shell commands to install and run them outside the dependency graph.

Create `modules/mori/docs-mori-bootstrap/module.dhall` with declared identity inputs, staged value files, a copied Python helper and a fixed command invoking that helper. Verify the actual graph's command order early: Fumadocs generation and skill application must precede final registration. The milestone's integration proof is a real install into an empty consumer using two disposable Git registry snapshots, retaining the external source edge and agent-gitignore's same-registry dependency. Inspect the manifest's source provenance and generated skill links. Rendering with `--no-commands` proves file composition only and must not be reported as registration success.

### Milestone 2: Seed, associate and register the documentation project

Implement `modules/mori/docs-mori-bootstrap/files/bootstrap-docs.py` and its configuration templates. Public helper inputs are required `project.name`, `project.description`, `mori.namespace`, `mori.source-namespace`, and `mori.source-project`. The latter two identify the project being documented independently of the site's name and namespace. Require that target to resolve in the local registry; report a missing target before writing the new manifest or registering anything. Reject self-association and a documentation identity already registered at a different path. Resolve paths without assuming GitHub names match Mori names. Use subprocess argument arrays and safe serialization of strings into Dhall, including quotes, backslashes, Unicode, newlines and interpolation syntax.

A new minimal manifest imports an immutable, integrity-hashed published Mori schema and uses `Schema.Project::{ ... }`. Its identity uses the site's name, namespace and description, `PackageType.Other "Documentation"`, `Language.TypeScript`, and `Lifecycle.Active`. Add exactly one project-level typed `dependencyRefs` entry for the target and a `docs` entry with key `site`, `DocKind.Guide`, `DocAudience.User` and `DocLocation.LocalDir "content/docs"`. Verify those constructor names against the selected published schema before writing the template. Omit fabricated packages, repository URLs, deployment locations and unrelated inventories. Preserve producer-owned manifests as user-owned seeds: on rerun, validate the existing file and verify its identity and required association without overwriting it or deleting extra fields.

Validate the new or existing manifest using released `mori validate`, then invoke `mori register --local --path <absolute-documentation-root>`. Verify success by reading back the registered identity/path and relation. Evaluate the typed manifest with `dhall-to-json --file mori.dhall` after `mori validate`, since Mori 7.2 omits dependencyRefs from show JSON. Emit completion only after both registration and readback succeed. A registration failure returns a nonzero result with the failing command and retry guidance while preserving generated files. Do not edit registry storage directly. The `--local` flag is mandatory so shared registry configuration cannot cause a remote write. A later Seihou removal must preserve the authored manifest and content and must not silently deregister the project.

Prove this milestone with real Mori, two identities intentionally named differently, and a disposable local registry. Check the actual commands/configuration for registry isolation in the current Mori source; a temporary HOME alone may not isolate a configured PostgreSQL connection. Use a disposable database via the documented `MORI_PG_CONNECTION_STRING` path when required, and keep production connection settings out of fixture execution. Test an unavailable registry and recovery by rerunning after it becomes available. Registration is a nontransactional external effect: Seihou cannot imply rollback of it.

### Milestone 3: Qualify and publish discovery

Add `scripts/test-fumadocs-project.py` for real acquisition plus render/bootstrap/registry verification. Reuse the existing Fumadocs harness for site and image behavior instead of adding another implementation of the container. Check two consumers with different namespaces and names, the target relation, local content discovery, writing skill sources and links, default container settings, exact registered path, reruns, preserved authored manifest additions, invalid/missing target inputs, self-reference, duplicate identity at another path, escaped input and failing registration. A no-commands render must leave the registry untouched. Verify that an existing plain Fumadocs consumer retains its original dependency identity and update behavior.

Register the recipe and helper in `seihou-registry.dhall` and `mori.dhall`, using version 0.1.0 initially, with correct required variables, tags and dependencies. Document the workflow and prerequisites in the recipe/helper READMEs and root README. Keep the external dependency visibly attributed to agent-seihou. Regenerate `okf-docs/` with `scripts/generate-okf-docs.py`, which adapts external edges for the released exporter and strictly validates the result. Run appropriate descriptor/catalog checks and the focused consumer tests. For Linux container acceptance prefer local Apple `container` tooling; use a matching remote builder only when local containers cannot satisfy the existing harness. Record site build, native image build/export and HTTP startup evidence separately. Finish by recording the durable registration/ownership contract in a local ADR, and triage any implementation friction.

### Milestone 4: Create the complete documentation repository

Move the current direct recipe into `recipes/fumadocs-site/recipe.dhall`, version 0.1.0. Change `recipes/fumadocs-project/recipe.dhall` to version 0.2.0, composing repo-dir with an explicit child scaffold `fumadocs-site` and source `https://github.com/shinzui/seihou-modules.git`. Declare the site and Mori inputs on the public wrapper, so context/CLI values resolve before entering the target. The public directory and GitHub name is `repo.name`; project.name remains the documentation identity and may differ. Omitted site-link overrides use the created repository coordinates; direct-site defaults are unchanged.

Extend `modules/git/repo-dir` to version 0.2.0 with a staged Python helper and declared Git/directory inputs. Add optional repo.scaffold and a repo.source defaulting to the declaring public registry URL. Read the current application's recipeInputs and repo-dir instance resolvedVars from Seihou's recorded manifest as data, excluding directory/Git controls before child application. The legacy flat variables projection omits recipe-only inputs; select the application whose appliedAt matches the manifest generatedAt and fail if ambiguous. Acquire git-init and any declared scaffold through `seihou install`, which preserves the scaffold's normal source-aware closure. Reject symlinks, non-directories and nonempty targets before installation or creation. Apply the scaffold in the new directory, then invoke the existing git-init module there with initial commit and GitHub creation enabled. Use generic repo.scaffoldBindings to default omitted site GitHub owner/repository/branch inputs from the actual created remote while preserving explicit overrides. Fumadocs 0.4.1 adds optional docs.github-repo, defaulting to project.name for ordinary direct sites; existing toolchain/container pins remain unchanged. On failure preserve generated files and report the target; never claim rollback of registration or a remote repository. Retry direct in-checkout site/registration through fumadocs-site; repeated creation must refuse nonempty directories.

Expand `scripts/test-fumadocs-project.py` to cover the public create workflow with a real Git commit and a GitHub CLI fixture that pushes to disposable local bare repositories. Assert the first pushed commit includes the site, six skills, Mori manifest and Seihou manifest, and that the invocation directory has no site or Git repository. Verify independent project/repo names, exact Mori path, owner context forwarding, visibility, branch and team API arguments, dry-run/no-commands, quoted parent directories, nonempty-target protection and GitHub/scaffold failure. Keep the existing direct-site/registry acceptance under fumadocs-site. Run the existing OpenAPI repository test to guard git-init behavior, update catalogs/READMEs/generated docs and ADR 10, and triage the additional friction. The container wiring and toolchain pins are unchanged, so the earlier native image acceptance remains applicable. Fresh host bootstrap/container checks exercise the optional link override and unchanged default rendering.

## Concrete Steps

Run authoring commands from `/Users/shinzui/Keikaku/bokuno/seihou-modules`. First rediscover dependency sources and check current releases rather than relying on stale corpus data:

```bash
mori registry list
mori registry show shinzui/agent-seihou --full
mori registry docs shinzui/agent-seihou
mori registry show shinzui/mori --full
mori registry docs shinzui/mori
mori registry show shinzui/mori-schema --full
mori registry show shinzui/seihou --full
seihou --version
mori --version
gh api repos/shinzui/seihou/releases/latest --jq .tag_name
gh api repos/shinzui/mori/releases/latest --jq .tag_name
```

Use `seihou new-module docs-mori-bootstrap`, `seihou new-recipe fumadocs-site --module fumadocs --module technical-docs --module docs-mori-bootstrap`, and `seihou new-recipe fumadocs-project --module repo-dir`, then place scaffold directories at the paths above and fill the descriptors. Confirm generator flags with `--help` if the installed release differs. These commands create scaffolds, not finished composition behavior.

After implementation, from this repository run:

```bash
seihou validate-module modules/mori/docs-mori-bootstrap
seihou validate-recipe recipes/fumadocs-project
seihou validate-recipe recipes/fumadocs-site
seihou validate-module modules/git/repo-dir
seihou registry sync-versions
seihou registry validate
python3 scripts/generate-okf-docs.py
python3 scripts/test-fumadocs-project.py
python3 scripts/test-fumadocs-bootstrap.py
python3 scripts/test-fumadocs-container.py --apple-linux
git diff --check
```

When the installed Mori is older than 7.2, build the released executables without replacing the global CLI, then run the fixture with explicit selectors (these are the qualification commands used here):

```bash
nix build github:shinzui/mori/v7.2.0.0#mori --out-link /tmp/seihou-plan14-mori-7.2
nix build github:shinzui/mori/v7.2.0.0#mori-migrations --out-link /tmp/seihou-plan14-mori-migrations-7.2
MORI_BIN=/tmp/seihou-plan14-mori-7.2/bin/mori \
  MORI_MIGRATIONS=/tmp/seihou-plan14-mori-migrations-7.2/bin/mori-migrations \
  python3 scripts/test-fumadocs-project.py
```

Descriptor and catalog commands must succeed, and the fixture script must assert actual source acquisition and actual local registry state. The native container test may need its documented Linux runner configuration; inspect its CLI/environment before execution and record the selected runner. Do not interpret host-only evaluation as native Linux acceptance.

The intended consumer interface, after publication, is the following from a launch directory. It creates ~/Projects/widget-docs and its Git/GitHub repositories. The target `mori://example/widget` must already resolve locally. The fixture test must create a disposable equivalent rather than using a real target or the user's registry.

```bash
seihou install https://github.com/shinzui/seihou-modules.git --module fumadocs-project
seihou run fumadocs-project --var repo.parentDir=~/Projects --var repo.name=widget-docs \
  --var git.githubOwner=example --var project.name=widget-docs \
  --var project.description='Widget documentation' --var docs.site-name='Widget docs' \
  --var docs.github-user=example --var mori.namespace=example \
  --var mori.source-namespace=example --var mori.source-project=widget
cd ~/Projects/widget-docs
git remote -v
mori show --full
mori registry show example/widget-docs --full
mori registry relations --from mori://example/widget-docs --json
mori registry relations --to mori://example/widget --json
```

The result must show the separate documentation identity, the absolute documentation checkout path, the local `site` doc entry and the typed dependency pointing to `mori://example/widget`. Confirm command selectors and relation JSON field names against the running release in the test. After dependencies are installed, from the same consumer:

```bash
bun install
nix run .#bun2nix -- --lock-file bun.lock --output-file bun-deps.nix
git add flake.nix flake.lock nix/ package.json bun.lock bun-deps.nix content/
nix build .#docs-site
```

The create workflow establishes the local Git checkout. Direct-site fixtures initialize their own Git repository before staging. On the native Linux runner, run `nix build .#dockerImage`, export with `nix run .#dockerImage.copyTo -- oci-archive:/absolute/artifacts/docs.tar:docs:latest`, and load/run the image using the existing container harness. No image push is needed.

## Validation and Acceptance

Acceptance requires one installed recipe invocation to apply both registries' artifacts, emit the container-enabled Fumadocs scaffold, preserve all six writing skill sources with correct discovery links, validate a minimal Mori manifest, and register it locally with the requested documented-project association. Use the real released CLIs for the successful path. A captured subprocess argument list or mocked registration cannot prove registration or relation projection.

The disposable target and docs project must be distinct, and the relation must resolve through Mori. Registry readback must contain the consumer's actual root rather than the helper's directory or the registry checkout. Rerunning with unchanged inputs must leave one identity and preserve authored additions. Invalid identity/target data must fail with actionable messages, and a missing target or identity collision must cause no registration. A registration service failure must be visible as failure and recover on retry. Tests must confirm no writes reach shared registries.

The generated site's sandbox build must contain a working `/docs` prerendered page. Native Linux acceptance must produce and inspect an exported image, run it as the documented non-root user, and get HTTP 200 for a docs page on port 8080. Existing Fumadocs font/network limitations remain documented. Check image outputs are absent on macOS while ordinary site outputs evaluate. Catalogs and generated docs must advertise the same initial versions and describe the required identity values and registry prerequisites.

## Idempotence and Recovery

Create a new manifest only when none exists. Preserve an existing manifest byte for byte, validate the requested identity and association, and stop with manual reconciliation guidance if they disagree; do not patch arbitrary Dhall with textual replacement. Registering the same identity/path again is allowed. A pre-existing different path is an error, not permission to move a registry entry. Preserve content and manifests during helper removal.

Generation, registration and dependency acquisition are separate effects. On a failed registration keep the valid generated manifest; after fixing connectivity rerun the recipe/helper and verify readback. Do not remove an unrelated registry entry or claim that Seihou file rollback removes registration. Fixture cleanup removes only fixture identities and disposable databases. On ordinary consumer removal leave registry lifecycle management to explicit Mori commands.

## Interfaces and Dependencies

The public root is `fumadocs-project` 0.2.0, whose member is repo-dir with repo.scaffold=fumadocs-site. It acquires and applies the inner recipe and git-init inside the created child directory. The inner recipe members are `fumadocs`, external `technical-docs`, and local `docs-mori-bootstrap`; their transitives are `nix-bun-flake` and `agent-gitignore`. Preserve source-aware acquisition and saved bindings in Seihou's manifest. All documentation identity fields are declared module inputs, and `mori.source-namespace`/`mori.source-project` always refer to the documented project. `project.name` names the documentation site, never an inferred source project.

Use Seihou 0.15.0.0's released source-aware dependency contract. Qualify Mori 7.2.0.0, the current release discovered during planning, and record the exact tested revision/schema hash during implementation; do not silently fall back to installed 7.1 when behavior differs. Verify authoritative release facts again before introducing bounds or pins. Implementation qualified the released Mori v7.2.0.0 commit `34ce2cfed6e49ccd28136ee0c8af712f94c60e69` through temporary Nix output links; the global CLI remains unchanged (FRIC-13 in `docs/friction-log/`). Its schema is `3522f4a51181d73c9c90fc27a7c0838bd29ae95f` with semantic hash `sha256:dcb19e2312e790bad14e622cc98a1281cd2298c5b564a2f0d0534d3c718d8803`, checked against the published release pin, published schema commit and local `dhall hash`. Keep the existing Fumadocs, nix-bun-flake, Bun and nix2container pins unless a demonstrated integration defect requires a separately explained change.

Every implementation commit uses Conventional Commits and an `ExecPlan:` trailer naming this plan's repository-relative path. No Intention trailer is active. Record the first substantive later edit with `agents/skills/exec-plan/record-provenance.ts` using that agent's verified runtime model. Record and triage implementation friction with the skill's scripts. Never search or traverse `/nix/store` or the filesystem root for dependency sources.

Revision note (2026-11-09): Implementation added explicit typed-manifest evaluation and a deterministic documentation generation adapter after exercising released CLI limitations; reverse association discovery now uses relations instead of dependents. The requested recipe, registration and ownership outcomes are unchanged.

Revision note (2026-11-09, repository creation): The user added directory/Git/GitHub creation after the initial implementation. Milestone 4 reuses and extends repo-dir, preserves git-init as the Git/GitHub owner, and separates public repository creation from direct in-checkout application.
