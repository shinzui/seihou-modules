---
type: Friction Entry
title: "Skopeo archive export needs an explicit sandbox temporary directory"
description: "The nix2container copy helper inherits Skopeo defaults and failed native archive acceptance because the Nix build sandbox omits /var/tmp."
generated:
  by: "codex-cli/gpt-6.1-sol"
  at: "2026-10-27T20:12:20Z"
frictionId: FRIC-6
status: "resolved"
impact: detour
kind: environment
origin: "mori://shinzui/seihou-modules"
affects: "mori://nlewo/nix2container"
plan: "docs/plans/9-use-nix2container-for-haskell-service-images-and-migrate-existing-consumers.md"
workaround: "Pass --tmpdir \"$TMPDIR\" through copyTo; inspect the exported archive in the build temporary directory."
resolution: "The native archive check now passes Skopeo --tmpdir explicitly, and ADR 7 records the sandbox requirement."
amended:
  - by: "codex-cli/gpt-6.1-sol"
    at: "2026-10-27T20:13:14Z"
    change: "Resolved sandbox export failure with an explicit writable temporary directory."
---
# Skopeo archive export needs an explicit sandbox temporary directory

## Attempted

Export a real Linux image through copyTo inside a Nix build check.

## Encountered

Skopeo attempted to create a temporary layer under absent /var/tmp and exited before writing the archive.

```text
creating temporary on-disk layer: open /var/tmp/container_images_stream-blob: no such file or directory
```

## Workaround

Pass --tmpdir "$TMPDIR" through copyTo; inspect the exported archive in the build temporary directory.
