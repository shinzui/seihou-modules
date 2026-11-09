---
type: Friction Entry
title: "Released Mori must be built for registration qualification"
description: "The installed Mori is 7.1 while plan acceptance requires 7.2, whose release has no executable assets."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-11-09T23:26:56Z"
frictionId: FRIC-13
status: "resolved"
impact: detour
kind: environment
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/mori"
affectedVersion: "7.2.0.0"
plan: "docs/plans/14-add-a-containerized-fumadocs-project-recipe-with-technical-writing-skills-and-mori-registration.md"
workaround: "Build the tagged Mori and migration runner with Nix into temporary output links; leave the global CLI unchanged"
resolution: "Built and qualified Mori v7.2.0.0 and the matching migration runner with temporary Nix output links; global tools were unchanged"
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-11-09T23:34:35Z"
    change: "Released executables are now available for isolated acceptance"
---
# Released Mori must be built for registration qualification

## Attempted

Qualify recipe registration against Mori 7.2.0.0

## Encountered

mori --version reports 7.1.0.0; GitHub release v7.2.0.0 has an empty assets array

## Workaround

Build the tagged Mori and migration runner with Nix into temporary output links; leave the global CLI unchanged
