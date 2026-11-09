---
type: Friction Entry
title: "Seihou copy decodes binary font assets as text"
description: "The released copy strategy rejects WOFF2 bytes, requiring a text-safe vendored font representation."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-11-09T14:58:04Z"
frictionId: FRIC-12
status: "accepted"
impact: detour
kind: interface
origin: "mori://shinzui/seihou-modules"
affects: "mori://shinzui/seihou"
affectedVersion: "0.15.0.0"
plan: "docs/plans/13-bootstrap-documentation-microapps-with-tanstack-start-and-nagare-recipes.md"
workaround: "Seed checksum-verified base64 font sources; the Vite plugin decodes and emits the same WOFF2 bytes for development and production without network access."
resolution: "Retain checksum-verified base64 font seeds and local Vite decoding until the released copy strategy supports binary payloads."
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-11-09T15:28:03Z"
    change: "Accepted the scoped scaffold workaround; original release bytes and licenses remain auditable and browser tests verify the decoded fonts."
---
# Seihou copy decodes binary font assets as text

## Attempted

Generate seeded WOFF2 files through seihou run docs-microapp --no-commands.

## Encountered

Plan compilation failed while decoding both binary WOFF2 sources.

```text
hGetContents: invalid argument (cannot decode byte sequence starting from 183)
```

## Workaround

Seed checksum-verified base64 font sources; the Vite plugin decodes and emits the same WOFF2 bytes for development and production without network access.
