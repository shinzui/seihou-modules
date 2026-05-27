# haskell-library-repo

> Bootstrap a single-package Haskell library in a fresh git repository. Composes `haskell-library` (which pulls in `nix-haskell-flake`) with `git-init`; seihou's planner runs all file generation before any commands, so the resulting `git init` + initial commit captures the full scaffold in one shot.

**Version:** `0.1.0`

## Overview

A recipe is a static composition of existing modules with pre-bound variables — no new
generation logic, just a named bundle. `haskell-library-repo` is the one-name handle for
"new Haskell library project in a fresh repo." After running it you end up with:

- A `<project>/<project>.cabal` library scaffolded by `haskell-library` (lens +
  generic-lens prelude, GHC 9.12.4 / GHC2024, optional tasty test-suite).
- A Nix dev shell (`flake.nix`, `flake.lock`, `.envrc`, optional `treefmt.nix` and
  pre-commit-hooks) supplied by `haskell-library`'s dependency on `nix-haskell-flake`.
- An initialized git repo (`git init -b master`) with a single `Initial commit`
  containing everything above, plus an optional GitHub remote created via
  `gh repo create` when `git.createGithub=true`.

## Composed Modules

Applied in this order (file generation order; commands run after all files are
written):

1. **`haskell-library`** — single-package cabal library, optional tasty test-suite.
   - Pulls in **`nix-haskell-flake`** (a transitive dependency) for the GHC dev shell.
2. **`git-init`** — `git init` + initial commit; optional `gh repo create --push`.

No variables are pre-bound by this recipe; every variable is resolved either from a
module's default, from project / user / global config, or from an interactive prompt
when the recipe is run.

## Variables

The recipe exposes the union of its modules' variables. Refer to each module's README
for full descriptions:

- `project.*` — see [`../../modules/haskell/haskell-library/README.md`](../../modules/haskell/haskell-library/README.md)
- `nix.*` and `ghc.*` — see [`../../modules/haskell/nix-haskell-flake/README.md`](../../modules/haskell/nix-haskell-flake/README.md)
- `git.*` — see [`../../modules/git/git-init/README.md`](../../modules/git/git-init/README.md)

Required values you will be asked for (or must supply via `--var`):

- `project.name`, `project.description`, `project.namespace` — library identity.

Optional with sensible defaults:

- `project.author`, `project.maintainer`, `project.copyright-year`,
  `project.cabal-version`, `project.tests`
- `nix.process-compose`, `nix.postgresql`, `nix.treefmt`, `nix.pre-commit`
- `git.defaultBranch`, `git.initialCommit`, `git.createGithub`,
  `git.githubVisibility`

## Generated Files

The full plan (with `project.tests=true`, both `nix.treefmt` and `nix.pre-commit`
enabled) produces 14 files:

- From `nix-haskell-flake`: `flake.nix`, `flake.lock`, `treefmt.nix`, `.envrc`, plus
  `.gitignore` patches.
- From `haskell-library`: `cabal.project`, `<project>/<project>.cabal`,
  `<project>/src/<Namespace>.hs`, `<project>/src/<Namespace>/Prelude.hs`,
  `<project>/test/Spec.hs` (when `project.tests=true`), `LICENSE`, `fourmolu.yaml`,
  `CHANGELOG.md`, `README.md`.
- From `git-init`: a `.gitignore` patch.

Then commands run:

- `git init -b {{git.defaultBranch}}`
- `git add -A && git commit -m 'Initial commit'` (when `git.initialCommit=true`)
- `gh repo create <owner>/<repo> --<visibility> --source=. --remote=origin --push`
  (when `git.createGithub=true`)

## Usage

Apply the recipe with all-defaults plus the three required identity variables:

```bash
seihou run haskell-library-repo \
  --var project.name=acme-text \
  --var project.description="Friendly text helpers" \
  --var project.namespace=AcmeText
```

Skip the test-suite and stay local-only:

```bash
seihou run haskell-library-repo \
  --var project.name=acme-text \
  --var project.description="Friendly text helpers" \
  --var project.namespace=AcmeText \
  --var project.tests=false \
  --var git.createGithub=false
```

Create a private GitHub repo under your configured owner (note that `git.repoName`
must currently be supplied separately; recipe-level var bindings cannot reference
`{{project.name}}`):

```bash
seihou config set git.githubOwner <your-org-or-user> --global   # one-time
seihou run haskell-library-repo \
  --var project.name=acme-text \
  --var project.description="Friendly text helpers" \
  --var project.namespace=AcmeText \
  --var git.createGithub=true \
  --var git.repoName=acme-text
```

Preview without writing files:

```bash
seihou run haskell-library-repo --dry-run \
  --var project.name=acme-text \
  --var project.description="Friendly text helpers" \
  --var project.namespace=AcmeText
```

## See Also

- `recipe.dhall` — full recipe definition and authoritative source
- `../../modules/haskell/haskell-library/` — the library scaffold
- `../../modules/haskell/nix-haskell-flake/` — the dev shell
- `../../modules/git/git-init/` — the git initializer
