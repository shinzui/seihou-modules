---
id: 13
slug: bootstrap-documentation-microapps-with-tanstack-start-and-nagare-recipes
title: "Bootstrap documentation microapps with TanStack Start and Nagare recipes"
kind: exec-plan
created_at: 2026-11-09T14:21:42Z
provenance:
  created_by:
    model: "gpt-6.1-sol"
    harness: "codex-cli"
    at: 2026-11-09T14:21:42Z
  revisions:
    - model: "gpt-6.1-sol"
      harness: "codex-cli"
      at: 2026-11-09T14:52:29Z
      mode: "implement"
      note: "Implement the documentation reader scaffold, content packaging, and Labs recipe with real consumer verification."
---

# Bootstrap documentation microapps with TanStack Start and Nagare recipes

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.
If durable project context changes, update or create ADRs in docs/adr/ in the same change.
Record friction met while implementing in the friction-log bundle as it occurs (see FRICTION.md).


## Purpose / Big Picture


Add a `docs-microapp` Seihou module, depending on `nix-bun-flake`, that creates a working documentation reader similar to the independent `web/` applications in `mori://tan/tan-product-management` and `mori://tan/tan-platform`. It uses TanStack Start, Bun, Tailwind and shadcn/ui's React Aria component style, with `@pierre/highlights` for fenced code. Use **Geist Serif for text and Paper Mono for code blocks**, following the user's final typography instruction. Both fonts must ship with the application and work without a font CDN.

The generated project can render its starter documentation, read an explicitly selected documentation collection, and build a Linux container with nix2container. Add a `docs-microapp-labs` recipe that composes this module with a small `nagare-docs-config` module to generate `nagare/Config.hs`. The recipe accepts a full domain and a service name independently of the package name. A user can prepare an image publication and Nagare deployment review using those values.

Implementation delivers a reusable scaffold, container proof and deployment instructions; changing the two reference applications or applying a live Labs deployment is separate work. The user skipped intention association.


## Progress


- [x] Milestone 1 (2026-11-09): Real Seihou generation builds and runs the production reader. `python3 scripts/test-docs-microapp.py` passes SSR, CSS/JS/font responses and Chromium font-loading, highlighting, copy and hydration checks.
- [x] Milestone 2 (2026-11-09): Explicit Markdown/bundle selection, scoped identities, anchored/reference links, search, mobile navigation, path boundaries and edited/deleted seed preservation pass the real consumer script. The container script also verifies a nested Git `web/` flake selecting parent-repository content.
- [x] Milestone 3 (2026-11-09): `python3 scripts/test-docs-microapp-container.py --native-linux x86_64-linux` passes all-system evaluation, Darwin sandbox app/snapshot smoke, nested content, cache comparisons, native x86_64 Linux build/export/archive inspection and live container Chromium/HTTP checks. The independent Apple Container archive check also passes locally.
- [x] Milestone 4 (2026-11-09): `python3 scripts/test-docs-microapp-labs.py` passes real isolated recipe installation, two independent emitted Applications, seed preservation and invalid-input/tag checks through released Nagare v0.16.2. Descriptors/catalogs validate and the OKF generator produces the new discovery pages and runbooks.

Completed on 2026-11-09. All four milestones are verified. No image was published and no live Labs context, grant or deployment was changed. The user subsequently directed local Linux work toward Apple Container; its additional archive/runtime/browser check passed in 3.26 seconds for amd64 via Rosetta, and the repeatable `--apple-archive` path is available for fast local iteration.


## Surprises & Discoveries


2026-11-09: Seihou 0.15.0.0 documents binary copy support but compiles copy sources as text; real generation rejects both WOFF2 files. FRIC-12 in `docs/friction-log/` records the observed error. Seed base64 representations with checksums and decode/emit the original WOFF2 bytes in Vite instead. The source module retains the original release assets and licenses; generation and builds require no font network access.

2026-11-09: The released Start API uses `.validator`, and keeping unrelated filesystem exports in the server-function wrapper retains Node imports in the browser bundle. Server handlers now import a separate `reader.server.ts` inside the server-function body. Production HTTP and browser tests pass with filesystem access absent from the client build.

2026-11-09: Font-table inspection confirms Geist Serif Regular is static and Paper Mono's weight axis is 100..800, default 400. CSS declares those actual ranges.

2026-11-09: Full container/browser acceptance exposed two packaging boundaries missed by a health-only probe. Symlinking individual snapshot files outside `/content` correctly trips the reader's root confinement; the image instead links the entire snapshot at `/content`. Tailwind automatic discovery also produced different server/client CSS URLs after client output existed. Explicit `source(none)` and source declarations keep the stylesheet identical; HTTP acceptance now requests every SSR-linked CSS/JS asset before browser checks.


## Decision Log


2026-11-09: Create a separate `docs-microapp` module and a `docs-microapp-labs` recipe. The application module owns a Bun workspace and container wiring; `nagare-docs-config` owns the deployment starter. This gives documentation sites the requested stack without coupling ordinary site generation to a particular deployment domain.

2026-11-09: Application source, manifests, reader configuration, starter content and Nagare configuration are project-owned seeds. A seed is created once and is thereafter preserved, including intentional deletion. Shared Nix wiring remains managed and configurable through an options interface; `flake.module.nix` remains the user's unmanaged extension. This follows local ADR 3 and extends the scaffold-specific image precedent in ADR 7.

