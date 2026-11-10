# Relaunch this Fumadocs documentation site

This site documents another project, called the documented project below. Bring the site onto the current `fumadocs` module, install the writing skills, register it with Mori, enable the semantic SVG diagram system and the release gates, and then measure its content against the documented project. Recommend whether to restart the content or refresh it, propose a page list and a diagram catalog, and stop for the operator to confirm. Do not write or rewrite pages in this run.

The documented project's Mori URI is "{{docs.source-project}}" and its display name is "{{docs.source-name}}". If the URI is empty, read the first typed `dependencyRefs` entry in the site's `mori.dhall`, which names the documented project as `mori://<namespace>/<name>`. If the display name is empty, use the project's own spelling from its README. Never hard-code a product name into a script; scripts read it from `docs-source.json`. Find the documented project's checkout with `mori path mori://<namespace>/<name> | tail -n 1`.

Rehearsal only: `{{relaunch.rehearsal-only}}`. When it is `true`, run every phase in the scratch clone and leave the real checkout untouched, including its Mori registration.

The blueprint's `files/` directory holds the files you copy into the site. They are listed at the end of this prompt.

## Rules for the whole run

- Do not commit or push unless the operator explicitly authorizes it in this session. Leave unrelated dirty files alone.
- Rehearse every Seihou operation in a scratch clone before running it in the real checkout.
- Record every non-content change in `docs/migration-ledger.md` as you make it, not afterward. Start the file from `files/migration-ledger.md` when it does not exist, and append to it when it does. Number entries in order and fill every field.
- Do not delete, move or edit authored pages under `content/`. Retiring the legacy corpus is the operator's decision after reading the assessment.
- Never write a local absolute path, a personal name or a `mori://` link into a page, a component or anything the site publishes. Cross-repository references in the ledger, plans and commit messages use canonical `mori://` URIs.
- Use `mori` to find dependency sources and documentation before relying on memory. Verify a version against npm and the upstream tags before choosing it.
- Never search `/nix/store` or the filesystem root.
- A gate that cannot fail proves nothing. Show each new gate rejecting a deliberate violation before you rely on it.

## Phase 1: Inventory and backup

Read the project instructions (`CLAUDE.md`, `AGENTS.md`), `git status`, `package.json` and its lock, `justfile`, `flake.nix`, `flake.module.nix`, `.envrc`, `tsconfig.json`, `.oxfmtrc.json`, `.oxlintrc.json`, `linkinator.config.json`, `source.config.ts`, everything under `src/` and `scripts/`, CI configuration, `mori.dhall` and `.seihou/manifest.json`. Run `seihou status` and record the module and recipe versions it reports.

Make a backup directory outside the project and copy into it the manifest, every managed file with local modifications, `package.json`, `justfile`, every file under `scripts/`, and `mori.dhall`.

```bash
BACKUP="$(mktemp -d)"
cp -R .seihou package.json justfile tsconfig.json mori.dhall scripts src "${BACKUP?}/"
find content -type f -print0 | sort -z | xargs -0 shasum -a 256 > "${BACKUP?}/content.sha256"
```

Check the content hashes after every phase. This command prints nothing when the content is unchanged.

```bash
shasum -a 256 -c --quiet "${BACKUP?}/content.sha256"
```

List the site's own gates: every `package.json` script and `justfile` recipe that the module does not generate, such as `lint:docs-nav`, `lint:source-sync`, `lint:static-output`, `check:docs` and a `check-docs` recipe. This is the restore list. Every reapplication of the recipe overwrites managed files, so you will restore these after each one.

Record the site's current Seihou variables from the manifest and the files: `project.name`, `project.description`, `docs.site-name`, `docs.github-user`, `docs.github-repo`, `docs.github-branch`, `docs.font-family`, `docs.font-basename`, `docs.font-package`, `docs.openapi`, `docs.openapi-spec` and `docs.openapi-base-dir`. Keep the complete list in the backup directory and in the ledger. Every later application passes all of them.

## Phase 2: Platform upgrade

