---
type: Friction Entry
title: "Seihou noninteractive dry-run requires orphan resolution"
description: "A noninteractive dry-run cannot report an edited orphan until a force resolution is supplied, so the harness must verify the narrowed resolution before applying it."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-10-26T18:23:33Z"
frictionId: FRIC-1
status: "accepted"
impact: detour
kind: interface
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/seihou"
plan: "docs/plans/7-add-optional-bun2nix-support-to-the-bun-nix-module.md"
workaround: "Use --dry-run --json --force only in the isolated fixture, assert its sole resolution is retainTracked for the edited orphan and that there are no conflicts, then apply the identical command."
resolution: "Retain current Seihou semantics; the isolated regression proves the sole retainTracked resolution before its noninteractive apply, and adoption docs require reviewed interactive choices."
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-10-26T18:28:31Z"
    change: "Accepted the CLI constraint with a narrowly verified fixture workaround."
---
# Seihou noninteractive dry-run requires orphan resolution

## Attempted

Run seihou update nix-bun-flake --var nix.bun2nix=false --dry-run with one edited feature file and select retain through stdin.

## Encountered

The CLI requires an interactive terminal even for dry-run; piped retain input does not qualify.

```text
Update failed [unresolved_conflicts]: Unresolved paths require an interactive terminal or an applicable --force choice: nix/bun2nix-package.nix
```

## Workaround

Use --dry-run --json --force only in the isolated fixture, assert its sole resolution is retainTracked for the edited orphan and that there are no conflicts, then apply the identical command.
