---
type: Friction Entry
title: "Nested scaffold modules have no install-only dependency declaration"
description: "Seihou 0.15 applies every declared dependency in the invocation directory, so a directory wrapper cannot declare its child scaffold or git-init as ordinary dependencies."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-11-09T23:50:49Z"
frictionId: FRIC-16
status: "accepted"
impact: detour
kind: interface
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/seihou"
affectedVersion: "0.15.0.0"
plan: "docs/plans/14-add-a-containerized-fumadocs-project-recipe-with-technical-writing-skills-and-mori-registration.md"
workaround: "Have repo-dir install its declared child scaffold and git-init through the released installer before running them in the new directory; retain the writing skills external edge in the child recipe"
resolution: "repo-dir acquires its child recipe and git-init through the normal source-aware installer, then applies them in the created directory"
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-11-09T23:59:49Z"
    change: "The create workflow reuses existing modules while preserving directory ownership and external skill acquisition"
---
# Nested scaffold modules have no install-only dependency declaration

## Attempted

Compose repo-dir with the Fumadocs modules and git-init while acquiring all nested requirements from one root installation

## Encountered

Recipe/module dependencies are both acquired and applied; there is no acquisition-only edge or target-directory scope

## Workaround

Have repo-dir install its declared child scaffold and git-init through the released installer before running them in the new directory; retain the writing skills external edge in the child recipe
