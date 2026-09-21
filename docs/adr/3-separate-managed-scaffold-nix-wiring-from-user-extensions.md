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
`nix.builtin-package=false`. It defines its packages and checks there. The dependent scaffold
must not generate `flake.module.nix`; that file remains the unmanaged user extension point and
is imported after managed modules.

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
