---
type: Friction Entry
title: "OKF exporter treats external recipe modules as local links"
description: "The released OKF exporter emits a dangling local concept link for a source-qualified recipe module and refuses generation."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-11-09T23:31:02Z"
frictionId: FRIC-14
status: "accepted"
impact: detour
kind: tooling
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/seihou"
affectedVersion: "0.15.0.0"
plan: "docs/plans/14-add-a-containerized-fumadocs-project-recipe-with-technical-writing-skills-and-mori-registration.md"
workaround: "Use a repository generation adapter that renders the local graph through the released exporter, restores external edges as canonical Mori links, then validates the final generated bundle"
resolution: "Keep the documented repository generation adapter until a released exporter preserves source-qualified module links"
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-11-09T23:35:30Z"
    change: "Generated documentation now retains external attribution and passes strict validation"
---
# OKF exporter treats external recipe modules as local links

## Attempted

seihou extension run okf -- docs --dir . --out okf-docs --force

## Encountered

recipes/fumadocs-project: link to missing concept: modules/technical-docs

## Workaround

Use a repository generation adapter that renders the local graph through the released exporter, restores external edges as canonical Mori links, then validates the final generated bundle
