# repo-dir

> Create a new directory `<repo.parentDir>/<repo.name>` and bootstrap it as a git repository with a matching GitHub repo by running `git-init` inside it.

**Version:** `0.1.0`

## Overview

Seihou always generates into the directory `seihou run` is invoked from, so a
module cannot simply depend on `git-init` and have it land in a *new* folder: a
dependency's `.gitignore`, `git init`, and `gh repo create` would all run in the
current directory. `repo-dir` instead does its work in its own commands:

1. Expands a leading `~` in `repo.parentDir`, then refuses to continue if
   `<repo.parentDir>/<repo.name>` already exists and is not an empty directory.
2. `mkdir -p` the target directory.
3. Runs `seihou run git-init` **inside** the target with `git.createGithub=true`,
   `git.initialCommit=true`, and `git.repoName` bound to the folder name, plus
   `git.githubTeam` / `git.githubTeamPermission` when a team was given.

Because the nested run's target is the new folder, git-init's `.gitignore`,
`.seihou/manifest.json`, initial commit, and GitHub remote all belong to the new
repository, and you can later `cd` into it and apply more modules.

`git-init` 0.2.0 or newer must be discoverable by `seihou` (installed from this registry, or in
`~/.config/seihou/modules/`), and `gh` must be installed and authenticated.

## Choosing the GitHub owner per context

`git.githubOwner` is resolved by the *outer* run through the normal config chain
(CLI → env → local → namespace → **context** → global → default) and passed
explicitly to the nested `git-init` run. Set one owner per context:

```bash
seihou config set git.githubOwner my-user   --context personal
seihou config set git.githubOwner acme-corp --context work
seihou context default personal              # used when no context is selected
```

Then select the context with `--context`, `SEIHOU_CONTEXT`, a project's
`.seihou/context`, or the global default. `repo.parentDir` can be set per context
the same way (e.g. `seihou config set repo.parentDir ~/Work --context work`).

## Variables

| Variable | Type | Default | Required | Description |
|---|---|---|---|---|
| `repo.parentDir` | text | `.` | yes | Directory the new folder is created in. Relative to where `seihou run` is invoked; leading `~` expands to `$HOME`. |
| `repo.name` | text | — | yes | Folder name and GitHub repo name (`A-Za-z0-9._-`). |
| `git.githubOwner` | text | — | yes | GitHub user or organization; usually supplied by context config. |
| `git.githubVisibility` | text | `private` | yes | `private`, `public`, or `internal`. |
| `git.defaultBranch` | text | `master` | yes | Forwarded to `git-init`. Not prompted. |
| `git.githubTeam` | text | — | no | Organization team slug to grant access (e.g. `tan-engineers`). Unset = no grant. |
| `git.githubTeamPermission` | text | `push` | no | `pull`, `triage`, `push`, `maintain`, or `admin`. Only used with `git.githubTeam`. |

## Prompts

In order: `repo.parentDir`, `repo.name`, `git.githubOwner` (skipped when config
supplies it), `git.githubVisibility` (choice menu). Then, under "Optional
configuration": `git.githubTeam` (press Enter to skip) and, only when a team was
given, `git.githubTeamPermission`.

## Optional team access

When `git.githubTeam` is set, git-init runs, after the push,

```bash
gh api -X PUT /orgs/<owner>/teams/<team>/repos/<owner>/<name> -f permission=<permission>
```

It only works when the owner is an organization. Answer the prompt, or pass
`--var git.githubTeam=<slug>`, on the runs that need it. Setting it in context
config (`seihou config set git.githubTeam <slug> --context work`) makes it apply
to every run in that context instead.

## Generated Files

None in the invocation directory. Inside `<repo.parentDir>/<repo.name>`, the
nested `git-init` run writes `.gitignore` and `.seihou/manifest.json`, commits
them as `Initial commit`, and runs
`gh repo create <owner>/<name> --<visibility> --source=. --remote=origin --push`.

Note that the outer run still records `repo-dir` in a `.seihou/manifest.json` in
the directory you invoked it from; delete it if you ran from a non-project
directory such as `~/code`.

## Usage

```bash
seihou run repo-dir --context work --var repo.parentDir=~/Work --var repo.name=acme-api
```

Usually you will run it through the [`github-repo`](../../../recipes/github-repo) recipe.

## See Also

- `module.dhall` — authoritative definition
- `../git-init/` — the module run inside the new directory
- `../../../recipes/github-repo/` — recipe wrapping this module
