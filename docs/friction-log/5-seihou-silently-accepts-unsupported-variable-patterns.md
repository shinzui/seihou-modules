---
type: Friction Entry
title: "Seihou silently accepts unsupported variable patterns"
description: "Seihou only implements one variable character-class pattern and silently accepts other patterns, requiring supported validation for project and Mori names."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-10-27T02:56:23Z"
frictionId: FRIC-5
status: "accepted"
impact: detour
kind: interface
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/seihou"
plan: "docs/plans/8-complete-the-keiro-project-bootstrap-with-api-testing-and-test-data.md"
workaround: "Use the supported lowercase/hyphen character-class pattern for project.name, keiro.context, and mori.namespace in both module and blueprint."
resolution: "Use Seihou supported lowercase name validation in both descriptors and require path-like inputs to fail before writes; broader regex support remains outside this bootstrap."
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-10-27T03:05:42Z"
    change: "Accept the supported character-class validation and enforce it with generated-project checks."
---
# Seihou silently accepts unsupported variable patterns

## Attempted

Render with mori.generate=true and mori.namespace=../bad, expecting the declared validation pattern to reject before writes

## Encountered

The declaration passed because simplePatternMatch returns True for every pattern except [a-z][a-z0-9-]*; the previous project.name pattern was affected too.

```text
Seihou.Core.Variable.simplePatternMatch: otherwise = True -- unknown patterns pass by default
```

## Workaround

Use the supported lowercase/hyphen character-class pattern for project.name, keiro.context, and mori.namespace in both module and blueprint.