Follow the `upgrade-fumadocs` blueprint for preservation and merging. Read its prompt in `mori://shinzui/seihou-modules`, at `blueprints/upgrade-fumadocs/prompt.md` in the checkout that `mori path mori://shinzui/seihou-modules | tail -n 1` prints. Its rules apply here: no automatic base modules, a canonical scaffold generated in isolation, `docs.starter-content=false`, custom work merged back from the backup, and consumer edits to managed files left visible. `baseModules` is empty in this blueprint for the same reason, as `docs/adr/4-preserve-authored-content-during-fumadocs-adoption.md` in `mori://shinzui/seihou-modules` requires.

Adopt the `fumadocs-site` recipe, which composes the `fumadocs` module with the container build, the `technical-docs` writing skills and `docs-mori-bootstrap`. Choose every variable now, including the ones phases 3 and 4 depend on, because each application overwrites managed files:

- `docs.starter-content=false`, always.
- `docs.svg-diagrams=true`.
- `docs.font-flake=` left empty. The font copy step then reads the flake from the `DOCS_FONT_FLAKE` environment variable. Set it locally, for example in the ignored `.envrc.local`, so the repository never carries a local path.
- With an HTTP API: `docs.openapi=true`, `docs.openapi-spec=openapi` and `docs.openapi-base-dir=api`. When `docs.openapi-spec` names a directory, the module renders every `.json`, `.yaml` and `.yml` document in it, in sorted order. Keep snapshots of the documented project's OpenAPI documents in that directory.

Correct `mori.dhall` before the first application, because the recipe's bootstrap registers the site from it (see Phase 3).

`seihou update` refuses `fumadocs-site` applications today, because it cannot reconcile `.seihou/docs-mori-bootstrap/`. Reconfigure by reapplying the recipe with every variable, never only the changed ones.

Rehearse in a scratch clone first.

```bash
SCRATCH="$(mktemp -d)"
git clone "$PWD" "${SCRATCH?}/site"
cd "${SCRATCH?}/site"
seihou run fumadocs-site --force --with-migrations --no-commands --no-save-prompted \
  --var docs.starter-content=false --var docs.svg-diagrams=true --var docs.font-flake= \
  --var project.name=... --var project.description=... --var docs.site-name=... \
  --var docs.github-user=... --var docs.github-repo=... --var docs.github-branch=...
```

Pass the remaining recorded variables the same way. `seihou run` refuses a legacy adoption without `--with-migrations`. Use `--no-commands` in the clone, because the Mori bootstrap rejects an identity that is registered at another path. Run `git diff --stat` and build a merge list: for each changed file, take the module's version, then restore the site's own gates and customizations from the backup. Record the merge list in the ledger's merge list table.

Module 0.6.0 already excludes `agents/` from `tsconfig.json`, makes formatting ignore `docs/plans`, `docs/masterplans` and `docs/friction-log`, crawls real pages from `docs/index.html` in `lint:links`, and highlights code with Pierre Highlights. Check that these hold. Do not add local copies of them.

Install and lock dependencies. A fresh pin can be blocked by a local Bun release-age setting, so allow a one-time override on the command line and never weaken the global setting.

```bash
git add -N <each new file the flake must see>
nix develop --command bun install --minimum-release-age=0
nix run .#bun2nix -- --lock-file bun.lock --output-file bun-deps.nix
```

Prove the upgraded platform on the real, unchanged content before any content work. Platform and content failures must never be mixed.

1. Run the site's complete gate, for example `nix develop --command just check-docs`, or `just check` when it has none, and then each `lint:*` script on its own.
2. Run `nix build .#docs-site`. The Nix build installs with an isolated linker, which can expose a dependency the hoisted local build hides.
3. Build the image from a clean clone, because the flake reads tracked files only. Prefer a local Apple container, for example `ghcr.io/nixos/nix` with the nested sandbox off, and run `nix build .#dockerImage.copyTo` there. Load the image, serve it on port 8080, and request a known page, a raw Markdown route (`/docs/<page>.md`) and the static search index. The site serves its shell with HTTP 200 for unknown paths, so compare against a path that does not exist; a 200 alone proves nothing.
4. Query the exported search index through `fumadocs-core/search/client` and require a known page in the results.
5. Check the content hashes.

When GitHub rate-limits a fixed-output fetch (HTTP 429 on anonymous downloads, common in fresh builders with an empty store), supply the file locally instead of waiting or adding credentials. A fixed-output path depends only on its name and hash. Produce the same content from a clone, for example with `git format-patch -1 <commit>` for a commit patch, and build the same fetcher with the same name, hash and `postFetch` but a `file://` URL. Confirm the hash matches before using it, and record the procedure in the ledger.

