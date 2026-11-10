---
type: SeihouRecipe
title: fumadocs-site
description: Apply container-enabled Fumadocs, external writing skills and local Mori
  registration inside an existing checkout
resource: seihou://seihou-modules/recipes/fumadocs-site
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

# fumadocs-site

Apply container-enabled Fumadocs, external writing skills and local Mori registration inside an existing checkout

**Version:** 0.1.0

## Composes

- [fumadocs](/modules/fumadocs.md) (with `docs.container` = `true`, `nix.bun2nix` = `true`, `nix.package-module` = `nix/fumadocs-container.nix`)
- [technical-docs](mori://shinzui/agent-seihou/templates/technical-docs) (from `https://github.com/shinzui/agent-seihou.git`)
- [docs-mori-bootstrap](/modules/docs-mori-bootstrap.md)
