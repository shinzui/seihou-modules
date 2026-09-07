---
type: SeihouModule
title: haskell-keiro-project
description: 'Bootstrap the six-package Keiro service structure, workspace-first domain workflow, and implementation brief on nix-haskell-flake. Domain implementation is completed by the haskell-keiro-service blueprint.'
resource: seihou://seihou-modules/modules/haskell-keiro-project
tags: [haskell, keiro, service, bootstrap]
version: 0.1.0
---

# haskell-keiro-project

Bootstrap the six-package Keiro service structure, workspace-first domain workflow, and implementation brief on nix-haskell-flake. Domain implementation is completed by the haskell-keiro-service blueprint.

**Version:** 0.1.0

## Dependencies

- [nix-haskell-flake](/modules/nix-haskell-flake.md)

## Variables

- `project.name` (required)
- `project.description` (required)
- `project.namespace` (required)
- `project.author` (default: `Nadeem Bitar`)
- `project.maintainer` (default: `nadeem@gmail.com`)
- `project.copyright-year` (default: `2026`)
- `keiro.context` (required)
- `haskell.index-state` (default: `2026-09-07T00:00:00Z`)

## Usage

```bash
seihou run haskell-keiro-project
```

Generates six initial libraries, a workspace manifest, development recipes, and
`docs/bootstrap-keiro.md`. Complete domain implementation with the
[haskell-keiro-service blueprint](/blueprints/haskell-keiro-service.md).
The initial libraries build, but do not implement HTTP, workers, migrations, or business behavior.
