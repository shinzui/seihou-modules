# nix-bun-flake

> Nix flake for Bun + TypeScript projects with oxlint linting, oxfmt formatting (semicolon-free, sorted imports), a `just` task runner, optional git-hooks.nix pre-commit checks, and opt-in pinned bun2nix build helpers.

**Version:** `0.4.0`

## Overview

Generates a reproducible Nix development environment for a Bun + TypeScript project: a
thin flake-parts `flake.nix` with revision-pinned inputs and a shared `flake.lock`, providing `bun`, `oxlint`, `oxfmt`, `typescript`, and
`just` in the dev shell, plus the tooling config it expects — `tsconfig.json`,
`.oxlintrc.json`, `.oxfmtrc.json`, a `justfile` with typecheck/format/lint recipes, a
`package.json`, an `.envrc` for direnv, and a `.gitignore`. Formatting is opinionated:
oxfmt strips semicolons and sorts imports. No database or runtime services are included.

## Shared toolchain and upgrades

This release provides Bun **1.4.2**, TypeScript **7.0.2**, Oxlint **1.87.0**,
Oxfmt **0.72.0**, and just **1.58.0**. Bun and just come from the pinned nixpkgs;
TypeScript and Oxc tools use fixed-hash upstream npm archives with native bindings,
packaged by Nix. Hooks and the shell use identical packages; no global npm install
is needed. `@types/bun` is pinned to **1.4.2** in the generated package manifest.
Commit the project's `bun.lock` after `just install` to lock its dependencies.

Supported systems are Apple Silicon macOS, ARM64 Linux, and x86-64 Linux, matching
the systems supported by Bun in the pinned nixpkgs. Intel macOS is not exposed.

The managed layout is:

```text
flake.nix                    # inputs and flake-parts imports
flake.lock                   # canonical lock seed
nix/bun.nix                  # development shell
nix/tooling.nix              # fixed-output tooling packages
nix/tooling-sources.json     # versions, archives, hashes, native bindings
nix/pre-commit.nix           # generated/imported when hooks are enabled
nix/bun2nix-package.nix      # optional compatibility-patched helper
nix/bun2nix-module.nix       # optional package/shell wiring
flake.module.nix.example     # example for unmanaged project customizations
```

All inputs are pinned by revision in `flake.nix`. The flake-parts and git-hooks
inputs follow the same nixpkgs. bun2nix follows nixpkgs and flake-parts. Both optional
inputs remain declared when disabled, so all four feature combinations share one lock.
Disabled bun2nix adds no generator to the shell and exposes no `packages.bun2nix`.
`nix flake update` cannot move module-owned revisions. Update projects together
by installing a new module release and running:

```bash
seihou update nix-bun-flake
git add flake.nix flake.lock nix/
nix develop
```

Existing projects gain the managed `nix/` files during the update. Review conflicts
in customized `flake.nix` files and move shell/output customizations into
`flake.module.nix`. Copy `flake.module.nix.example` as a starting point; Seihou
never creates or removes `flake.module.nix`. It is imported automatically when
present. Extend shell packages with `perSystem.bunProject.extraDevPackages`, or define
additional flake-parts packages, checks, apps, and named shells. Put local environment exports in `.envrc.local`. The generated `.envrc`
watches the imported modules and sources that optional file after entering the shell.

To recover the module-owned pins in a drifted project:

```bash
nix flake lock --reference-lock-file ~/.config/seihou/installed/nix-bun-flake/files/flake.lock
```

Project-specific inputs must be added to `flake.nix`; pin them by revision and
update them by name. Projects with additional inputs have additional lock nodes.

Maintainers choose verification, lock regeneration, or an explicit upstream refresh:

```bash
python3 scripts/update-nix-bun-flake.py --check       # committed pins/hashes; read-only
python3 scripts/update-nix-bun-flake.py --write-lock  # only regenerate the canonical lock
python3 scripts/update-nix-bun-flake.py               # explicitly refresh upstream releases
```

