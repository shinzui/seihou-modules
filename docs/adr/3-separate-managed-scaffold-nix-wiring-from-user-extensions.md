# Separate managed scaffold Nix wiring from user extensions

## Status

Accepted on 2026-09-20.

## Context

`nix-haskell-flake` provides shared development shells from
`mori://shinzui/haskell-nix-dev` and can build a single Cabal package at the repository root.
Composed scaffolds may need a different package topology. In particular, `haskell-cli-app`
generates two Cabal packages in child directories, so the generic root `callCabal2nix` output
cannot build it.

The generated `flake.module.nix` is deliberately unmanaged: users copy the example and keep
project-specific tools, outputs, overlays, and environment wiring there so Seihou upgrades do
not conflict with their changes. Having a scaffold generate that file would solve package wiring
by taking over the user extension point and reintroducing the conflicts it exists to avoid.

## Decision

`nix-haskell-flake` exposes an optional `nix.package-module` variable containing a validated,
project-relative `.nix` path. When set, the managed `flake.nix` imports that flake-parts module
alongside `nix/haskell.nix` and watches it from `.envrc`.

A dependent scaffold that needs custom package outputs owns the referenced file and binds
`nix.builtin-package=false`. It defines its packages, checks, or scaffold-specific development tools there. The dependent scaffold
must not generate `flake.module.nix`; that file remains the unmanaged user extension point and
is imported after managed modules.

The Keiro scaffold owns nix/keiro-dev-tools.nix through the same seam, contributing only
extraDevPackages; it does not introduce a second application runtime/toolchain.

The CLI scaffold therefore owns `nix/haskell-cli-app.nix`, which recursively adds its core and
CLI packages to the selected GHC package set, exposes both outputs, makes the CLI the default,
and adds its Tasty suite as a check.

## Consequences

Multi-package scaffolds can ship working Nix outputs without teaching the base module every
possible repository layout. Ownership stays explicit: the base module owns the import seam, the
dependent scaffold owns its package module, and the user owns `flake.module.nix`.

Changing a scaffold's generated package wiring remains a normal Seihou-managed update and may
conflict with direct edits to that managed file. Users who need additional project-specific Nix
behavior extend `flake.module.nix` instead. A project must not enable the base root package output
and a dependent package module that both define `packages.default`, because flake-parts will
reject the duplicate definition.

## Bun scaffold extension (2026-11-01)

The Bun base exposes the same optional `nix.package-module` seam. Its managed
module contributes tools through `perSystem.bunProject.extraDevPackages`, keeping
one Bun/TypeScript/Oxc toolchain and the canonical lock. The optional import and
`.envrc` watch are conditional on the contributing file existing, so removing a
client module leaves any surviving base shell valid. The user's unmanaged
`flake.module.nix` remains last in import order.

`bun.starter-files` defaults to true. A dependent module providing its own project
seeds disables the base's five starter outputs and their matching removal steps.
Mixed managed/seed destinations are rejected; overwrite order cannot establish
ownership. Accepted run/update settles removal conditions from typed inputs and
records Boolean results per application instance. Removal reuses those results;
flattened text or a shared module summary cannot recover the accepted decision.
This requires the 0.15.0.0/schema-14 contract from `mori://shinzui/seihou`.
Separate applications sharing a configured base must use identical dependency
bindings; conflicting instances still fail safely.
