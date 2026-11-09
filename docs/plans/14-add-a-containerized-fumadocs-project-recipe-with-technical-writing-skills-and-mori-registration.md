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
---


# Add a containerized Fumadocs project recipe with technical writing skills and Mori registration

This ExecPlan is a living document. Keep Progress, Surprises & Discoveries, Decision Log, and Outcomes & Retrospective current. Record implementation friction with the exec-plan skill scripts and distill durable decisions into docs/adr/ before completion.

## Purpose / Big Picture

A user will install and run one `fumadocs-project` recipe in a documentation checkout. It will generate the existing Fumadocs site with its nix2container build enabled, acquire and apply `technical-docs` from agent-seihou, create a minimal `mori.dhall`, associate the documentation project with the project it describes, and register the documentation project in the local Mori registry. A user can then find that association through Mori and build the site and Linux container using the existing Fumadocs commands.

This is recipe authoring for future documentation projects. The user requested create mode, so this session creates the plan only. Actual implementation and fixture registration belong to the milestones below. A recipe is a named composition of Seihou modules; a Mori manifest is a typed Dhall file describing a project's identity and discoverable artifacts. nix2container produces an image description with explicit export helpers.

## Progress

- [ ] Milestone 1: Installing the recipe acquires Fumadocs, its Bun base, technical-docs and agent-gitignore from their correct registries; rendering enables all three container settings and installs the writing skills.
- [ ] Milestone 2: Running the recipe creates a valid minimal documentation manifest with the documented-project association and registers it locally; reruns preserve authored manifests and reject conflicting identities.
- [ ] Milestone 3: Isolated end-to-end checks prove acquisition, registration, association, recovery and ownership; the existing site/container checks pass and the recipe is discoverable in both catalogs and generated documentation.

No intention is active; the user selected Skip. Implementation has not started.

## Surprises & Discoveries

(None yet.)

## Decision Log

2026-11-09: Compose the existing `fumadocs` module with explicit container bindings, the external `technical-docs` module, and a small local `docs-mori-bootstrap` helper. This uses released cross-registry dependency acquisition and keeps existing Fumadocs dependency identities unchanged.

2026-11-09: Represent the association in the documentation project's `dependencyRefs` as a typed project-level Mori reference. The inspected schema has no dedicated “documents project” relationship field. This makes the target queryable through the supported dependency relation without modifying another checkout or inventing schema fields. Documentation must label this as the documented-project association. Add a local `DocRef` for the site's `content/docs` tree. Do not use `upstream`, which describes fork/vendor origin.

2026-11-09: Apply the recipe in the user's chosen documentation directory. Directory creation, GitHub repository creation, image publication and deployment are outside this recipe's requested scope. Local registration is a required normal command step, never an opt-in defaulting to false.

## Outcomes & Retrospective

(To be filled during implementation.)

## Context and Orientation

The repository publishes file-generating modules in `modules/`, compositions in `recipes/`, a Seihou acquisition catalog in `seihou-registry.dhall`, and Mori template discovery entries in `mori.dhall`. `README.md` documents authoring and catalog regeneration. `okf-docs/` is generated and must be regenerated rather than edited manually. There is no repository-root flake; generated consumer projects own their flakes.

`modules/typescript/fumadocs/module.dhall` is version 0.4.0. It depends on `nix-bun-flake` and already supports `docs.container=true`, `nix.bun2nix=true` and `nix.package-module=nix/fumadocs-container.nix`. All three values are required together. `modules/typescript/fumadocs/README.md` explains the sandboxed static build, Caddy on port 8080 with user 65532, fonts and generated lock files. `modules/typescript/fumadocs/files/source.config.ts` reads `content/docs`. The module owns its known static-site image; the consumer owns `bun.lock`, `bun-deps.nix`, and `flake.module.nix`. The recipe must leave the ordinary module's defaults unchanged.

`recipes/docs-microapp-labs/recipe.dhall` demonstrates composition. `scripts/test-docs-microapp-labs.py` demonstrates real installation from a disposable Git registry with isolated Seihou cache/configuration; adapt that pattern rather than copying files into the installed module cache as the only acceptance check. `modules/typescript/openapi-typescript-client-dir/module.dhall` demonstrates staging a Python helper and value files to keep values out of shell command text. `scripts/test-fumadocs-bootstrap.py` and `scripts/test-fumadocs-container.py` provide the existing consumer and native image acceptance paths.

