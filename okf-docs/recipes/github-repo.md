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
  by: seihou-okf-extension/0.16.0.0
version: 0.1.0
---

# github-repo

Prompt for a parent directory and folder name, create the folder, and run git-init inside it so it becomes a git repo with a matching GitHub repo under the context's git.githubOwner

**Version:** 0.1.0

## Declaration metadata

- description: ``Create a new, empty project directory and turn it into a git repository with a matching GitHub repo. Prompts for the parent directory and the folder name, creates `<repo.parentDir>/<repo.name>`, and runs `git-init` inside it with `git.createGithub=true` and `git.repoName` bound to the folder name. The GitHub user or organization comes from `git.githubOwner`, so per-context config (`seihou config set git.githubOwner <org-or-user> --context <ctx>`) together with `--context` / `SEIHOU_CONTEXT` / `seihou context default` decides where the repo is created.``

## Composes

- [repo-dir](/modules/repo-dir.md) (declaring registry)
