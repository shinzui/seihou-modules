# openapi-typescript-client-repo

Create `<repo.parentDir>/<project.name>`, generate an OpenAPI TypeScript client
inside it, and create a matching GitHub repository under a configurable owner.

**Version:** `0.1.0`

## Usage

Install the recipe and the modules it invokes, including `nix-bun-flake`:

```bash
seihou install https://github.com/shinzui/seihou-modules.git --all

seihou run openapi-typescript-client-repo \
  --var repo.parentDir=~/Work/clients \
  --var project.name=widgets-client \
  --var project.description='TypeScript client for the Widgets API' \
  --var git.githubOwner=my-org
```

Omit the variables to answer prompts. The folder, package and GitHub repository
share `project.name`. GitHub repositories default to private, with an initial
commit on `master`; override `git.githubVisibility` or `git.defaultBranch` as needed.
Requires Python 3.9+, Git, and an installed and authenticated GitHub CLI (`gh`).

## GitHub owner

Set `git.githubOwner` for one invocation with `--var`, or reuse an owner through
context config:

```bash
seihou config set git.githubOwner my-user --context personal
seihou config set git.githubOwner my-org --context work
seihou config set repo.parentDir ~/Work/clients --context work

seihou run openapi-typescript-client-repo --context work
```

The selected owner is passed explicitly to `git-init` in the new directory.
Optional `git.githubTeam` and `git.githubTeamPermission` settings grant an
organization team access after the repository is created.

## Composition and generated project

The recipe uses [`openapi-typescript-client-dir`](../../modules/typescript/openapi-typescript-client-dir),
which creates the directory and runs `openapi-typescript-client -m git-init`
inside it. As with [`github-repo`](../github-repo), a wrapper is necessary because
Seihou generates a composition in the invocation directory. All client, Nix and
Git files are generated before the initial commit and GitHub push.

The client starts with the module's example `openapi.yaml`. Replace it with your
API schema and follow the generated README to install dependencies, generate the
client and run checks. Optional `nix.bun2nix` and `mori.generate` settings are
forwarded; enabling Mori also requires `mori.namespace`, `mori.source-namespace`
and `mori.source-project`.

The target must be absent or an empty directory. Existing nonempty directories
and symlinks are refused, including repeat runs against the created client.
The invocation directory receives the wrapper's `.seihou` configuration and
manifest; the client directory receives its own manifest for the client and
`git-init`. Run future client updates from there:

```bash
cd ~/Work/clients/widgets-client
seihou update openapi-typescript-client
```

`--dry-run` previews the wrapper without creating the client directory. If a
nested command fails, its error is propagated and the partially created folder
is retained for inspection.
