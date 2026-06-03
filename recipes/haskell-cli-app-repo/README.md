# haskell-cli-app-repo

> Bootstrap a two-package Haskell CLI app (core library + CLI executable) in a fresh git repository. Composes `haskell-cli-app` (which pulls in `nix-haskell-flake`) with `git-init`; seihou's planner runs all file generation before any commands, so the resulting `git init` + initial commit captures the full scaffold in one shot.

**Version:** `0.1.0`

## Overview

A recipe is a static composition of existing modules with pre-bound variables — no new
generation logic, just a named bundle. `haskell-cli-app-repo` is the one-name handle
for "new Haskell CLI project in a fresh repo." After running it you end up with:

- A two-package cabal layout scaffolded by `haskell-cli-app`:
  - `<project>-core/` — the library, with a project-wide `<Namespace>.Prelude` that
    re-exports `lens` and `generic-lens`.
  - `<project>-cli/` — a library exposing `<Namespace>.Cli.runCli` plus an executable
    named `<project>` whose `Main` just delegates to it.
- A flake-parts Nix dev shell (`flake.nix` stub + `nix/*.nix` modules, `flake.lock`,
  `flake.module.nix.example`, `.envrc`, optional treefmt-nix and pre-commit-hooks)
  supplied by `haskell-cli-app`'s dependency on `nix-haskell-flake`.
- An initialized git repo (`git init -b master`) with a single `Initial commit`
  containing everything above, plus an optional GitHub remote created via
  `gh repo create` when `git.createGithub=true`.

## Composed Modules

Applied in this order (file generation order; commands run after all files are
written):

1. **`haskell-cli-app`** — two-package CLI scaffold.
   - Pulls in **`nix-haskell-flake`** (a transitive dependency) for the GHC dev shell.
2. **`git-init`** — `git init` + initial commit; optional `gh repo create --push`.

No variables are pre-bound by this recipe; every variable is resolved either from a
module's default, from project / user / global config, or from an interactive prompt
when the recipe is run.

## Variables

The recipe exposes the union of its modules' variables. Refer to each module's README
for full descriptions:

- `project.*` — see [`../../modules/haskell/haskell-cli-app/README.md`](../../modules/haskell/haskell-cli-app/README.md)
- `nix.*` and `ghc.*` — see [`../../modules/haskell/nix-haskell-flake/README.md`](../../modules/haskell/nix-haskell-flake/README.md)
- `git.*` — see [`../../modules/git/git-init/README.md`](../../modules/git/git-init/README.md)

Required values you will be asked for (or must supply via `--var`):

- `project.name`, `project.description`, `project.namespace` — CLI identity.

Optional with sensible defaults:

- `project.description-long`, `project.author`, `project.maintainer`,
  `project.copyright-year`
- `nix.process-compose`, `nix.postgresql`, `nix.treefmt`, `nix.pre-commit`
- `git.defaultBranch`, `git.initialCommit`, `git.createGithub`,
  `git.githubVisibility`

## Generated Files

The full plan (with both `nix.treefmt` and `nix.pre-commit` enabled) produces 18
files:

- From `nix-haskell-flake`: `flake.nix`, `flake.lock`, `nix/haskell.nix`,
  `nix/treefmt.nix`, `nix/pre-commit.nix`, `flake.module.nix.example`, `.envrc`, plus
  `.gitignore` patches.
- From `haskell-cli-app`: `cabal.project`, `<project>-core/<project>-core.cabal`,
  `<project>-core/src/<Namespace>/Prelude.hs`,
  `<project>-cli/<project>-cli.cabal`, `<project>-cli/app/Main.hs`,
  `<project>-cli/src/<Namespace>/Cli.hs`, `LICENSE`, `fourmolu.yaml`, `CHANGELOG.md`,
  `README.md`.
- From `git-init`: a `.gitignore` patch.

Then commands run:

- `git init -b {{git.defaultBranch}}`
- `git add -A && git commit -m 'Initial commit'` (when `git.initialCommit=true`)
- `gh repo create <owner>/<repo> --<visibility> --source=. --remote=origin --push`
  (when `git.createGithub=true`)

## Usage

Apply the recipe with all-defaults plus the three required identity variables:

```bash
seihou run haskell-cli-app-repo \
  --var project.name=acme-tool \
  --var project.description="A friendly demo tool" \
  --var project.namespace=AcmeTool
```

Once generated, build and try the binary:

```bash
cd acme-tool
nix develop      # or `direnv allow` if you use direnv
cabal build all
cabal run acme-tool -- hello --name world
```

Stay local-only without pushing to GitHub:

```bash
seihou run haskell-cli-app-repo \
  --var project.name=acme-tool \
  --var project.description="A friendly demo tool" \
  --var project.namespace=AcmeTool \
  --var git.createGithub=false
```

Create a private GitHub repo under your configured owner (note that `git.repoName`
must currently be supplied separately; recipe-level var bindings cannot reference
`{{project.name}}`):

```bash
seihou config set git.githubOwner <your-org-or-user> --global   # one-time
seihou run haskell-cli-app-repo \
  --var project.name=acme-tool \
  --var project.description="A friendly demo tool" \
  --var project.namespace=AcmeTool \
  --var git.createGithub=true \
  --var git.repoName=acme-tool
```

Preview without writing files:

```bash
seihou run haskell-cli-app-repo --dry-run \
  --var project.name=acme-tool \
  --var project.description="A friendly demo tool" \
  --var project.namespace=AcmeTool
```

## See Also

- `recipe.dhall` — full recipe definition and authoritative source
- `../haskell-library-repo/` — sister recipe for libraries (no executable)
- `../../modules/haskell/haskell-cli-app/` — the CLI scaffold
- `../../modules/haskell/nix-haskell-flake/` — the dev shell
- `../../modules/git/git-init/` — the git initializer