When the rehearsal passes and rehearsal only is not `true`, apply the same commands in the real checkout without `--no-commands`, restore the same merge list, and repeat the proofs.

## Phase 3: Writing skills and Mori registration

The recipe installs the `technical-docs` skills from `mori://shinzui/agent-seihou` under `agents/skills/` and links them from `.claude/skills/`. Confirm that `.claude/skills/tech-docs` resolves and that the tutorial, how-to, reference, explanation and walkthrough skills are present. The writing rules are in `agents/skills/tech-docs/WRITING-RULES.md`.

Before the in-place application, correct `mori.dhall` as `docs/adr/10-register-documentation-projects-with-explicit-typed-associations.md` in `mori://shinzui/seihou-modules` requires:

- `language = Schema.Language.TypeScript`.
- A typed `dependencyRefs` entry naming the documented project: `Schema.MoriRef::{ namespace = "<namespace>", name = "<name>" }`.
- A `site` document: `Schema.DocRef::{ key = "site", kind = Schema.DocKind.Guide, audience = Schema.DocAudience.User, location = Schema.DocLocation.LocalDir "content/docs" }`.
- No stale entries for pages or packages that no longer exist.

The recipe's `docs-mori-bootstrap` registers the site during the in-place application. Rerun it after any later `mori.dhall` change with `python3 .seihou/docs-mori-bootstrap/bootstrap-docs.py`. Confirm with `mori registry relations --from mori://<namespace>/<site> --json` that the `depends-on` edge to the documented project is resolved.

## Phase 4: Diagram system and release gates

### Diagrams

With `docs.svg-diagrams=true` the module generates `src/components/diagram.tsx`, `src/lib/diagram-svg.mjs`, `src/styles/diagrams.css`, `scripts/check-doc-diagrams.mjs`, `scripts/render-diagram.mjs` and the authoring contract `content/diagrams/README.md`. It registers `<Diagram>` in `src/components/mdx.tsx`, imports the stylesheet, and adds the `lint:diagrams` and `preview:diagram` scripts. Every diagram is a hand-authored SVG under `content/diagrams/` with no color literals, using only the semantic classes in `diagrams.css`. Mermaid stays available, and legacy pages that use it keep working.

Prove the system in the scratch clone only. Add one small diagram to one page, run `bun run lint:diagrams` and `bun run preview:diagram`, and check the page under `just dev` in a browser in light and dark themes, with Expand working and no horizontal scroll at 375 pixels. Show `lint:diagrams` rejecting a missing alt and a color literal. Then discard the change. Diagrams load in the browser, so they are absent from prerendered HTML.

### Source pin

One pinned revision keeps every page describing one product state, and commit-pinned permalinks keep local paths off the site. Copy `files/scripts/prepare-source-pin.mjs` to `scripts/`, then write the pin.

```bash
bun scripts/prepare-source-pin.mjs --init --name "<display name>" \
  --environment aarch64-darwin
```

It reads the project from `mori.dhall`, the revision from the project's `HEAD`, the version from its latest tag and the GitHub URL from its origin remote. Pass `--revision` with the documented project's latest release when it has one, and `--version` when it has no tag. The result is `docs-source.json`: `project` (the Mori URI), `name`, `github`, the full `revision`, `version` and `environments`. It refuses to replace an existing pin without `--force`. Only a deliberate pin move replaces it, after `bun run report:source-drift -- --to <revision>`. Add `.cache/` to `.gitignore`; `bun scripts/prepare-source-pin.mjs` with no arguments creates a worktree of the pin there.

### Gates and components

Copy these from `files/`, comparing first when the target exists, so a second run never overwrites a site's adjusted copy:

