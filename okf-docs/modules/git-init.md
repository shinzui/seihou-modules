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
version: 0.1.0
---

# git-init

Initialize a local git repo (default branch master), seed .gitignore with .claude/, .agents/, and .seihou/manifest.json.tmp, and optionally create a private GitHub repo via `gh` under a configured org or username

**Version:** 0.1.0

## Dependencies

This module has no dependencies.

## Variables

- `git.defaultBranch` (required)
- `git.initialCommit`
- `git.createGithub`
- `git.githubOwner`
- `git.repoName`
- `git.githubVisibility`


## Exports

No exports declared.
