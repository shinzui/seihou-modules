# openapi-typescript-client-dir

**Version:** `0.1.1`

Directory-creation wrapper for the
[`openapi-typescript-client-repo`](../../../recipes/openapi-typescript-client-repo)
recipe. It runs `seihou run openapi-typescript-client -m git-init` inside
`<repo.parentDir>/<project.name>` so generation, the initial commit and GitHub
creation happen in the new client repository.

Install this module together with `openapi-typescript-client`, `nix-bun-flake`
and `git-init` (for example, install this registry with `--all`). These are
invoked inside the target rather than declared as composition dependencies,
which would generate their files in the invocation directory.

| Variable | Default | Purpose |
|---|---|---|
| `repo.parentDir` | `.` | Parent directory; relative to invocation directory, leading `~` expanded |
| `repo.postCreateScript` | unset | Python script run from the invocation directory after successful creation and push |
| `project.name` | required | Folder, package and GitHub repo name; lowercase letters, digits and hyphens, starting with a letter |
| `project.description` | required | One-line client description |
| `git.githubOwner` | required | GitHub user or organization; CLI, context or global config, or prompt |
| `git.githubVisibility` | `private` | `private`, `public` or `internal` |
| `git.defaultBranch` | `master` | Initial Git branch |
| `git.githubTeam` | unset | Optional organization team slug |
| `git.githubTeamPermission` | `push` | `pull`, `triage`, `push`, `maintain` or `admin` |
| `nix.bun2nix` | `false` | Include optional Bun Nix build helpers |
| `mori.generate` | `false` | Seed client Mori inventory |
| `mori.namespace` | unset | Client Mori namespace; required when Mori is enabled |
| `mori.source-namespace` | unset | API provider namespace; required when Mori is enabled |
| `mori.source-project` | unset | API provider project name; required when Mori is enabled |

Python 3.9+, Git and authenticated `gh` are required. Resolved inputs are written
as separate data files under `.seihou/openapi-typescript-client-dir/`. The Python
helper reads them and passes argument arrays to the nested CLI, preserving spaces
and quotes in directory names without shell interpolation. The wrapper refuses
nonempty targets and symlinks. It always requests an initial commit and GitHub
creation with a matching repository name. The module seeds `openapi.yaml`; schema
replacement and client generation follow the generated project's README.

Extending recipes can stage a Python script and bind `repo.postCreateScript` to
its path. The wrapper validates the script before creating the target and runs it
only after the nested client/Git invocation succeeds. Script failures propagate;
the created repository is retained for inspection and recovery.

The wrapper and its configuration are recorded in the invocation directory;
the nested run records the client, its Nix dependency and `git-init` in the new
repository. Maintain the client with `seihou update openapi-typescript-client`
from that directory. See the recipe README for examples and context configuration.
