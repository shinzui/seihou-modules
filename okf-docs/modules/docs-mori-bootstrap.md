---
type: SeihouModule
title: docs-mori-bootstrap
description: Seed a documentation manifest, associate its documented project and register
  locally with Mori
resource: seihou://seihou-modules/modules/mori/docs-mori-bootstrap
tags:
- docs
- mori
- bootstrap
status: stable
generated:
  by: seihou-okf-extension/0.16.0.0
version: 0.1.0
---

# docs-mori-bootstrap

Seed a documentation manifest, associate its documented project and register locally with Mori

**Version:** 0.1.0

## Declaration metadata

- description: `Seed a project-owned documentation manifest, associate its documented project and register locally with Mori`

## Dependencies

This module has no dependencies.

## Variables

- `project.name` — text, required, matching `[a-z][a-z0-9-]*`. Documentation project name (independent of the documented project).
- `project.description` — text, required. Description of the documentation project.
- `mori.namespace` — text, required, matching `[a-z][a-z0-9-]*`. Namespace of this documentation project.
- `mori.source-namespace` — text, required, matching `[a-z][a-z0-9-]*`. Namespace of the already registered project being documented.
- `mori.source-project` — text, required, matching `[a-z][a-z0-9-]*`. Name of the already registered project being documented.

## Exports

No exports declared.

## Prompts

- `project.name` — `Documentation project name (independent of the documented project).`
- `project.description` — `Description of the documentation project.`
- `mori.namespace` — `Namespace of this documentation project.`
- `mori.source-namespace` — `Namespace of the already registered project being documented.`
- `mori.source-project` — `Name of the already registered project being documented.`

## Generation steps

- `Copy` `bootstrap-docs.py` → `.seihou/docs-mori-bootstrap/bootstrap-docs.py` — Managed: owned and reconciled by Seihou updates
- `Template` `project.name.conf.tpl` → `.seihou/docs-mori-bootstrap/project.name.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `project.description.conf.tpl` → `.seihou/docs-mori-bootstrap/project.description.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `mori.namespace.conf.tpl` → `.seihou/docs-mori-bootstrap/mori.namespace.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `mori.source-namespace.conf.tpl` → `.seihou/docs-mori-bootstrap/mori.source-namespace.conf` — Managed: owned and reconciled by Seihou updates
- `Template` `mori.source-project.conf.tpl` → `.seihou/docs-mori-bootstrap/mori.source-project.conf` — Managed: owned and reconciled by Seihou updates

## Commands

- `python3 .seihou/docs-mori-bootstrap/bootstrap-docs.py` (application command)

## Removal

- delete `.seihou/docs-mori-bootstrap/bootstrap-docs.py`
- delete `.seihou/docs-mori-bootstrap/project.name.conf`
- delete `.seihou/docs-mori-bootstrap/project.description.conf`
- delete `.seihou/docs-mori-bootstrap/mori.namespace.conf`
- delete `.seihou/docs-mori-bootstrap/mori.source-namespace.conf`
- delete `.seihou/docs-mori-bootstrap/mori.source-project.conf`
