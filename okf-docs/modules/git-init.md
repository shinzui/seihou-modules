---
type: SeihouModule
title: git-init
description: Initialize a local git repo (default branch master), seed .gitignore
  with .claude/, .agents/, and .seihou/manifest.json.tmp, and optionally create a
  private GitHub repo via `gh` under a configured org or username
resource: seihou://seihou-modules/modules/git/git-init
tags:
- git
- github
- bootstrap
- gitignore
status: stable
generated:
  by: seihou-okf-extension/0.8.0.0
version: 0.1.0
---

# git-init

Initialize a local git repo (default branch master), seed .gitignore with .claude/, .agents/, and .seihou/manifest.json.tmp, and optionally create a private GitHub repo via `gh` under a configured org or username

**Version:** 0.1.0

## Dependencies

This module has no dependencies.

## Variables

- `git.defaultBranch` — text, required, default `master`, matching `[A-Za-z0-9._/-]+`. Initial branch name passed to `git init -b`. Defaults to master.
- `git.initialCommit` — boolean, optional, default `true`. If true, stage everything currently in the project and create an `Initial commit` after `git init`.
- `git.createGithub` — boolean, optional, default `false`. If true, create a remote GitHub repository via `gh repo create` and push the initial commit. Requires the GitHub CLI (`gh`) to be installed and authenticated.
- `git.githubOwner` — text, optional. GitHub org or username under which the repo should be created. Required when `git.createGithub` is true. Recommended to set via `seihou config set git.githubOwner <value> --global` so it is reused across projects.
- `git.repoName` — text, optional, matching `[A-Za-z0-9._-]+`. Name of the GitHub repo to create. Required when `git.createGithub` is true. Typically the same as the project name / current directory name.
- `git.githubVisibility` — text, optional, default `private`, matching `private|public|internal`. Visibility of the GitHub repo: `private`, `public`, or `internal`. Defaults to `private`. Only used when `git.createGithub` is true.

## Exports

No exports declared.

## Prompts

- `git.defaultBranch` — Initial git branch name?
- `git.initialCommit` — Create an initial commit after `git init`?
- `git.createGithub` — Create a GitHub repo with `gh repo create`?
- `git.githubOwner` — GitHub org or username? (tip: set globally with `seihou config set git.githubOwner <value> --global`) — when `Eq git.createGithub true`
- `git.repoName` — GitHub repo name? — when `Eq git.createGithub true`
- `git.githubVisibility` — GitHub repo visibility? (choices: `private`, `public`, `internal`) — when `Eq git.createGithub true`

## Generation steps

- `Template` `gitignore.tpl` → `.gitignore` (appends one line to a file another module owns, if absent)

## Commands

- `git init -b {{git.defaultBranch}}`
- `git add -A && (git diff --cached --quiet || git -c commit.gpgsign=false commit -m 'Initial commit')` — when `Eq git.initialCommit true`
- `gh repo create {{git.githubOwner}}/{{git.repoName}} --private --source=. --remote=origin --push` — when `Eq git.createGithub true && Eq git.githubVisibility "private"`
- `gh repo create {{git.githubOwner}}/{{git.repoName}} --public --source=. --remote=origin --push` — when `Eq git.createGithub true && Eq git.githubVisibility "public"`
- `gh repo create {{git.githubOwner}}/{{git.repoName}} --internal --source=. --remote=origin --push` — when `Eq git.createGithub true && Eq git.githubVisibility "internal"`
