# fumadocs-project

Create a documentation directory, populate it with a container-enabled Fumadocs
site and six writing skills, register it locally with Mori, then create its Git
repository, initial commit and matching GitHub repository and push that commit.

Version **0.2.0** uses the existing `repo-dir` and `git-init` modules. The former
direct in-checkout composition is now [fumadocs-site](../fumadocs-site/README.md).
Use that recipe when you already have a checkout; `fumadocs-project` protects
existing directories by refusing nonempty targets.

Requires Seihou 0.15+, Python 3, Git with author identity configured, authenticated
`gh`, `dhall-to-json`, Mori 7.2 and a migrated local registry selected through
`MORI_PG_CONNECTION_STRING`. The project being documented must already be registered.
Initial acquisition needs access to both Seihou registries. Nix builds retain the
existing Fumadocs prerequisites.

Run from the directory where you want to launch creation:

```bash
seihou install https://github.com/shinzui/seihou-modules.git --module fumadocs-project
seihou run fumadocs-project \
  --var repo.parentDir=~/Projects --var repo.name=widget-docs \
  --var project.name=widget-docs --var project.description='Widget documentation' \
  --var docs.site-name='Widget docs' --var docs.github-user=example \
  --var git.githubOwner=example --var mori.namespace=example \
  --var mori.source-namespace=example --var mori.source-project=widget
cd ~/Projects/widget-docs
git remote -v
mori registry show example/widget-docs --full
```

`repo.parentDir` defaults to `.` and expands a leading `~`. `repo.name` names the
folder and GitHub repository. `project.name` and `mori.namespace` identify the
documentation project and may differ from the folder, remote and documented
project. All source/project identity inputs remain explicit. Existing files,
non-directories and symlinks at the target are rejected before acquisition or creation.

`git.githubOwner` follows normal CLI/context/global configuration and is forwarded
to the child run. Visibility defaults to `private`; `git.defaultBranch` defaults to
`master`. Optional `git.githubTeam` and `git.githubTeamPermission` are forwarded to
`git-init` for organization access. Site GitHub links default to the created owner, repository name and branch, including
when repo.name differs from project.name. Override `docs.github-user`,
`docs.github-repo` or `docs.github-branch` explicitly to link elsewhere. All other Fumadocs inputs and `skill.prefix` remain
available.

The public recipe composes `repo-dir` with `repo.scaffold=fumadocs-site`.
`repo.source` defaults to `https://github.com/shinzui/seihou-modules.git` and can
select a fork or local registry. Released Seihou applies every ordinary dependency
in the invocation directory, so `repo-dir` acquires `git-init` and the child recipe
with the released installer, then applies them inside the new directory. The child
recipe retains its source-qualified dependency on
`mori://shinzui/agent-seihou/templates/technical-docs`; no writing skill templates
are duplicated. The child's complete acquisition closure is available before files
are generated there.

The initial commit includes the site, canonical writing skills, authored `mori.dhall`
and Seihou manifest. GitHub creation/push runs only after the scaffold and Mori
registration succeed. The invocation directory receives only Seihou control files;
the site, `.git`, remote and registered Mori path belong to the new child directory.
`--dry-run` creates nothing; `--no-commands` stages only the outer control files and
creates no target, registration, Git repository or remote.

Failures preserve completed work and report the target and failing command. A failed
Mori registration prevents Git/GitHub creation. A failed GitHub command leaves the
generated, registered local repository for explicit recovery. Reconcile the failing
command inside that checkout; rerunning creation refuses nonempty directories rather
than overwriting them. For site/manifest recovery use `fumadocs-site` or the generated
Mori helper inside the target. Seihou does not roll back a registry identity, remote
repository or push. Removing the outer wrapper never deletes the created checkout.

See [fumadocs-site](../fumadocs-site/README.md) for building `docs-site`, native Linux
image export and ownership rules. `bun.lock`, `bun-deps.nix` and `flake.module.nix`
remain consumer owned. This workflow creates the GitHub repository but does not publish
container images or deploy the site.

`scripts/test-fumadocs-project.py` qualifies the wrapper with real Git commits and
pushes to disposable local bare remotes, an offline GitHub fixture, and real isolated
Mori registration. No live GitHub test repositories are created.