The immutable check validates exact committed npm metadata and archive hashes, compares
all four toggle locks, evaluates all three systems with the copied extension, and proves
a full update leaves managed pins unchanged. It never compares against moving latest
releases. Refresh additionally verifies registry versions against upstream release tags
and checks Bun/just in nixpkgs. A new bun2nix release stops refresh until its patch and
fixtures are qualified; enabling this feature needs no toolchain refresh. Bump module,
registry, Mori and catalog versions together when releasing.

## Variables

| Name | Type | Default | Required | Validation | Description |
|------|------|---------|----------|------------|-------------|
| `project.name` | `text` | — | yes | `[a-z][a-z0-9-]*` | Project name (used in flake description and `package.json` name) |
| `project.description` | `text` | — | yes | — | One-line project description |
| `nix.bun2nix` | `bool` | `false` | yes | — | Include the pinned generator, hook and dependency-cache helper; build recipes remain project-owned |
| `nix.pre-commit` | `bool` | `true` | yes | — | Include pre-commit-hooks (git-hooks.nix) wiring `oxlint` and `oxfmt --check` as git hooks |

## Prompts

The following values are asked interactively (unless supplied via `--var`):

- **`project.name`** — What is your project name?
- **`project.description`** — Describe your project in one line:
- **`nix.bun2nix`** — Include bun2nix for explicit Nix dependency generation and builds?
- **`nix.pre-commit`** — Include pre-commit hooks (oxlint + oxfmt) via git-hooks.nix?

## Exports

Variables this module exposes to parent modules:

- `project.name`
- `project.description`

## Generated Files

When run, this module writes:

- `flake.nix` — strategy: `template`
- `flake.lock` — strategy: `copy`
- `nix/bun.nix` — strategy: `template`
- `nix/tooling.nix` and `nix/tooling-sources.json` — strategy: `copy`
- `nix/pre-commit.nix` — strategy: `copy`, when hooks are enabled
- `nix/bun2nix-package.nix` and `nix/bun2nix-module.nix` — strategy: `copy`, only with bun2nix enabled
- `flake.module.nix.example` — strategy: `copy`
- `package.json` — strategy: `template`
- `tsconfig.json` — strategy: `copy`
- `.oxlintrc.json` — strategy: `copy`
- `.oxfmtrc.json` — strategy: `copy`
- `justfile` — strategy: `copy`
- `.envrc` — strategy: `copy`
- `.gitignore` — strategy: `template`, patch mode: `append-line-if-absent`
- `.gitignore` — strategy: `template`, patch mode: `append-line-if-absent`
  - Applied when: `Eq nix.pre-commit true`

## Removal

This module supports removal via:

```bash
seihou remove nix-bun-flake
```

Removal steps remove the files it created: `flake.nix`, `flake.lock`, `package.json`,
`tsconfig.json`, `.oxlintrc.json`, `.oxfmtrc.json`, `justfile`, `.envrc`, the managed
`nix/` files, and `flake.module.nix.example`. User `flake.module.nix`, `bun.lock`, `bun-deps.nix`, and application sources are preserved. Lines
appended to `.gitignore` are left in place.

## Usage

Apply the module:

```bash
seihou run nix-bun-flake
```

With variable overrides:

```bash
seihou run nix-bun-flake --var project.name=acme-api --var project.description="Acme HTTP API" --var nix.pre-commit=true
```

Preview without writing files:

```bash
seihou run nix-bun-flake --dry-run
```

Once generated, enter the dev shell (`direnv allow` or `nix develop`) and:

```bash
just install      # bun install
just typecheck    # tsc --noEmit
just format       # oxfmt --write . (strips semicolons, sorts imports)
just lint         # oxlint
just check        # typecheck + lint + format-check
```

## Optional sandbox builds with bun2nix

The default is `nix.bun2nix=false`. Opting in exposes the exact same patched helper as
`packages.bun2nix` and in the development shell, including upstream `hook` and
`fetchBunDeps`. It does not install dependencies, generate `bun-deps.nix`, change
`packageManager` or scripts, or infer `packages.default`. The base scaffold has no
application entry point or production build command; those choices belong to your
unmanaged `flake.module.nix`. Container and deployment recipes remain project-owned.