2026-11-09: Use an explicit publication manifest and bundle configuration, with all required metadata present in the generated project. Do not transplant the reference applications' project-specific regular-expression parser for `mori.dhall` as a general Dhall parser. A caller lists approved Markdown files and bundle identities in JSON; the same selection drives development reading and packaged content.

2026-11-09: The Labs configuration uses Nagare login protection and port 8080, matching the reference readers. Service name, full hostname and namespace are configurable; the image repository follows `project.name`, so a different service name does not silently select a different image. An immutable release tag is supplied through `DOCS_IMAGE_TAG` for checking and deployment.

2026-11-09: Prefer Apple Container for local Linux iteration and new local build checks whose architecture matches the requirement, following the user's implementation-time direction. Keep the completed native x86_64 acceptance evidence and use the local archive/Rosetta browser path for fast repeat checks.

2026-11-09: The user's final font choice supersedes the earlier Paper Mono-only request: Geist Serif is the text family and Paper Mono is the code family. Vendor released WOFF2 font assets with their licenses and source/checksum metadata, making local and container rendering independent of a private fonts checkout or a live download.


## Outcomes & Retrospective


The reusable scaffold, explicit publication loader, separately cached application/content packages, unprivileged Linux image and protected Nagare recipe are delivered and verified. The full consumer script, native container script and offline Labs script pass. Registry validation reports 13 modules, 5 recipes and 6 blueprints with aligned versions; the generator writes 25 OKF concepts. Source/artifact ownership, content selection and deployment boundaries are distilled into ADR 9 and the scaffold-image extension to ADR 7.

The native fixture demonstrates concrete cache boundaries: content edits preserve the app and registry cache, while application edits preserve the registry cache. The accepted final native run recorded:

```text
app baseline/content edit: skxfv9m2gf9rj3im1d536n2rsdds85kz-docs-app-0.1.0.drv
app source edit: djsdy2wpja3al67nm504d8vcivq9s7mq-docs-app-0.1.0.drv
registry in all three cases: wyfgp4wlqlnjpfprsmbbdizymiz2vg30-bun-cache.drv
content baseline/edit: yiq65140nx7395j53bqfsc41m4v4cnkl-docs-content.drv -> 9ngf13lnhhz440c7p9b42mqimh98wy3a-docs-content.drv
```

FRIC-12 in `docs/friction-log/` is triaged **accepted**: keep checksummed base64 font seeds and local Vite decoding until released Seihou supports binary payloads. Original release bytes/licenses remain in the module and actual decoded fonts are verified in browsers.

Apple Container was already available but was not checked before choosing the configured remote builder for native x86_64 acceptance. The user's correction established Apple as the preferred local Linux environment when architecture permits; a local amd64/Rosetta runtime check passed in 3.26 seconds. Native architecture evidence and fast local iteration are recorded separately. No remaining acceptance is pending; live publication/deployment remains outside this plan.


## Context and Orientation


This repository distributes Seihou modules (Dhall descriptors plus files/templates) and recipes (named compositions of modules). `seihou-registry.dhall` is the install catalog, `mori.dhall` is the separate Mori discovery catalog, and `README.md` describes the public artifacts. `okf-docs/` is generated documentation; regenerate it through Seihou rather than hand-editing it. There is no root `flake.nix`; Nix build commands in this plan run inside generated consumer fixtures.

`modules/typescript/nix-bun-flake/module.dhall` is version 0.6.1. It exports `project.name` and `project.description`, offers `bun.starter-files`, `nix.bun2nix`, `nix.pre-commit` and `nix.package-module`, and owns the common toolchain and canonical `flake.lock`. `modules/typescript/nix-bun-flake/files/flake.nix.tpl` imports the optional managed package module before the unmanaged `flake.module.nix`. Bind `bun.starter-files=false` when the new module supplies its own package and TypeScript starters; duplicate managed and seed ownership is rejected, not resolved by overwrite order. Enable `nix.bun2nix=true` and import `nix/docs-microapp.nix` for production builds. Its shell exposes the generator as `packages.bun2nix`. `bun.lock` and generated `bun-deps.nix` remain consumer-owned.

The base already pins nix2container v1.1.0 at `e503eb81630a0c5d7ec244e08e0733650235d8f1`. The latest upstream release and tag agreed during research. nix2container produces an image description, not a Docker archive. Its `copyTo` helper exports a chosen transport, and `copyToDockerDaemon` loads an image into a daemon. Image outputs must be guarded to Linux; shell and application outputs must still evaluate on macOS. `modules/typescript/fumadocs/files/nix/fumadocs-site.nix`, `modules/typescript/fumadocs/files/nix/container.nix` and `scripts/test-fumadocs-container.py` demonstrate a managed scaffold build, explicit sandboxed Bun installation and native Linux archive verification. The new module packages a running Start server rather than the Fumadocs static-site output.

