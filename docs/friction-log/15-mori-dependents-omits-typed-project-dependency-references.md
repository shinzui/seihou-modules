---
type: Friction Entry
title: "Mori dependents omits typed project dependency references"
description: "Mori 7.2 resolves typed dependencyRefs as relations but its dependents command does not return those project edges."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-11-09T23:32:45Z"
frictionId: FRIC-15
status: "accepted"
impact: detour
kind: interface
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/mori"
affectedVersion: "7.2.0.0"
plan: "docs/plans/14-add-a-containerized-fumadocs-project-recipe-with-technical-writing-skills-and-mori-registration.md"
workaround: "Query the typed association in both directions with registry relations --from and --to; preserve the minimal typed manifest"
resolution: "Use registry relations --to and --from for typed-only project associations in Mori 7.2"
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-11-09T23:35:30Z"
    change: "Document and test the supported relation query surface without redundant legacy dependencies"
---
# Mori dependents omits typed project dependency references

## Attempted

Verify the generated association with mori registry dependents products/widget-engine --json

## Encountered

The command returns an empty list while registry relations --from reports a resolved depends-on edge

## Workaround

Query the typed association in both directions with registry relations --from and --to; preserve the minimal typed manifest
