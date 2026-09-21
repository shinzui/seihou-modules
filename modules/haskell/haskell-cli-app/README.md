# haskell-cli-app

> Bootstrap a tested Haskell CLI app as two packages (reusable core library + CLI executable) under GHC2024, with GHC 9.12.4 as the HLS-backed default and GHC 9.14.1 as a secondary build shell. Generates valid package-local distribution metadata and workspace-aware Nix package/check outputs through the latest `nix-haskell-flake`.

**Version:** `0.3.0`

## Overview

Generates a two-package cabal layout for a Haskell command-line tool:

- `<project>-core` — the reusable library. It exposes a starter `<Namespace>.greet`
  function and a project-wide `<Namespace>.Prelude` that re-exports `lens` and
  `generic-lens`.
- `<project>-cli` — the command-line library and executable. Its `hello` command calls the
  core package, and its exported parser supports pure tests.
- `<project>-cli` tests — a default-on Tasty suite covering core behavior and
  `optparse-applicative` parsing.

Pulls in `nix-haskell-flake` so the new repo lands with a pinned GHC, an `.envrc`,
formatter/pre-commit checks, named outputs for both packages, and a working default executable
output. The dependency binds `ghc.secondary=ghc9141`, `nix.builtin-package=false`, and a managed
`nix.package-module` while preserving `flake.module.nix` for user customizations.

## Variables

| Name | Type | Default | Required | Validation | Description |
|------|------|---------|----------|------------|-------------|
| `project.name` | `text` | — | yes | `[a-z][a-z0-9-]*` | Project base name; cabal packages are named `<name>-core` and `<name>-cli`, the executable is named `<name>`. Re-declared here so step `dest` paths validate; the value is shared with `nix-haskell-flake` via the dependency graph. |
| `project.description` | `text` | — | yes | — | One-line synopsis. Re-declared here so this module's templates can interpolate it; the value is shared with `nix-haskell-flake` (which uses it as the flake description) via the dependency graph. |
| `project.description-long` | `text` | — | no | — | Optional longer prose description used as the `description:` paragraph in both `.cabal` files. When not set, the templates fall back to `project.description` (the one-line synopsis). |
| `project.namespace` | `text` | — | yes | `[A-Z][A-Za-z0-9]*` | Top-level Haskell module namespace (single segment, e.g. `Rei`). Used both as the source-tree directory and as the module prefix in generated `.hs` files. |
| `project.category` | `text` | `Development` | yes | — | Hackage category written into both generated `.cabal` files. The CLI package also adds `CLI`. |
| `project.author` | `text` | `Nadeem Bitar` | yes | — | Author name written into `LICENSE` and `.cabal` files. |
| `project.maintainer` | `text` | `nadeem@gmail.com` | yes | — | Maintainer email written into `.cabal` files. |
| `project.copyright-year` | `text` | `2026` | yes | `[0-9]{4}` | Copyright year written into `LICENSE`. |
| `project.tests` | `bool` | `true` | yes | — | Generate the Tasty suite and corresponding Nix check. |

## Prompts

The following values are asked interactively (unless supplied via `--var`):

- **`project.name`** — What is your project name? (lowercase, hyphenated; cabal packages will be `<name>-core` and `<name>-cli`)
- **`project.description`** — One-line project synopsis (used as cabal `synopsis:` and the flake description):
- **`project.description-long`** — Longer project description (optional; press Enter to reuse the one-line synopsis):
- **`project.namespace`** — Top-level Haskell module namespace? (single PascalCase segment, e.g. `Rei`)
- **`project.category`** — Hackage category?
- **`project.author`** — Author name?
- **`project.maintainer`** — Maintainer email?
- **`project.copyright-year`** — Copyright year?
- **`project.tests`** — Generate the tasty test-suite scaffold? (yes/no)

## Dependencies

This module pulls in:

- **`nix-haskell-flake` 0.25.0 or newer** — supplies the two compiler shells and imports the
  generated workspace package module without taking ownership of the unmanaged
  `flake.module.nix` extension point.

## Exports

Variables this module exposes to parent modules:

- `project.name`
- `project.namespace`

## Generated Files

When run, this module writes:

- `cabal.project` — strategy: `template`
- `{{project.name}}-core/{{project.name}}-core.cabal` — strategy: `template`
- `{{project.name}}-core/src/{{project.namespace}}/Prelude.hs` — strategy: `template`
- `{{project.name}}-core/src/{{project.namespace}}.hs` — strategy: `template`
- `{{project.name}}-cli/{{project.name}}-cli.cabal` — strategy: `template`
- `{{project.name}}-cli/app/Main.hs` — strategy: `template`
- `{{project.name}}-cli/src/{{project.namespace}}/Cli.hs` — strategy: `template`
- `{{project.name}}-cli/test/Spec.hs` — strategy: `template` when `project.tests=true`
- `nix/haskell-cli-app.nix` — strategy: `template`; builds both local packages and exposes the
  CLI as `packages.default`, plus a test check when enabled
- `LICENSE`, `{{project.name}}-core/LICENSE`, `{{project.name}}-cli/LICENSE` — strategy: `template`
- `CHANGELOG.md`, `{{project.name}}-core/CHANGELOG.md`,
  `{{project.name}}-cli/CHANGELOG.md` — strategy: `template`
- `README.md` — strategy: `template`

`dest` may contain `{{var}}` placeholders; they are resolved at run time. In addition,
the files generated by `nix-haskell-flake` (the flake-parts `flake.nix` stub, exact
`flake.lock`, shared `fourmolu.yaml`, base `nix/*.nix` modules,
`flake.module.nix.example`, `.envrc`, `.gitignore` patches, and optionally
`process-compose.yaml`) are written by the dependency.

## Upgrading from 0.2.0

Version 0.3.0 adds files but does not move or delete user files. Re-resolve the dependency edge
so the new Nix bindings and defaulted variables are recorded:

```bash
seihou update haskell-cli-app --reconfigure
```

The update adds the core module, test, package-local release files, and managed workspace Nix
module. It also transfers `fourmolu.yaml` ownership to `nix-haskell-flake` without deleting the
file. Existing edits to managed Cabal or source templates remain protected by Seihou's conflict
handling; `flake.module.nix` remains untouched.

## Removal

This module is **not removable** — `seihou remove haskell-cli-app` will refuse. File
additions made by this module will have to be reverted manually.

## Usage

Apply the module:

```bash
seihou run haskell-cli-app
```

With variable overrides (note that `nix-haskell-flake` variables apply too):

```bash
seihou run haskell-cli-app \
  --var project.name=foo \
  --var project.description="A foo CLI" \
  --var project.namespace=Foo \
  --var project.category=Development \
  --var project.tests=true \
  --var nix.process-compose=false \
  --var nix.postgresql=false \
  --var nix.treefmt=true \
  --var nix.pre-commit=true
```

Preview without writing files:

```bash
seihou run haskell-cli-app --dry-run
```

## See Also

- `module.dhall` — full module definition and authoritative source
- `files/` — template sources
- `../nix-haskell-flake/` — the dev-shell dependency
