---
type: SeihouRecipe
title: fumadocs-project
description: Container-enabled Fumadocs with technical writing skills from agent-seihou
  and local Mori registration
resource: seihou://seihou-modules/recipes/fumadocs-project
tags:
- docs
- fumadocs
- container
- mori
- recipe
status: stable
generated:
  by: seihou-okf-extension/0.15.0.0
version: 0.1.0
---

# fumadocs-project

Container-enabled Fumadocs with technical writing skills from agent-seihou and local Mori registration

**Version:** 0.1.0

## Composes

- [fumadocs](/modules/fumadocs.md) (with `docs.container` = `true`, `nix.bun2nix` = `true`, `nix.package-module` = `nix/fumadocs-container.nix`)
- [technical-docs](mori://shinzui/agent-seihou/templates/technical-docs) (from `https://github.com/shinzui/agent-seihou.git`)
- [docs-mori-bootstrap](/modules/docs-mori-bootstrap.md)
