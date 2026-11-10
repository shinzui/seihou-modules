---
okf_version: "0.2"
---

# Files

- [profile.dhall](profile.dhall)

# Friction Entry

- [Seihou noninteractive dry-run requires orphan resolution](1-seihou-noninteractive-dry-run-requires-orphan-resolution.md) - A noninteractive dry-run cannot report an edited orphan until a force resolution is supplied, so the harness must verify the narrowed resolution before applying it.
- [Seihou treats a new dependency binding as a new instance and breaks update](10-seihou-treats-a-new-dependency-binding-as-a-new-instance-and-breaks-update.md) - Adding a var binding to a released dependency makes mori://shinzui/seihou lose the saved inputs of the existing instance, so seihou update fails for existing projects with an error that names neither the dependency nor the binding.
- [Seihou update silently cancels and exits 0 without a terminal](11-seihou-update-silently-cancels-and-exits-0-without-a-terminal.md) - Plain seihou update in a non-interactive shell treats end of input as a declined confirmation, prints a cancellation with no visible prompt, changes nothing and still exits 0, so automation has to retry with --json and cannot detect the skip from the exit status.
- [Seihou copy decodes binary font assets as text](12-seihou-copy-decodes-binary-font-assets-as-text.md) - The released copy strategy rejects WOFF2 bytes, requiring a text-safe vendored font representation.
- [Released Mori must be built for registration qualification](13-released-mori-must-be-built-for-registration-qualification.md) - The installed Mori is 7.1 while plan acceptance requires 7.2, whose release has no executable assets.
- [OKF exporter treats external recipe modules as local links](14-okf-exporter-treats-external-recipe-modules-as-local-links.md) - The released OKF exporter emits a dangling local concept link for a source-qualified recipe module and refuses generation.
- [Mori dependents omits typed project dependency references](15-mori-dependents-omits-typed-project-dependency-references.md) - Mori 7.2 resolves typed dependencyRefs as relations but its dependents command does not return those project edges.
- [Nested scaffold modules have no install-only dependency declaration](16-nested-scaffold-modules-have-no-install-only-dependency-declaration.md) - Seihou 0.15 applies every declared dependency in the invocation directory, so a directory wrapper cannot declare its child scaffold or git-init as ordinary dependencies.
- [Rosetta Linux builder rejects Nix seccomp filter](2-rosetta-linux-builder-rejects-nix-seccomp-filter.md) - The existing x86 Linux Apple container could not load the Nix seccomp BPF filter, requiring a filter-only override while retaining the Nix network sandbox.
- [Translated x86 Python loses its Nix environment prefix](3-translated-x86-python-loses-its-nix-environment-prefix.md) - Python withPackages resolves its base interpreter prefix under the translated x86 Apple container, hiding pyelftools and blocking supplemental shell tooling builds.
- [Released probe schema omits nullable timestamp semantics](4-released-probe-schema-omits-nullable-timestamp-semantics.md) - The released OpenAPI generic record derivation drops Maybe nullability, requiring correction of the derived probe schema before publication.
- [Seihou silently accepts unsupported variable patterns](5-seihou-silently-accepts-unsupported-variable-patterns.md) - Seihou only implements one variable character-class pattern and silently accepts other patterns, requiring supported validation for project and Mori names.
- [Skopeo archive export needs an explicit sandbox temporary directory](6-skopeo-archive-export-needs-an-explicit-sandbox-temporary-directory.md) - The nix2container copy helper inherits Skopeo defaults and failed native archive acceptance because the Nix build sandbox omits /var/tmp.
- [Pinned Orval output needs fidelity and ESM adapters](7-pinned-orval-output-needs-fidelity-and-esm-adapters.md) - Orval 8.46.0 required a derived-output compatibility stage to preserve nullable optional and recursive input types, empty response data, and Node imports.
- [Seihou rejects managed base starters overlapping child seeds](8-seihou-rejects-managed-base-starters-overlapping-child-seeds.md) - Real composition rejected five base-managed starter paths that the client declares as project-owned seeds.
- [Seihou retirement retains bound base wiring and later deletes released seeds](9-seihou-retirement-retains-bound-base-wiring-and-later-deletes-released-seeds.md) - Recorded child retirement leaves inherited base wiring live, while later legacy base removal no longer recognizes retired child seed ownership.

