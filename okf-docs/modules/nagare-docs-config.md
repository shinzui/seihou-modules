---
type: SeihouModule
title: nagare-docs-config
description: Project-owned protected Nagare Application config with independent service,
  hostname and image values
resource: seihou://seihou-modules/modules/cloud/nagare-docs-config
tags:
- nagare
- docs
- deployment
status: stable
generated:
  by: seihou-okf-extension/0.16.0.0
version: 0.1.0
---

# nagare-docs-config

Project-owned protected Nagare Application config with independent service, hostname and image values

**Version:** 0.1.0

## Declaration metadata

- description: `Project-owned protected Nagare Application config for an immutable documentation image; independent full domain and service name (Nagare 0.16.2)`

## Dependencies

This module has no dependencies.

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`
- `nagare.service-name` — text, required, matching `[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?`
- `nagare.namespace` — text, required, default `personal`, matching `[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?`
- `nagare.domain` — text, required, matching `[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?([.][a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+`

## Exports

No exports declared.

## Generation steps

- `Template` `nagare/Config.hs.tpl` → `nagare/Config.hs` — Seed: created once when absent, then project owned; updates and removal preserve it
- `Template` `nagare/README.md.tpl` → `nagare/README.md` — Seed: created once when absent, then project owned; updates and removal preserve it