The external module is `mori://shinzui/agent-seihou/templates/technical-docs`, currently version 0.1.0. Its owning project is `mori://shinzui/agent-seihou`; artifact-level source URI coverage is pending for project-relative `modules/technical-docs/module.dhall`. It creates `agents/skills/tech-docs/SKILL.md` and five form skills with shared writing rules, with checkout links under `.claude/skills`, `.codex/skills`, and `.agents/skills`. It depends on `agent-gitignore` in the same external registry. The `skill.prefix` default is `tech-docs`. Use `https://github.com/shinzui/agent-seihou.git` as the acquisition source; source URLs in executable descriptors are distinct from durable cross-repository citations.

Mori owns the registry contract: `mori://shinzui/mori`. The schema belongs to `mori://shinzui/mori-schema`; artifact-level source URI coverage is pending for `Project.dhall`, `records/MoriRef.dhall`, `records/DocRef.dhall`, and `types/DocLocation.dhall`. `Project` has `dependencyRefs`, `docs`, and defaults for omitted lists. `MoriRef::{ namespace = ..., name = ... }` points at a project when kind/key are omitted. `DocLocation.LocalDir` identifies the local content tree. The current inspected `PackageType` uses `Other "Documentation"`, not a nonexistent `Documentation` union arm. Canonical project URIs have the form `mori://<namespace>/<name>`.

Research found installed Seihou 0.15.0.0 and Mori 7.1.0.0. GitHub's release endpoints and tags report Seihou v0.15.0.0 and Mori v7.2.0.0 as latest; the Mori working checkout can lag those releases. The released Seihou v0.15.0.0 install closure reads an explicit dependency `source` and locates transitive dependencies in that registry. The local schema's `Dependency` record also exposes `source : Optional Text`. Before selecting an immutable schema import, verify the published schema at the chosen revision and the current Mori release's pinned schema; do not assume this repository's older import is appropriate. No application dependency upgrade is needed for this recipe.

Relevant local ADRs were scanned by filenames/headings and read. [ADR 3](../adr/3-separate-managed-scaffold-nix-wiring-from-user-extensions.md) preserves the managed package-module seam and unmanaged extension file. [ADR 4](../adr/4-preserve-authored-content-during-fumadocs-adoption.md) requires preserving authored content and makes existing-site adoption a distinct workflow. [ADR 6](../adr/6-share-an-opt-in-bun2nix-helper-and-isolate-registry-caches.md) leaves lock generation explicit and consumer owned. [ADR 7](../adr/7-keep-service-images-unmanaged-and-use-nix2container-transports.md) explicitly permits the managed Fumadocs Caddy image, requires explicit transports, and explains why container bindings cannot be imposed on every Fumadocs dependency. The current manifest has no profiled docs/adr bundle; preserve the existing filesystem ADR convention. No existing ADR defines this new documentation-project registration contract.

## Plan of Work

### Milestone 1: Acquire and render the composition

Create `recipes/fumadocs-project/recipe.dhall` and `recipes/fumadocs-project/README.md`. Bind all three container values on its Fumadocs member. Declare `technical-docs` with `source = Some "https://github.com/shinzui/agent-seihou.git"`; keep local members in the declaring registry. Use descriptor records compatible with released Seihou 0.15, including explicit `source = None Text` where required by the selected common record type. Add the helper module described below as the final member. Do not duplicate the external writing skill templates or add shell commands to install and run them outside the dependency graph.

Create `modules/mori/docs-mori-bootstrap/module.dhall` with declared identity inputs, staged value files, a copied Python helper and a fixed command invoking that helper. Verify the actual graph's command order early: Fumadocs generation and skill application must precede final registration. The milestone's integration proof is a real install into an empty consumer using two disposable Git registry snapshots, retaining the external source edge and agent-gitignore's same-registry dependency. Inspect the manifest's source provenance and generated skill links. Rendering with `--no-commands` proves file composition only and must not be reported as registration success.

### Milestone 2: Seed, associate and register the documentation project

Implement `modules/mori/docs-mori-bootstrap/files/bootstrap-docs.py` and its configuration templates. Public helper inputs are required `project.name`, `project.description`, `mori.namespace`, `mori.source-namespace`, and `mori.source-project`. The latter two identify the project being documented independently of the site's name and namespace. Require that target to resolve in the local registry; report a missing target before writing the new manifest or registering anything. Reject self-association and a documentation identity already registered at a different path. Resolve paths without assuming GitHub names match Mori names. Use subprocess argument arrays and safe serialization of strings into Dhall, including quotes, backslashes, Unicode, newlines and interpolation syntax.

