# github-repo

> Prompt for a parent directory and a folder name, create the folder, and turn it into a git repository with a matching GitHub repo under the active context's GitHub user or organization.

**Version:** `0.1.0`

## Overview

`github-repo` is the one-name handle for "start a new, empty repo on GitHub."
Running it:

1. Prompts for the parent directory (`repo.parentDir`) and folder name
   (`repo.name`).
2. Creates `<repo.parentDir>/<repo.name>`.
3. Runs `git-init` inside that new folder: `git init -b master`, a seeded
   `.gitignore`, an `Initial commit`, and
   `gh repo create <git.githubOwner>/<repo.name> --<visibility> --source=. --remote=origin --push`.

The GitHub repo name always matches the folder name.

## Composed Modules

1. **`repo-dir`** — creates the directory and runs `seihou run git-init` inside it
   (see its README for why `git-init` is invoked rather than composed directly).

## Context-aware GitHub owner

The owner is the `git.githubOwner` variable, which seihou resolves from the
active context's config before falling back to global config or a prompt:

```bash
# one-time setup
seihou config set git.githubOwner my-user   --context personal
seihou config set git.githubOwner acme-corp --context work
seihou config set repo.parentDir ~/Work     --context work   # optional
seihou context default personal

seihou run github-repo                    # personal context → my-user/<name>
seihou run github-repo --context work     # → acme-corp/<name>, created under ~/Work
SEIHOU_CONTEXT=work seihou run github-repo
```

If no context or global value is set, the recipe prompts for the owner.

## Variables

- `repo.parentDir` (default `.`, `~` expanded), `repo.name` — prompted.
- `git.githubOwner` — from context/global config, otherwise prompted.
- `git.githubVisibility` (default `private`) — prompted.
- `git.defaultBranch` (default `master`) — not prompted; override with `--var`.
- `git.githubTeam` — optional; prompted under "Optional configuration" (Enter
  skips). When set, the team gets `git.githubTeamPermission` (default `push`)
  on the new repo.

See [`../../modules/git/repo-dir/README.md`](../../modules/git/repo-dir/README.md)
for full descriptions.

## Usage

```bash
seihou run github-repo --context work \
  --var repo.parentDir=~/Work \
  --var repo.name=acme-api \
  --var git.githubVisibility=private
```

Also grant an organization team push access:

```bash
seihou run github-repo --context work --var repo.name=acme-api \
  --var git.githubTeam=acme-engineers          # optional: --var git.githubTeamPermission=maintain
```

Requires `gh` (installed and authenticated) and `git-init` to be installed
alongside this recipe (`seihou install … --module github-repo --module repo-dir --module git-init`).
The run also records `repo-dir` in a `.seihou/manifest.json` in the directory you
invoked it from; remove it if that directory is not a seihou project.

## See Also

- `recipe.dhall` — authoritative definition
- `../../modules/git/repo-dir/` — directory creation + nested git-init
- `../../modules/git/git-init/` — the git initializer
