---
type: Friction Entry
title: "Pinned Orval output needs fidelity and ESM adapters"
description: "Orval 8.46.0 required a derived-output compatibility stage to preserve nullable optional and recursive input types, empty response data, and Node imports."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-11-01T23:42:27Z"
frictionId: FRIC-7
status: logged
impact: detour
kind: tooling
origin: "mori://shinzui/seihou-modules"
affects: "mori://orval-labs/orval"
affectedVersion: "8.46.0"
plan: "docs/plans/11-add-a-bun-based-openapi-typescript-client-module.md"
workaround: "Preserve raw generation; normalize a separately compared client tree with explicit compatibility rewrites and type contracts."
---
# Pinned Orval output needs fidelity and ESM adapters

## Attempted

Generate status-specific validators and fetch factory, then check bidirectional response contracts with TypeScript 7.0.2.

## Encountered

Optional nullable fields used nullish(), recursive ZodType inputs defaulted to unknown, empty bodies decoded as {}, and split imports needed Node normalization.

```text
contracts.ts: TS2344 Type false does not satisfy constraint true; factory Fetch rejected because Bun adds fetch.preconnect.
```

## Workaround

Preserve raw generation; normalize a separately compared client tree with explicit compatibility rewrites and type contracts.