A new minimal manifest imports an immutable, integrity-hashed published Mori schema and uses `Schema.Project::{ ... }`. Its identity uses the site's name, namespace and description, `PackageType.Other "Documentation"`, `Language.TypeScript`, and `Lifecycle.Active`. Add exactly one project-level typed `dependencyRefs` entry for the target and a `docs` entry with key `site`, `DocKind.Guide`, `DocAudience.User` and `DocLocation.LocalDir "content/docs"`. Verify those constructor names against the selected published schema before writing the template. Omit fabricated packages, repository URLs, deployment locations and unrelated inventories. Preserve producer-owned manifests as user-owned seeds: on rerun, validate the existing file and verify its identity and required association without overwriting it or deleting extra fields.

Validate the new or existing manifest using released `mori validate`, then invoke `mori register --local --path <absolute-documentation-root>`. Verify success by reading back the registered identity/path and relation. Emit completion only after both registration and readback succeed. A registration failure returns a nonzero result with the failing command and retry guidance while preserving generated files. Do not edit registry storage directly. The `--local` flag is mandatory so shared registry configuration cannot cause a remote write. A later Seihou removal must preserve the authored manifest and content and must not silently deregister the project.

Prove this milestone with real Mori, two identities intentionally named differently, and a disposable local registry. Check the actual commands/configuration for registry isolation in the current Mori source; a temporary HOME alone may not isolate a configured PostgreSQL connection. Use a disposable database via the documented `MORI_PG_CONNECTION_STRING` path when required, and keep production connection settings out of fixture execution. Test an unavailable registry and recovery by rerunning after it becomes available. Registration is a nontransactional external effect: Seihou cannot imply rollback of it.

### Milestone 3: Qualify and publish discovery

Add `scripts/test-fumadocs-project.py` for real acquisition plus render/bootstrap/registry verification. Reuse the existing Fumadocs harness for site and image behavior instead of adding another implementation of the container. Check two consumers with different namespaces and names, the target relation, local content discovery, writing skill sources and links, default container settings, exact registered path, reruns, preserved authored manifest additions, invalid/missing target inputs, self-reference, duplicate identity at another path, escaped input and failing registration. A no-commands render must leave the registry untouched. Verify that an existing plain Fumadocs consumer retains its original dependency identity and update behavior.

Register the recipe and helper in `seihou-registry.dhall` and `mori.dhall`, using version 0.1.0 initially, with correct required variables, tags and dependencies. Document the workflow and prerequisites in the recipe/helper READMEs and root README. Keep the external dependency visibly attributed to agent-seihou. Regenerate `okf-docs/`. Run appropriate descriptor/catalog checks and the focused consumer tests. For Linux container acceptance prefer local Apple `container` tooling; use a matching remote builder only when local containers cannot satisfy the existing harness. Record site build, native image build/export and HTTP startup evidence separately. Finish by recording the durable registration/ownership contract in a local ADR, and triage any implementation friction.

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

Use `seihou new-module docs-mori-bootstrap` and `seihou new-recipe fumadocs-project --module fumadocs --module technical-docs --module docs-mori-bootstrap`, then move generated scaffold directories into the paths above and fill the descriptors. Confirm generator flags with `--help` if the installed release differs. These commands create scaffolds, not finished composition behavior.

After implementation, from this repository run:

```bash
seihou validate-module modules/mori/docs-mori-bootstrap
seihou validate-recipe recipes/fumadocs-project
seihou registry sync-versions
seihou registry validate
seihou extension run okf -- docs --dir . --out okf-docs --force
python3 scripts/test-fumadocs-project.py
python3 scripts/test-fumadocs-bootstrap.py
python3 scripts/test-fumadocs-container.py
git diff --check
```

Descriptor and catalog commands must succeed, and the fixture script must assert actual source acquisition and actual local registry state. The native container test may need its documented Linux runner configuration; inspect its CLI/environment before execution and record the selected runner. Do not interpret host-only evaluation as native Linux acceptance.

The intended consumer interface, after publication, is the following from an existing empty documentation directory. The target `mori://example/widget` must already resolve locally. The fixture test must create a disposable equivalent rather than using a real target or the user's registry.