Read [ADR 3](../adr/3-separate-managed-scaffold-nix-wiring-from-user-extensions.md), [ADR 6](../adr/6-share-an-opt-in-bun2nix-helper-and-isolate-registry-caches.md), and [ADR 7](../adr/7-keep-service-images-unmanaged-and-use-nix2container-transports.md). ADR 3 separates shared managed wiring, composing scaffold seeds and user extensions; Seihou 0.15's typed dependency bindings and ownership receipts are relevant. ADR 6 keeps lock generation explicit and removes workspace-local packages lazily from the registry dependency cache. ADR 7 distinguishes image descriptions from transport archives and allows a scaffold-specific managed image when its behavior is known. The new configurable scaffold image must be recorded as an explicit extension of ADR 7 during implementation. Local ADRs use ordinary Markdown, and `mori show --full` exposes no profiled `docs/adr` bundle.

The two reference readers were located through `mori registry list` and `mori registry show --full`. In `mori://tan/tan-platform` and `mori://tan/tan-product-management`, inspect project-relative `web/package.json`, `web/apps/hub/package.json`, `web/apps/hub/vite.config.ts`, `web/apps/hub/server.ts`, `web/packages/ui/components.json`, `web/packages/ui/src/components/button.tsx`, `web/packages/corpus/src/`, `web/flake.module.nix` and `web/apps/hub/nagare/Config.hs` (source artifact URIs pending). They use a Bun workspace with an app, UI library and corpus reader. Their `aria-nova` shadcn style wraps `react-aria-components` primitives; using the default Radix/Base UI component set would change the requested stack. Start performs server-side rendering, meaning the server returns document HTML before browser JavaScript runs. Their production Vite builds bundle server dependencies and their Bun server serves `dist/client`, a health route and the Start fetch handler.

Relevant upstream decisions, discovered and resolved through Mori, are `mori://tan/tan-platform/docs/adr-0020-publish-a-read-only-engineering-corpus-from-an-independent-web-workspace` and `mori://tan/tan-platform/docs/adr-0022-serve-protected-immutable-engineering-releases-on-labs`. They establish a read-only published snapshot, bundle-scoped document identities, explicit content selection, token-based highlighting and commit-tagged protected hosting. Carry those general principles into this scaffold. Their specific engineering/product views, analytics integration and TAN ownership data stay in their owning applications. The font choice in this plan intentionally follows the user rather than their Geist Sans/Mono styling.

Dependency research must start with Mori. Relevant owners are `mori://TanStack/router`, `mori://adobe/react-spectrum`, `mori://shadcn-ui/ui`, `mori://pierrecomputer/pierre/packages/@pierre/highlights`, `mori://shinzui/seihou`, `mori://shinzui/seihou-schema`, and `mori://shinzui/nagare`. Curated React Aria docs are available with `mori registry docs adobe/react-spectrum`. For Pierre, the corpus source is project-relative `pierre/packages/highlights/` and its rendering guide is `pierre/skills/highlights/references/rendering.md`. It initializes WebAssembly during import, exposes synchronous `codeToTokens`, validates labels through `isSupportedLanguage`, and returns per-token styles plus root styles for multiple themes. Render token contents as React text nodes and map unsupported labels to `plain`. Both production server and browser must successfully initialize the package.

On 2026-11-09 npm reported Start 1.169.5, Router 1.170.46, React Aria Components 1.22.1, React 19.3.1, Vite 8.3.7, shadcn 4.23.0 and Highlights 0.5.0. Upstream tags were verified for Start, Router, React Aria, Vite and Highlights; Highlights 0.5.0 is tag `highlights-v0.5.0`, commit `31ecdba60483fe1377db4a99f56740ece16adc4d`. The local Pierre source still declares 0.3.0 and the reference apps pin 0.2.0, so neither establishes the current package API alone. The released Highlights `package.json` and `lib/index.ts` were also inspected upstream. Treat these as research observations, not permission to copy every reference pin. Qualify one released dependency set against current registry metadata and tags before committing package versions; retain that exact set in test fixtures.

