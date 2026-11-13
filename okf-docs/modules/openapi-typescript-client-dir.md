---
type: SeihouModule
title: openapi-typescript-client-dir
description: Create a new client directory and compose openapi-typescript-client with
  git-init inside it, including GitHub creation under a configurable owner
resource: seihou://seihou-modules/modules/typescript/openapi-typescript-client-dir
tags:
- typescript
- openapi
- client
- git
- github
- bootstrap
status: stable
generated:
  by: seihou-okf-extension/0.16.0.0
version: 0.1.1
---

# openapi-typescript-client-dir

Create a new client directory and compose openapi-typescript-client with git-init inside it, including GitHub creation under a configurable owner

**Version:** 0.1.1

## Declaration metadata

- description: `Create a new client folder and run openapi-typescript-client with git-init inside it, including GitHub creation under a configurable owner.`

## Dependencies

This module has no dependencies.

## Variables

- `repo.postCreateScript` — text, optional. Optional Python script in the invocation directory, run after successful repository creation.
- `repo.parentDir` — text, required, default `.`. Parent directory for the new client folder; a leading ~ is expanded.
- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Client package, folder and GitHub repository name.
- `project.description` — text, required. One-line client description.
- `git.githubOwner` — text, required, matching `[A-Za-z0-9-]+`. GitHub user or organization; may be set with --var or context/global config.
- `git.githubVisibility` — text, required, default `private`, matching `private|public|internal`. GitHub repository visibility.
- `git.defaultBranch` — text, required, default `master`, matching `[A-Za-z0-9._/-]+`. Initial branch name forwarded to git-init.
- `git.githubTeam` — text, optional, matching `[A-Za-z0-9._-]+`. Optional organization team to grant repository access.
- `git.githubTeamPermission` — text, optional, default `push`, matching `pull|triage|push|maintain|admin`. Permission for the optional organization team.
- `nix.bun2nix` — boolean, required, default `false`. Include optional bun2nix helpers.
- `mori.generate` — boolean, optional, default `false`. Seed optional client Mori inventory.
- `mori.namespace` — text, optional, matching `[a-z][a-z0-9-]*`. Client Mori namespace when mori.generate=true.
- `mori.source-namespace` — text, optional, matching `[a-z][a-z0-9-]*`. Mori namespace of the API provider.
- `mori.source-project` — text, optional, matching `[a-z][a-z0-9-]*`. Mori project name of the API provider.

## Exports

No exports declared.

## Prompts

- `repo.parentDir` — `Directory to create the client repo in?`
- `project.name` — `Client project name?`
- `project.description` — `Describe the client in one line:`
- `git.githubOwner` — `GitHub user or organization?`
- `git.githubVisibility` — `GitHub repo visibility?`
- `git.githubTeam` — `Organization team to grant access? (leave empty to skip)`
- `git.githubTeamPermission` — `Team permission?` — when `IsSet git.githubTeam`
- `mori.namespace` — `Mori namespace for this client?` — when `Eq mori.generate true`
- `mori.source-namespace` — `Mori namespace of the OpenAPI provider?` — when `Eq mori.generate true`
- `mori.source-project` — `Mori project name of the OpenAPI provider?` — when `Eq mori.generate true`

## Generation steps

- `Copy` `create-client-repo.py` → `.seihou/openapi-typescript-client-dir/create-client-repo.py` — Managed: owned and reconciled by Seihou updates
- `Template` `repo.postCreateScript.conf.tpl` → `.seihou/openapi-typescript-client-dir/repo.postCreateScript.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `repo.parentDir.conf.tpl` → `.seihou/openapi-typescript-client-dir/repo.parentDir.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `project.name.conf.tpl` → `.seihou/openapi-typescript-client-dir/project.name.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `project.description.conf.tpl` → `.seihou/openapi-typescript-client-dir/project.description.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `git.githubOwner.conf.tpl` → `.seihou/openapi-typescript-client-dir/git.githubOwner.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `git.githubVisibility.conf.tpl` → `.seihou/openapi-typescript-client-dir/git.githubVisibility.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `git.defaultBranch.conf.tpl` → `.seihou/openapi-typescript-client-dir/git.defaultBranch.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `git.githubTeam.conf.tpl` → `.seihou/openapi-typescript-client-dir/git.githubTeam.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `git.githubTeamPermission.conf.tpl` → `.seihou/openapi-typescript-client-dir/git.githubTeamPermission.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `nix.bun2nix.conf.tpl` → `.seihou/openapi-typescript-client-dir/nix.bun2nix.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `mori.generate.conf.tpl` → `.seihou/openapi-typescript-client-dir/mori.generate.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `mori.namespace.conf.tpl` → `.seihou/openapi-typescript-client-dir/mori.namespace.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `mori.source-namespace.conf.tpl` → `.seihou/openapi-typescript-client-dir/mori.source-namespace.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `mori.source-project.conf.tpl` → `.seihou/openapi-typescript-client-dir/mori.source-project.conf` — Managed: owned and reconciled by Seihou updates

## Commands

- `python3 .seihou/openapi-typescript-client-dir/create-client-repo.py` (application command)
