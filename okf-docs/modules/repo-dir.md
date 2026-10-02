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
  by: seihou-okf-extension/0.9.0.0
version: 0.1.0
---

# repo-dir

Create <repo.parentDir>/<repo.name> and bootstrap it by running git-init inside it with a matching GitHub repo; the GitHub user or organization comes from git.githubOwner, so per-context config picks the owner

**Version:** 0.1.0

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

## Exports

No exports declared.

## Prompts

- `repo.parentDir` — Directory to create the repo in?
- `repo.name` — Folder / GitHub repo name?
- `git.githubOwner` — GitHub user or organization? (tip: set per context with `seihou config set git.githubOwner <value> --context <ctx>`)
- `git.githubVisibility` — GitHub repo visibility? (choices: `private`, `public`, `internal`)
- `git.githubTeam` — Organization team to grant access? (slug; tip: set per context with `seihou config set git.githubTeam <slug> --context <ctx>`)
- `git.githubTeamPermission` — Team permission? (choices: `pull`, `triage`, `push`, `maintain`, `admin`) — when `IsSet git.githubTeam`

## Commands

- `set -eu
parent='{{repo.parentDir}}'
name='{{repo.name}}'
owner='{{git.githubOwner}}'
case "$name" in
  ""|.|..|*[!A-Za-z0-9._-]*) echo "repo-dir: invalid repo.name '$name' (use letters, digits, '.', '_', '-')" >&2; exit 1 ;;
esac
case "$owner" in
  ""|*[!A-Za-z0-9-]*) echo "repo-dir: invalid git.githubOwner '$owner'" >&2; exit 1 ;;
esac
case "$parent" in
  "~") parent="$HOME" ;;
  "~/"*) parent="$HOME/${parent#"~/"}" ;;
esac
target="$parent/$name"
if [ -e "$target" ] && [ -n "$(ls -A "$target" 2>/dev/null || echo x)" ]; then
  echo "repo-dir: $target already exists and is not an empty directory" >&2
  exit 1
fi
mkdir -p "$target"
`
- `set -eu
parent='{{repo.parentDir}}'
name='{{repo.name}}'
owner='{{git.githubOwner}}'
case "$name" in
  ""|.|..|*[!A-Za-z0-9._-]*) echo "repo-dir: invalid repo.name '$name' (use letters, digits, '.', '_', '-')" >&2; exit 1 ;;
esac
case "$owner" in
  ""|*[!A-Za-z0-9-]*) echo "repo-dir: invalid git.githubOwner '$owner'" >&2; exit 1 ;;
esac
case "$parent" in
  "~") parent="$HOME" ;;
  "~/"*) parent="$HOME/${parent#"~/"}" ;;
esac
target="$parent/$name"
cd "$target"
seihou run git-init --no-save-prompted \
  --var git.defaultBranch='{{git.defaultBranch}}' \
  --var git.initialCommit=true \
  --var git.createGithub=true \
  --var git.githubOwner="$owner" \
  --var git.repoName="$name" \
  --var git.githubVisibility='{{git.githubVisibility}}'
echo "repo-dir: created $(pwd) -> https://github.com/$owner/$name"
` — when `!IsSet git.githubTeam`
- `set -eu
parent='{{repo.parentDir}}'
name='{{repo.name}}'
owner='{{git.githubOwner}}'
case "$name" in
  ""|.|..|*[!A-Za-z0-9._-]*) echo "repo-dir: invalid repo.name '$name' (use letters, digits, '.', '_', '-')" >&2; exit 1 ;;
esac
case "$owner" in
  ""|*[!A-Za-z0-9-]*) echo "repo-dir: invalid git.githubOwner '$owner'" >&2; exit 1 ;;
esac
case "$parent" in
  "~") parent="$HOME" ;;
  "~/"*) parent="$HOME/${parent#"~/"}" ;;
esac
target="$parent/$name"
cd "$target"
seihou run git-init --no-save-prompted \
  --var git.defaultBranch='{{git.defaultBranch}}' \
  --var git.initialCommit=true \
  --var git.createGithub=true \
  --var git.githubOwner="$owner" \
  --var git.repoName="$name" \
  --var git.githubVisibility='{{git.githubVisibility}}' --var git.githubTeam='{{git.githubTeam}}' --var git.githubTeamPermission='{{git.githubTeamPermission}}'
echo "repo-dir: created $(pwd) -> https://github.com/$owner/$name"
` — when `IsSet git.githubTeam`
