---
type: Friction Entry
title: "Seihou retirement retains bound base wiring and later deletes released seeds"
description: "Recorded child retirement leaves inherited base wiring live, while later legacy base removal no longer recognizes retired child seed ownership."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-11-01T23:54:08Z"
frictionId: FRIC-9
status: logged
impact: blocked
kind: interface
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/seihou"
affectedVersion: "0.14.0.0"
plan: "docs/plans/11-add-a-bun-based-openapi-typescript-client-module.md"
---
# Seihou retirement retains bound base wiring and later deletes released seeds

## Attempted

Remove openapi-typescript-client, evaluate the remaining shell, then remove its inherited nix-bun-flake in a temporary project.

## Encountered

Client removal deleted its Nix module without updating the base import; subsequent base removal deleted package.json, tsconfig.json, both Oxc configs and justfile after child seed claims retired.

```text
Client removal: Retired 18 seed claims; project files were kept. Base removal: Delete package.json (unchanged). package exists: False.
```
