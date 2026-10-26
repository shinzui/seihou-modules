---
okf_version: "0.2"
---

# Files

- [profile.dhall](profile.dhall)

# Friction Entry

- [Seihou noninteractive dry-run requires orphan resolution](1-seihou-noninteractive-dry-run-requires-orphan-resolution.md) - A noninteractive dry-run cannot report an edited orphan until a force resolution is supplied, so the harness must verify the narrowed resolution before applying it.
- [Rosetta Linux builder rejects Nix seccomp filter](2-rosetta-linux-builder-rejects-nix-seccomp-filter.md) - The existing x86 Linux Apple container could not load the Nix seccomp BPF filter, requiring a filter-only override while retaining the Nix network sandbox.
- [Translated x86 Python loses its Nix environment prefix](3-translated-x86-python-loses-its-nix-environment-prefix.md) - Python withPackages resolves its base interpreter prefix under the translated x86 Apple container, hiding pyelftools and blocking supplemental shell tooling builds.