| From `files/`                      | To                                    |
| ---------------------------------- | ------------------------------------- |
| `scripts/doc-pages.mjs`            | `scripts/doc-pages.mjs`               |
| `scripts/check-source-refs.mjs`    | `scripts/check-source-refs.mjs`       |
| `scripts/check-verification.mjs`   | `scripts/check-verification.mjs`      |
| `scripts/check-doc-prose.mjs`      | `scripts/check-doc-prose.mjs`         |
| `scripts/check-static-output.mjs`  | `scripts/check-static-output.mjs`     |
| `scripts/check-doc-links.mjs`      | `scripts/check-doc-links.mjs`         |
| `scripts/report-source-drift.mjs`  | `scripts/report-source-drift.mjs`     |
| `scripts/generate-api-index.mjs`   | `scripts/generate-api-index.mjs`, only with OpenAPI |
| `src/components/source-ref.tsx`    | `src/components/source-ref.tsx`       |
| `verification.schema.json`         | `docs/verification.schema.json`       |
| `docs-gates.json`                  | `docs-gates.json`                     |

Register the components in `src/components/mdx.tsx` with `import { SourceRef, TestedWith } from "@/components/source-ref"` and add both to the returned map. This is a consumer edit to a managed file, so add it to the merge list. Pages cite code as `<SourceRef path="src/server.ts" symbol="startServer" />`, which renders a permalink at the pinned revision, and state their verification with `<TestedWith />`. The component imports named fields of `docs-source.json` only, so the `mori://` URI is never bundled into client JavaScript.

Create `docs/verification.json` as `{ "$schema": "./verification.schema.json" }`. It gets one record per page as each page is written: the form, the one reader, the verified revision, the environments, what was run and what was not checked.

Set `docs-gates.json`: `openapiDir` equal to `docs.openapi-spec`, `apiBaseDir` equal to `docs.openapi-base-dir`, and `generatedPages` listing every generated page, relative to `content/docs`. Keep private words such as local directory names out of the repository: put them in the `DOCS_PRIVATE_TEXT` environment variable, one regular expression per line. The gates already reject `/Users/`, `/home/<name>`, `mori://`, the home directory and this checkout's path.

Add these scripts to `package.json`:

```json
"lint:source-refs": "bun scripts/check-source-refs.mjs",
"lint:verification": "bun scripts/check-verification.mjs",
"lint:prose": "bun scripts/check-doc-prose.mjs",
"lint:doc-links": "bun scripts/check-doc-links.mjs",
"lint:static-output": "bun scripts/check-static-output.mjs",
"report:source-drift": "bun scripts/report-source-drift.mjs",
"gen:api-index": "bun scripts/generate-api-index.mjs",
"check:api-index": "bun scripts/generate-api-index.mjs --check"
```

`lint:doc-links` checks links at the source and accepts `/docs/<apiBaseDir>/<operationId>` for every operation in the OpenAPI documents. The module's `lint:links` crawls the built pages. Keep both. With OpenAPI, add a sync script that copies the documented project's OpenAPI documents at the pin into the `openapi/` directory, with a `--check` mode that fails when a snapshot differs, then run `gen:api-index` and add `api` to `content/docs/meta.json` only if the site's navigation lists sections explicitly. Add the generated index and the snapshot directory to the formatter's ignore patterns.

Wire the gates in two tiers, because legacy pages are expected to fail the content gates. `check:docs` keeps the site's restored gates and adds `lint:diagrams`, `check:api-index` and every new gate that passes on the current content. A `check:release` script runs `check:docs` followed by the gates that do not pass yet, usually `lint:source-refs`, `lint:verification`, `lint:prose` and `lint:static-output`. Record each failing gate's problem count in the assessment as evidence. The operator moves a gate into `check:docs` once the content passes it.

In the scratch clone, show each new gate rejecting a deliberate violation for the right reason, then remove it: a `<SourceRef>` to a missing file and one with a false symbol, a page with no register record, a local path, a `$` prompt in a `bash` fence, a vague heading, a link to a missing page and to an unknown operation, and a private path in a built HTML file.

When the documented project or the site's repository is private, permalinks fail for readers. Add a `skip` for `github\.com/<owner>/<repository>` to `linkinator.config.json`, record it in the merge list, and note that it must be removed when both repositories are public.

Generated reference is optional. A CLI reference generated from the program's `--help` output and a glossary generated from a terminology bundle avoid pages that drift, but each generator depends on the product's parser and terminology, so write one only when the operator wants it. A generated CLI page is stable only per platform when option defaults print the build machine's platform.

## Phase 5: Content assessment

Run the assessment from the site root, with the script read from the blueprint's `files/` directory. Do not copy it into the site.

```bash
node <files>/assess-content.mjs --name "<display name>" \
  --out docs/content-assessment.md --json docs/content-assessment.json
```

