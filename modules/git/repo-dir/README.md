# repo-dir

Version **0.2.0** creates `<repo.parentDir>/<repo.name>`, optionally applies a scaffold
there, then calls the existing `git-init` module to create the initial commit,
matching GitHub repository, initial push and optional organization team access.

Seihou generates ordinary members into the invocation directory. This module uses
a staged Python command to acquire and apply its child members in the new directory,
so their files, manifests, Git repository and remote belong to that checkout. It
does not duplicate Git or GitHub creation logic.

| Variable | Default | Meaning |
|---|---|---|
| `repo.parentDir` | `.` | Parent directory, relative to invocation; leading `~` expands |
| `repo.name` | required | Folder and GitHub repository name |
| `repo.scaffold` | omitted | Optional module/recipe applied in the target before git-init |
| `repo.scaffoldBindings` | `{}` | JSON map from omitted child inputs to resolved outer input names |
| `repo.source` | public seihou-modules Git URL | Registry used to acquire git-init and the optional scaffold |
| `git.githubOwner` | required | GitHub user/organization, resolved through ordinary context/config |
| `git.githubVisibility` | `private` | `private`, `public` or `internal` |
| `git.defaultBranch` | `master` | Initial branch |
| `git.githubTeam` | omitted | Organization team slug |
| `git.githubTeamPermission` | `push` | Team permission |

Names permit letters, digits, `.`, `_` and `-`; empty names, `.` and `..` are rejected.
The target must be absent or an empty directory and cannot be a symlink. Target
checks happen before acquisition or creation. Parent paths, including quotes and
spaces, are passed as data rather than embedded in shell commands.

Seihou 0.15 has no install-only dependency edge: normal dependencies would apply
git-init and the scaffold in the parent. The command therefore uses
`seihou install <repo.source> --module git-init [--module <repo.scaffold>]` to acquire
the normal source-aware closure before applying children. A fork/local registry can
be selected explicitly; there is no forced overwrite of installed foreign artifacts.

Wrapper recipes declare the scaffold's public inputs. The command reads their
resolved values from the current application's `resolvedVars` and `recipeInputs`
in `.seihou/manifest.json`, excludes
`repo.*`/`git.*` controls and forwards the rest using argument arrays. Git/context
choices are forwarded separately to git-init. Values are never evaluated as shell
code, and registry storage is never edited directly. `repo.scaffoldBindings` can supply
omitted child inputs from outer controls without coupling this module to a particular
scaffold; explicit child inputs win. The Fumadocs wrapper uses it to default site links
to the actual GitHub owner, repository name and branch.

```bash
seihou config set git.githubOwner example-org --context work
seihou run repo-dir --context work --var repo.parentDir=~/Work --var repo.name=example
```

[github-repo](../../../recipes/github-repo/README.md) creates an empty repository.
[fumadocs-project](../../../recipes/fumadocs-project/README.md) supplies a complete
documentation scaffold and its typed inputs. `gh` must be authenticated and Git
must have an author identity. The optional scaffold may have further prerequisites.

Only the helper under `.seihou/repo-dir/` and the outer manifest are generated
in the invocation directory. All child outputs and the first commit live in the
target. Preview skips commands: `--dry-run` creates nothing and `--no-commands`
creates only outer controls. Failures preserve the target and report the failed
command. Reconcile partial work in that checkout; repeated creation refuses a
nonempty target. Removing the outer application never deletes the child repository,
remote, registration or content.
