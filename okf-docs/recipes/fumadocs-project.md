---
type: SeihouRecipe
title: fumadocs-project
description: Create a directory and Git/GitHub repository with container-enabled Fumadocs,
  writing skills and local Mori registration
resource: seihou://seihou-modules/recipes/fumadocs-project
tags:
- docs
- fumadocs
- container
- mori
- recipe
status: stable
generated:
  by: seihou-okf-extension/0.16.0.0
version: 0.2.0
---

# fumadocs-project

Create a directory and Git/GitHub repository with container-enabled Fumadocs, writing skills and local Mori registration

**Version:** 0.2.0

## Declaration metadata

- description: `Create a documentation directory and Git/GitHub repository with container-enabled Fumadocs, technical writing skills and local Mori registration`

## Composes

- [repo-dir](/modules/repo-dir.md) (declaring registry) (with `repo.scaffold` = `fumadocs-site`, `repo.scaffoldBindings` = `{"docs.github-user":"git.githubOwner","docs.github-branch":"git.defaultBranch","docs.github-repo":"repo.name"}`)

## Variables

- `docs.starter-content` — boolean, required, default `true`. Generate starter content for a new site; set false when adopting an existing documentation tree
- `docs.openapi` — boolean, required, default `false`. Generate API reference pages from an OpenAPI document with fumadocs-openapi
- `docs.openapi-spec` — text, required, default `openapi.yaml`. OpenAPI document rendered when docs.openapi is true: a project-relative path or a URL. New sites with starter content get an example at openapi.yaml.
- `docs.openapi-base-dir` — text, required, default `api`, matching `[a-z][a-z0-9-]*`. Docs folder holding the generated OpenAPI pages (served under /docs/<dir>/). Pick one no authored content uses.
- `docs.container` — boolean, required, default `true`. Generate a Nix build of the static site and a non-root Caddy image built with nix2container; also requires nix.bun2nix=true and nix.package-module=nix/fumadocs-container.nix
- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Project name (package.json name). Re-declared so step `dest` paths and templates validate; the value is shared with `nix-bun-flake` via the dependency graph (it exports `project.name`).
- `project.description` — text, required. One-line project description (package.json description, home page intro). Inherited from `nix-bun-flake`, which exports `project.description`.
- `docs.site-name` — text, required. Human-readable site/nav title shown in the navbar and browser tab (e.g. "keiro runtime docs").
- `docs.github-user` — text, optional. Optional site GitHub link override; defaults to the created repository owner/branch.
- `docs.github-branch` — text, optional. Optional site GitHub link override; defaults to the created repository owner/branch.
- `docs.github-repo` — text, optional, matching `[A-Za-z0-9._-]+`. Optional site GitHub repository override; defaults to repo.name.
- `docs.font-family` — text, required, default `PragmataPro Mono`. CSS font-family name for the self-hosted monospace/code font (routed at --fd-font-mono and every code surface).
- `docs.font-basename` — text, required, default `PragmataProMono`. Stable file-name prefix the font copy step writes into public/fonts/ (e.g. <basename>-Regular.otf), referenced by @font-face in app.css. Version-independent so the CSS URLs never change.
- `docs.font-flake` — text, required, default `/Users/shinzui/Keikaku/bokuno/fonts`. Local Nix flake path the font copy step builds to source the licensed OTFs. Tolerant: if unavailable, the build still proceeds and code falls back to system monospace.
- `docs.font-package` — text, required, default `pragmataPro`. Package attribute built from docs.font-flake (path:<flake>#<package>).
- `mori.namespace` — text, required, matching `[a-z][a-z0-9-]*`. Namespace of this documentation project.
- `mori.source-namespace` — text, required, matching `[a-z][a-z0-9-]*`. Namespace of the already registered project being documented.
- `mori.source-project` — text, required, matching `[a-z][a-z0-9-]*`. Name of the already registered project being documented.
- `skill.prefix` — text, optional, default `tech-docs`, matching `[a-z][a-z0-9-]*`. Prefix of the six technical writing skills.
