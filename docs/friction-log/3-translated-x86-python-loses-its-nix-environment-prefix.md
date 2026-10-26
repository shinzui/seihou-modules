---
type: Friction Entry
title: "Translated x86 Python loses its Nix environment prefix"
description: "Python withPackages resolves its base interpreter prefix under the translated x86 Apple container, hiding pyelftools and blocking supplemental shell tooling builds."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-10-26T18:33:10Z"
frictionId: FRIC-3
status: "accepted"
impact: detour
kind: environment
origin: "mori://shinzui/seihou-modules"
affects: "mori://apple/container"
plan: "docs/plans/7-add-optional-bun2nix-support-to-the-bun-nix-module.md"
workaround: "Build the unchanged x86 tooling derivations through the existing configured native Linux Nix builder, then transfer their closures to the test container; do not change module toolchain pins."
resolution: "The unchanged tooling derivations built on the configured native x86 Linux builder; importing their closures let the translated container pass nix develop -c bun2nix --help without any module or toolchain change."
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-10-26T18:35:36Z"
    change: "Accepted the translated-Python environment limit and documented native build plus closure transfer as the workaround."
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-10-26T18:38:58Z"
    change: "Corrected the affecting project reference to its canonical Mori URI under repository reference policy."
---
# Translated x86 Python loses its Nix environment prefix

## Attempted

Run the supplemental nix develop -c bun2nix --help check on x86 Linux after both application fixtures passed.

## Encountered

The pre-existing Oxfmt auto-patchelf step cannot import elftools; direct python3.withPackages pyelftools reproduces the missing environment prefix on x86, while ARM resolves the environment and imports version 0.32.

```text
ModuleNotFoundError: No module named elftools; x86 sys.prefix is the base python3-3.14.7 output, ARM sys.prefix is python3-3.14.7-env.
```

## Workaround

Build the unchanged x86 tooling derivations through the existing configured native Linux Nix builder, then transfer their closures to the test container; do not change module toolchain pins.
