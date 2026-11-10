---
type: SeihouModule
title: repo-dir
description: Create <repo.parentDir>/<repo.name> and bootstrap it by running git-init
  inside it with a matching GitHub repo; the GitHub user or organization comes from
  git.githubOwner, so per-context config picks the owner
resource: seihou://seihou-modules/modules/git/repo-dir
tags:
- git
- github
- bootstrap
- context
status: stable
generated:
  by: seihou-okf-extension/0.15.0.0
version: 0.2.0
---

# repo-dir

Create <repo.parentDir>/<repo.name> and bootstrap it by running git-init inside it with a matching GitHub repo; the GitHub user or organization comes from git.githubOwner, so per-context config picks the owner

**Version:** 0.2.0

## Dependencies

This module has no dependencies.

## Variables

- `repo.parentDir` — text, required, default `.`. Directory in which the new repo folder is created. Relative paths resolve against the directory `seihou run` is invoked from; a leading `~` expands to `$HOME`. Created if missing. Can be set per context, e.g. `seihou config set repo.parentDir ~/Work --context work`.
- `repo.name` — text, required, matching `[A-Za-z0-9._-]+`. Name of the new folder, which is also used as the GitHub repo name. Letters, digits, `.`, `_`, and `-` only.
- `git.githubOwner` — text, required, matching `[A-Za-z0-9-]+`. GitHub user or organization that will own the repo. Resolved through the normal config chain, so set it per context (`seihou config set git.githubOwner <value> --context <ctx>`) or globally (`--global`) and select the context with `--context`, `SEIHOU_CONTEXT`, `.seihou/context`, or `seihou context default`.
- `git.githubVisibility` — text, required, default `private`, matching `private|public|internal`. Visibility of the GitHub repo: `private`, `public`, or `internal`. Defaults to `private`.
- `git.defaultBranch` — text, required, default `master`, matching `[A-Za-z0-9._/-]+`. Initial branch name forwarded to git-init. Not prompted; override with `--var` or config.
- `git.githubTeam` — text, optional, matching `[A-Za-z0-9._-]+`. Slug of an organization team to grant access to the new repo (forwarded to git-init). Leave unset to skip. Best set per context: `seihou config set git.githubTeam <slug> --context <ctx>`.
- `git.githubTeamPermission` — text, optional, default `push`, matching `pull|triage|push|maintain|admin`. Permission granted to `git.githubTeam`: `pull`, `triage`, `push`, `maintain`, or `admin`. Defaults to `push`.
- `repo.scaffold` — text, optional, matching `[a-z][a-z0-9-]*`. Optional module or recipe applied inside the new directory before git-init.
- `repo.source` — text, required, default `https://github.com/shinzui/seihou-modules.git`. Registry source used to acquire git-init and the optional child scaffold.
- `repo.scaffoldBindings` — text, required, default `{}`. JSON object mapping omitted child inputs to resolved outer input names.

## Exports

No exports declared.

## Prompts

- `repo.parentDir` — Directory to create the repo in?
- `repo.name` — Folder / GitHub repo name?
- `git.githubOwner` — GitHub user or organization? (tip: set per context with `seihou config set git.githubOwner <value> --context <ctx>`)
- `git.githubVisibility` — GitHub repo visibility? (choices: `private`, `public`, `internal`)
- `git.githubTeam` — Organization team to grant access? (slug; tip: set per context with `seihou config set git.githubTeam <slug> --context <ctx>`)
- `git.githubTeamPermission` — Team permission? (choices: `pull`, `triage`, `push`, `maintain`, `admin`) — when `IsSet git.githubTeam`

## Generation steps

- `Copy` `create-repo.py` → `.seihou/repo-dir/create-repo.py`

## Commands

- `python3 .seihou/repo-dir/create-repo.py`

## Removal

- delete `.seihou/repo-dir/create-repo.py`