For a fresh project:

```bash
seihou run nix-bun-flake --var project.name=acme-app \
  --var project.description="Acme app" --var nix.bun2nix=true
# Add the project manifest, sources and a build recipe as below.
bun install
nix run .#bun2nix -- --lock-file bun.lock --output-file bun-deps.nix
nix develop -c bun2nix --help
nix build --option sandbox true
nix flake check --option sandbox true
```

In a Git flake, add every new source, managed Nix file and `bun-deps.nix` to Git
before evaluation. The generator explicitly writes a user-owned dependency expression;
this is distinct from the managed development module `nix/bun.nix`.

### Adopt or disable in an existing project

After installing the candidate module release, inventory saved variables and shared
owners in `.seihou/manifest.json`, back up custom files, and review the update:

```bash
seihou update nix-bun-flake --var nix.bun2nix=true --dry-run
seihou update nix-bun-flake --var nix.bun2nix=true --json
```

Saved variables are reused. Review three-way conflicts in custom flake inputs and
package manifests, retaining the project's package-manager choice and authored scripts.
For co-owned paths, coordinate the owning application; select its recorded target or
review `--include-shared-owners` instead of replacing receipts or using blanket
`--force`. Keep application recipes in `flake.module.nix`. Existing custom wrappers
such as `nix/bun2nix.nix` do not collide with the two new managed paths. Switch callers
to `config.packages.bun2nix`, run the checks, and only then remove obsolete custom wiring.

To disable, first adapt any enabled-only recipe in your unmanaged extension, then:

```bash
seihou update nix-bun-flake --var nix.bun2nix=false --dry-run
seihou update nix-bun-flake --var nix.bun2nix=false --json
```

Unedited managed feature files are removed. An edited orphan requires a deliberate
retain/unmanage/delete choice through Seihou's interactive update; retained files
are no longer imported. `bun.lock`, `bun-deps.nix` and authored builds are retained.
Copying the ordinary `flake.module.nix.example` works with the feature disabled.
Full module removal still follows the base contract, including removal of generated
`package.json`; it does not remove authored locks, expressions, extensions or sources.

### Single-package example

The compact executable example in [the single-package fixture](../../../scripts/fixtures/nix-bun-flake/single)
uses a pinned registry dependency. Start with this `package.json` and `index.js`:

```json
{ "name": "bun-fixture", "private": true, "version": "1.0.0",
  "dependencies": { "is-number": "7.0.0" } }
```

```javascript
import isNumber from "is-number"
console.log(`app-original:${isNumber(42)}`)
```

Run `bun install`, generate `bun-deps.nix` as above, and create `flake.module.nix`:

```nix
# Fixture-owned application recipe; never generated by nix-bun-flake.
{ ... }:
{
  perSystem = { config, pkgs, lib, ... }:
    let
      bun2nix = config.packages.bun2nix;
      bunDeps = bun2nix.fetchBunDeps { bunNix = ./bun-deps.nix; };
      src = builtins.path {
        path = ./.;
        name = "bun-fixture-source";
        filter = path: _:
          let relative = lib.removePrefix (toString ./. + "/") (toString path);
          in builtins.elem relative [ "package.json" "bun.lock" "index.js" ];
      };
      app = pkgs.stdenvNoCC.mkDerivation {
        pname = "bun-fixture";
        version = "1.0.0";
        inherit src bunDeps;
        strictDeps = true;
        nativeBuildInputs = [ pkgs.bun bun2nix.hook ];
        bunInstallFlags = [ "--frozen-lockfile" "--linker=isolated" ]
          ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "--backend=symlink";
        dontRunLifecycleScripts = true;
        buildPhase = ''
          runHook preBuild
          bun --no-install index.js > result.txt
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          cp result.txt "$out/result.txt"
          runHook postInstall
        '';
      };
    in {
      packages.default = app;
      packages.registry-cache = bunDeps;
      packages.fixture-bun = pkgs.bun;
      checks.fixture = app;
      apps.default = {
        type = "app";
        program = "${pkgs.writeShellScript "fixture-result" ''
          exec ${pkgs.coreutils}/bin/cat ${app}/result.txt
        ''}";
      };
    };
}
```

