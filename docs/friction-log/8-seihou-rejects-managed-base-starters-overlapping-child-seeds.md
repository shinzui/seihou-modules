---
type: Friction Entry
title: "Seihou rejects managed base starters overlapping child seeds"
description: "Real composition rejected five base-managed starter paths that the client declares as project-owned seeds."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-11-01T23:50:21Z"
frictionId: FRIC-8
status: "accepted"
impact: detour
kind: interface
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/seihou"
affectedVersion: "0.14.0.0"
plan: "docs/plans/11-add-a-bun-based-openapi-typescript-client-module.md"
workaround: "Give the Bun base a default-on starter-output switch, disabled by the child, with matching conditional removal."
resolution: "Keep mixed managed/seed overlap rejection and compose through the default-on Bun starter-output switch; the client disables those outputs and matching cleanup, as documented in ADRs 3 and 8."
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-11-02T00:55:30Z"
    change: "Accepted explicit output ownership as the composition contract; publication of the conditional-removal runtime remains tracked by FRIC-9."
---
# Seihou rejects managed base starters overlapping child seeds

## Attempted

seihou run openapi-typescript-client with the published seed schema and nix-bun-flake dependency

## Encountered

Plan compilation rejected package.json, tsconfig.json, justfile and Oxc configs because seed and managed steps overlap.

```text
seed 'package.json' overlaps a different lifecycle or file destination 'package.json'
```

## Workaround

Give the Bun base a default-on starter-output switch, disabled by the child, with matching conditional removal.