For typography, the user supplied [Vercel's Geist Serif specimen](https://vercel.com/font?type=serif#get). Its text extraction includes older family descriptions, while Vercel's [Serif announcement](https://vercel.com/blog/introducing-geist-serif) and upstream release files explicitly identify the serif family. The intended project identities are `mori://vercel/geist-font` and `mori://paper-design/paper-mono`; neither is registered locally, and font artifact-level URI coverage is pending. The Fontsource package names queried during planning returned npm 404s. Use upstream font artifacts rather than inventing a Fontsource dependency or importing Next.js font helpers into Start. `geist` npm 1.9.2 agrees with [the upstream v1.9.2 release](https://github.com/vercel/geist-font/releases/tag/v1.9.2), tag commit `ef2597cfc42f4797676df105517ccc0a1cfa6569`, which contains project-relative `fonts/GeistSerif/webfonts/GeistSerif-Regular.woff2` and `GeistSerifVF.woff2`. [Paper Mono v1.000](https://github.com/paper-design/paper-mono/releases/tag/v1.000), tag commit `e6eaeceaef02e77e3db997711e07a16378de2bd7`, contains project-relative `fonts/webfonts/PaperMono[wght].woff2`, static weights, `OFL.txt` and `LICENSE.txt`. Both distributions include the SIL Open Font License; preserve their original copyright/license files from each exact release. Verify actual font axes before writing CSS ranges: Geist Serif's shape variation must not be assumed to be a weight axis.

Nagare loads a typed Haskell `Config.hs` and validates its values before deployment. `mori://shinzui/nagare`, project-relative `cli/nagare-dsl/src/Nagare/Dsl/Presets.hs`, `Application.hs`, `Build.hs`, `Types.hs` and `Config.hs` are the relevant sources (source artifact URIs pending). `webService :: Text -> Text -> Either Text Deployment` creates a service on port 8080. Use its smart constructors for service, namespace, domain, tag and health path, wrap the configured service in a validated single-service `Application` with `mkApplication`, and emit it with `emitApplication`. This permits the real offline `nagarectl app check` path; that command is documented for `Application`, not an arbitrary `Deployment` document. The outer application and service must agree on namespace, image, environment and access.

Nagare's latest release observed was v0.16.2, whose annotated tag resolves to commit `7224ff43b320204386c33e5ec1654fcca3ef3d9c`; Seihou was v0.15.0.0. Their GitHub release tags are authoritative distributions here: the queried Hackage package endpoints for `nagarectl` and `seihou` returned 404. `mori://shinzui/nagare`, project-relative `docs/user/deploying-apps.md`, documents offline config checking, archive publication with `app image-plan`, and a separate `app deploy` review using the accepted publication resource ID. Labs is `mori://tan/tan-ng-labs`; its registered Nagare constraint is stale, so check the selected context's actual platform compatibility before any future live operation. Config generation itself needs no cluster context.


## Plan of Work


### Milestone 1 — Generate one working production reader


Create `modules/typescript/docs-microapp/module.dhall` and `modules/typescript/docs-microapp/files/`. Declare `project.name`, `project.description` and `docs.site-name`, and depend on `nix-bun-flake` with static bindings `bun.starter-files=false`, `nix.pre-commit=false`, `nix.bun2nix=true`, and `nix.package-module=nix/docs-microapp.nix`. Require Seihou 0.15.0.0 or newer in the module documentation and test setup. Respect the schema's released constraint vocabulary if expressing minimums in the descriptor; use the installed author's generated schema pin, verified upstream.

Generate a workspace rooted at the current directory, containing `apps/docs/`, `packages/ui/` and `packages/corpus/`. Use private workspace package names derived from `project.name`, with all imports and exports agreeing after substitution. Application and library manifests, TypeScript configuration, Vite configuration, source, task definitions and starter content use `lifecycle = Some "seed"`. Keep `.gitignore` additions managed and additive. Produce `nix/docs-microapp.nix` as the managed package-module entry, initially sufficient to evaluate the development environment. Never generate the user's `flake.module.nix`.

Start with a single Markdown page and the minimal reader shell. Implement `apps/docs/src/router.tsx`, root and document routes, `apps/docs/src/server/content.ts`, `apps/docs/server.ts`, and `apps/docs/vite.config.ts`. Keep filesystem reading in server functions, outside browser bundles. Use the current released Start/Bun entry contract, informed by `mori://TanStack/router`, project-relative `router/examples/react/start-bun/server.ts` and `router/docs/start/framework/react/guide/hosting.md` (artifact URIs pending). The [official hosting guide](https://tanstack.com/start/latest/docs/framework/react/guide/hosting) describes the custom Bun path. Configure the actual production entry filename and server bundling deliberately; verify them by running the built server without the source checkout's installed dependencies.

Place shadcn `aria-nova` configuration and a small usable set of React Aria primitives in `packages/ui/`: button/link, search field and a navigation dialog for small screens. Preserve attribution for copied component source. Build `apps/docs/src/components/code-block.tsx` using Highlights tokens, light/dark themes, exact source copy and a plain-text fallback. Qualify WebAssembly initialization in server rendering and browser hydration immediately, before adding the rest of the reader. The first fixture page includes TypeScript, Haskell, shell and an unknown fenced language, plus literal markup inside code.

Vendor fonts into `modules/typescript/docs-microapp/files/apps/docs/public/fonts/` using stable filenames such as `geist-serif.woff2` and `paper-mono.woff2`, plus separate license files. Record immutable upstream tag/commit, original path and SHA-256 for each in `font-sources.json`. Deliver their base64 representations as seeded application assets so project typography remains editable; Seihou 0.15 cannot copy the binary originals. A seeded Vite plugin verifies checksums and decodes the same WOFF2 bytes for dev and production. Changing a font requires updating its manifest checksum. In `packages/ui/src/styles/globals.css`, define `@font-face` for `Geist Serif` and `Paper Mono`, `font-display: swap`, local `/fonts/` URLs, a serif fallback for text and a monospace fallback for code. Set body/prose/navigation text to Geist Serif; set `pre`, `code` and code-block controls to Paper Mono. Use the regular Geist Serif face or verified variation axes; do not invent bold/italic font files or weight ranges. Keep styles for prose, focus and theme readable at ordinary document sizes.

Add `scripts/test-docs-microapp.py` with temporary project-local copies of modules, following existing test scripts. Its first acceptance path executes the real Seihou resolver, installs one exact dependency set, builds, starts the production server, and requests the page, one static JS asset, `/healthz` and both WOFF2 files. A browser check must prove code hydration and the actual loaded font families. A passing dev server alone does not accept this milestone.

### Milestone 2 — Make the reader reusable and preserve project ownership


Define a seeded `content.config.json` with a versioned JSON shape. It explicitly identifies Markdown paths, asset paths and optional named bundles under one content root. Start with the workspace itself as that root and `content/docs/index.md` as the starter. Keep bundle metadata in this file instead of requiring a particular spelling of `mori.dhall`; a bundle record supplies its name, directory and optional canonical project URI. An OKF bundle is a group of Markdown documents whose frontmatter can identify concepts with a `docId`; ordinary Markdown remains readable without such metadata. A canonical concept identity contains project, bundle and handle so duplicate handles in distinct bundles remain distinct.

Implement the common loader in `packages/corpus/src/`, including typed input validation, Markdown/frontmatter parsing, document summaries, scoped identities and source-relative link resolution. Resolve only explicitly approved files, preserve anchors, return 404 for missing/unpublished documents, and reject absolute paths, traversal, duplicate identities and symlinks escaping the root. Asset serving uses the same publication selection. Keep raw HTML disabled in Markdown and render highlighted source as text. A bundle's `index.md` and `log.md` remain normal documents. If a canonical project URI is absent, keep source-path identities rather than fabricating ownership. The reader must work in a fresh fixture without Mori, OKF, Dhall or Git running in the request path.

Finish a home page, navigable document collection, client search over public summaries, frontmatter details and theme controls. Include a plain document, two small bundles reusing one handle, an internal anchored link, a code sample and a local image in the fixture. This establishes useful documentation behavior without embedding product/engineering-specific models. A seeded manifest can be edited to publish an existing collection; a source-root override through the Nix interface allows a nested `web/` consumer to select parent-repository documentation. Prove that case explicitly in a temporary Git repository, checking how Nix retains a subdirectory flake's parent source; do not assume `self.outPath` is the repository root. The generated README must name the working override and publication-root convention demonstrated by the fixture.

Extend the integration test to edit app source, content config, CSS, a font asset and `nagare/Config.hs` once available; rerun and update through real Seihou state, using an isolated local registry fixture. Prove edited seeds survive, deleted seeds stay deleted, and application removal preserves them. Managed package wiring should update and be removed normally, while the surviving base flake remains evaluable because its optional import is guarded. Reuse the Bun ownership regression pattern instead of text-only descriptor assertions. Add focused reader tests for identity, links and path boundaries, and browser tests for navigation, search, keyboard interaction, theme selection and copying source.

### Milestone 3 — Build and run the released content image


Complete managed `nix/docs-microapp.nix`, and add managed helpers `nix/docs-microapp-app.nix`, `nix/docs-microapp-content.nix` and `nix/docs-microapp-image.nix`. Expose `docsMicroapp` options for content source, content-config path and image-name customization through `flake.module.nix`. Default the image name to `project.name`; keep package attributes stable as `docs-app`, `docs-content` and Linux-only `docs-image`. Expose `checks.docs-smoke` and `flake.lib.docsImageTag`. Consumers supply explicit Bun lock and generated dependency expression before these builds; before those files exist, shell evaluation must remain usable and image/build attempts should explain what to generate.

Use the base's pinned bun2nix generator and hook, frozen installation, explicit lifecycle handling and filtered workspace source. As ADR 6 requires, derive workspace-local package names from their manifests and exclude them lazily before passing registry records to `fetchBunDeps`. The fetched registry cache must not depend on current workspace source or documentation bytes. Use the shared `bunProject` toolchain and `extraDevPackages` for needed build/test tools rather than creating another dev shell. Preserve the base canonical lock and dependency pins unless an observed build failure justifies a separately recorded change.

Build app code and the selected content snapshot separately. The application package contains `server.ts`, built client/server outputs and both fonts; the content package contains exactly the configured documents/assets and a content inventory with checksums. Keep app source selection limited to application, UI and reader code, manifests, locks and fonts. Supply release commit/date from the snapshot inventory or runtime image environment, so a documentation-only commit does not invalidate the app through an embedded revision, version field or full-repository source. Do not copy the whole repository or depend on an absolute developer path. Start the installed app against that snapshot for `checks.docs-smoke`; run away from the checkout with no `node_modules` and with the source content unavailable. `/healthz` returns status and the exact release commit; UI release metadata agrees. If the proven released build needs a runtime sidecar, package it explicitly and adjust the smoke check; a claim that `ssr.noExternal` made the app self-contained must be demonstrated.

Use nix2container for a Linux image with separate runtime, app/font and content layers. Configure Bun, CA roots, an unprivileged numeric user, working directory, `PORT=8080`, `NODE_ENV=production` and an explicit snapshot root. Listen on `0.0.0.0` and honor the runtime `PORT`. Use a clean committed source and `git-<12-character-revision>` image tags; refuse publication-image builds without a real clean revision. If a packaging suffix is supported, expose it explicitly through the options interface and use it consistently in `docsImageTag`. Ordinary development/app builds may run on dirty source.

Add `scripts/test-docs-microapp-container.py` following `scripts/test-fumadocs-container.py`'s real rendering and transport pattern. Evaluate normal outputs on all three base systems, build app/snapshot smoke on an available native host, and build/export/run the image on `x86_64-linux` with a matching builder and Linux container daemon. Inspect the archive configuration and selected files through archive APIs, without traversing `/nix/store`. Export through `copyTo` with an explicit transport, repository/tag and temporary directory; do not mistake the image derivation for a tarball. Verify image startup, deep routes, assets, fonts, source copy and health. Changing documentation should change the snapshot/image while leaving the app and registry dependency derivations unchanged; changing app source should preserve the registry cache. Record concrete derivation comparisons rather than promising general build-speed guarantees.

### Milestone 4 — Compose the Nagare recipe and publish the workflow


Create `modules/cloud/nagare-docs-config/module.dhall`, its `files/nagare/Config.hs.tpl`, and a seeded `files/nagare/README.md.tpl`. Create `recipes/docs-microapp-labs/recipe.dhall` composing `docs-microapp` and `nagare-docs-config` in one resolution pass. The helper consumes `project.name`, required `nagare.service-name`, required `nagare.domain`, and `nagare.namespace` defaulting to `personal`. Define the domain as a full DNS hostname, such as `handbook.labs.topagentnetwork.net`; never append the service name automatically. Validate service and namespace as DNS labels and domain as hostname labels with length rules; reject schemes, ports, paths, trailing command syntax and empty labels. Generated Haskell text must be escaped correctly, with runtime smart constructors as a second validation layer.

The generated `Config.hs` constructs a single-service `Application`, with name equal to the chosen service name, image repository equal to `project.name`, `PrebuiltImage` from required `DOCS_IMAGE_TAG`, port 8080, a `/healthz` check, small stateless resources, scale-to-zero and `requireLogin`. Use `mkApplication` to enforce outer/service agreement and `emitApplication` to serialize it. Fail clearly when the environment tag is missing or invalid; do not seed a mutable `latest` or dummy release tag. Keep every field consistent with the exact released Nagare DSL tested in the fixture. Use qualified record imports or the released lens pattern to avoid ambiguous Haskell field labels.

Add `scripts/test-docs-microapp-labs.py`. Generate two real recipe consumers with different project, service and domain values; one must use a service name different from `project.name`. Compile/load their config through the released packaged Nagare runtime in an empty context/config environment. `app check` must report one service and zero workers/databases/brokers. Inspect the emitted application using the released runtime/loader in a fixture to assert the full hostname, image, port, health, access policy and immutable tag; summary output alone cannot prove those values. Missing/invalid tags and invalid service/domain inputs must fail before any provider access. A plain `docs-microapp` run must not generate Nagare configuration. Test real recipe installation acquiring its declared module dependency closure, without changing the personal module cache.

Register both modules and the recipe in `seihou-registry.dhall` and `mori.dhall`; keep descriptor/catalog versions aligned. Add `modules/typescript/docs-microapp/README.md`, `modules/cloud/nagare-docs-config/README.md`, `recipes/docs-microapp-labs/README.md`, and update `README.md`. Include the supported Seihou/Nagare releases, seed ownership, nested-workspace content example, font provenance, explicit lock generation, Linux builder requirement, exact export workflow and rollback using an existing publication. Regenerate `okf-docs/` through its generator. Extend ADR 7 for this parameterized managed scaffold image and record durable publication/config boundaries in an appropriate local ADR following the repository's convention.

The runbook walks from a committed source to an exported archive, a saved Nagare image publication review, and a separate application deployment review. Config creation and local verification must never publish, deploy, create grants or change a Labs context. Login protection must be documented together with the need for an existing authorized hostname grant at the chosen Labs context; generating `requireLogin` does not itself create that grant. Record the real checks, triage implementation friction and distill durable decisions before closing the plan.


## Concrete Steps


Run repository discovery and descriptor validation from the repository root. Dependency paths come from Mori; never search `/` or `/nix/store`.

```bash
cd /Users/shinzui/Keikaku/bokuno/seihou-modules
mori registry list
mori registry search highlights
mori registry show pierrecomputer/pierre --full
mori registry docs pierrecomputer/pierre
mori registry docs adobe/react-spectrum
mori registry show shinzui/seihou --full
mori registry show shinzui/seihou-schema --full
mori registry show shinzui/nagare --full
mori registry docs shinzui/nagare
seihou --version
```

Recheck release tags and npm versions as described above before fixing the implementation's exact dependency set. For unregistered dependencies such as the font distributions and nix2container, record the failed Mori discovery and inspect authoritative upstream source at the selected release. Do not refresh other local corpus checkouts merely to write the scaffold.

Once the new descriptors and scripts exist, run:

```bash
cd /Users/shinzui/Keikaku/bokuno/seihou-modules
seihou validate-module modules/typescript/docs-microapp
seihou validate-module modules/cloud/nagare-docs-config
seihou validate-recipe recipes/docs-microapp-labs </dev/null
python3 scripts/test-docs-microapp.py
python3 scripts/test-docs-microapp-container.py --native-linux x86_64-linux
python3 scripts/test-docs-microapp-labs.py
seihou registry sync-versions
seihou registry validate
seihou extension run okf -- docs --dir . --out okf-docs --force
git diff --check
```

All commands must exit zero. The new scripts must be implemented with those entry points and print concise successful scenario descriptions; native image acceptance must not silently skip when a Linux builder or daemon is absent. Keep such acceptance pending until it actually runs. Re-run `scripts/test-nix-bun-flake.py` if the base or its ownership bindings change, and the existing Fumadocs checks if shared build/transport helpers change; ordinary additive module work need not rebuild unrelated scaffolds.

The following is the proposed public consumer workflow after publication. It runs inside a new documentation project (or the chosen independent `web/` directory); `seihou install` selects the recipe and acquires its dependency closure. During development the automated fixture uses project-local module copies instead of the published registry.

```bash
mkdir handbook-web
cd handbook-web
seihou install https://github.com/shinzui/seihou-modules.git --module docs-microapp-labs
seihou run docs-microapp-labs --no-save-prompted --no-commands \
  --var project.name=handbook-web \
  --var project.description='Team documentation' \
  --var docs.site-name='Team Handbook' \
  --var nagare.service-name=handbook \
  --var nagare.domain=handbook.labs.topagentnetwork.net \
  --var nagare.namespace=personal
nix develop -c bun install
nix develop -c bun2nix -o bun-deps.nix
nix develop -c bun run check
nix develop -c bun run build
nix develop -c bun run start
```

The generated root package must provide `check`, `build`, `start`, `dev`, `test` and `test:e2e` scripts that route to the workspace packages. `check` includes types, lint, format checking and content validation. `start` runs the built Bun server; another terminal can verify:

```bash
curl --fail http://127.0.0.1:8080/healthz
curl --fail http://127.0.0.1:8080/docs/content/docs/index
curl --fail --output /dev/null http://127.0.0.1:8080/fonts/geist-serif.woff2
curl --fail --output /dev/null http://127.0.0.1:8080/fonts/paper-mono.woff2
```

Expect JSON status `ok` and HTTP 200 for the document and font files. The browser at `/` must navigate to the document, load Geist Serif for prose and Paper Mono for code, highlight supported languages and preserve unknown-language text. Stop the server after checking. Commit the generated sources, fonts, configuration, `bun.lock` and `bun-deps.nix` in the consumer before the publication-image commands. In this repository, implementation commits use Conventional Commits and an `ExecPlan:` trailer pointing to this plan; stay on the current branch unless asked otherwise.

In a clean committed consumer, the proposed image and offline configuration commands are:

```bash
nix build .#docs-app .#docs-content
nix build .#checks.aarch64-darwin.docs-smoke
nix build .#packages.x86_64-linux.docs-image --out-link result-docs-image
export DOCS_IMAGE_TAG="$(nix eval --raw .#lib.docsImageTag)"
nix run github:shinzui/nagare/v0.16.2#nagarectl -- \
  app check --file nagare/Config.hs
```

Use the native system's smoke-check attribute on Linux. The `x86_64-linux` image build requires a Linux host or configured builder. The exact tagged Nagare release is the planning baseline; qualify and record any update before changing the runbook. The offline check should print a one-line application summary naming `handbook` in `personal` with a single service. It must work without a Labs context.

For archive export, set the registry prefix to the already selected target context's actual registry; no registry value belongs in the generic template. Export from the same committed revision, using an absolute archive path:

```bash
export REGISTRY='registry.example/namespace'
export IMAGE_REF="$REGISTRY/handbook-web:$DOCS_IMAGE_TAG"
export DOCS_IMAGE_ARCHIVE="$PWD/handbook-web-$DOCS_IMAGE_TAG.tar"
nix run .#packages.x86_64-linux.docs-image.copyTo -- \
  "docker-archive:$DOCS_IMAGE_ARCHIVE:$IMAGE_REF" --tmpdir "${TMPDIR:-/tmp}"
```

The exporter must execute on Linux. When using a remote Nix builder from macOS, run export through the Linux test/build runner and copy its archive back; `nix run` on macOS does not execute a Linux binary just because a remote builder produced it. The generated README must include the exact tested runner/export command for that path. Run the native container smoke through the test script, loading the exported archive into the selected Linux daemon and probing it on an isolated port.

The runbook then shows these review-preparation commands using a configured, compatible Labs context and the released `nagarectl` executable. They are examples for an authorized operator; planning and automated tests do not execute live publication or deployment:

```bash
nagarectl app image-plan --archive "$DOCS_IMAGE_ARCHIVE" \
  --destination "$IMAGE_REF" --key "handbook-web-$DOCS_IMAGE_TAG" \
  --save-plan image-review
```

After the operator reviews and applies that publication through Nagare's inventory workflow, use its returned accepted resource ID as `IMAGE_RESOURCE_ID`:

```bash
nagarectl app deploy --file nagare/Config.hs --tag "$DOCS_IMAGE_TAG" \
  --image-resource "$IMAGE_RESOURCE_ID" --save-plan app-review
```

Review generation must use an image destination matching the config's image repository and tag. Publication acceptance precedes deployment review; do not invent a resource ID. Keep reviews and archive at stable paths until their inventory transaction completes. A later live acceptance, when requested, checks anonymous protection and an authorized page read at `https://handbook.labs.topagentnetwork.net/`.


## Validation and Acceptance


Accept Milestone 1 only when real Seihou generation produces a production server that renders document HTML, hydrates without errors and loads its own fonts. Browser verification must use `document.fonts.load`/`document.fonts.check` plus response and computed-style assertions to prove the selected font faces actually loaded, not merely that a CSS fallback family was listed. Assert Geist Serif on prose and Paper Mono on code. Font network requests must be same-origin. Supported fenced code has themed tokens in both modes, an unsupported label remains legible and copy yields the original source. Literal markup in source must remain text.

Accept Milestone 2 when an explicitly selected collection works without runtime repository tools, two identical handles in different bundles resolve separately, internal links retain anchors, search navigates to documents, missing routes return 404, and unapproved/escaping paths cannot be read. Exercise keyboard search, the small-screen menu and code copy in a real browser against the production build. Prove a root consumer and a nested `web/` consumer can package their documented content roots. Real rerun/update/removal must preserve user edits and intentional deletions while cleaning managed wiring. The generated tree must contain neither TAN project-specific names/data nor absolute paths from this workstation.

Accept Milestone 3 when sandbox app/content builds pass, the installed server works away from the checkout, and a native Linux image serves health, a deep document, bundled assets and both fonts as the configured non-root user. Inspect the exported archive's command, user, port, fonts and snapshot, and compare its inventory to the configured publication set. Confirm macOS does not expose an unusable image package. Show the expected cache boundaries with an app-only edit and a content-only edit. Evaluation or archive inspection alone does not prove native startup.

Accept Milestone 4 when a public recipe install acquires the expected closure, two distinct configurations load under the released Nagare executable without context/provider access, and emitted application values match both independent service/domain choices. Changing only `nagare.service-name` must not change `project.name` or the selected image repository. A bare app module must produce no Nagare config. Missing tags and invalid inputs must fail clearly. All descriptor/catalog checks pass and generated documentation explains the exact tested export and two-review deployment sequence. No successful live Labs operation is required to declare this scaffold plan complete.


## Idempotence and Recovery


Scaffold test projects and their module registries are disposable and isolated. Rerunning Seihou preserves seeds and authored content; it must not run an install or compiler command that rewrites those files. Lock generation is an explicit user action after initial dependency installation or deliberate version changes. Commit locks and generated dependency expressions together, and rerun the frozen Nix build after changing either. Rebuild against recorded pins when a release/API check fails rather than silently bypassing frozen installation or substituting fake hashes.

For fonts, retain vendored bytes, original licenses and their recorded checksums. A font refresh is an explicit asset/source-metadata update; no first-start download or private-path fallback should conceal a missing asset. A Nix or image failure leaves source/content untouched and can be retried after fixing the build inputs. Clean only the known temporary fixture directories and stop test servers/containers with cleanup handlers.

Recipe reruns do not reconfigure a deployed service: `nagare/Config.hs` is a seed. After creation, edit it directly to change domain/service settings and prepare a new reviewed deployment. Document that rerunning with different values preserves existing seed content, so a user must not mistake the new CLI values for an applied rename. Live changes can alter service identity and hostname grants; their review belongs to the operator workflow. Rollback selects an existing accepted image publication and its original config/source revision; it does not overwrite an immutable tag.


## Interfaces and Dependencies


`docs-microapp` consumes `project.name`, `project.description` and `docs.site-name`. Its configured `nix-bun-flake` dependency is the sole owner of `flake.nix`, the base Nix modules and canonical `flake.lock`. It contributes scaffold-specific managed Nix files through `nix.package-module`, project-owned application seeds through lifecycle declarations, and additive ignore rules. `nagare-docs-config` consumes `project.name`, `nagare.service-name`, `nagare.domain` and `nagare.namespace`. `docs-microapp-labs` composes both without shelling out to a second Seihou invocation or creating a GitHub repository.

The intended content interface begins as follows; specify and validate the exact bundle and asset records in `packages/corpus/src/types.ts` during implementation. Paths are relative to the selected content root, with explicit additions required before files are published.

```json
{
  "schemaVersion": 1,
  "projectUri": null,
  "documents": ["content/docs/index.md"],
  "bundles": [],
  "assets": []
}
```

`docsMicroapp.contentSource` is a Nix path, `docsMicroapp.contentConfig` selects that source's manifest path, and `docsMicroapp.imageName` defaults to `project.name`. Keep `packages.docs-app`, `packages.docs-content`, Linux `packages.docs-image`, `checks.docs-smoke` and `lib.docsImageTag` stable. The server accepts `PORT` and `DOCS_CONTENT_ROOT`; the image explicitly sets the content root to `/content`. Local `dev` and `start` scripts select the workspace root so the documented commands work before any content installation. `/healthz` and font paths work independently of a documentation route. If a user overrides `docsMicroapp.imageName`, the seeded Nagare config and archive destination must be updated to that same repository name; no rerun silently rewrites an existing config.

The text stack is Geist Serif from intended project `mori://vercel/geist-font` (upstream `https://github.com/vercel/geist-font`) and Paper Mono from intended project `mori://paper-design/paper-mono` (upstream `https://github.com/paper-design/paper-mono`); these are not locally registered and artifact-level URI coverage is pending. Record those project identities, exact released commits, project-relative asset paths, checksums and licenses in the vendored source manifest. Use local CSS font faces; a dependency on Next.js is unnecessary. The UI stack is React, TanStack Start/Router, Vite, Tailwind, seeded shadcn `aria-nova` components, React Aria Components and Highlights. Read dependencies through Mori and verify released registry/tag state before any bound, pin or workaround changes.

Nagare's public boundary is validated Haskell `Application`/`Deployment`, `BuildSpec.PrebuiltImage`, smart constructors, `requireLogin`, `mkApplication` and `emitApplication`. The release test must exercise those APIs rather than compiling against uncommitted local source. The image name used in `Config.hs`, the archive destination and the accepted publication must identify the same repository/tag after the target context resolves registry prefixes. `DOCS_IMAGE_TAG` is a required runtime input to config evaluation and must equal `lib.docsImageTag` for the exported image. No cluster credentials, user identity values or hostname grants are embedded in generated files.