`nix run .#default` prints `app-original:true`. The explicit phases build and install
a text artifact; replace those phases with your application's actual build and
install commands. `strictDeps` and `nativeBuildInputs` make tool requirements explicit.
Add a build interpreter such as Node only if your build actually requires it.

### Workspace example

Use this root `package.json`:

```json
{ "name": "bun-fixture", "private": true, "version": "1.0.0",
  "workspaces": ["packages/*"] }
```

Create `packages/app/package.json` and `packages/shared/package.json`:

```json
{ "name": "fixture-app", "version": "1.0.0", "type": "module",
  "dependencies": { "fixture-shared": "workspace:*", "is-number": "7.0.0" } }
```

```json
{ "name": "fixture-shared", "version": "1.0.0", "type": "module",
  "exports": "./index.js" }
```

`packages/shared/index.js` exports `export const message = "shared-original"`.
`packages/app/index.js` uses both local and registry packages:

```javascript
import isNumber from "is-number"
import { message } from "fixture-shared"
console.log(`app-original:${isNumber(42)}:${message}`)
```

Generate the root lock and expression normally. The generated expression contains
workspace `copyPathToStore` records. Passing those directly to `fetchBunDeps` makes
source edits invalidate the registry cache. Remove local names lazily at evaluation,
using names read from the workspace manifests, and pass the current complete source
to the app. Bun then creates current workspace links during frozen installation.
This complete `flake.module.nix` implements that boundary:

```nix
# Fixture-owned application recipe; workspace sources never enter the registry cache.
{ ... }:
{
  perSystem = { config, pkgs, lib, ... }:
    let
      bun2nix = config.packages.bun2nix;
      workspacePaths = [ ./packages/app/package.json ./packages/shared/package.json ];
      workspaceNames = map (path: (builtins.fromJSON (builtins.readFile path)).name) workspacePaths;
      registryOnly = { copyPathToStore, fetchFromGitHub, fetchgit, fetchurl, ... }@args:
        builtins.removeAttrs (import ./bun-deps.nix args) workspaceNames;
      bunDeps = bun2nix.fetchBunDeps { bunNix = registryOnly; };
      src = builtins.path {
        path = ./.;
        name = "bun-fixture-source";
        filter = path: _:
          let relative = lib.removePrefix (toString ./. + "/") (toString path);
          in builtins.elem relative [
            "package.json" "bun.lock" "packages" "packages/app" "packages/shared"
            "packages/app/package.json" "packages/app/index.js"
            "packages/shared/package.json" "packages/shared/index.js"
          ];
      };
      app = pkgs.stdenvNoCC.mkDerivation {
        pname = "bun-workspace-fixture";
        version = "1.0.0";
        inherit src bunDeps;
        strictDeps = true;
        nativeBuildInputs = [ pkgs.bun bun2nix.hook ];
        bunInstallFlags = [ "--frozen-lockfile" "--linker=isolated" ]
          ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin "--backend=symlink";
        dontRunLifecycleScripts = true;
        buildPhase = ''
          runHook preBuild
          bun --no-install packages/app/index.js > result.txt
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p "$out"
          cp result.txt "$out/result.txt"
          runHook postInstall
        '';
      };
    in {
      packages.default = app;
      packages.registry-cache = bunDeps;
      packages.fixture-bun = pkgs.bun;
      checks.fixture = app;
      apps.default = {
        type = "app";
        program = "${pkgs.writeShellScript "fixture-result" ''
          exec ${pkgs.coreutils}/bin/cat ${app}/result.txt
        ''}";
      };
    };
}
```

