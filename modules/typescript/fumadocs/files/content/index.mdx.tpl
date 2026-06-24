---
title: {{docs.site-name}}
description: {{project.description}}
---

Welcome to **{{docs.site-name}}**. {{project.description}}

This site is built with [Fumadocs](https://fumadocs.dev) on TanStack Start +
Vite, with a self-hosted code font and interactive Mermaid diagrams.

## Start here

<Cards>
  <Card
    title="Diagram demo"
    href="/docs/diagram-demo"
    description="Beautiful Mermaid diagrams with wheel-zoom, drag-pan, and expand."
  />
</Cards>

## Authoring

Write pages as `.mdx` files under `content/docs/`. Each folder can carry a
`meta.json` to order its pages in the sidebar. Fenced ` ```mermaid ` code blocks
render as interactive, zoomable diagrams — see the demo above.

```mermaid
flowchart LR
    A[Write MDX] --> B[fumadocs-mdx]
    B --> C[Static SPA]
    C --> D[Deploy .output/public]
```