```bash
seihou install https://github.com/shinzui/seihou-modules.git --module fumadocs-project
seihou run fumadocs-project --var project.name=widget-docs \
  --var project.description='Widget documentation' --var docs.site-name='Widget docs' \
  --var docs.github-user=example --var mori.namespace=example \
  --var mori.source-namespace=example --var mori.source-project=widget
mori show --full
mori registry show example/widget-docs --full
mori registry relations --from mori://example/widget-docs --json
mori registry dependents example/widget
```

The result must show the separate documentation identity, the absolute documentation checkout path, the local `site` doc entry and the typed dependency pointing to `mori://example/widget`. Confirm command selectors and relation JSON field names against the running release in the test. After dependencies are installed, from the same consumer:

```bash
bun install
nix run .#bun2nix -- --lock-file bun.lock --output-file bun-deps.nix
git add flake.nix flake.lock nix/ package.json bun.lock bun-deps.nix content/
nix build .#docs-site
```

These steps require a local Git checkout; initialize a fixture Git repository before staging. On the native Linux runner, run `nix build .#dockerImage`, export with `nix run .#dockerImage.copyTo -- oci-archive:/absolute/artifacts/docs.tar:docs:latest`, and load/run the image using the existing container harness. No image push is needed.

## Validation and Acceptance

Acceptance requires one installed recipe invocation to apply both registries' artifacts, emit the container-enabled Fumadocs scaffold, preserve all six writing skill sources with correct discovery links, validate a minimal Mori manifest, and register it locally with the requested documented-project association. Use the real released CLIs for the successful path. A captured subprocess argument list or mocked registration cannot prove registration or relation projection.

The disposable target and docs project must be distinct, and the relation must resolve through Mori. Registry readback must contain the consumer's actual root rather than the helper's directory or the registry checkout. Rerunning with unchanged inputs must leave one identity and preserve authored additions. Invalid identity/target data must fail with actionable messages, and a missing target or identity collision must cause no registration. A registration service failure must be visible as failure and recover on retry. Tests must confirm no writes reach shared registries.

The generated site's sandbox build must contain a working `/docs` prerendered page. Native Linux acceptance must produce and inspect an exported image, run it as the documented non-root user, and get HTTP 200 for a docs page on port 8080. Existing Fumadocs font/network limitations remain documented. Check image outputs are absent on macOS while ordinary site outputs evaluate. Catalogs and generated docs must advertise the same initial versions and describe the required identity values and registry prerequisites.

## Idempotence and Recovery

Create a new manifest only when none exists. Preserve an existing manifest byte for byte, validate the requested identity and association, and stop with manual reconciliation guidance if they disagree; do not patch arbitrary Dhall with textual replacement. Registering the same identity/path again is allowed. A pre-existing different path is an error, not permission to move a registry entry. Preserve content and manifests during helper removal.

Generation, registration and dependency acquisition are separate effects. On a failed registration keep the valid generated manifest; after fixing connectivity rerun the recipe/helper and verify readback. Do not remove an unrelated registry entry or claim that Seihou file rollback removes registration. Fixture cleanup removes only fixture identities and disposable databases. On ordinary consumer removal leave registry lifecycle management to explicit Mori commands.

## Interfaces and Dependencies

The public root is `fumadocs-project`. Members are `fumadocs`, external `technical-docs`, and local `docs-mori-bootstrap`; their transitives are `nix-bun-flake` and `agent-gitignore`. Preserve source-aware acquisition and saved bindings in Seihou's manifest. All documentation identity fields are declared module inputs, and `mori.source-namespace`/`mori.source-project` always refer to the documented project. `project.name` names the documentation site, never an inferred source project.

Use Seihou 0.15.0.0's released source-aware dependency contract. Qualify Mori 7.2.0.0, the current release discovered during planning, and record the exact tested revision/schema hash during implementation; do not silently fall back to installed 7.1 when behavior differs. Verify authoritative release facts again before introducing bounds or pins. Keep the existing Fumadocs, nix-bun-flake, Bun and nix2container pins unless a demonstrated integration defect requires a separately explained change.

Every implementation commit uses Conventional Commits and an `ExecPlan:` trailer naming this plan's repository-relative path. No Intention trailer is active. Record the first substantive later edit with `agents/skills/exec-plan/record-provenance.ts` using that agent's verified runtime model. Record and triage implementation friction with the skill's scripts. Never search or traverse `/nix/store` or the filesystem root for dependency sources.