It finds the documented project through `docs-source.json` or `mori.dhall`, and measures, each as a number:

1. Commits to the documented project since the content last changed, and since it was first written.
2. Cited source paths that no longer exist at the documented project's current revision, as a share of distinct paths and of citations, and the pages citing at least one.
3. Pages exposing private local paths or `mori://` links.
4. The documented project's capabilities that no page mentions, read from `docs/capabilities/` in the project when present, or else from its README. Pass `--capabilities <file>`, one per line, when neither lists them well.
5. Pages in legacy structure outside Diátaxis, such as a cookbook, an FAQ, templates or demos, and pages with no Diátaxis form.

It recommends restart when most pages cite missing source, most pages expose private paths, or most capabilities are never mentioned, and refresh otherwise. Pass `--since <date or site revision>` when the last content commit was not a real content change, for example a formatting pass.

Then check and complete the report by hand:

- The capability check is a word match. Read the unmentioned capabilities against the pages and correct the list.
- Add the problem counts of the gates in `check:release`.
- Refine the proposed page list with the `tech-docs` skill: group pages by Diátaxis form, give each page one named reader, and drop or merge seeds that do not serve a reader. For a refresh, mark each legacy page keep, revise or retire. For a restart, propose tagging the legacy pages in Git history before removal.
- Refine the proposed diagram catalog: each diagram illustrates a claim on a named page, and shows position, boundaries or sequence that prose cannot.
- List the open decisions: the pin revision, the qualified environments, repository visibility and the link skip, and any generated reference.

Then stop. Present the measures, the recommendation and its reasoning, the page list and the diagram catalog, and wait for the operator to confirm. Do not write pages, remove legacy pages or move the pin in this run.

## After the operator confirms: authoring and qualification

Continue only when the operator confirms the page list and asks you to go on. These are the practices the first relaunch proved.

- Author independent sections in parallel from one pin. Give each authoring agent its own directories and a fragment file for its register records, and let one coordinator merge the fragments into `docs/verification.json`, edit shared files and run the gates centrally.
- Write each page's register record as the page is written. Name what was run, and list what was not checked.
- Build what the pages run at the pin, under `.cache/`. Service-backed guides need a release build of the server, not only the client. Check that scratch servers actually stopped.
- Prove a tutorial by extracting the page's `bash` fences and running them in order under `env -i` with a new `HOME`. A hand-kept copy of the commands drifts from the page.
- Never generate MDX through an unquoted shell heredoc, because backticks in the page execute.
- Generate a configuration reference from the program's own schema output where it has one.
- Plan about 6.5 pixels per character for `small` diagram text, and preview each diagram in both themes.
- After authoring, hold every page to an independent review by reviewers who did not write it. Give each reviewer only its pages and the matching skill, and forbid reading the plans or the register first. Each reviewer verifies at least three claims per page against the pin and previews every diagram in both themes. Review does not replace running: a reviewer who cannot re-run a correction says so in the page's `notChecked`.
- Run the install path and the first tutorial in a clean room on a second platform, for example a fresh `ghcr.io/nixos/nix` Apple container as a non-root user with an empty store and a new `HOME`. Extract the commands from the pages; substitute only a local clone for a private repository URL through `git config url.<local>.insteadOf`. Run the container with an init process, since a PID 1 that does not reap children makes database-backed tools see zombies as alive. Fresh containers are rate limited by GitHub without a token.
- Before release, write a release readiness report: the pin, what was verified on which platform, what was not, and the blockers outside the repository. Move the pin only with `report:source-drift`, reverifying every page it lists.

## Idempotence

A second run must cause no toolchain drift. Reapply the recipe with the same variables and confirm that `flake.lock`, `bun.lock` and `bun-deps.nix` do not change. Append to the ledger instead of restarting it, never replace `docs-source.json` or `docs/verification.json`, and compare each gate with its blueprint copy before replacing it. Back up `.seihou/manifest.json` before every Seihou operation.

## Handoff

Leave `docs/migration-ledger.md`, `docs-source.json`, `docs/verification.json`, `docs/content-assessment.md` and `docs/content-assessment.json`. Report the module and library versions now in use, the merge list, every command's result, the content hash check, the gates in each tier with their counts, the assessment, and anything still blocked. Do not commit or push unless the operator authorizes it.