`nix run .#default` prints `app-original:true:shared-original`. The explicit fetcher
signature lets `callPackage` supply every fetcher the generated expression requires.
Do not edit the generated expression or remove workspace records from the real lock.
The full tested layout is in [the workspace fixture](../../../scripts/fixtures/nix-bun-flake/workspace).

### Dependency changes and build behavior

Update manifests first, run `bun install` to update `bun.lock`, then regenerate
`bun-deps.nix` with `nix run .#bun2nix -- --lock-file bun.lock --output-file bun-deps.nix`.
Commit those files together and run the frozen sandbox build. Never change the lock
format number to appease the generator. Registry fetches are hash-checked Nix fetches;
ordinary application build phases have no network. No `--offline` flag is required.

The hook installs with isolated linking. Explicit frozen flags replace its defaults,
so keep `--linker=isolated` and Darwin's `--backend=symlink` as shown. Every install
ignores scripts initially; `dontRunLifecycleScripts=true` skips the hook's second install
that would run lifecycle scripts. Set it only when the build does not need them.
Provide explicit build/install phases for static outputs. If enabling checks for a
package script, use an explicit `checkPhase` with `bun run test`; the hook's default
`bun test` invokes Bun's separate built-in runner.

Named `builtins.path` source selection includes only build inputs, keeping
`node_modules`, local caches and irrelevant checkout files out of the derivation.
Expand the allowlist for real assets/configuration. Do not depend on a plain
`filterSource` retaining a checkout hash. App/shared source edits rebuild the app
and preserve the registry-cache derivation. A registry dependency change changes
the cache after regeneration. Unchanged builds reuse their outputs. Including an
explicit Git revision in a recipe or output name will deliberately cause rebuilds
even when the selected source bytes are unchanged; the cache boundary cannot avoid that.

### Compatibility patch and maintenance

The shared wrapper qualifies bun2nix **2.1.2**, commit
`0f2a1f0b6f42cebe3b149bf62d38754c5e0e9729`, from `mori://nix-community/bun2nix`,
project-relative `programs/bun2nix/src/lib.rs` (source artifact URI pending). Its
derivation selects `programs/bun2nix`, so the patch path is `src/lib.rs`:

```diff
-    if lockfile.lockfile_version != 1 {
+    if !matches!(lockfile.lockfile_version, 1 | 2) {
```

Without it, the released generator reports `Unsupported lockfile version: '2'.`
Bun 1.4.2's v2 uses stronger parse-time validation of the same supported package
tuples: `mori://oven-sh/bun`, project-relative `src/install/lockfile/bun.lock.rs`
(source artifact URI pending). The patch preserves previous `postPatch`, hook and
fetch APIs. `substituteInPlace --replace-fail` makes source drift an error.
Qualification covers ordinary registry packages and local workspaces in v1/v2;
v3, including scoped-override locks, and untested package protocols are unsupported.
This is a narrow gate change, not general lock-format compatibility.

[Released source](https://github.com/nix-community/bun2nix/tree/2.1.2) and the
[upstream hook guide](https://nix-community.github.io/bun2nix/building-packages/hook.html)
explain the helper; the pinned source governs this release. Retire the override only
after verifying a released upstream version accepts required formats and all
generator/frozen-install fixtures pass without it on supported systems. Never silence
a failed substitution, bypass all versions, or silently replace this with a private fork.

Maintainer acceptance:

```bash
python3 scripts/update-nix-bun-flake.py --check
python3 scripts/test-nix-bun-flake.py          # rendering, ownership and evaluation
python3 scripts/test-nix-bun-flake.py --native # actual host-system sandbox builds
python3 scripts/test-fumadocs-adoption.py
```

Repeat native acceptance on `aarch64-darwin`, `aarch64-linux` and `x86_64-linux`;
evaluation alone does not establish native build support. The fixtures compare
generator bytes, reject v3, preserve real locks, run registry-backed outputs, and
check app/shared edits and dependency changes against cache derivation identities.
Fumadocs remains disabled by default and ordinary build/test commands do not use bun2nix.

## See Also

- `module.dhall` — full module definition and authoritative source
- `files/` — template sources
