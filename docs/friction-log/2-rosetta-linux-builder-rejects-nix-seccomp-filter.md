---
type: Friction Entry
title: "Rosetta Linux builder rejects Nix seccomp filter"
description: "The existing x86 Linux Apple container could not load the Nix seccomp BPF filter, requiring a filter-only override while retaining the Nix network sandbox."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-10-26T18:24:55Z"
frictionId: FRIC-2
status: "accepted"
impact: detour
kind: environment
origin: "mori://shinzui/seihou-modules"
affects: "mori://apple/container"
plan: "docs/plans/7-add-optional-bun2nix-support-to-the-bun-nix-module.md"
workaround: "Set filter-syscalls = false only in the test coordinator environment; continue passing sandbox = true for every application build and check."
resolution: "Both x86 Linux layouts passed with filter-syscalls=false and sandbox=true; retain the environment qualification without changing module pins or weakening application network isolation."
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-10-26T18:28:31Z"
    change: "Accepted the translated-container syscall limitation after native sandbox acceptance passed."
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-10-26T18:38:58Z"
    change: "Corrected the affecting project reference to its canonical Mori URI under repository reference policy."
---
# Rosetta Linux builder rejects Nix seccomp filter

## Attempted

Run frozen native x86_64-linux acceptance in mp3-linux-builder with --option sandbox true.

## Encountered

Nix failed to set up a build environment under the translated x86 container.

```text
error: unable to load seccomp BPF program: Invalid argument
```

## Workaround

Set filter-syscalls = false only in the test coordinator environment; continue passing sandbox = true for every application build and check.
