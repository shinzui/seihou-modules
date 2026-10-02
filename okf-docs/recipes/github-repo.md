---
type: SeihouRecipe
title: github-repo
description: Prompt for a parent directory and folder name, create the folder, and
  run git-init inside it so it becomes a git repo with a matching GitHub repo under
  the context's git.githubOwner
resource: seihou://seihou-modules/recipes/github-repo
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

# github-repo

Prompt for a parent directory and folder name, create the folder, and run git-init inside it so it becomes a git repo with a matching GitHub repo under the context's git.githubOwner

**Version:** 0.1.0

## Composes

- [repo-dir](/modules/repo-dir.md)
